import 'package:autocare_pro/data/models/inventory_model.dart';
import 'package:autocare_pro/data/models/job_card_model.dart';
import 'package:autocare_pro/data/models/service_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddServicePartScreen extends ConsumerStatefulWidget {
  final JobCard jobCard;
  const AddServicePartScreen({super.key, required this.jobCard});

  @override
  ConsumerState<AddServicePartScreen> createState() =>
      _AddServicePartScreenState();
}

class _AddServicePartScreenState extends ConsumerState<AddServicePartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Custom Service Input
  final _serviceNameController = TextEditingController();
  final _servicePriceController = TextEditingController();

  // Part Selection
  final _partQtyController = TextEditingController(text: '1');
  String? _selectedPartId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serviceNameController.dispose();
    _servicePriceController.dispose();
    _partQtyController.dispose();
    super.dispose();
  }

  Future<void> _addCustomService() async {
    if (_serviceNameController.text.isEmpty ||
        _servicePriceController.text.isEmpty) {
      return;
    }

    final service = JobService(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: _serviceNameController.text.trim(),
      price: double.parse(_servicePriceController.text.trim()),
    );

    await ref
        .read(garageRepositoryProvider)
        .addServiceToJob(widget.jobCard.id, service);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Service Added')));
      Navigator.pop(context);
    }
  }

  Future<void> _addExistingService(GarageService s) async {
    final service = JobService(id: s.id, name: s.name, price: s.price);
    await ref
        .read(garageRepositoryProvider)
        .addServiceToJob(widget.jobCard.id, service);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${s.name} Added')));
      Navigator.pop(context);
    }
  }

  Future<void> _addPart(InventoryItem item) async {
    final qty = int.tryParse(_partQtyController.text) ?? 1;

    final part = JobPart(
      id: item.id,
      name: item.name,
      price: item.price,
      quantity: qty,
    );

    await ref
        .read(garageRepositoryProvider)
        .addPartToJob(widget.jobCard.id, part);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Part Added')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Items'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Services'),
            Tab(text: 'Spare Parts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Services Tab
          Column(
            children: [
              // Custom Service Form
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Custom Service',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _serviceNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _servicePriceController,
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.blue,
                              ),
                              onPressed: _addCustomService,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(),
              // Existing Services List
              Expanded(
                child: StreamBuilder<List<GarageService>>(
                  stream: ref.read(garageRepositoryProvider).getServices(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final services = snapshot.data!;
                    if (services.isEmpty) {
                      return const Center(
                        child: Text('No predefined services found.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final s = services[index];
                        return ListTile(
                          title: Text(s.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('₹${s.price}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _addExistingService(s),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Spare Parts Tab
          // Spare Parts Tab
          StreamBuilder<List<InventoryItem>>(
            stream: ref.read(garageRepositoryProvider).getInventory(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final parts = snapshot.data!;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPartId,
                      items: parts
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.name} (₹${p.price})'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedPartId = val),
                      decoration: const InputDecoration(
                        labelText: 'Select Part',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _partQtyController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedPartId == null ||
                            _partQtyController.text.isEmpty) {
                          return;
                        }
                        final selectedPart = parts.firstWhere(
                          (p) => p.id == _selectedPartId,
                        );
                        _addPart(selectedPart);
                      },
                      child: const Text('Add Part to Job'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
