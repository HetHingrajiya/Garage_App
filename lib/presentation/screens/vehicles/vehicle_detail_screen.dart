import 'package:autocare_pro/data/models/job_card_model.dart';
import 'package:autocare_pro/data/models/vehicle_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:autocare_pro/presentation/screens/vehicles/add_vehicle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Provider for vehicle history
final vehicleHistoryProvider = StreamProvider.family<List<JobCard>, String>((
  ref,
  vehicleId,
) {
  return ref.watch(garageRepositoryProvider).getJobCardsByVehicleId(vehicleId);
});

class VehicleDetailScreen extends ConsumerWidget {
  final Vehicle vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(vehicleHistoryProvider(vehicle.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${vehicle.brand} ${vehicle.model}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddVehicleScreen(vehicle: vehicle),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Vehicle Info Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        vehicle.number,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(vehicle.status),
                        backgroundColor: theme.colorScheme.primaryContainer,
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildDetailRow(context, 'Type', vehicle.vehicleType),
                  _buildDetailRow(context, 'Fuel', vehicle.fuelType),
                  _buildDetailRow(context, 'Year', vehicle.year),
                  _buildDetailRow(
                    context,
                    'Mileage',
                    '${vehicle.currentKm} km',
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('Service History', style: theme.textTheme.titleMedium),
                const Spacer(),
                // Placeholder for adding service directly from here
                // IconButton(icon: Icon(Icons.add), onPressed: () {})
              ],
            ),
          ),

          // History List
          Expanded(
            child: historyAsync.when(
              data: (jobCards) {
                if (jobCards.isEmpty) {
                  return const Center(child: Text('No service history found.'));
                }
                return ListView.builder(
                  itemCount: jobCards.length,
                  itemBuilder: (context, index) {
                    final job = jobCards[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.build)),
                      title: Text(
                        'Service on ${DateFormat.yMMMd().format(job.date)}',
                      ),
                      subtitle: Text(job.status),
                      // trailing: Text('\$${job.totalCost}'), // If cost exists
                      onTap: () {
                        // Navigate to Job Card Details (Future)
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
