import 'package:autocare_pro/data/models/notification_model.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final notificationListProvider = StreamProvider<List<GarageNotification>>((
  ref,
) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(garageRepositoryProvider).getNotifications(user.uid);
});

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifsAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) {
            return const Center(child: Text('No notifications.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (context, index) {
              final n = notifs[index];
              return Card(
                color: n.isRead ? null : Colors.blue.shade50,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTypeColor(n.type),
                    child: Icon(
                      _getTypeIcon(n.type),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.message),
                      Text(
                        DateFormat.yMMMd().add_jm().format(n.date),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Status':
        return Colors.blue;
      case 'Reminder':
        return Colors.orange;
      case 'Payment':
        return Colors.green;
      case 'Offer':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Status':
        return Icons.info;
      case 'Reminder':
        return Icons.alarm;
      case 'Payment':
        return Icons.payment;
      case 'Offer':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }
}
