import 'package:autocare_pro/data/models/mechanic_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MechanicDetailScreen extends StatelessWidget {
  final MechanicModel mechanic;

  const MechanicDetailScreen({super.key, required this.mechanic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(mechanic.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/mechanics/add', extra: mechanic),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        mechanic.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mechanic.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: mechanic.status == 'Active'
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              mechanic.status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: mechanic.status == 'Active'
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Info Sections
            _buildSectionTitle(context, 'Contact Information'),
            _buildInfoCard([
              _buildInfoRow(context, Icons.email_outlined, 'Email', mechanic.email),
              if (mechanic.mobile != null)
                _buildInfoRow(context, Icons.phone_outlined, 'Phone', mechanic.mobile!),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'Professional Details'),
            _buildInfoCard([
              _buildInfoRow(
                context,
                Icons.work_outline_rounded,
                'Experience',
                '${mechanic.experience} Years',
              ),
              _buildInfoRow(
                context,
                Icons.check_circle_outline_rounded,
                'Completed Jobs',
                '${mechanic.completedJobs} Jobs',
              ),
              _buildInfoRow(
                context,
                Icons.star_outline_rounded,
                'Rating',
                mechanic.rating.toStringAsFixed(1),
                isLast: true,
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'Skills & Expertise'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mechanic.skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[300]!),
                );
              }).toList(),
            ),
            if (mechanic.skills.isEmpty)
              Text(
                'No skills listed',
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value,
      {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 52, color: Colors.grey[100]),
      ],
    );
  }
}
