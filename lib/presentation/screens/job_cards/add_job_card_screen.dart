import 'package:autocare_pro/data/models/customer_model.dart';
import 'package:autocare_pro/data/models/job_card_model.dart';
import 'package:autocare_pro/data/models/vehicle_model.dart';
import 'package:autocare_pro/data/models/user_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddJobCardScreen extends ConsumerStatefulWidget {
  const AddJobCardScreen({super.key});

  @override
  ConsumerState<AddJobCardScreen> createState() => _AddJobCardScreenState();
}

class _AddJobCardScreenState extends ConsumerState<AddJobCardScreen> {
  final _formKey = GlobalKey<FormState>();

  // Selections
  String? _selectedCustomerId;
  String? _selectedVehicleId;
  String? _selectedMechanicId; // New mechanic selection
  DateTime? _estimatedDeliveryDate;

  // Controllers
  final _complaintController = TextEditingController();
  final _kmController = TextEditingController();

  // Values
  String _priority = 'Medium';
  bool _isLoading = false;

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _estimatedDeliveryDate = picked);
    }
  }

  Future<void> _saveJobCard() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null || _selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Customer and Vehicle')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Auto-generate Job Number: e.g. JO-20241010-1234
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final jobNo = 'JOB-${timestamp.substring(timestamp.length - 8)}';

      final jobCard = JobCard(
        id: const Uuid().v4(),
        jobNo: jobNo,
        customerId: _selectedCustomerId!,
        vehicleId: _selectedVehicleId!,
        status: 'Received',
        date: DateTime.now(),
        priority: _priority,
        complaint: _complaintController.text.trim(),
        mechanicIds: _selectedMechanicId != null ? [_selectedMechanicId!] : [],
        initialKm: int.parse(_kmController.text.trim()),
        estimatedDeliveryDate: _estimatedDeliveryDate,
      );

      await ref.read(garageRepositoryProvider).createJobCard(jobCard);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Job Card Created')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Fetch Customers

    return Scaffold(
      appBar: AppBar(title: const Text('Create Job Card')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Step 1: Customer ---
              StreamBuilder<List<Customer>>(
                stream: ref.read(garageRepositoryProvider).getCustomers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final customers = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCustomerId,
                    decoration: const InputDecoration(
                      labelText: 'Select Customer',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: customers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCustomerId = val;
                        _selectedVehicleId =
                            null; // Reset vehicle when customer changes
                      });
                    },
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // --- Step 2: Vehicle (Dependent) ---
              if (_selectedCustomerId != null)
                StreamBuilder<List<Vehicle>>(
                  stream: ref
                      .read(garageRepositoryProvider)
                      .getVehicles(customerId: _selectedCustomerId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final vehicles = snapshot.data!;
                    if (vehicles.isEmpty) {
                      return const Text(
                        'No vehicles found for this customer.',
                        style: TextStyle(color: Colors.red),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedVehicleId,
                      decoration: const InputDecoration(
                        labelText: 'Select Vehicle',
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      items: vehicles
                          .map(
                            (v) => DropdownMenuItem(
                              value: v.id,
                              child: Text(
                                '${v.brand} ${v.model} (${v.number})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedVehicleId = val),
                      validator: (v) => v == null ? 'Required' : null,
                    );
                  },
                )
              else
                const Text(
                  'Select a customer to see vehicles.',
                  style: TextStyle(color: Colors.grey),
                ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // --- Step 3: Details ---
              TextFormField(
                controller: _complaintController,
                decoration: const InputDecoration(
                  labelText: 'Problem Description / Complaint',
                  prefixIcon: Icon(Icons.report_problem),
                  hintText: 'e.g. Engine noise, Brake failure',
                ),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: _priorities
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _priority = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _kmController,
                      decoration: const InputDecoration(
                        labelText: 'Initial KM',
                        prefixIcon: Icon(Icons.speed),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              StreamBuilder<List<UserModel>>(
                stream: ref.read(garageRepositoryProvider).getMechanics(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    );
                  }
                  final mechanics = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedMechanicId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Mechanic',
                      prefixIcon: Icon(Icons.engineering),
                    ),
                    items: mechanics
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedMechanicId = val),
                  );
                },
              ),
              const SizedBox(height: 16),

              ListTile(
                title: Text(
                  _estimatedDeliveryDate == null
                      ? 'Select Estimated Delivery Date'
                      : 'Delivery: ${DateFormat.yMMMd().format(_estimatedDeliveryDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
                onTap: _pickDate,
              ),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveJobCard,
                icon: const Icon(Icons.save),
                label: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Job Card'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
