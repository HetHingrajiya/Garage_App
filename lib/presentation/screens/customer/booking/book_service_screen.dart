import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';
import 'package:autocare_pro/core/constants/service_categories.dart';
import 'package:autocare_pro/presentation/widgets/booking_confirmation_dialog.dart';

class BookServiceScreen extends ConsumerStatefulWidget {
  const BookServiceScreen({super.key});

  @override
  ConsumerState<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends ConsumerState<BookServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String? _selectedVehicleId;
  Map<String, dynamic>? _selectedVehicleData;
  ServiceType? _selectedService;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null; // Reset time slot when date changes
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    if (_selectedVehicleData == null || _selectedService == null) return;

    showDialog(
      context: context,
      builder: (context) => BookingConfirmationDialog(
        vehicleBrand: _selectedVehicleData!['brand'] ?? 'Unknown',
        vehicleModel: _selectedVehicleData!['model'] ?? 'Unknown',
        vehicleNumber: _selectedVehicleData!['number'] ?? '',
        service: _selectedService!,
        scheduledDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        onConfirm: _confirmBooking,
      ),
    );
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      final jobCardId = const Uuid().v4();
      final timeOfDay = TimeSlots.parseTimeSlot(_selectedTimeSlot!);
      final category = ServiceCategories.getCategoryForService(
        _selectedService!.id,
      );

      // Generate job number
      final jobNo =
          'JOB${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final jobCardData = {
        'jobNo': jobNo,
        'customerId': user.uid,
        'vehicleId': _selectedVehicleId ?? '',
        'mechanicIds': [], // Empty initially, admin will assign later
        'status': 'Pending',
        'priority': 'Normal',
        'date': Timestamp.now(),
        'estimatedDeliveryDate': Timestamp.fromDate(
          DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            timeOfDay.hour,
            timeOfDay.minute,
          ),
        ),
        'complaint': _notesController.text.trim().isEmpty
            ? 'Service Request: ${_selectedService!.name}'
            : _notesController.text.trim(),
        'initialKm':
            0, // Customer doesn't know this yet, will be filled by mechanic
        'finalKm': null,
        'totalAmount': 0.0,
        'notes': 'Customer Booking - ${_selectedService!.name}',
        'selectedServices': [],
        'selectedParts': [],
        // Additional fields for customer bookings
        'serviceType': _selectedService!.name,
        'serviceId': _selectedService!.id,
        'serviceCategory': category?.name ?? 'General',
        'estimatedCost': _selectedService!.estimatedPrice,
        'estimatedDuration': _selectedService!.estimatedDurationMinutes,
        'scheduledDate': Timestamp.fromDate(
          DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            timeOfDay.hour,
            timeOfDay.minute,
          ),
        ),
        'scheduledTimeSlot': _selectedTimeSlot,
        'bookingSource': 'mobile_app',
      };

      await FirebaseFirestore.instance
          .collection('job_cards')
          .doc(jobCardId)
          .set(jobCardData);

      if (mounted) {
        // Show success message with animation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Service booked successfully!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Scheduled for ${DateFormat('MMM dd').format(_selectedDate!)} at $_selectedTimeSlot',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/customer/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Book Service'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Text(
              'Schedule Your Service',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a service and preferred time slot',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Selection
            _VehicleSelector(
              selectedVehicle: _selectedVehicleId,
              onChanged: (id, data) => setState(() {
                _selectedVehicleId = id;
                _selectedVehicleData = data;
              }),
            ),
            const SizedBox(height: 24),

            // Service Selection
            Text(
              'Select Service',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _ServiceCategorySelector(
              selectedService: _selectedService,
              onServiceSelected: (service) =>
                  setState(() => _selectedService = service),
            ),
            const SizedBox(height: 24),

            // Date & Time Selection
            if (_selectedService != null) ...[
              Text(
                'Select Date & Time',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Selection
                      OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : DateFormat(
                                  'EEEE, MMM dd, yyyy',
                                ).format(_selectedDate!),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          alignment: Alignment.centerLeft,
                        ),
                      ),

                      // Time Slots
                      if (_selectedDate != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Available Time Slots',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: TimeSlots.slots.map((slot) {
                            final isAvailable = TimeSlots.isSlotAvailable(
                              slot,
                              _selectedDate!,
                            );
                            final isSelected = _selectedTimeSlot == slot;

                            return ChoiceChip(
                              label: Text(slot),
                              selected: isSelected,
                              onSelected: isAvailable
                                  ? (selected) {
                                      setState(() {
                                        _selectedTimeSlot = selected
                                            ? slot
                                            : null;
                                      });
                                    }
                                  : null,
                              backgroundColor: isAvailable
                                  ? null
                                  : Colors.grey[200],
                              labelStyle: TextStyle(
                                color: isAvailable
                                    ? (isSelected ? Colors.white : null)
                                    : Colors.grey[400],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Additional Notes
            if (_selectedService != null) ...[
              Text(
                'Additional Notes (Optional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText:
                          'Describe any specific issues or requirements...',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Booking Summary
            if (_selectedService != null &&
                _selectedVehicleData != null &&
                _selectedDate != null &&
                _selectedTimeSlot != null) ...[
              _BookingSummaryCard(
                vehicleBrand: _selectedVehicleData!['brand'] ?? 'Unknown',
                vehicleModel: _selectedVehicleData!['model'] ?? 'Unknown',
                vehicleNumber: _selectedVehicleData!['number'] ?? '',
                service: _selectedService!,
                scheduledDate: _selectedDate!,
                timeSlot: _selectedTimeSlot!,
              ),
              const SizedBox(height: 24),
            ],

            // Submit Button
            if (_selectedService != null) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      (_selectedDate == null ||
                          _selectedTimeSlot == null ||
                          _selectedVehicleId == null)
                      ? null
                      : (_isLoading ? null : _submitBooking),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isLoading ? 'Processing...' : 'Proceed to Confirm',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// Vehicle Selector Widget
class _VehicleSelector extends ConsumerWidget {
  final String? selectedVehicle;
  final Function(String?, Map<String, dynamic>?) onChanged;

  const _VehicleSelector({
    required this.selectedVehicle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return const Text('Please login to continue');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Vehicle',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vehicles')
              .where('customerId', isEqualTo: user.uid)
              .where('status', isEqualTo: 'Active')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${snapshot.error}'),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final vehicles = snapshot.data?.docs ?? [];

            if (vehicles.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No vehicles found',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Add a vehicle to book a service',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/customer/vehicles/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Vehicle'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: vehicles.map((doc) {
                    final vehicle = doc.data() as Map<String, dynamic>;
                    final brand = vehicle['brand'] ?? 'Unknown';
                    final model = vehicle['model'] ?? 'Unknown';
                    final number = vehicle['number'] ?? '';
                    final isSelected = selectedVehicle == doc.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.05)
                            : null,
                      ),
                      child: RadioListTile<String>(
                        value: doc.id,
                        groupValue: selectedVehicle,
                        onChanged: (value) => onChanged(value, vehicle),
                        title: Text(
                          '$brand $model',
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          number.toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  )
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Service Category Selector
class _ServiceCategorySelector extends StatefulWidget {
  final ServiceType? selectedService;
  final Function(ServiceType) onServiceSelected;

  const _ServiceCategorySelector({
    required this.selectedService,
    required this.onServiceSelected,
  });

  @override
  State<_ServiceCategorySelector> createState() =>
      _ServiceCategorySelectorState();
}

class _ServiceCategorySelectorState extends State<_ServiceCategorySelector> {
  ServiceCategory? _expandedCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ServiceCategories.categories.map((category) {
        final isExpanded = _expandedCategory?.id == category.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedCategory = isExpanded ? null : category;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${category.services.length} services',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: category.services.map((service) {
                      final isSelected =
                          widget.selectedService?.id == service.id;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? category.color
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? category.color.withValues(alpha: 0.05)
                              : Colors.white,
                        ),
                        child: RadioListTile<String>(
                          value: service.id,
                          groupValue: widget.selectedService?.id,
                          onChanged: (value) {
                            widget.onServiceSelected(service);
                          },
                          title: Text(
                            service.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                service.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.currency_rupee,
                                    size: 14,
                                    color: category.color,
                                  ),
                                  Text(
                                    service.estimatedPrice > 0
                                        ? '${service.estimatedPrice.toStringAsFixed(0)} (Est.)'
                                        : 'To be quoted',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: category.color,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '~${service.estimatedDurationMinutes} mins',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Booking Summary Card
class _BookingSummaryCard extends StatelessWidget {
  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleNumber;
  final ServiceType service;
  final DateTime scheduledDate;
  final String timeSlot;

  const _BookingSummaryCard({
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.service,
    required this.scheduledDate,
    required this.timeSlot,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = ServiceCategories.getCategoryForService(service.id);

    return Card(
      elevation: 2,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Booking Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              Icons.build,
              'Service',
              service.name,
              category?.color,
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              Icons.directions_car,
              'Vehicle',
              '$vehicleBrand $vehicleModel - ${vehicleNumber.toUpperCase()}',
              null,
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              Icons.calendar_today,
              'Date',
              DateFormat('EEEE, MMM dd, yyyy').format(scheduledDate),
              null,
            ),
            const Divider(height: 24),
            _buildSummaryRow(Icons.access_time, 'Time', timeSlot, null),
            if (service.estimatedPrice > 0) ...[
              const Divider(height: 24),
              _buildSummaryRow(
                Icons.currency_rupee,
                'Estimated Cost',
                '₹${service.estimatedPrice.toStringAsFixed(0)}',
                Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value,
    Color? valueColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
