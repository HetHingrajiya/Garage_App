import 'package:autocare_pro/data/repositories/garage_repository.dart';
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: statsAsync.when(
        data: (stats) {
          final totalValue = stats['totalValue'] ?? 0;
          final lowStock = stats['lowStockCount'] ?? 0;
          final totalItems = stats['totalItems'] ?? 0;

          return Column(
            children: [
              Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Total Inventory Value',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '₹${totalValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Total Items',
                      '$totalItems',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoCard(
                      'Low Stock Alerts',
                      '$lowStock',
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Stock Health',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              // Placeholder for a chart or list of fast moving items
              const Expanded(
                child: Center(
                  child: Text(
                    'Detailed stock analysis available in Inventory List.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
