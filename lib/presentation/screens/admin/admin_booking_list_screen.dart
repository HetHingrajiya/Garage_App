import 'package:autocare_pro/data/models/job_card_model.dart';
import 'package:autocare_pro/data/models/user_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final adminBookingsProvider = StreamProvider<List<JobCard>>((ref) {
  return ref.watch(garageRepositoryProvider).getJobCards().map((jobs) {
    return jobs.where((job) {
      // Filter for mobile app bookings that are still pending
      return job.bookingSource == 'mobile_app' && job.status == 'Pending';
    }).toList();
  });
});

class AdminBookingListScreen extends ConsumerWidget {
  const AdminBookingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(adminBookingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(garageRepositoryProvider),
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending bookings',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('New customer appointments will appear here'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _BookingCard(booking: booking);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _BookingCard extends ConsumerStatefulWidget {
  final JobCard booking;

  const _BookingCard({required this.booking});

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _isProcessing = false;

  Future<void> _declineBooking() async {
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(garageRepositoryProvider)
          .updateJobStatusWithNotification(widget.booking, 'Cancelled');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking Declined'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showAcceptDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AcceptBookingDialog(booking: widget.booking),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking Accepted & Mechanic Assigned'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduledDate =
        widget.booking.estimatedDeliveryDate ?? widget.booking.date;
    final scheduledStr = DateFormat(
      'EEE, MMM dd • hh:mm a',
    ).format(scheduledDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.booking.serviceType ?? 'General Service',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${widget.booking.jobNo}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Details
            Row(
              children: [
                Expanded(
                  child: _DetailItem(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: scheduledStr,
                  ),
                ),
                Expanded(
                  child: _DetailItem(
                    icon: Icons.person,
                    label: 'Customer',
                    value: 'View Profile >', // Placeholder
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.booking.complaint.isNotEmpty) ...[
              const Text(
                'Customer Notes:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                widget.booking.complaint,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _declineBooking,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _showAcceptDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept & Assign'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- New Dialog for Accepting and Assigning Mechanic ---
class _AcceptBookingDialog extends ConsumerStatefulWidget {
  final JobCard booking;

  const _AcceptBookingDialog({required this.booking});

  @override
  ConsumerState<_AcceptBookingDialog> createState() =>
      _AcceptBookingDialogState();
}

class _AcceptBookingDialogState extends ConsumerState<_AcceptBookingDialog> {
  String? _selectedMechanicId;
  bool _isLoading = false;

  Future<void> _confirm() async {
    if (_selectedMechanicId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a mechanic')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(garageRepositoryProvider)
          .acceptBooking(
            jobId: widget.booking.id,
            customerId: widget.booking.customerId,
            jobNo: widget.booking.jobNo,
            mechanicIds: [_selectedMechanicId!],
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Mechanic'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking #${widget.booking.jobNo}'),
            const SizedBox(height: 16),
            StreamBuilder<List<UserModel>>(
              stream: ref.read(garageRepositoryProvider).getMechanics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error loading mechanics: ${snapshot.error}');
                }
                final mechanics = snapshot.data ?? [];

                if (mechanics.isEmpty) {
                  return const Text('No mechanics available.');
                }

                return DropdownButtonFormField<String>(
                  value: _selectedMechanicId,
                  decoration: const InputDecoration(
                    labelText: 'Select Mechanic',
                    border: OutlineInputBorder(),
                  ),
                  items: mechanics
                      .map(
                        (m) =>
                            DropdownMenuItem(value: m.id, child: Text(m.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedMechanicId = val),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirm,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }
}
