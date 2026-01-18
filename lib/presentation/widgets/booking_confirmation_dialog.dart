import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:autocare_pro/core/constants/service_categories.dart';

class BookingConfirmationDialog extends StatefulWidget {
  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleNumber;
  final ServiceType service;
  final DateTime scheduledDate;
  final String timeSlot;
  final String? notes;
  final VoidCallback onConfirm;

  const BookingConfirmationDialog({
    super.key,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.service,
    required this.scheduledDate,
    required this.timeSlot,
    this.notes,
    required this.onConfirm,
  });

  @override
  State<BookingConfirmationDialog> createState() =>
      _BookingConfirmationDialogState();
}

class _BookingConfirmationDialogState extends State<BookingConfirmationDialog> {
  bool _termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = ServiceCategories.getCategoryForService(widget.service.id);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          category?.color.withValues(alpha: 0.1) ??
                          Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category?.icon ?? Icons.build,
                      color: category?.color ?? Colors.blue,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confirm Booking',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please review your booking details',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Service Details
              _buildSection('Service Details', Icons.build_circle, [
                _buildDetailRow('Service', widget.service.name),
                _buildDetailRow('Category', category?.name ?? 'General'),
                _buildDetailRow(
                  'Estimated Cost',
                  widget.service.estimatedPrice > 0
                      ? '₹${widget.service.estimatedPrice.toStringAsFixed(0)}'
                      : 'To be quoted',
                ),
                _buildDetailRow(
                  'Duration',
                  '${widget.service.estimatedDurationMinutes} mins',
                ),
              ]),
              const SizedBox(height: 16),

              // Vehicle Details
              _buildSection('Vehicle Details', Icons.directions_car, [
                _buildDetailRow(
                  'Vehicle',
                  '${widget.vehicleBrand} ${widget.vehicleModel}',
                ),
                _buildDetailRow('Number', widget.vehicleNumber.toUpperCase()),
              ]),
              const SizedBox(height: 16),

              // Schedule Details
              _buildSection('Schedule', Icons.calendar_today, [
                _buildDetailRow(
                  'Date',
                  DateFormat('EEEE, MMM dd, yyyy').format(widget.scheduledDate),
                ),
                _buildDetailRow('Time', widget.timeSlot),
              ]),

              if (widget.notes != null && widget.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSection('Additional Notes', Icons.note, [
                  Text(widget.notes!, style: theme.textTheme.bodyMedium),
                ]),
              ],

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Important Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Final cost may vary based on actual work required\n'
                            '• Please arrive 10 minutes before scheduled time\n'
                            '• Cancellation allowed up to 2 hours before appointment',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Terms and Conditions
              CheckboxListTile(
                value: _termsAccepted,
                onChanged: (value) =>
                    setState(() => _termsAccepted = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'I agree to the terms and conditions',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _termsAccepted
                          ? () {
                              Navigator.of(context).pop();
                              widget.onConfirm();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Confirm Booking'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
