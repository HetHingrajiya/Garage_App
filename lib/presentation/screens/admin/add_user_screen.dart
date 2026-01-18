import 'dart:math';

import 'package:autocare_pro/data/models/user_model.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';
import 'package:autocare_pro/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddUserScreen extends ConsumerStatefulWidget {
  final UserModel? userToEdit;

  const AddUserScreen({super.key, this.userToEdit});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  String _selectedRole = 'admin';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _roles = ['admin', 'mechanic'];

  // Mechanic Fields
  final List<String> _availableSkills = [
    'Engine',
    'Electrical',
    'Body',
    'Accessories',
    'Paint',
    'Washing',
  ];
  List<String> _selectedSkills = [];
  int _experience = 0;

  bool get _isEditing => widget.userToEdit != null;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.userToEdit?.email ?? '',
    );
    _passwordController = TextEditingController(); // Empty for edit mode
    _nameController = TextEditingController(
      text: widget.userToEdit?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userToEdit?.mobile ?? '',
    );

    if (_isEditing) {
      _selectedRole = widget.userToEdit!.role;
      _selectedSkills = List.from(widget.userToEdit!.skills);
      _experience = widget.userToEdit!.experience;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
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
    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        // Update User
        final updatedUser = UserModel(
          id: widget.userToEdit!.id,
          email:
              widget.userToEdit!.email, // Email cannot be changed here easily
          name: _nameController.text.trim(),
          role: _selectedRole,
          mobile: _phoneController.text.trim(),
          status: widget.userToEdit!.status,
          createdAt: widget.userToEdit!.createdAt,
          skills: _selectedSkills,
          experience: _experience,
        );

        await ref.read(userRepositoryProvider).updateUser(updatedUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated successfully!')),
          );
        }
      } else {
        // Create User
        await ref
            .read(authRepositoryProvider)
            .signUpWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              role: _selectedRole,
              name: _nameController.text.trim(),
              mobile: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
              skills: _selectedSkills,
              experience: _experience,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User created successfully!')),
          );
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error: $e';
        if (e.toString().contains('email-already-in-use')) {
          errorMessage =
              'This email is already registered. Please use another.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
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
        title: Text(_isEditing ? 'Edit User' : 'Add Staff / Mechanic'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _isEditing ? Icons.edit : Icons.person_add,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'Update Details' : 'Create New User',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isEditing
                                  ? 'Update information for ${_nameController.text}'
                                  : 'Add staff or mechanic to your garage',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information Section
              Text(
                'Basic Information',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter full name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isEditing, // Disable email editing
                decoration: InputDecoration(
                  labelText: 'Email Address *',
                  hintText: 'example@email.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: _isEditing,
                  fillColor: _isEditing ? Colors.grey[200] : null,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    'Email cannot be changed directly.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '10-digit mobile number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length != 10) {
                    return 'Phone number must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field (Only for new users)
              if (!_isEditing) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    hintText: 'Min 6 characters',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Generate Password',
                          onPressed: () {
                            final password = _generatePassword();
                            _passwordController.text = password;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Generated Password: $password'),
                                action: SnackBarAction(
                                  label: 'Copy',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: password),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Password copied to clipboard',
                                        ),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Role Selection Section
              Text(
                'Role & Permissions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Select Role *',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _roles.map((role) {
                  IconData icon;
                  String description;
                  switch (role) {
                    case 'admin':
                      icon = Icons.admin_panel_settings;
                      description = 'Full system access';
                      break;
                    case 'mechanic':
                      icon = Icons.handyman;
                      description = 'Service & repair work';
                      break;
                    default:
                      icon = Icons.person;
                      description = 'General staff member';
                  }
                  return DropdownMenuItem(
                    value: role,
                    child: Row(
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              role.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (context) {
                  return _roles.map((role) {
                    IconData icon;
                    switch (role) {
                      case 'admin':
                        icon = Icons.admin_panel_settings;
                        break;
                      case 'mechanic':
                        icon = Icons.handyman;
                        break;
                      default:
                        icon = Icons.person;
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min, // Fix 1: Compact row
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                        Text(role.toUpperCase()),
                      ],
                    );
                  }).toList();
                },
                isExpanded: true, // Fix 2: Enable expansion
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 24),

              // Mechanic-Specific Fields
              if (_selectedRole == 'mechanic') ...[
                Text(
                  'Mechanic Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller:
                      TextEditingController(text: _experience.toString())
                        ..selection = TextSelection.collapsed(
                          offset: _experience.toString().length,
                        ),
                  decoration: InputDecoration(
                    labelText: 'Years of Experience',
                    hintText: 'Enter years',
                    prefixIcon: const Icon(Icons.timeline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (val) => _experience = int.tryParse(val) ?? 0,
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.handyman, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Skills & Expertise',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
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
                            selectedColor: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.3),
                            checkmarkColor: Theme.of(context).primaryColor,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Submit Button
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
                      : Icon(_isEditing ? Icons.save : Icons.person_add),
                  label: Text(
                    _isLoading
                        ? 'Saving...'
                        : (_isEditing ? 'Update User' : 'Create User'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              // Delete Button (Only in Edit Mode and NOT for Super Admin)
              if (_isEditing &&
                  !(widget.userToEdit?.isSuperAdmin ?? false)) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete User?'),
                                content: Text(
                                  'Are you sure you want to delete ${_nameController.text}? This action cannot be undone and they will no longer be able to log in.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              setState(() => _isLoading = true);
                              try {
                                await ref
                                    .read(userRepositoryProvider)
                                    .deleteUser(widget.userToEdit!.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'User deleted successfully',
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            }
                          },
                    icon: _isLoading
                        ? const SizedBox()
                        : const Icon(Icons.delete, color: Colors.red),
                    label: Text(
                      _isLoading ? 'Deleting...' : 'Delete User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
