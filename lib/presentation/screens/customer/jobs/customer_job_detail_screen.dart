import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Provider to fetch job details
final jobDetailProvider = StreamProvider.family<Map<String, dynamic>?, String>((
  ref,
  jobId,
) {
  return FirebaseFirestore.instance
      .collection('job_cards')
      .doc(jobId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return null;
        final data = snapshot.data()!;
        data['id'] = snapshot.id;
        return data;
      });
});

// Provider to fetch vehicle details for a job
final jobVehicleProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, vehicleId) async {
    if (vehicleId.isEmpty) return null;
    final doc = await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicleId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  },
);

class CustomerJobDetailScreen extends ConsumerWidget {
  final String jobId;
  final Map<String, dynamic>? initialJobData;

  const CustomerJobDetailScreen({
    super.key,
    required this.jobId,
    this.initialJobData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));

    return Scaffold(
      appBar: AppBar(title: const Text('Service Details')),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading job details',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ),
        ),
        data: (job) {
          if (job == null) {
            return const Center(child: Text('Job not found'));
          }

          final status = job['status'] ?? 'Pending';
          final serviceType = job['serviceType'] ?? 'Service';
          final description = job['description'] ?? '';
          final vehicleId = job['vehicleId'] ?? '';
          final priority = job['priority'] ?? 'Normal';
          final estimatedCost = (job['estimatedCost'] ?? 0.0).toDouble();
          final actualCost = (job['actualCost'] ?? 0.0).toDouble();
          final createdAt = (job['createdAt'] as Timestamp?)?.toDate();
          final scheduledDate = (job['scheduledDate'] as Timestamp?)?.toDate();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status Card
              Card(
                elevation: 2,
                color: _getStatusColor(status).withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 48,
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                      if (scheduledDate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Scheduled: ${DateFormat('MMM dd, yyyy • hh:mm a').format(scheduledDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Service Information
              _buildSectionTitle('Service Information'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.build_circle,
                        'Service Type',
                        serviceType,
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.description,
                          'Description',
                          description,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.flag,
                        'Priority',
                        priority,
                        valueColor: _getPriorityColor(priority),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Booked On',
                          DateFormat('MMM dd, yyyy').format(createdAt),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Vehicle Information
              if (vehicleId.isNotEmpty) ...[
                _buildSectionTitle('Vehicle Information'),
                _buildVehicleCard(ref, vehicleId),
                const SizedBox(height: 16),
              ],

              // Cost Information
              if (estimatedCost > 0 || actualCost > 0) ...[
                _buildSectionTitle('Cost Information'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (estimatedCost > 0)
                          _buildCostRow('Estimated Cost', estimatedCost, false),
                        if (estimatedCost > 0 && actualCost > 0)
                          const Divider(height: 24),
                        if (actualCost > 0)
                          _buildCostRow('Actual Cost', actualCost, true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Status Timeline
              _buildSectionTitle('Status Timeline'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildTimeline(status),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard(WidgetRef ref, String vehicleId) {
    final vehicleAsync = ref.watch(jobVehicleProvider(vehicleId));

    return vehicleAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading vehicle: $error'),
        ),
      ),
      data: (vehicle) {
        if (vehicle == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Vehicle not found'),
            ),
          );
        }

        final brand = vehicle['brand'] ?? 'Unknown';
        final model = vehicle['model'] ?? 'Unknown';
        final number = vehicle['number'] ?? '';
        final year = vehicle['year']?.toString() ?? '';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.directions_car, size: 40, color: Colors.grey[600]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$brand $model',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        number.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      if (year.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Year: $year',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCostRow(String label, double amount, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isBold ? Colors.green[700] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final statuses = ['Pending', 'In Progress', 'Completed'];
    final currentIndex = statuses.indexWhere(
      (s) => s.toLowerCase() == currentStatus.toLowerCase(),
    );

    return Column(
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.circle,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                if (index < statuses.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted ? Colors.green : Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      }),
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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      case 'normal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
