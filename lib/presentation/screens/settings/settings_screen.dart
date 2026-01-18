import 'package:autocare_pro/core/services/data_clear_service.dart';
import 'package:autocare_pro/core/services/super_admin_service.dart';
import 'package:autocare_pro/core/utils/data_filter_helper.dart';
import 'package:autocare_pro/data/models/settings_model.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final settingsProvider = FutureProvider<GarageSettings>((ref) {
  return ref.watch(garageRepositoryProvider).getSettings();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _gstController = TextEditingController();

  bool _gstEnabled = false;
  String _themeMode = 'system';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider).asData?.value ?? false;

    // Initialize controllers with data once loaded
    settingsAsync.whenData((settings) {
      if (!_isLoading && _nameController.text.isEmpty) {
        _nameController.text = settings.garageName;
        _addressController.text = settings.address;
        _contactController.text = settings.contactNumber;
        _gstController.text = settings.gstPercentage.toString();
        _gstEnabled = settings.gstEnabled;
        _themeMode = settings.themeMode;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile', icon: Icon(Icons.store)),
            Tab(text: 'Tax & Billing', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Preferences', icon: Icon(Icons.settings_applications)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveSettings(),
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) => TabBarView(
          controller: _tabController,
          children: [
            _buildProfileTab(),
            _buildTaxTab(),
            _buildPrefsTab(isSuperAdmin),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading settings: $e')),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.store, size: 40)),
          TextButton(onPressed: () {}, child: const Text('Change Logo')),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Garage Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(
              labelText: 'Contact Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildTaxTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable GST/Tax'),
            subtitle: const Text('Apply tax on invoices automatically'),
            value: _gstEnabled,
            onChanged: (val) => setState(() => _gstEnabled = val),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _gstController,
            decoration: const InputDecoration(
              labelText: 'Tax Percentage (%)',
              border: OutlineInputBorder(),
              suffixText: '%',
            ),
            keyboardType: TextInputType.number,
            enabled: _gstEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildPrefsTab(bool isSuperAdmin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ListTile(title: Text('App Theme')),
          ListTile(
            title: const Text('System Default'),
            leading: Radio<String>(
              value: 'system',
              groupValue: _themeMode,
              onChanged: (val) => setState(() => _themeMode = val!),
            ),
            onTap: () => setState(() => _themeMode = 'system'),
          ),
          ListTile(
            title: const Text('Light'),
            leading: Radio<String>(
              value: 'light',
              groupValue: _themeMode,
              onChanged: (val) => setState(() => _themeMode = val!),
            ),
            onTap: () => setState(() => _themeMode = 'light'),
          ),
          ListTile(
            title: const Text('Dark'),
            leading: Radio<String>(
              value: 'dark',
              groupValue: _themeMode,
              onChanged: (val) => setState(() => _themeMode = val!),
            ),
            onTap: () => setState(() => _themeMode = 'dark'),
          ),
          const Divider(),
          // Data Management Section
          if (isSuperAdmin) ...[
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Super Admin Controls',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text(
                'Fix Orphaned Customers',
                style: TextStyle(color: Colors.orange),
              ),
              leading: const Icon(Icons.group_add, color: Colors.orange),
              subtitle: const Text(
                'Assign existing self-registered users to me',
              ),
              onTap: () async {
                final userId = ref.read(currentUserIdProvider);
                if (userId != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fixing orphans...')),
                  );
                  final count = await ref
                      .read(superAdminServiceProvider)
                      .fixOrphanedCustomers(userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Fixed $count customers. Please refresh list.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              title: const Text(
                'Factory Reset',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Delete ALL data except your account',
                style: TextStyle(color: Colors.red),
              ),
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              onTap: () => _showCleanupDialog(),
            ),
          ],
          ListTile(
            title: const Text('Backup Data'),
            leading: const Icon(Icons.cloud_download),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup feature is coming soon!')),
              );
            },
          ),

          const SizedBox(height: 24),
          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.logout),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final newSettings = GarageSettings(
        garageName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        contactNumber: _contactController.text.trim(),
        gstEnabled: _gstEnabled,
        gstPercentage: double.tryParse(_gstController.text.trim()) ?? 0.0,
        themeMode: _themeMode,
      );

      await ref.read(garageRepositoryProvider).updateSettings(newSettings);

      // Invalidate provider to fetch fresh data next time
      ref.invalidate(settingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings Saved!')));
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

  Future<void> _showCleanupDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '⚠️ FACTORY RESET?',
          style: TextStyle(color: Colors.red),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action is IRREVERSIBLE!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 12),
              Text('This will PERMANENTLY DELETE:'),
              Text('• All customers and users'),
              Text('• All vehicles and jobs'),
              Text('• All invoices and payments'),
              Text('• All inventory and parts'),
              Text('• All other admins'),
              SizedBox(height: 12),
              Text(
                'Only YOUR Super Admin account will remain.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Are you absolutely sure?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE EVERYTHING'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _performCleanup();
    }
  }

  Future<void> _performCleanup() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text('Wiping System Data...'),
            Text('Please wait...', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    try {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null) throw Exception('User not logged in');

      final dbCleanup = DataClearService();
      await dbCleanup.clearAllSystemData(currentUserId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Reset Complete'),
            content: const Text(
              'All system data has been cleared.\n\nPlease log in again to ensure a clean state.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Navigate to login or logout
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
