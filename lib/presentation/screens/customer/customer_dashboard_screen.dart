import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:intl/intl.dart';

// Provider for customer's active jobs
final customerActiveJobsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('job_cards')
      .where('customerId', isEqualTo: user.uid)
      .where('status', whereIn: ['Pending', 'In Progress'])
      .limit(3)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
});

// Provider for customer's recent invoices
final customerRecentInvoicesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (user == null) return Stream.value([]);

      return FirebaseFirestore.instance
          .collection('invoices')
          .where('customerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
          });
    });

class CustomerDashboardScreen extends ConsumerWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authRepositoryProvider).currentUser;
    final customerAsync = ref
        .watch(garageRepositoryProvider)
        .getCustomer(user?.uid ?? '');
    final activeJobsAsync = ref.watch(customerActiveJobsProvider);
    final recentInvoicesAsync = ref.watch(customerRecentInvoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Garage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.push('/customer/profile');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerActiveJobsProvider);
          ref.invalidate(customerRecentInvoicesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Card
            FutureBuilder(
              future: customerAsync,
              builder: (context, snapshot) {
                final customerName =
                    snapshot.data?.name ?? user?.displayName ?? 'Customer';
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: theme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              child: Text(
                                customerName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Back!',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customerName,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.directions_car,
                    label: 'My Vehicles',
                    color: Colors.blue,
                    onTap: () => context.push('/customer/vehicles'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.build_circle,
                    label: 'Book Service',
                    color: Colors.orange,
                    onTap: () => context.push('/customer/book-service'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.assignment,
                    label: 'My Jobs',
                    color: Colors.green,
                    onTap: () => context.push('/customer/jobs'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.receipt_long,
                    label: 'Invoices',
                    color: Colors.purple,
                    onTap: () => context.push('/customer/invoices'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Active Services Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Services',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/customer/jobs'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            activeJobsAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => _EmptyStateCard(
                icon: Icons.error_outline,
                message: 'Error loading jobs',
                subtitle: error.toString(),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return _EmptyStateCard(
                    icon: Icons.assignment_outlined,
                    message: 'No active services',
                    subtitle: 'Book a service to get started',
                    actionLabel: 'Book Now',
                    onAction: () => context.push('/customer/book-service'),
                  );
                }

                return Column(
                  children: jobs.map((job) {
                    final status = job['status'] ?? 'Pending';
                    final serviceType = job['serviceType'] ?? 'Service';
                    final createdAt = (job['createdAt'] as Timestamp?)
                        ?.toDate();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(
                            status,
                          ).withValues(alpha: 0.1),
                          child: Icon(
                            _getStatusIcon(status),
                            color: _getStatusColor(status),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          serviceType,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 12,
                          ),
                        ),
                        trailing: createdAt != null
                            ? Text(
                                DateFormat('MMM dd').format(createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              )
                            : null,
                        onTap: () => context.push(
                          '/customer/jobs/${job['id']}',
                          extra: job,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent Invoices
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Invoices',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/customer/invoices'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            recentInvoicesAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => _EmptyStateCard(
                icon: Icons.error_outline,
                message: 'Error loading invoices',
                subtitle: error.toString(),
              ),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return _EmptyStateCard(
                    icon: Icons.receipt_outlined,
                    message: 'No invoices yet',
                    subtitle: 'Your invoices will appear here',
                  );
                }

                return Column(
                  children: invoices.map((invoice) {
                    final total = (invoice['total'] ?? 0.0).toDouble();
                    final paid = (invoice['paid'] ?? 0.0).toDouble();
                    final isPaid = paid >= total;
                    final invoiceId = invoice['id'] as String;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPaid
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          child: Icon(
                            isPaid ? Icons.check_circle : Icons.pending,
                            color: isPaid ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '#${invoiceId.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isPaid ? 'Paid' : 'Pending',
                          style: TextStyle(
                            color: isPaid ? Colors.green : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customer/book-service'),
        icon: const Icon(Icons.add),
        label: const Text('Book Service'),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
      case 'in-progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in progress':
      case 'in-progress':
        return Icons.build_circle;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.assignment;
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyStateCard({
    required this.icon,
    required this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
