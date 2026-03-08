import 'package:autocare_pro/data/repositories/auth_repository.dart';
import 'package:autocare_pro/presentation/controllers/dashboard_controller.dart';
import 'package:autocare_pro/presentation/screens/reports/reports_dashboard_screen.dart';
import 'package:autocare_pro/core/theme/app_theme.dart';
import 'package:autocare_pro/presentation/widgets/common/realistic_container.dart';
import 'package:autocare_pro/presentation/widgets/common/neumorphic_button.dart';
import 'package:autocare_pro/presentation/screens/notifications/notification_list_screen.dart';
import 'package:autocare_pro/data/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardNavigator {
  static Widget buildDrawer(BuildContext context, WidgetRef ref) {
    return const DashboardScreen()._buildDrawer(context, ref);
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final userRoleAsync = ref.watch(currentUserRoleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.nmBaseDark : AppTheme.nmBaseLight,
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(dashboardStatsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                child: Column(
                  children: [
                    Builder(
                      builder: (context) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              NeumorphicIconButton(
                                icon: Icons.menu_rounded,
                                onTap: () => Scaffold.of(context).openDrawer(),
                                color: isDark ? Colors.white70 : AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dashboard',
                                    style: GoogleFonts.inter(
                                      color: isDark ? Colors.white : const Color(0xFF1E293B), // Slate 800
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'AutoCare Pro',
                                    style: GoogleFonts.inter(
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B), // Slate 500
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          NeumorphicIconButton(
                            icon: Icons.notifications_none_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationListScreen()),
                            ),
                            color: isDark ? Colors.white70 : AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Main Summary Card
                    RealisticContainer(
                      width: double.infinity,
                      state: NeumorphicState.convex,
                      borderRadius: 32,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.auto_graph, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Performance Overview',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B), // Slate 800
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          statsAsync.when(
                            data: (stats) {
                              final isMechanic = userRoleAsync.value?.toLowerCase() == 'mechanic';
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _StatItem(
                                    label: 'Active Jobs',
                                    value: stats.activeJobs.toString(),
                                    color: Colors.blue,
                                  ),
                                  if (!isMechanic) ...[
                                    Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2)),
                                    _StatItem(
                                      label: 'Revenue',
                                      value: '₹${NumberFormat('##,##0').format(stats.todayIncome)}',
                                      color: Colors.green,
                                    ),
                                    Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2)),
                                    _StatItem(
                                      label: 'Customers',
                                      value: stats.totalCustomers.toString(),
                                      color: Colors.orange,
                                    ),
                                  ],
                                ],
                              );
                            },
                            loading: () => const Center(child: LinearProgressIndicator()),
                            error: (err, _) => Text('Error: $err'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B), // Slate 800
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: userRoleAsync.when(
                data: (role) {
                  final isMechanic = role?.toLowerCase() == 'mechanic';
                  return SliverGrid.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    children: [
                      _ActionTile(
                        title: 'Job Cards',
                        icon: Icons.assignment_rounded,
                        onTap: () => context.push('/job-cards'),
                        color: Colors.blueAccent,
                      ),
                      _ActionTile(
                        title: 'Inventory',
                        icon: Icons.inventory_2_rounded,
                        onTap: () => context.push('/inventory'),
                        color: Colors.teal,
                      ),
                      _ActionTile(
                        title: 'Profile',
                        icon: Icons.account_circle_rounded,
                        onTap: () => context.push('/settings'),
                        color: Colors.blueGrey,
                      ),
                      if (!isMechanic) ...[
                        _ActionTile(
                          title: 'New Job',
                          icon: Icons.add_rounded,
                          onTap: () => context.push('/job-cards/add'),
                          color: Colors.indigo,
                        ),
                        _ActionTile(
                          title: 'Bookings',
                          icon: Icons.calendar_today_rounded,
                          onTap: () => context.push('/admin/bookings'),
                          color: Colors.deepOrange,
                        ),
                        _ActionTile(
                          title: 'Customers',
                          icon: Icons.people_rounded,
                          onTap: () => context.push('/customers'),
                          color: Colors.blue,
                        ),
                        _ActionTile(
                          title: 'Mechanics',
                          icon: Icons.engineering_rounded,
                          onTap: () => context.push('/mechanics'),
                          color: Colors.amber.shade800,
                        ),
                        _ActionTile(
                          title: 'Reports',
                          icon: Icons.analytics_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReportsDashboardScreen()),
                          ),
                          color: Colors.purple,
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      drawer: _buildDrawer(context, ref),
      floatingActionButton: userRoleAsync.value?.toLowerCase() == 'mechanic' 
        ? null 
        : NeumorphicButton(
            onTap: () => context.push('/job-cards/add'),
            borderRadius: 20,
            padding: 16,
            color: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final userRoleAsync = ref.watch(currentUserRoleProvider);

    return Drawer(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.nmBaseDark : AppTheme.nmBaseLight,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          userProfileAsync.when(
            data: (user) {
              final role = userRoleAsync.value ?? '';
              return DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, Color(0xFF6366F1)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_circle, size: 48, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          'AutoCare Pro',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          user?.name ?? 'User',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (role.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primaryColor),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
            error: (_, __) => const DrawerHeader(
              decoration: BoxDecoration(color: Colors.redAccent),
              child: Text('Error loading profile', style: TextStyle(color: Colors.white)),
            ),
          ),
          userRoleAsync.when(
            data: (role) {
              final isMechanic = role?.toLowerCase() == 'mechanic';
              return Column(
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    onTap: () => Navigator.pop(context),
                    isSelected: true,
                  ),
                  if (!isMechanic)
                    _DrawerItem(
                      icon: Icons.people_rounded,
                      title: 'Customers',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/customers');
                      },
                    ),
                  _DrawerItem(
                    icon: Icons.assignment_rounded,
                    title: 'Job Cards',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/job-cards');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.inventory_2_rounded,
                    title: 'Inventory',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/inventory');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.account_circle_rounded,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  if (!isMechanic)
                    _DrawerItem(
                      icon: Icons.engineering_rounded,
                      title: 'Mechanics',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/mechanics');
                      },
                    ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(),
          _DrawerItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            textColor: Colors.redAccent,
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NeumorphicButton(
      onTap: onTap,
      borderRadius: 24,
      padding: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF334155), // Slate 700
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? textColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSelected = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : textColor),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}
