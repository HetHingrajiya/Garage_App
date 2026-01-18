import 'package:autocare_pro/data/models/customer_model.dart';
import 'package:autocare_pro/data/models/vehicle_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:flutter/material.dart';
import 'package:autocare_pro/core/utils/formatters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  final Customer? preSelectedCustomer;
  final Vehicle? vehicle; // For Edit Mode

  const AddVehicleScreen({super.key, this.preSelectedCustomer, this.vehicle});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _numberController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _kmController;

  // Dropdown Values
  String _vehicleType = 'Car';
  String _fuelType = 'Petrol';
  String? _selectedCustomerId;
  String _selectedCustomerName = ''; // Store the name

  // Vehicle Data
  final Map<String, List<String>> _vehicleData = {
    'Maruti Suzuki': [
      'Swift',
      'Baleno',
      'Dzire',
      'WagonR',
      'Alto',
      'Brezza',
      'Ertiga',
      'Grand Vitara',
      'Other',
    ],
    'Hyundai': [
      'Creta',
      'Venue',
      'i20',
      'Grand i10 Nios',
      'Verna',
      'Aura',
      'Alcazar',
      'Tucson',
      'Other',
    ],
    'Tata': [
      'Nexon',
      'Punch',
      'Tiago',
      'Altroz',
      'Harrier',
      'Safari',
      'Tigor',
      'Other',
    ],
    'Mahindra': [
      'Thar',
      'Scorpio-N',
      'XUV700',
      'XUV300',
      'Bolero',
      'XUV400',
      'Marazzo',
      'Other',
    ],
    'Toyota': [
      'Innova Crysta',
      'Innova Hycross',
      'Fortuner',
      'Glanza',
      'Urban Cruiser Hyryder',
      'Camry',
      'Other',
    ],
    'Kia': ['Seltos', 'Sonet', 'Carens', 'Carnival', 'EV6', 'Other'],
    'Honda': ['City', 'Amaze', 'Elevate', 'Other'],
    'Other': [],
  };

  String? _selectedBrand;
  String? _selectedModel;
  bool _isCustomBrand = false;
  bool _isCustomModel = false;

  bool _isLoading = false;

  final List<String> _vehicleTypes = ['Car', 'Bike', 'Truck', 'Other'];
  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'CNG', 'EV', 'Hybrid'];

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _numberController = TextEditingController(text: v?.number ?? '');
    _brandController = TextEditingController(text: v?.brand ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _yearController = TextEditingController(text: v?.year ?? '');
    _kmController = TextEditingController(text: v?.currentKm.toString() ?? '');

    _vehicleType = v?.vehicleType ?? 'Car';
    _fuelType = v?.fuelType ?? 'Petrol';
    _selectedCustomerId = v?.customerId ?? widget.preSelectedCustomer?.id;
    _selectedCustomerName =
        v?.customerName ?? widget.preSelectedCustomer?.name ?? '';

    // Initialize Dropdowns or Custom Fields based on existing data
    if (v != null) {
      if (_vehicleData.containsKey(v.brand)) {
        _selectedBrand = v.brand;
        if (_vehicleData[v.brand]!.contains(v.model)) {
          _selectedModel = v.model;
        } else {
          _selectedModel = 'Other';
          _isCustomModel = true;
          _modelController.text = v.model;
        }
      } else {
        _selectedBrand = 'Other';
        _isCustomBrand = true;
        _brandController.text = v.brand;
        _isCustomModel = true;
        _modelController.text = v.model;
      }
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEdit = widget.vehicle != null;

      // Determine final Brand/Model
      final brand = _isCustomBrand
          ? _brandController.text.trim()
          : _selectedBrand ?? '';
      final model = _isCustomModel
          ? _modelController.text.trim()
          : _selectedModel ?? '';

      final vehicle = Vehicle(
        id: isEdit ? widget.vehicle!.id : const Uuid().v4(),
        customerId: _selectedCustomerId!,
        customerName: _selectedCustomerName, // Use the captured name

        number: _numberController.text.trim().toUpperCase(),
        brand: brand,
        model: model,
        vehicleType: _vehicleType,
        fuelType: _fuelType,
        year: _yearController.text.trim(),
        currentKm: int.tryParse(_kmController.text.trim()) ?? 0,
        createdAt: isEdit ? widget.vehicle!.createdAt : DateTime.now(),
        status: isEdit ? widget.vehicle!.status : 'Active',
      );

      if (isEdit) {
        await ref.read(garageRepositoryProvider).updateVehicle(vehicle);
      } else {
        await ref.read(garageRepositoryProvider).addVehicle(vehicle);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Vehicle Updated' : 'Vehicle Added')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no customer is pre-selected and not editing, we need to pick one.
    // Fetching all customers for dropdown (simplified)
    // In production, use an Autocomplete or dedicated picker screen.

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle != null ? 'Edit Vehicle' : 'Add Vehicle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Selection
              if (widget.preSelectedCustomer != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text(widget.preSelectedCustomer!.name),
                    subtitle: const Text('Customer'),
                    leading: const Icon(Icons.person),
                    tileColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else if (widget.vehicle != null)
                // Editing existing vehicle - Customer read-only or fetch name?
                // For simplicity, just showing ID or skipped.
                // Ideally we fetch the customer name.
                const SizedBox.shrink()
              else
                StreamBuilder<List<Customer>>(
                  stream: ref.read(garageRepositoryProvider).getCustomers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final customers = snapshot.data!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCustomerId,
                        decoration: const InputDecoration(
                          labelText: 'Select Customer',
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: customers
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.name} (${c.mobile})'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCustomerId = val;
                            // Find and store the name
                            final selectedCustomer = customers.firstWhere(
                              (c) => c.id == val,
                              orElse: () => Customer(
                                id: '',
                                name: '',
                                mobile: '',
                                email: '',
                                createdAt: DateTime.now(),
                                vehicleIds: [],
                                createdBy: '',
                              ),
                            );
                            _selectedCustomerName = selectedCustomer.name;
                          });
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    );
                  },
                ),

              // Vehicle Details
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _vehicleType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: _vehicleTypes
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _vehicleType = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _numberController,
                      decoration: const InputDecoration(
                        labelText: 'Reg Number',
                        hintText: 'e.g. MH 01 AB 1234',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      keyboardType: TextInputType
                          .visiblePassword, // Disables cheeky auto-correct
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9 ]'),
                        ),
                        UpperCaseTextFormatter(),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        // Basic Indian Vehicle Regex: MH01AB1234 or MH 01 AB 1234
                        final regExp = RegExp(
                          r'^[A-Z]{2}[ -]?\d{2}[ -]?[A-Z]{0,2}[ -]?\d{4}$',
                        );
                        if (!regExp.hasMatch(v)) {
                          return 'Invalid Format (e.g. MH01AB1234)';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _isCustomBrand
                        ? TextFormField(
                            controller: _brandController,
                            decoration: InputDecoration(
                              labelText: 'Brand *',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    setState(() => _isCustomBrand = false),
                              ),
                            ),
                            validator: (v) => _isCustomBrand && (v!.isEmpty)
                                ? 'Required'
                                : null,
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedBrand,
                            decoration: const InputDecoration(
                              labelText: 'Brand *',
                            ),
                            items: _vehicleData.keys
                                .map(
                                  (brand) => DropdownMenuItem(
                                    value: brand,
                                    child: Text(brand),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                if (val == 'Other') {
                                  _isCustomBrand = true;
                                  _selectedBrand = null;
                                  _selectedModel = null;
                                } else {
                                  _selectedBrand = val;
                                  _selectedModel = null;
                                }
                              });
                            },
                            validator: (v) => !_isCustomBrand && (v == null)
                                ? 'Required'
                                : null,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _isCustomModel || _isCustomBrand
                        ? TextFormField(
                            controller: _modelController,
                            decoration: InputDecoration(
                              labelText: 'Model *',
                              suffixIcon: _isCustomBrand
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => setState(
                                        () => _isCustomModel = false,
                                      ),
                                    ),
                            ),
                            validator: (v) =>
                                (_isCustomModel || _isCustomBrand) &&
                                    (v!.isEmpty)
                                ? 'Required'
                                : null,
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedModel,
                            decoration: const InputDecoration(
                              labelText: 'Model *',
                            ),
                            items:
                                (_selectedBrand != null &&
                                    _vehicleData.containsKey(_selectedBrand))
                                ? _vehicleData[_selectedBrand]!
                                      .map(
                                        (model) => DropdownMenuItem(
                                          value: model,
                                          child: Text(model),
                                        ),
                                      )
                                      .toList()
                                : [],
                            onChanged: _selectedBrand == null
                                ? null
                                : (val) {
                                    setState(() {
                                      if (val == 'Other') {
                                        _isCustomModel = true;
                                        _selectedModel = null;
                                      } else {
                                        _selectedModel = val;
                                      }
                                    });
                                  },
                            validator: (v) =>
                                !_isCustomModel &&
                                    !_isCustomBrand &&
                                    (v == null)
                                ? 'Required'
                                : null,
                            disabledHint: const Text('Select Brand First'),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _fuelType,
                      decoration: const InputDecoration(labelText: 'Fuel'),
                      items: _fuelTypes
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _fuelType = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(labelText: 'Year'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _kmController,
                decoration: const InputDecoration(
                  labelText: 'Current KM Reading',
                  prefixIcon: Icon(Icons.speed),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveVehicle,
                icon: const Icon(Icons.save),
                label: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save Vehicle'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
