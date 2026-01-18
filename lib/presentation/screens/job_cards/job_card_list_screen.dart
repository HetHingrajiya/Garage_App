import 'package:autocare_pro/core/permissions/permissions.dart';
import 'package:autocare_pro/data/models/job_card_model.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:autocare_pro/presentation/screens/job_cards/add_job_card_screen.dart';
import 'package:autocare_pro/presentation/screens/job_cards/job_card_detail_screen.dart';
import 'package:autocare_pro/presentation/widgets/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Search Query Notifier
class JobSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String query) => state = query;
}

final jobSearchQueryProvider = NotifierProvider<JobSearchNotifier, String>(
  JobSearchNotifier.new,
);

// Filter Status Notifier
class JobStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All'; // All, Active, Completed
  void set(String filter) => state = filter;
}

final jobStatusFilterProvider =
    NotifierProvider<JobStatusFilterNotifier, String>(
      JobStatusFilterNotifier.new,
    );

final jobCardListProvider = StreamProvider<List<JobCard>>((ref) {
  final currentUser = ref.watch(authStateProvider).value;
  final userRole = ref.watch(currentUserRoleProvider).value;

  return ref.watch(garageRepositoryProvider).getJobCards().map((allJobs) {
    final query = ref.watch(jobSearchQueryProvider).toLowerCase();
    final filter = ref.watch(jobStatusFilterProvider);

    var filteredJobs = allJobs;

    // Filter by mechanic if user is a mechanic (only show assigned jobs)
    if (userRole == 'mechanic' && currentUser != null) {
      filteredJobs = filteredJobs.where((job) {
        return job.mechanicIds.contains(currentUser.uid);
      }).toList();
    }

    return filteredJobs.where((job) {
      // 1. Filter by status
      if (filter == 'Active' &&
          (job.status == 'Completed' || job.status == 'Delivered')) {
        return false;
      }
      if (filter == 'Completed' &&
          (job.status != 'Completed' && job.status != 'Delivered')) {
        return false;
      }

      // 2. Search
      if (query.isEmpty) return true;
      return job.jobNo.toLowerCase().contains(query) ||
          job.vehicleId.toLowerCase().contains(
            query,
          ); // Ideally we search customer name/vehicle reg no, needs join or simplified Logic.
      // Since vehicleId is UUID usually, this search might not be great unless we fetch linked data.
      // For now, search Job No is primary.
    }).toList();
  });
});

class JobCardListScreen extends ConsumerWidget {
  const JobCardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobCardListProvider);
    final theme = Theme.of(context);
    final currentFilter = ref.watch(jobStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Cards'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SearchBar(
                  hintText: 'Search Job No...',
                  leading: const Icon(Icons.search),
                  onChanged: (val) =>
                      ref.read(jobSearchQueryProvider.notifier).set(val),
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['All', 'Active', 'Completed'].map((filter) {
                    final isSelected = currentFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) => ref
                            .read(jobStatusFilterProvider.notifier)
                            .set(filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      // Only admins can create new job cards
      floatingActionButton: PermissionBuilder(
        permission: Permission.createJobCards,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddJobCardScreen()),
            );
          },
          label: const Text('New Job Card'),
          icon: const Icon(Icons.add),
        ),
      ),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(child: Text('No job cards found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return Card(
                elevation: 1, // Subtle card
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(job.status),
                    child: const Icon(
                      Icons.work,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    job.jobNo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${job.status}'),
                      Text(
                        DateFormat.yMMMd().format(job.date),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobCardDetailScreen(jobCard: job),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Received':
        return Colors.blue;
      case 'Inspection':
        return Colors.orange;
      case 'InProgress':
        return Colors.purple;
      case 'Completed':
        return Colors.green;
      case 'Delivered':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}
