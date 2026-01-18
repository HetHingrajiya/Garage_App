import 'dart:math';

import 'package:autocare_pro/data/models/mechanic_model.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';
import 'package:autocare_pro/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddMechanicScreen extends ConsumerStatefulWidget {
  final MechanicModel? mechanicToEdit;

  const AddMechanicScreen({super.key, this.mechanicToEdit});

  @override
  ConsumerState<AddMechanicScreen> createState() => _AddMechanicScreenState();
}

class _AddMechanicScreenState extends ConsumerState<AddMechanicScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _experienceController;

  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _availableSkills = [
    'Engine Repair',
    'Electrical Systems',
    'Body Work',
    'Accessories Installation',
    'Paint & Finishing',
    'Washing & Detailing',
    'Brake Systems',
    'Transmission',
    'AC & Cooling',
    'Diagnostics',
  ];
  List<String> _selectedSkills = [];

  bool get _isEditing => widget.mechanicToEdit != null;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.mechanicToEdit?.email ?? '',
    );
    _passwordController = TextEditingController();
    _nameController = TextEditingController(
      text: widget.mechanicToEdit?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.mechanicToEdit?.mobile ?? '',
    );
    _experienceController = TextEditingController(
      text: widget.mechanicToEdit?.experience.toString() ?? '0',
    );

    if (_isEditing) {
      _selectedSkills = List.from(widget.mechanicToEdit!.skills);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one skill'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final experience = int.tryParse(_experienceController.text.trim()) ?? 0;

      if (_isEditing) {
        // Update existing mechanic
        final updatedMechanic = MechanicModel(
          id: widget.mechanicToEdit!.id,
          email: widget.mechanicToEdit!.email,
          name: _nameController.text.trim(),
          mobile: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          status: widget.mechanicToEdit!.status,
          createdAt: widget.mechanicToEdit!.createdAt,
          skills: _selectedSkills,
          experience: experience,
          rating: widget.mechanicToEdit!.rating,
          completedJobs: widget.mechanicToEdit!.completedJobs,
        );

        await ref
            .read(userRepositoryProvider)
            .saveToRoleCollection(updatedMechanic);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mechanic updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } else {
        // Create new mechanic
        final password = _passwordController.text.trim().isEmpty
            ? _generatePassword()
            : _passwordController.text.trim();

        await ref
            .read(authRepositoryProvider)
            .signUpWithEmail(
              email: _emailController.text.trim(),
              password: password,
              role: 'mechanic',
              name: _nameController.text.trim(),
              mobile: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
              skills: _selectedSkills,
              experience: experience,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Mechanic created successfully\nPassword: $password',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Mechanic' : 'Add Mechanic'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Personal Information Section
            Text(
              'Personal Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (val) =>
                  val?.trim().isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email *',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isEditing,
              validator: (val) {
                if (val?.trim().isEmpty ?? true) return 'Email is required';
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(val!)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            if (!_isEditing) ...[
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: _obscurePassword,
              ),
            ],
            const SizedBox(height: 24),

            // Professional Information Section
            Text(
              'Professional Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _experienceController,
              decoration: InputDecoration(
                labelText: 'Years of Experience *',
                prefixIcon: const Icon(Icons.work),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val?.trim().isEmpty ?? true) {
                  return 'Experience is required';
                }
                final exp = int.tryParse(val!);
                if (exp == null || exp < 0) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Skills Section
            Text(
              'Skills *',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select all applicable skills',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSkills.map((skill) {
                final isSelected = _selectedSkills.contains(skill);
                return FilterChip(
                  label: Text(skill),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSkills.add(skill);
                      } else {
                        _selectedSkills.remove(skill);
                      }
                    });
                  },
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.onPrimaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Update Mechanic' : 'Create Mechanic',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
