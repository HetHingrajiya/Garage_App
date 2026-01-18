import 'package:autocare_pro/core/permissions/permissions.dart';
import 'package:autocare_pro/data/models/inventory_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:autocare_pro/presentation/screens/inventory/add_spare_part_screen.dart';
import 'package:autocare_pro/presentation/widgets/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Search
class InventorySearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}

final inventorySearchProvider =
    NotifierProvider<InventorySearchNotifier, String>(
      InventorySearchNotifier.new,
    );

// Filter Category
class InventoryCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void set(String c) => state = c;
}

final inventoryCategoryProvider =
    NotifierProvider<InventoryCategoryNotifier, String>(
      InventoryCategoryNotifier.new,
    );

final inventoryListProvider = StreamProvider<List<InventoryItem>>((ref) {
  final category = ref.watch(inventoryCategoryProvider);
  return ref
      .watch(garageRepositoryProvider)
      .getInventory(category: category)
      .map((items) {
        final query = ref.watch(inventorySearchProvider).toLowerCase();
        if (query.isEmpty) return items;
        return items
            .where(
              (i) =>
                  i.name.toLowerCase().contains(query) ||
                  i.brand.toLowerCase().contains(query),
            )
            .toList();
      });
});

class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryListProvider);
    final theme = Theme.of(context);
    final currentCat = ref.watch(inventoryCategoryProvider);
    final categories = [
      'All',
      'Engine',
      'Electrical',
      'Body',
      'Brake System',
      'Suspension',
      'Consumables',
      'Accessories',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SearchBar(
                  hintText: 'Search Parts...',
                  leading: const Icon(Icons.search),
                  onChanged: (val) =>
                      ref.read(inventorySearchProvider.notifier).set(val),
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: categories
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(c),
                            selected: currentCat == c,
                            onSelected: (_) => ref
                                .read(inventoryCategoryProvider.notifier)
                                .set(c),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      // Only admins can add/edit inventory
      floatingActionButton: PermissionBuilder(
        permission: Permission.manageInventory,
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSparePartScreen()),
          ),
          child: const Icon(Icons.add),
        ),
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('No items found'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return CircleAvatar(
                                backgroundColor: _getStatusColor(item.status),
                                child: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: _getStatusColor(item.status),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${item.brand} • ${item.category}\nStock: ${item.quantity}  |  Price: ₹${item.price}',
                  ),
                  isThreeLine: true,
                  // Only admins can edit inventory
                  trailing: PermissionBuilder(
                    permission: Permission.manageInventory,
                    child: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddSparePartScreen(item: item),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Stock':
        return Colors.green;
      case 'Low Stock':
        return Colors.orange;
      case 'Out of Stock':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
