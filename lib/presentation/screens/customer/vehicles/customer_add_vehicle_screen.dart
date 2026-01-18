import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:autocare_pro/core/utils/formatters.dart';
import 'package:flutter/services.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';

class CustomerAddVehicleScreen extends ConsumerStatefulWidget {
  const CustomerAddVehicleScreen({super.key});

  @override
  ConsumerState<CustomerAddVehicleScreen> createState() =>
      _CustomerAddVehicleScreenState();
}

class _CustomerAddVehicleScreenState
    extends ConsumerState<CustomerAddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _registrationController = TextEditingController();
  final _vinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _registrationController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      // Fetch full customer details to get the Name
      final customer = await ref
          .read(garageRepositoryProvider)
          .getCustomer(user.uid);
      final customerName =
          customer?.name ?? user.displayName ?? 'Unknown Customer';

      final vehicleId = const Uuid().v4();
      final vehicleData = {
        'customerId': user.uid,
        'customerName': customerName,
        'brand': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'year': _yearController.text.trim(),
        'number': _registrationController.text.trim().toUpperCase(),
        'vin': _vinController.text.trim().toUpperCase(),
        'vehicleType': 'Car', // Default
        'fuelType': 'Petrol', // Default
        'currentKm': 0,
        'status': 'Active',
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .set(vehicleData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Vehicle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _makeController,
                      decoration: const InputDecoration(
                        labelText: 'Make *',
                        hintText: 'e.g., Toyota, Honda',
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Make is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model *',
                        hintText: 'e.g., Camry, Civic',
                        prefixIcon: Icon(Icons.car_rental),
                      ),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Model is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Year *',
                        hintText: 'e.g., 2020',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Year is required';
                        final year = int.tryParse(v!);
                        if (year == null || year < 1900 || year > 2100) {
                          return 'Enter a valid year';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _registrationController,
                      decoration: const InputDecoration(
                        labelText: 'Registration Number *',
                        hintText: 'e.g., MH 01 AB 1234',
                        prefixIcon: Icon(Icons.confirmation_number),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      keyboardType: TextInputType.visiblePassword,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9 ]'),
                        ),
                        UpperCaseTextFormatter(),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Registration number is required';
                        }
                        // Basic Indian Vehicle Regex
                        final regExp = RegExp(
                          r'^[A-Z]{2}[ -]?\d{2}[ -]?[A-Z]{0,2}[ -]?\d{4}$',
                        );
                        if (!regExp.hasMatch(v)) {
                          return 'Invalid Format (e.g. MH01AB1234)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vinController,
                      decoration: const InputDecoration(
                        labelText: 'VIN (Optional)',
                        hintText: 'Vehicle Identification Number',
                        prefixIcon: Icon(Icons.fingerprint),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitForm,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Add Vehicle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
