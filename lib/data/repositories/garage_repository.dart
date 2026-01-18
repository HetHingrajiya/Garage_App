import 'package:autocare_pro/data/models/customer_model.dart';
import 'package:autocare_pro/data/models/inventory_model.dart';
import 'package:autocare_pro/data/models/job_card_model.dart';
import 'package:autocare_pro/data/models/service_model.dart';
import 'package:autocare_pro/data/models/invoice_model.dart';
import 'package:autocare_pro/data/models/notification_model.dart';
import 'package:autocare_pro/data/models/payment_model.dart';
import 'package:autocare_pro/data/models/settings_model.dart';
import 'package:autocare_pro/data/models/user_model.dart';
import 'package:autocare_pro/data/models/vehicle_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GarageRepository {
  final FirebaseFirestore _firestore;

  GarageRepository(this._firestore);

  // --- Customers ---
  /// Get customers with optional filtering by admin
  /// If adminId is null, returns all customers (for super admin)
  /// If adminId is provided, returns only customers created by that admin
  Stream<List<Customer>> getCustomers({String? createdByAdminId}) {
    Query query = _firestore.collection('customers');

    // Filter by admin if specified (not super admin)
    if (createdByAdminId != null) {
      query = query.where('createdByAdminId', isEqualTo: createdByAdminId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .where((c) => c.status == 'Active')
          .toList();
    });
  }

  Future<void> addCustomer(Customer customer) async {
    // Check for duplicate mobile
    final existingDocs = await _firestore
        .collection('customers')
        .where('mobile', isEqualTo: customer.mobile)
        .get();

    if (existingDocs.docs.isNotEmpty) {
      throw Exception('Customer with this mobile number already exists.');
    }

    await _firestore
        .collection('customers')
        .doc(customer.id)
        .set(customer.toMap());
  }

  Future<void> updateCustomer(Customer customer) async {
    await _firestore
        .collection('customers')
        .doc(customer.id)
        .update(customer.toMap());
  }

  Future<void> deleteCustomer(String id) async {
    // Soft Delete
    await _firestore.collection('customers').doc(id).update({
      'status': 'Inactive',
    });
  }

  Future<Customer?> getCustomer(String id) async {
    final doc = await _firestore.collection('customers').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Customer.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Stream<List<Customer>> searchCustomers(String query) {
    // Basic search filtering on client side for flexibility (Firestore doesn't support substring)
    return _firestore.collection('customers').snapshots().map((snapshot) {
      final customers = snapshot.docs
          .map((doc) => Customer.fromMap(doc.data(), doc.id))
          .where((c) => c.status != 'Inactive') // Filter out inactive
          .toList();

      if (query.isEmpty) return customers;

      final lowerQuery = query.toLowerCase();
      return customers.where((c) {
        return c.name.toLowerCase().contains(lowerQuery) ||
            (c.mobile?.contains(lowerQuery) ?? false);
      }).toList();
    });
  }

  // --- Vehicles ---
  Stream<List<Vehicle>> getVehicles({String? customerId}) {
    Query query = _firestore.collection('vehicles');

    if (customerId != null && customerId.isNotEmpty) {
      query = query.where('customerId', isEqualTo: customerId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                Vehicle.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    // Check duplicate vehicle number
    final existingDocs = await _firestore
        .collection('vehicles')
        .where('number', isEqualTo: vehicle.number)
        .get();

    if (existingDocs.docs.isNotEmpty) {
      throw Exception('Vehicle with this number already exists.');
    }

    // Dual Update using Transaction:
    // 1. Create Vehicle Document
    // 2. Add vehicleId to Customer's vehicleIds array
    final vehicleRef = _firestore.collection('vehicles').doc(vehicle.id);
    final customerRef = _firestore
        .collection('customers')
        .doc(vehicle.customerId);

    await _firestore.runTransaction((transaction) async {
      // Optional: Check if customer exists to prevent orphans
      final customerDoc = await transaction.get(customerRef);
      if (!customerDoc.exists) {
        throw Exception('Customer not found with ID: ${vehicle.customerId}');
      }

      // 1. Set Vehicle Data
      transaction.set(vehicleRef, vehicle.toMap());

      // 2. Update Customer's vehicleIds
      transaction.update(customerRef, {
        'vehicleIds': FieldValue.arrayUnion([vehicle.id]),
      });
    });
  }

  Future<void> addCustomerWithVehicle(
    Customer customer,
    Vehicle vehicle,
  ) async {
    // Check for duplicate mobile
    final existingCustomerDocs = await _firestore
        .collection('customers')
        .where('mobile', isEqualTo: customer.mobile)
        .get();

    if (existingCustomerDocs.docs.isNotEmpty) {
      throw Exception('Customer with this mobile number already exists.');
    }

    // Check duplicate vehicle number
    final existingVehicleDocs = await _firestore
        .collection('vehicles')
        .where('number', isEqualTo: vehicle.number)
        .get();

    if (existingVehicleDocs.docs.isNotEmpty) {
      throw Exception('Vehicle with this number already exists.');
    }

    final customerRef = _firestore.collection('customers').doc(customer.id);
    final vehicleRef = _firestore.collection('vehicles').doc(vehicle.id);

    await _firestore.runTransaction((transaction) async {
      // 1. Set Customer Data (with vehicleId already in list if passed, or we add it)
      // We ensure the customer has the vehicle ID in their list
      final updatedCustomer = customer.copyWith(
        vehicleIds: [...customer.vehicleIds, vehicle.id],
      );
      transaction.set(customerRef, updatedCustomer.toMap());

      // 2. Set Vehicle Data
      transaction.set(vehicleRef, vehicle.toMap());
    });
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _firestore
        .collection('vehicles')
        .doc(vehicle.id)
        .update(vehicle.toMap());
  }

  Stream<List<Vehicle>> searchVehicles(String query, {String? customerId}) {
    return _firestore.collection('vehicles').snapshots().map((snapshot) {
      final vehicles = snapshot.docs
          .map((doc) => Vehicle.fromMap(doc.data(), doc.id))
          .where((v) => v.status != 'Sold') // Example filter based on logic
          .toList();

      // Filter by Customer if provided
      final customerFiltered = customerId != null
          ? vehicles.where((v) => v.customerId == customerId).toList()
          : vehicles;

      if (query.isEmpty) return customerFiltered;

      final lowerQuery = query.toLowerCase();
      return customerFiltered.where((v) {
        return v.number.toLowerCase().contains(lowerQuery) ||
            v.brand.toLowerCase().contains(lowerQuery) ||
            v.model.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  // --- Job Cards ---
  Stream<List<JobCard>> getJobCards() {
    return _firestore
        .collection('job_cards')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JobCard.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<JobCard>> getJobCardsByVehicleId(String vehicleId) {
    return _firestore
        .collection('job_cards')
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JobCard.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> createJobCard(JobCard jobCard) async {
    // Generate ID or use provided.
    // Ideally we might want to check for 'jobNumber' uniqueness here if generated locally.
    await _firestore
        .collection('job_cards')
        .doc(jobCard.id)
        .set(jobCard.toMap());
  }

  Future<void> updateJobStatus(String id, String status) async {
    await _firestore.collection('job_cards').doc(id).update({'status': status});
  }

  Future<void> closeJobCard(String id, int finalKm, String remarks) async {
    await _firestore.collection('job_cards').doc(id).update({
      'status': 'Delivered',
      'finalKm': finalKm,
      'notes': remarks,
      // 'estimatedDeliveryDate': FieldValue.delete(), // Optional cleanup
    });
  }

  // --- Inventory: See 'Inventory Management' section below ---

  // --- Services ---
  Stream<List<GarageService>> getServices() {
    return _firestore.collection('services').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => GarageService.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // --- Billing & Invoicing ---

  Future<void> addServiceToJob(String jobId, JobService service) async {
    await _firestore.collection('job_cards').doc(jobId).update({
      'selectedServices': FieldValue.arrayUnion([service.toMap()]),
    });
  }

  Future<void> addPartToJob(String jobId, JobPart part) async {
    await _firestore.collection('job_cards').doc(jobId).update({
      'selectedParts': FieldValue.arrayUnion([part.toMap()]),
    });
  }

  Future<void> createInvoice(Invoice invoice) async {
    // Check for existing invoice for this job
    final existingDocs = await _firestore
        .collection('invoices')
        .where('jobCardId', isEqualTo: invoice.jobCardId)
        .limit(1)
        .get();

    if (existingDocs.docs.isNotEmpty) {
      throw Exception('Invoice already exists for this job.');
    }

    // 1. Create Invoice
    await _firestore
        .collection('invoices')
        .doc(invoice.id)
        .set(invoice.toMap());
    // 2. Update Job Status to 'Completed' (if not already) or just marker
    await updateJobStatus(invoice.jobCardId, 'Completed');
  }

  Stream<List<Invoice>> getInvoices({String? jobId}) {
    Query query = _firestore
        .collection('invoices')
        .orderBy('date', descending: true);
    if (jobId != null) query = query.where('jobCardId', isEqualTo: jobId);

    return query.snapshots().map(
      (qs) => qs.docs
          .map((d) => Invoice.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList(),
    );
  }

  Future<void> recordPayment(Payment payment) async {
    // 1. Add Payment Record
    await _firestore
        .collection('payments')
        .doc(payment.id)
        .set(payment.toMap());

    // 2. Update Invoice Payment Status
    // Fetch current invoice to calculate total paid
    final invoiceDoc = await _firestore
        .collection('invoices')
        .doc(payment.invoiceId)
        .get();
    final invoice = Invoice.fromMap(invoiceDoc.data()!, invoiceDoc.id);

    // Calculate total paid so far (this might need a separate query or aggregation,
    // for now assuming we trust client or simple logic: check balance)
    // Better: Fetch all payments for this invoice
    final paymentsSnap = await _firestore
        .collection('payments')
        .where('invoiceId', isEqualTo: payment.invoiceId)
        .get();
    double totalPaid = 0;
    for (var doc in paymentsSnap.docs) {
      totalPaid += (doc.data()['amount'] ?? 0);
    }

    String newStatus = 'Pending';
    if (totalPaid >= invoice.total) {
      newStatus = 'Paid';
      // Also update Job to Delivered if Paid? Optional logic.
    } else if (totalPaid > 0) {
      newStatus = 'Partial';
    }

    await _firestore.collection('invoices').doc(payment.invoiceId).update({
      'paymentStatus': newStatus,
    });

    if (newStatus == 'Paid') {
      try {
        final jobSnapshot = await _firestore
            .collection('job_cards')
            .doc(invoice.jobCardId)
            .get();
        if (jobSnapshot.exists) {
          final jobCard = JobCard.fromMap(jobSnapshot.data()!, jobSnapshot.id);
          await updateJobStatusWithNotification(jobCard, 'Delivered');
        }
      } catch (e) {
        debugPrint('Error auto-updating job status: $e');
      }
    }
  }

  // --- Inventory Management ---

  Stream<List<InventoryItem>> getInventory({String? category}) {
    // Fetch ALL items, then filter/sort client-side.
    // This avoids ALL Firestore Index issues (Composite/Ordering).
    debugPrint('🔧 Fetching inventory (Client-Side Mode)');
    return _firestore.collection('inventory').snapshots().map((qs) {
      var items = qs.docs
          .map((d) => InventoryItem.fromMap(d.data(), d.id))
          .toList();

      // Filter by Category
      if (category != null && category != 'All') {
        items = items.where((i) => i.category == category).toList();
      }

      // Sort by Name
      items.sort((a, b) => a.name.compareTo(b.name));

      return items;
    });
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    // Check Status logic
    String status = item.quantity == 0
        ? 'Out of Stock'
        : (item.quantity <= item.lowStockThreshold ? 'Low Stock' : 'In Stock');
    // Using a map to force update status based on logic
    final data = item.toMap();
    data['status'] = status;

    await _firestore.collection('inventory').doc(item.id).set(data);
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    String status = item.quantity == 0
        ? 'Out of Stock'
        : (item.quantity <= item.lowStockThreshold ? 'Low Stock' : 'In Stock');
    final data = item.toMap();
    data['status'] = status;
    await _firestore.collection('inventory').doc(item.id).update(data);
  }

  Future<void> deductStock(String itemId, int qty) async {
    final docRef = _firestore.collection('inventory').doc(itemId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Item does not exist!");

      final currentQty = snapshot.data()!['quantity'] as int;
      final newQty = currentQty - qty;
      final lowStockThreshold = snapshot.data()!['lowStockThreshold'] as int;

      if (newQty < 0) throw Exception("Not enough stock!");

      String status = newQty == 0
          ? 'Out of Stock'
          : (newQty <= lowStockThreshold ? 'Low Stock' : 'In Stock');

      transaction.update(docRef, {'quantity': newQty, 'status': status});
    });
  }

  // --- Mechanic Management ---

  Stream<List<UserModel>> getMechanics() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'mechanic')
        .snapshots()
        .map(
          (qs) =>
              qs.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<UserModel?> getMechanic(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // --- Notifications ---

  Future<void> createNotification(GarageNotification notification) async {
    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }

  Stream<List<GarageNotification>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (qs) => qs.docs
              .map((d) => GarageNotification.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // Update Job Status with Notification Trigger
  // Replacing previous generic method to include notification logic
  Future<void> updateJobStatusWithNotification(
    JobCard job,
    String newStatus,
  ) async {
    // 1. Update Status
    await updateJobStatus(job.id, newStatus);

    // 2. Create Notification for Customer
    final notifId = const Uuid().v4();
    final notification = GarageNotification(
      id: notifId,
      userId: job.customerId,
      title: 'Job Status Update',
      message: 'Your Job #${job.jobNo} is now $newStatus',
      type: 'Status',
      date: DateTime.now(),
    );
    await createNotification(notification);
  }

  // Accept Online Booking: Assign Mechanic + Update Status + Notify
  Future<void> acceptBooking({
    required String jobId,
    required String customerId,
    required String jobNo,
    required List<String> mechanicIds,
  }) async {
    // 1. Update Job Card
    await _firestore.collection('job_cards').doc(jobId).update({
      'status': 'Received',
      'mechanicIds': mechanicIds,
    });

    // 2. Notify Customer
    final notifId = const Uuid().v4();
    final notification = GarageNotification(
      id: notifId,
      userId: customerId,
      title: 'Booking Confirmed',
      message:
          'Your service appointment #${jobNo} has been confirmed. Mechanic assigned.',
      type: 'Status',
      date: DateTime.now(),
    );
    await createNotification(notification);
  }

  // --- Reports & Analytics ---

  // Income Stats: { 'total': double, 'received': double, 'pending': double }
  Future<Map<String, double>> getIncomeStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _firestore.collection('invoices');
    if (startDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    final qs = await query.get();
    double total = 0;
    double received = 0;
    double pending = 0;

    // Using client-side aggregation as Firestore doesn't support sum queries easily without extensions
    for (var doc in qs.docs) {
      final Invoice inv = Invoice.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      total += inv.total;
      if (inv.paymentStatus == 'Paid') {
        received += inv.total;
      } else if (inv.paymentStatus == 'Partial') {
        // Assuming partial logic elsewhere, but for now treat as pending based on status or check payments
        // For simplicity in this iteration:
        pending += inv.total;
      } else {
        pending += inv.total;
      }
    }

    // Better accuracy: Fetch Payments for 'Received'
    // But sticking to Invoice Status for 'Billed' vs 'Pending' Overview
    return {'total': total, 'received': received, 'pending': pending};
  }

  // Mechanic Performance: { 'mechanicId': count }
  Future<Map<String, int>> getMechanicJobCounts() async {
    // Fetch all completed jobs
    final qs = await _firestore.collection('job_cards').get();

    Map<String, int> counts = {};
    for (var doc in qs.docs) {
      final job = JobCard.fromMap(doc.data(), doc.id);
      // Only count completed/delivered
      if (['Completed', 'Delivered'].contains(job.status)) {
        for (var mechId in job.mechanicIds) {
          counts[mechId] = (counts[mechId] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  // Inventory Stats: { 'totalValue': double, 'lowStockCount': int }
  Future<Map<String, dynamic>> getInventoryStats() async {
    final qs = await _firestore.collection('inventory').get();
    double totalValue = 0;
    int lowStockCount = 0;

    for (var doc in qs.docs) {
      final item = InventoryItem.fromMap(doc.data(), doc.id);
      totalValue += (item.purchasePrice * item.quantity);
      if (item.quantity <= item.lowStockThreshold) {
        lowStockCount++;
      }
    }
    return {
      'totalValue': totalValue,
      'lowStockCount': lowStockCount,
      'totalItems': qs.docs.length,
    };
  }

  // --- Settings ---

  Future<GarageSettings> getSettings() async {
    final doc = await _firestore
        .collection('settings')
        .doc('garage_config')
        .get();
    if (doc.exists && doc.data() != null) {
      return GarageSettings.fromMap(doc.data()!);
    }
    return GarageSettings(); // Default
  }

  Future<void> updateSettings(GarageSettings settings) async {
    await _firestore
        .collection('settings')
        .doc('garage_config')
        .set(settings.toMap());
  }

  // --- Initialize Default Inventory ---
  Future<void> initializeDefaultInventory() async {
    // Check if inventory already has items
    final snapshot = await _firestore.collection('inventory').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return; // Inventory already initialized
    }

    try {
      // Load JSON from assets
      final String response = await rootBundle.loadString(
        'assets/data/default_inventory.json',
      );
      final List<dynamic> data = jsonDecode(response);

      for (var itemData in data) {
        final item = InventoryItem(
          id: const Uuid().v4(),
          name: itemData['name'],
          category: itemData['category'],
          brand: itemData['brand'],
          quantity: itemData['quantity'],
          purchasePrice: (itemData['purchasePrice'] as num).toDouble(),
          price: (itemData['price'] as num).toDouble(),
          lowStockThreshold: 5, // Default or add to JSON if needed
          vehicleType: itemData['vehicleType'],
        );

        await addInventoryItem(item);
      }
    } catch (e) {
      debugPrint('Error initializing inventory: $e');
    }
  }
}

final garageRepositoryProvider = Provider<GarageRepository>((ref) {
  return GarageRepository(FirebaseFirestore.instance);
});
