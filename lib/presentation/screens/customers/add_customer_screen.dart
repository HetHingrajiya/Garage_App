import 'dart:math';

import 'package:autocare_pro/data/models/customer_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  final Customer? customer; // For Edit Mode

  const AddCustomerScreen({super.key, this.customer});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  // Customer Controllers
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController; // Added for explicit password

  String _gender = 'Male';

  bool _isLoading = false;
  bool _obscurePassword = true;
  // Predefined Vehicle Data

  @override
  void initState() {
    super.initState();
    // Customer Init
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _mobileController = TextEditingController(
      text: widget.customer?.mobile ?? '',
    );
    _emailController = TextEditingController(
      text: widget.customer?.email ?? '',
    );
    _addressController = TextEditingController(
      text: widget.customer?.address ?? '',
    );
    _passwordController = TextEditingController();
    _gender = widget.customer?.gender ?? 'Male';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  String _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(
      12,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final isEdit = widget.customer != null;
    final email = _emailController.text.trim(); // Required now

    // 1. Determine Password (Only for new customer)
    String? password;
    if (!isEdit) {
      if (_passwordController.text.trim().isNotEmpty) {
        password = _passwordController.text.trim();
      } else {
        password = _generatePassword(); // Auto-generate if empty
      }
    }

    // 2. Prepare Base Customer Object
    // ID Handling: Start with Temp ID. If Auth succeeds, use Auth UID.
    String customerId = isEdit ? widget.customer!.id : const Uuid().v4();

    try {
      if (isEdit) {
        // --- Edit Mode ---
        final customer = Customer(
          id: customerId,
          email: email,
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim().isEmpty
              ? null
              : _mobileController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          gender: _gender,
          createdAt: widget.customer!.createdAt,
          status: widget.customer!.status,
          vehicleIds: widget.customer!.vehicleIds,
          hasAuthAccount: true,
          createdBy: 'admin',
          createdByAdminId: null,
        );

        await ref.read(garageRepositoryProvider).updateCustomer(customer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer Updated Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } else {
        // --- Create Mode ---

        // 1. Create Auth Account First
        try {
          debugPrint('🔄 Creating Auth account for customer: $email');
          final userCredential = await ref
              .read(authRepositoryProvider)
              .signUpWithEmail(
                email: email,
                password: password!,
                role: 'customer',
                name: _nameController.text.trim(),
                mobile: _mobileController.text.trim(),
              );

          customerId = userCredential.user!.uid; // Use real Auth UID
          debugPrint('✅ Auth account created. Customer ID: $customerId');
        } catch (authError) {
          debugPrint('⚠️ Failed to create Auth account: $authError');
          throw Exception('Failed to create Auth account: $authError');
        }

        // 2. Prepare Customer Object with Correct ID
        final customer = Customer(
          id: customerId,
          email: email,
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim().isEmpty
              ? null
              : _mobileController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          gender: _gender,
          createdAt: DateTime.now(),
          status: 'Active',
          vehicleIds: [], // Will be updated by transaction if adding vehicle
          hasAuthAccount: true,
          createdBy: 'admin',
          createdByAdminId: null,
        );

        // 3. Save Data
        await ref.read(garageRepositoryProvider).addCustomer(customer);

        // 4. Show Success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Customer created successfully!\nEmail: $email\nPassword: $password',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
          context.pop();
        }
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
      appBar: AppBar(
        title: Text(widget.customer != null ? 'Edit Customer' : 'Add Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Customer Details Section ---
              _buildSectionHeader('Customer Details'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length != 10) {
                    return 'Must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _gender = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *', // Marked as required
                  prefixIcon: Icon(Icons.email),
                  helperText: 'Required for account login',
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: widget.customer == null, // Email usually immutable key
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Email is required for creating account';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(val)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),

              // Password Field (Only for New Customers)
              if (widget.customer == null) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password (leave empty to auto-generate)',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  // No validator needed as we auto-generate if empty
                ),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveCustomer,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.save),
                  label: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.customer != null
                              ? 'Update Customer'
                              : 'Create Customer',
                        ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
