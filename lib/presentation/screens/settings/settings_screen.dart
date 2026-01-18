import 'package:autocare_pro/data/models/settings_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:autocare_pro/core/utils/database_cleanup.dart';
import 'package:autocare_pro/core/permissions/permissions.dart';
import 'package:autocare_pro/presentation/widgets/permission_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          children: [_buildProfileTab(), _buildTaxTab(), _buildPrefsTab()],
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

  Widget _buildPrefsTab() {
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
          ListTile(
            title: const Text('Backup Data'),
            subtitle: const Text('Export all garage data'),
            trailing: const Icon(Icons.cloud_download),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup feature is coming soon!')),
              );
            },
          ),
          // Super Admin only - Clear Database
          PermissionBuilder(
            permission: Permission.createAdmins,
            child: ListTile(
              title: const Text(
                'Clear Database',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Delete all data (except inventory)'),
              trailing: const Icon(Icons.delete_forever, color: Colors.red),
              onTap: () => _showCleanupDialog(),
            ),
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
        title: const Text('⚠️ Clear Database?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• All admins'),
            Text('• All mechanics'),
            Text('• All customers'),
            Text('• All job cards'),
            Text('• All vehicles'),
            Text('• All invoices'),
            SizedBox(height: 12),
            Text(
              '✅ Inventory will be kept',
              style: TextStyle(color: Colors.green),
            ),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
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
            child: const Text('Delete All'),
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
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cleaning database...'),
          ],
        ),
      ),
    );

    try {
      final cleanup = DatabaseCleanup(FirebaseFirestore.instance);

      await cleanup.cleanAll(keepInventory: true);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Database cleaned successfully!'),
            backgroundColor: Colors.green,
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
