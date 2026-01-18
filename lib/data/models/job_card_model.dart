import 'package:cloud_firestore/cloud_firestore.dart';

class JobService {
  final String id;
  final String name;
  final double price;

  JobService({required this.id, required this.name, required this.price});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'price': price};
  factory JobService.fromMap(Map<String, dynamic> map) => JobService(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    price: (map['price'] ?? 0).toDouble(),
  );
}

class JobPart {
  final String id;
  final String name;
  final double price;
  final int quantity;

  JobPart({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
  };
  factory JobPart.fromMap(Map<String, dynamic> map) => JobPart(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    price: (map['price'] ?? 0).toDouble(),
    quantity: map['quantity'] ?? 0,
  );
}

class JobCard {
  final String id;
  final String jobNo;
  final String vehicleId;
  final String customerId;
  final List<String> mechanicIds; // Multiple mechanics
  final String
  status; // 'Received', 'Inspection', 'InProgress', 'Completed', 'Delivered'
  final String priority; // 'Low', 'Medium', 'High'
  final DateTime date;
  final DateTime? estimatedDeliveryDate;
  final String
  complaint; // Single large text or list, adhering to req "Problem Description"
  final int initialKm;
  final int? finalKm;
  final double totalAmount;
  final String? notes; // Remarks
  final List<JobService> selectedServices;
  final List<JobPart> selectedParts;
  final String? bookingSource;
  final String? scheduledTimeSlot;
  final String? serviceType;
  final String? serviceCategory;

  JobCard({
    required this.id,
    required this.jobNo,
    required this.vehicleId,
    required this.customerId,
    this.mechanicIds = const [],
    required this.status,
    this.priority = 'Medium',
    required this.date,
    this.estimatedDeliveryDate,
    required this.complaint,
    required this.initialKm,
    this.finalKm,
    this.totalAmount = 0.0,
    this.notes,
    this.selectedServices = const [],
    this.selectedParts = const [],
    this.bookingSource,
    this.scheduledTimeSlot,
    this.serviceType,
    this.serviceCategory,
  });

  Map<String, dynamic> toMap() {
    return {
      'jobNo': jobNo,
      'vehicleId': vehicleId,
      'customerId': customerId,
      'mechanicIds': mechanicIds,
      'status': status,
      'priority': priority,
      'date': Timestamp.fromDate(date),
      'estimatedDeliveryDate': estimatedDeliveryDate != null
          ? Timestamp.fromDate(estimatedDeliveryDate!)
          : null,
      'complaint': complaint,
      'initialKm': initialKm,
      'finalKm': finalKm,
      'totalAmount': totalAmount,
      'notes': notes,
      'selectedServices': selectedServices.map((e) => e.toMap()).toList(),
      'selectedParts': selectedParts.map((e) => e.toMap()).toList(),
      'bookingSource': bookingSource,
      'scheduledTimeSlot': scheduledTimeSlot,
      'serviceType': serviceType,
      'serviceCategory': serviceCategory,
    };
  }

  factory JobCard.fromMap(Map<String, dynamic> map, String id) {
    return JobCard(
      id: id,
      jobNo: map['jobNo'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      customerId: map['customerId'] ?? '',
      mechanicIds: List<String>.from(map['mechanicIds'] ?? []),
      status: map['status'] ?? 'Received',
      priority: map['priority'] ?? 'Medium',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedDeliveryDate: (map['estimatedDeliveryDate'] as Timestamp?)
          ?.toDate(),
      complaint: map['complaint'] ?? '',
      initialKm: map['initialKm'] ?? 0,
      finalKm: map['finalKm'],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      notes: map['notes'],
      selectedServices:
          (map['selectedServices'] as List<dynamic>?)
              ?.map((e) => JobService.fromMap(e))
              .toList() ??
          [],
      selectedParts:
          (map['selectedParts'] as List<dynamic>?)
              ?.map((e) => JobPart.fromMap(e))
              .toList() ??
          [],
      bookingSource: map['bookingSource'],
      scheduledTimeSlot: map['scheduledTimeSlot'],
      serviceType: map['serviceType'],
      serviceCategory: map['serviceCategory'],
    );
  }
}
