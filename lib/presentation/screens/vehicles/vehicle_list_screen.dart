import 'package:autocare_pro/data/models/vehicle_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:autocare_pro/presentation/screens/vehicles/add_vehicle_screen.dart';
import 'package:autocare_pro/presentation/screens/vehicles/vehicle_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final vehicleSearchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// Provider to search vehicles, optionally filtered by customerId
final vehicleListProvider = StreamProvider.family<List<Vehicle>, String?>((
  ref,
  customerId,
) {
  final query = ref.watch(vehicleSearchQueryProvider);
  return ref
      .watch(garageRepositoryProvider)
      .searchVehicles(query, customerId: customerId);
});

class VehicleListScreen extends ConsumerWidget {
  final String? customerId;
  const VehicleListScreen({super.key, this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehicleListProvider(customerId));
    final theme = Theme.of(context);

    // If customerId is null, we are in "All Vehicles" mode.
    // Ideally we might want to know the Customer Name if filtered, but we'll keep UI simple.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Reg No, Brand, or Model',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.secondaryContainer.withValues(
                  alpha: 0.3,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: (val) =>
                  ref.read(vehicleSearchQueryProvider.notifier).set(val),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddVehicleScreen(
                // We'll need to fetch customer object if we want to pre-fill detailed customer info
                // But AddVehicleScreen only needs ID really for the form logic if we updated it to accept just ID?
                // Actually AddVehicleScreen takes Customer object.
                // For now, if we are in a customer context, we might not have the full customer object passed here easily without fetching.
                // Let's rely on User selecting customer if not easy, OR fetch it.
                // Refactor AddVehicleScreen to take `preSelectedCustomerId` as well?
                // Checked AddVehicleScreen: it takes `preSelectedCustomer` (object).
                // Simplification: Allow selecting customer in Add Screen if null.
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const Center(child: Text('No vehicles found.'));
          }
          return ListView.builder(
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      vehicle.vehicleType == 'Bike'
                          ? Icons.two_wheeler
                          : Icons.directions_car,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: Text('${vehicle.brand} ${vehicle.model}'),
                  subtitle: Text(vehicle.number),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${vehicle.currentKm} km',
                        style: theme.textTheme.bodySmall,
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        ],
                        onSelected: (val) {
                          if (val == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddVehicleScreen(vehicle: vehicle),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VehicleDetailScreen(vehicle: vehicle),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
