import 'package:autocare_pro/core/permissions/permissions.dart';
import 'package:autocare_pro/data/models/customer_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:autocare_pro/presentation/screens/customers/add_customer_screen.dart';
import 'package:autocare_pro/presentation/widgets/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void update(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

final customerListProvider = StreamProvider<List<Customer>>((ref) {
  final query = ref.watch(searchQueryProvider);
  return ref.watch(garageRepositoryProvider).searchCustomers(query);
});

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  Future<void> _makeCall(String? mobile) async {
    if (mobile == null || mobile.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: mobile);
    if (!await launchUrl(launchUri)) {
      debugPrint('Could not launch call to $mobile');
    }
  }

  Future<void> _openWhatsApp(String? mobile) async {
    if (mobile == null || mobile.isEmpty) return;
    // Basic cleanup for mobile number if needed (e.g. remove spaces)
    // Assuming mobile includes or needs country code. Append 91 if missing or just try direct.
    // For simplicity, using direct number.
    final Uri launchUri = Uri.parse("https://wa.me/$mobile");
    if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch WhatsApp to $mobile');
    }
  }

  Future<void> _deleteCustomer(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: const Text(
          'This will mark the customer as inactive. History will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(garageRepositoryProvider).deleteCustomer(id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: PermissionBuilder(
        permission: Permission.addCustomer,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddCustomerScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
      appBar: AppBar(
        title: const Text('Customers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Name or Mobile',
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
                  ref.read(searchQueryProvider.notifier).update(val),
            ),
          ),
        ),
      ),

      // Only admins can add customers
      body: customersAsync.when(
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(child: Text('No customers found.'));
          }
          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(
                    customer.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${customer.mobile} • ${customer.gender ?? "N/A"}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () => _makeCall(customer.mobile),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.message,
                          color: Colors.teal,
                        ), // WhatsApp metaphor
                        onPressed: () => _openWhatsApp(customer.mobile),
                      ),
                      // Only admins can edit/delete customers
                      Consumer(
                        builder: (context, ref, child) {
                          return PermissionBuilder(
                            permission: Permission.editCustomers,
                            child: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                              onSelected: (val) {
                                if (val == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddCustomerScreen(customer: customer),
                                    ),
                                  );
                                } else if (val == 'delete') {
                                  _deleteCustomer(context, ref, customer.id);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddCustomerScreen(customer: customer),
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
