import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:autocare_pro/presentation/widgets/common/neumorphic_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// --- Providers ---

final incomeStatsProvider =
    FutureProvider.family<Map<String, double>, DateTimeRange?>((ref, range) {
      return ref
          .watch(garageRepositoryProvider)
          .getIncomeStats(startDate: range?.start, endDate: range?.end);
    });

final mechanicStatsProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(garageRepositoryProvider).getMechanicJobCounts();
});

final inventoryStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(garageRepositoryProvider).getInventoryStats();
});

// --- Screens ---

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Income', icon: Icon(Icons.attach_money)),
            Tab(text: 'Mechanics', icon: Icon(Icons.people)),
            Tab(text: 'Inventory', icon: Icon(Icons.inventory)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          IncomeReportTab(),
          MechanicReportTab(),
          InventoryReportTab(),
        ],
      ),
    );
  }
}

// --- Income Tab ---

class IncomeReportTab extends ConsumerStatefulWidget {
  const IncomeReportTab({super.key});

  @override
  ConsumerState<IncomeReportTab> createState() => _IncomeReportTabState();
}

class _IncomeReportTabState extends ConsumerState<IncomeReportTab> {
  DateTimeRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(incomeStatsProvider(_selectedRange));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedRange == null
                    ? 'All Time'
                    : '${DateFormat.yMMMd().format(_selectedRange!.start)} - ${DateFormat.yMMMd().format(_selectedRange!.end)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: const Text('Filter Date'),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (range != null) setState(() => _selectedRange = range);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          statsAsync.when(
            data: (stats) {
              final total = stats['total'] ?? 0;
              final received = stats['received'] ?? 0;
              final pending = stats['pending'] ?? 0;

              return Column(
                children: [
                  _buildStatCard('Total Revenue', total, Colors.blue),
                  _buildStatCard('Received Payment', received, Colors.green),
                  _buildStatCard('Pending Amount', pending, Colors.orange),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, double value, Color color) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: const Icon(Icons.currency_rupee, color: Colors.white),
        ),
        title: Text(title),
        trailing: Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

// --- Mechanic Tab ---

class MechanicReportTab extends ConsumerWidget {
  const MechanicReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(mechanicStatsProvider);

    return StreamBuilder(
      // Combining Future and Stream is tricky, let's just listen to mechanics stream and future stats
      stream: ref.watch(garageRepositoryProvider).getMechanics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final mechanicsList = snapshot.data!;

        return statsAsync.when(
          data: (stats) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mechanicsList.length,
              itemBuilder: (context, index) {
                final mech = mechanicsList[index];
                final completedJobs = stats[mech.id] ?? 0;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(mech.name[0])),
                    title: Text(mech.name),
                    subtitle: Text(mech.skills.join(", ")),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$completedJobs',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Text('Jobs Done', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        );
      },
    );
  }
}

// --- Inventory Tab ---

class InventoryReportTab extends ConsumerWidget {
  const InventoryReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(inventoryStatsProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: statsAsync.when(
        data: (stats) {
          final totalValue = stats['totalValue'] ?? 0;
          final lowStock = stats['lowStockCount'] ?? 0;

          return Column(
            children: [
              // Total Value Card with high contrast
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'TOTAL INVENTORY VALUE',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${totalValue.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stock Health Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'In Stock',
                      '${stats['inStockCount'] ?? 0}',
                      Colors.green,
                      Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Low Stock',
                      '$lowStock',
                      Colors.orange,
                      Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Out of Stock',
                      '${stats['outOfStockCount'] ?? 0}',
                      Colors.red,
                      Icons.error_outline_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              
              // Stock Health Visualization
              Text(
                'Stock Health Distribution',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      if (stats['inStockCount'] != 0)
                        Expanded(
                          flex: stats['inStockCount'],
                          child: Container(color: Colors.green),
                        ),
                      if (lowStock != 0)
                        Expanded(
                          flex: lowStock,
                          child: Container(color: Colors.orange),
                        ),
                      if (stats['outOfStockCount'] != 0)
                        Expanded(
                          flex: stats['outOfStockCount'],
                          child: Container(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              const Spacer(),
              Center(
                child: Text(
                  'Detailed stock analysis available in Inventory List.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color, IconData icon) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
