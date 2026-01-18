import 'package:autocare_pro/data/models/job_card_model.dart';
import 'package:autocare_pro/data/models/user_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:autocare_pro/data/models/invoice_model.dart';
import 'package:autocare_pro/presentation/screens/billing/add_service_part_screen.dart';
import 'package:autocare_pro/presentation/screens/billing/invoice_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class JobCardDetailScreen extends ConsumerStatefulWidget {
  final JobCard jobCard;
  const JobCardDetailScreen({super.key, required this.jobCard});

  @override
  ConsumerState<JobCardDetailScreen> createState() =>
      _JobCardDetailScreenState();
}

class _JobCardDetailScreenState extends ConsumerState<JobCardDetailScreen> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.jobCard.status;
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await ref
          .read(garageRepositoryProvider)
          .updateJobStatusWithNotification(widget.jobCard, newStatus);
      setState(() => _currentStatus = newStatus);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _closeJob() async {
    final kmController = TextEditingController();
    final remarksController = TextEditingController();

    final success = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Job Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: kmController,
              decoration: const InputDecoration(labelText: 'Final KM Reading'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Completion Remarks',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (kmController.text.isNotEmpty) Navigator.pop(context, true);
            },
            child: const Text('Close Job'),
          ),
        ],
      ),
    );

    if (success == true) {
      try {
        await ref
            .read(garageRepositoryProvider)
            .closeJobCard(
              widget.jobCard.id,
              int.parse(kmController.text),
              remarksController.text,
            );
        if (mounted) {
          setState(() => _currentStatus = 'Delivered');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job Closed Successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.jobCard;
    final theme = Theme.of(context);

    // Status Flow
    final List<String> statusFlow = [
      'Received',
      'Inspection',
      'InProgress',
      'Completed',
      'Delivered',
    ];
    // We want to show buttons to move to next reasonable status or specific ones.

    return Scaffold(
      appBar: AppBar(title: Text(job.jobNo)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          _currentStatus,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info
            _buildSection(theme, 'Details', [
              _buildRow('Date', DateFormat.yMMMd().format(job.date)),
              _buildRow('Priority', job.priority),
              _buildRow('Initial KM', '${job.initialKm} km'),
              if (job.estimatedDeliveryDate != null)
                _buildRow(
                  'Est. Delivery',
                  DateFormat.yMMMd().format(job.estimatedDeliveryDate!),
                ),
            ]),

            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final complaintText = job.complaint
                    .replaceAll('Service Request: ', '')
                    .trim();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (complaintText.isNotEmpty) ...[
                      _buildSection(theme, 'Complaint', [
                        Text(complaintText, style: theme.textTheme.bodyLarge),
                      ]),
                      const SizedBox(height: 16),
                    ],
                    if (job.selectedServices.isNotEmpty) ...[
                      _buildSection(theme, 'Requested Services', [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: job.selectedServices.map((s) {
                            return Chip(
                              label: Text(s.name),
                              backgroundColor:
                                  theme.colorScheme.secondaryContainer,
                              labelStyle: TextStyle(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            );
                          }).toList(),
                        ),
                      ]),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),

            _buildSection(theme, 'Mechanics', [
              if (job.mechanicIds.isEmpty)
                const Text('No mechanics assigned')
              else
                Wrap(
                  spacing: 8,
                  children: job.mechanicIds.map((mId) {
                    return FutureBuilder<UserModel?>(
                      future: ref
                          .read(garageRepositoryProvider)
                          .getMechanic(mId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Chip(
                            label: Text(
                              mId.length > 5 ? mId.substring(0, 5) : mId,
                            ),
                          );
                        }
                        final mechanic = snapshot.data;
                        return Chip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: Text(mechanic?.name ?? 'Unknown'),
                        );
                      },
                    );
                  }).toList(),
                ),
            ]),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Actions
            Text('Update Status', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: statusFlow.map((status) {
                final isCurrent = status == _currentStatus;
                if (status == 'Delivered') {
                  return const SizedBox.shrink(); // Handled by close button
                }
                return ChoiceChip(
                  label: Text(status),
                  selected: isCurrent,
                  onSelected: isCurrent
                      ? null
                      : (selected) {
                          if (selected) _updateStatus(status);
                        },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            if (_currentStatus != 'Delivered') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddServicePartScreen(jobCard: job),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add Services / Parts'),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_currentStatus == 'Completed' || _currentStatus == 'Delivered')
              StreamBuilder<List<Invoice>>(
                stream: ref
                    .watch(garageRepositoryProvider)
                    .getInvoices(jobId: job.id),
                builder: (context, snapshot) {
                  final invoices = snapshot.data ?? [];
                  final hasInvoice = invoices.isNotEmpty;

                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InvoiceScreen(
                              jobCard: hasInvoice ? null : job,
                              invoice: hasInvoice ? invoices.first : null,
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        hasInvoice ? Icons.visibility : Icons.receipt_long,
                      ),
                      label: Text(
                        hasInvoice ? 'View Invoice' : 'Generate Invoice',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: hasInvoice
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),

            if (_currentStatus != 'Delivered' && _currentStatus != 'Completed')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _closeJob,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Close Job Card'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
