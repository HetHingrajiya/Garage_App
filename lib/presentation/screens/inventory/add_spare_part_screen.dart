import 'package:autocare_pro/data/models/inventory_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class AddSparePartScreen extends ConsumerStatefulWidget {
  final InventoryItem? item;
  const AddSparePartScreen({super.key, this.item});

  @override
  ConsumerState<AddSparePartScreen> createState() => _AddSparePartScreenState();
}

class _AddSparePartScreenState extends ConsumerState<AddSparePartScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _qtyController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _minStockController;

  String _selectedCategory = 'Accessories';
  final List<String> _categories = [
    'Engine',
    'Electrical',
    'Body',
    'Accessories',
    'Consumables',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _brandController = TextEditingController(text: widget.item?.brand ?? '');
    _qtyController = TextEditingController(
      text: widget.item?.quantity.toString() ?? '0',
    );
    _purchasePriceController = TextEditingController(
      text: widget.item?.purchasePrice.toString() ?? '0',
    );
    _sellingPriceController = TextEditingController(
      text: widget.item?.price.toString() ?? '0',
    );
    _minStockController = TextEditingController(
      text: widget.item?.lowStockThreshold.toString() ?? '5',
    );

    if (widget.item != null) {
      if (_categories.contains(widget.item!.category)) {
        _selectedCategory = widget.item!.category;
      } else {
        _selectedCategory = 'Accessories';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _qtyController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final qty = int.parse(_qtyController.text.trim());
    final purchasePrice = double.parse(_purchasePriceController.text.trim());
    final sellingPrice = double.parse(_sellingPriceController.text.trim());
    final minStock = int.parse(_minStockController.text.trim());

    // Status logic handled in Repo, but nice to be explicit or let repo handle it.
    // Repo handles it.

    final item = InventoryItem(
      id: widget.item?.id ?? const Uuid().v4(),
      name: name,
      category: _selectedCategory,
      brand: brand,
      quantity: qty,
      purchasePrice: purchasePrice,
      price: sellingPrice,
      lowStockThreshold: minStock,
    );

    try {
      if (widget.item == null) {
        await ref.read(garageRepositoryProvider).addInventoryItem(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Part Added Successfully')),
          );
        }
      } else {
        await ref.read(garageRepositoryProvider).updateInventoryItem(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Part Updated Successfully')),
          );
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add Spare Part' : 'Edit Spare Part'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Part Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      decoration: const InputDecoration(
                        labelText: 'Stock Qty',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      decoration: const InputDecoration(
                        labelText: 'Min Stock',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v!.isEmpty) return 'Required';
                        if (double.tryParse(v)! <
                            double.tryParse(_purchasePriceController.text)!) {
                          return 'Check Price';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveItem,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Text(widget.item == null ? 'Add Part' : 'Update Part'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
