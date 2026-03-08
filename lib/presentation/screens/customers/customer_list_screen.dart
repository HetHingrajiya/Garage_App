import 'package:autocare_pro/data/models/customer_model.dart';
import 'package:autocare_pro/presentation/providers/filtered_data_providers.dart';
import 'package:autocare_pro/presentation/screens/customers/add_customer_screen.dart';
import 'package:autocare_pro/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:autocare_pro/core/theme/app_theme.dart';
import 'package:autocare_pro/presentation/widgets/common/realistic_container.dart';
import 'package:autocare_pro/presentation/widgets/common/neumorphic_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void update(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() => SearchQueryNotifier());

final customerListProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final customersAsync = ref.watch(filteredCustomersProvider);

  return customersAsync.when(
    data: (customers) {
      if (query.isEmpty) return AsyncValue.data(customers);
      return AsyncValue.data(customers.where((c) =>
          c.name.toLowerCase().contains(query) ||
          (c.mobile?.contains(query) ?? false) ||
          (c.email.toLowerCase().contains(query))).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) debugPrint('Could not launch $url');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.nmBaseDark : AppTheme.nmBaseLight;

    return Scaffold(
      backgroundColor: baseColor,
      body: Column(
        children: [
          // Custom Neumorphic AppBar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            child: Row(
              children: [
                NeumorphicIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                  color: isDark ? Colors.white70 : const Color(0xFF334155), // Slate 700
                ),
                const SizedBox(width: 20),
                Text(
                  'Customers',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B), // Slate 800
                  ),
                ),
                const Spacer(),
                NeumorphicIconButton(
                  icon: Icons.add_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCustomerScreen())),
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
          
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: RealisticContainer(
              padding: EdgeInsets.zero,
              borderRadius: 20,
              state: NeumorphicState.concave,
              depth: 8,
              child: TextField(
                onChanged: (val) => ref.read(searchQueryProvider.notifier).update(val),
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : const Color(0xFFCBD5E1)), // Slate 300
                ),
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)), // Slate 800
              ),
            ),
          ),

          Expanded(
            child: customersAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return Center(
                    child: Text('No customers found', style: GoogleFonts.inter(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: RealisticContainer(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 28,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: baseColor,
                              child: RealisticContainer(
                                padding: EdgeInsets.zero,
                                borderRadius: 100,
                                state: NeumorphicState.convex,
                                depth: 4,
                                child: Center(
                                  child: Text(
                                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B), // Slate 800
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customer.mobile ?? 'No contact',
                                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            NeumorphicIconButton(
                              icon: Icons.phone_rounded,
                              onTap: () => _launchUrl('tel:${customer.mobile}'),
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            NeumorphicIconButton(
                              icon: Icons.chat_bubble_rounded,
                              onTap: () => _launchUrl('https://wa.me/${customer.mobile}'),
                              color: Colors.teal,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      drawer: DashboardNavigator.buildDrawer(context, ref),
    );
  }
}
