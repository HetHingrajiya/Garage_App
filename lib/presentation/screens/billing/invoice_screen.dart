import 'package:autocare_pro/data/models/invoice_model.dart';
import 'package:autocare_pro/data/models/job_card_model.dart';
import 'package:autocare_pro/data/models/payment_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class InvoiceScreen extends ConsumerStatefulWidget {
  final JobCard? jobCard; // If generating new
  final Invoice? invoice; // If viewing existing

  const InvoiceScreen({super.key, this.jobCard, this.invoice});

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  late Invoice _invoice; // Temporary or Final
  bool _isGenerated = false;

  final _discountController = TextEditingController(text: '0');
  final _taxRateController = TextEditingController(
    text: '18',
  ); // 18% GST Default

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _invoice = widget.invoice!;
      _isGenerated = true;
    } else if (widget.jobCard != null) {
      _calculatePreview();
    }
  }

  void _calculatePreview() {
    final job = widget.jobCard!;
    double subtotal = 0;
    List<InvoiceItem> items = [];

    for (var s in job.selectedServices) {
      subtotal += s.price;
      items.add(
        InvoiceItem(name: s.name, price: s.price, quantity: 1, type: 'Service'),
      );
    }
    for (var p in job.selectedParts) {
      subtotal += (p.price * p.quantity);
      items.add(
        InvoiceItem(
          name: p.name,
          price: p.price,
          quantity: p.quantity,
          type: 'Part',
        ),
      );
    }

    final discount = double.tryParse(_discountController.text) ?? 0;
    final taxRate = double.tryParse(_taxRateController.text) ?? 0;
    final taxable = subtotal - discount;
    final tax = taxable * (taxRate / 100);
    final total = taxable + tax;

    // Generate Invoice Number
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final invNo = 'INV-${timestamp.substring(timestamp.length - 6)}';

    setState(() {
      _invoice = Invoice(
        id: widget.invoice?.id ?? const Uuid().v4(),
        jobCardId: job.id,
        invoiceNumber: widget.invoice?.invoiceNumber ?? invNo,
        date: DateTime.now(),
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        total: total,
        paymentStatus: 'Pending',
        items: items,
      );
    });
  }

  Future<void> _generateInvoice() async {
    try {
      await ref.read(garageRepositoryProvider).createInvoice(_invoice);
      setState(() => _isGenerated = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invoice Generated')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _recordPayment() async {
    final amountController = TextEditingController(
      text: _invoice.total.toString(),
    );
    String paymentMode = 'Cash';

    final success = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: paymentMode,
              items: [
                'Cash',
                'UPI',
                'Card',
              ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => paymentMode = val!,
              decoration: const InputDecoration(labelText: 'Payment Mode'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (success == true) {
      final payment = Payment(
        id: const Uuid().v4(),
        invoiceId: _invoice.id,
        amount: double.parse(amountController.text),
        mode: paymentMode,
        date: DateTime.now(),
      );

      await ref.read(garageRepositoryProvider).recordPayment(payment);

      // Refresh screen logic (simplified: pop or fetch new)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment Recorded')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isGenerated
              ? 'Invoice ${_invoice.invoiceNumber}'
              : 'Generate Invoice',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Invoice Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _isGenerated ? 'INVOICE' : 'DRAFT',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Divider(),
                    ..._invoice.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.name} x${item.quantity}'),
                            Text(
                              '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    if (!_isGenerated) ...[
                      Row(
                        children: [
                          const Text('Discount: '),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _discountController,
                              onChanged: (_) => _calculatePreview(),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const Spacer(),
                          const Text('Tax (%): '),
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: _taxRateController,
                              onChanged: (_) => _calculatePreview(),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildSummaryRow('Subtotal', _invoice.subtotal),
                    _buildSummaryRow(
                      'Discount',
                      -_invoice.discount,
                      color: Colors.green,
                    ),
                    _buildSummaryRow('Tax (GST)', _invoice.tax),
                    const Divider(thickness: 2),
                    _buildSummaryRow(
                      'Total',
                      _invoice.total,
                      isBold: true,
                      fontSize: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            if (!_isGenerated)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _generateInvoice,
                  child: const Text('Confirm & Generate Invoice'),
                ),
              )
            else ...[
              Text(
                'Status: ${_invoice.paymentStatus}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              if (_invoice.paymentStatus != 'Paid')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _recordPayment,
                    icon: const Icon(Icons.payment),
                    label: const Text('Record Payment'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double val, {
    Color? color,
    bool isBold = false,
    double? fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            '₹${val.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
