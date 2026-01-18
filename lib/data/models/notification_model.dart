import 'package:cloud_firestore/cloud_firestore.dart';

class GarageNotification {
  final String id;
  final String userId; // Customer ID or Staff ID
  final String title;
  final String message;
  final String type; // 'Status', 'Reminder', 'Payment', 'Offer'
  final DateTime date;
  final bool isRead;

  GarageNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.date,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'date': Timestamp.fromDate(date),
      'isRead': isRead,
    };
  }

  factory GarageNotification.fromMap(Map<String, dynamic> map, String id) {
    return GarageNotification(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'Status',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
}
