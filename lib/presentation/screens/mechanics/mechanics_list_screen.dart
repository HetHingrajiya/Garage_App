import 'package:autocare_pro/core/permissions/permissions.dart';
import 'package:autocare_pro/data/repositories/user_repository.dart';
import 'package:autocare_pro/presentation/widgets/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final mechanicsListProvider = FutureProvider((ref) {
  return ref.watch(userRepositoryProvider).getAllMechanics();
});

class MechanicsListScreen extends ConsumerWidget {
  const MechanicsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mechanicsAsync = ref.watch(mechanicsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mechanics'),
        actions: [
          // Only admins can add mechanics
          PermissionBuilder(
            permission: Permission.editMechanics,
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/mechanics/add'),
              tooltip: 'Add Mechanic',
            ),
          ),
        ],
      ),
      // Only admins can add mechanics
      floatingActionButton: PermissionBuilder(
        permission: Permission.editMechanics,
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/mechanics/add'),
          icon: const Icon(Icons.add),
          label: const Text('Add Mechanic'),
        ),
      ),
      body: mechanicsAsync.when(
        data: (mechanics) {
          if (mechanics.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.engineering_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Mechanics Found',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first mechanic to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/mechanics/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Mechanic'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(mechanicsListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mechanics.length,
              itemBuilder: (context, index) {
                final mechanic = mechanics[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        mechanic.name.isNotEmpty
                            ? mechanic.name[0].toUpperCase()
                            : 'M',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(
                      mechanic.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.email,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                mechanic.email,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        if (mechanic.mobile != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                mechanic.mobile!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: mechanic.skills.take(3).map((skill) {
                            return Chip(
                              label: Text(
                                skill,
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                        if (mechanic.skills.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+${mechanic.skills.length - 3} more skills',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: mechanic.status == 'Active'
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            mechanic.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: mechanic.status == 'Active'
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${mechanic.experience} yrs exp',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // TODO: Navigate to mechanic detail/edit screen
                      context.push('/mechanics/add', extra: mechanic);
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading mechanics',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(mechanicsListProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
