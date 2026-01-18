import 'package:autocare_pro/core/permissions/permissions.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';
import 'package:autocare_pro/presentation/controllers/dashboard_controller.dart';
import 'package:autocare_pro/presentation/screens/reports/reports_dashboard_screen.dart';
import 'package:autocare_pro/presentation/widgets/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Placeholder
            },
          ),
          // Reports - Admin only
          PermissionBuilder(
            permission: Permission.viewReports,
            child: IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsDashboardScreen(),
                  ),
                );
              },
            ),
          ),
          // Settings - Admin only (full access)
          PermissionBuilder(
            permission: Permission.manageSettings,
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                context.push('/settings');
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(dashboardStatsProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Overview', style: theme.textTheme.headlineMedium),
                if (statsAsync.value?.lastUpdated != null)
                  Text(
                    'Updated: ${DateFormat('HH:mm').format(statsAsync.value!.lastUpdated!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Customers',
                          value: stats.totalCustomers.toString(),
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Active Jobs',
                          value: stats.activeJobs.toString(),
                          icon: Icons.build,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Today Income',
                          value: '₹${stats.todayIncome.toStringAsFixed(2)}',
                          icon: Icons.attach_money,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading dashboard stats...'),
                    ],
                  ),
                ),
              ),
              error: (err, stack) => Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load dashboard stats',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: $err',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(dashboardStatsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check Firebase connection and Firestore rules',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Quick Actions', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),

            // Admin-only quick actions
            PermissionBuilder(
              permission: Permission.createJobCards,
              child: _ActionTile(
                title: 'New Job Card',
                icon: Icons.note_add,
                onTap: () {
                  context.push('/job-cards/add');
                },
              ),
            ),
            PermissionBuilder(
              permission: Permission.createJobCards,
              child: _ActionTile(
                title: 'Online Bookings',
                icon: Icons.calendar_month,
                onTap: () {
                  context.push('/admin/bookings');
                },
                color: Colors.deepOrange,
              ),
            ),
            // Super Admin only - Add New Admin
            PermissionBuilder(
              permission: Permission.createAdmins,
              child: _ActionTile(
                title: 'Add New Admin',
                icon: Icons.admin_panel_settings_outlined,
                color: Colors.purple,
                onTap: () {
                  context.push('/admin/add-user');
                },
              ),
            ),
            // Mechanics can view job cards
            PermissionBuilder(
              permission: Permission.viewJobCards,
              child: _ActionTile(
                title: 'View Job Cards',
                icon: Icons.assignment,
                onTap: () {
                  context.push('/job-cards');
                },
              ),
            ),
            PermissionBuilder(
              permission: Permission.manageInventory,
              child: _ActionTile(
                title: 'Manage Inventory',
                icon: Icons.inventory,
                onTap: () {
                  context.push('/inventory');
                },
              ),
            ),
            // Mechanics can view inventory (read-only)
            MechanicOnly(
              child: _ActionTile(
                title: 'View Inventory',
                icon: Icons.inventory_2_outlined,
                onTap: () {
                  context.push('/inventory');
                },
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Consumer(
                builder: (context, ref, child) {
                  final user = ref.watch(authStateProvider).value;
                  final roleAsync = ref.watch(currentUserRoleProvider);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.garage, size: 48, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        user?.displayName ?? 'AutoCare Pro',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      roleAsync.when(
                        data: (role) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Role: ${role?.toUpperCase() ?? "UNKNOWN"}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        loading: () => const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        error: (error, stack) => const Text(
                          'Error loading role',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Customers - Admin only
            PermissionBuilder(
              permission: Permission.viewAllCustomers,
              child: ListTile(
                title: const Text('Customers'),
                leading: const Icon(Icons.people),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/customers');
                },
              ),
            ),
            // Job Cards - Admin and Mechanics
            PermissionBuilder(
              permission: Permission.viewJobCards,
              child: ListTile(
                title: const Text('Job Cards'),
                leading: const Icon(Icons.assignment),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/job-cards');
                },
              ),
            ),
            PermissionBuilder(
              permission: Permission.createJobCards,
              child: ListTile(
                title: const Text('Online Bookings'),
                leading: const Icon(Icons.calendar_month),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/admin/bookings');
                },
              ),
            ),
            // Vehicles - Admin and Mechanics (read-only for mechanics)
            PermissionBuilder(
              permission: Permission.viewVehicles,
              child: ListTile(
                title: const Text('Vehicles'),
                leading: const Icon(Icons.directions_car),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/vehicles');
                },
              ),
            ),
            // Inventory - Admin and Mechanics (read-only for mechanics)
            PermissionBuilder(
              permission: Permission.viewInventory,
              child: ListTile(
                title: const Text('Inventory'),
                leading: const Icon(Icons.inventory_2),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/inventory');
                },
              ),
            ),
            // Mechanics - Admin only
            PermissionBuilder(
              permission: Permission.viewAllMechanics,
              child: ListTile(
                title: const Text('Mechanics'),
                leading: const Icon(Icons.engineering),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/mechanics');
                },
              ),
            ),
            // Add Admin - Super Admin only
            PermissionBuilder(
              permission: Permission.createAdmins,
              child: ListTile(
                title: const Text('Add Admin'),
                leading: const Icon(Icons.admin_panel_settings),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/admin/add-user');
                },
              ),
            ),

            // Reports - Admin only
            PermissionBuilder(
              permission: Permission.viewReports,
              child: ListTile(
                title: const Text('Reports'),
                leading: const Icon(Icons.bar_chart),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsDashboardScreen(),
                    ),
                  );
                },
              ),
            ),
            // Settings - Admin only
            PermissionBuilder(
              permission: Permission.manageSettings,
              child: ListTile(
                title: const Text('Settings'),
                leading: const Icon(Icons.settings),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileColor = color ?? theme.colorScheme.primary;

    return Card(
      child: ListTile(
        leading: Icon(icon, color: tileColor),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: tileColor),
        onTap: onTap,
      ),
    );
  }
}
