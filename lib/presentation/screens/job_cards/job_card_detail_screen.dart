import 'package:autocare_pro/presentation/widgets/common/neumorphic_container.dart';
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
  // _currentStatus is now handled reactively by snapshots

  @override
  void initState() {
    super.initState();
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await ref
          .read(garageRepositoryProvider)
          .updateJobStatusWithNotification(widget.jobCard, newStatus);
      // Removed local state update - handled by stream
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
    // We want to show buttons to move to next reasonable status or specific ones.

    return StreamBuilder<JobCard>(
      stream: ref.read(garageRepositoryProvider).getJobCard(widget.jobCard.id),
      initialData: widget.jobCard,
      builder: (context, snapshot) {
        final job = snapshot.data!;
        final theme = Theme.of(context);

        // Status Flow
        final List<String> statusFlow = [
          'Received',
          'Inspection',
          'InProgress',
          'Completed',
          'Delivered',
        ];

        return Scaffold(
          appBar: AppBar(title: Text(job.jobNo)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                NeumorphicContainer(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.8),
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
                            job.status,
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
                            Text(
                              complaintText,
                              style: theme.textTheme.bodyLarge,
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

                const SizedBox(height: 16),
                _buildSection(theme, 'Services', [
                  if (job.selectedServices.isEmpty)
                    const Text('No services added')
                  else
                    ...job.selectedServices.map(
                      (s) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${s.price.toStringAsFixed(0)}'),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => ref
                                  .read(garageRepositoryProvider)
                                  .removeServiceFromJob(job.id, s),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                ]),

                const SizedBox(height: 16),
                _buildSection(theme, 'Parts', [
                  if (job.selectedParts.isEmpty)
                    const Text('No parts added')
                  else
                    ...job.selectedParts.map(
                      (p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.name),
                        subtitle: Text('Qty: ${p.quantity} x ₹${p.price}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${(p.price * p.quantity).toStringAsFixed(0)}'),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => ref
                                  .read(garageRepositoryProvider)
                                  .removePartFromJob(job.id, p),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
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
                    final isCurrent = status == job.status;
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
                if (job.status != 'Delivered') ...[
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

                if (job.status == 'Completed' || job.status == 'Delivered')
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

                if (job.status != 'Delivered' && job.status != 'Completed')
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
      },
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return NeumorphicContainer(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
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
