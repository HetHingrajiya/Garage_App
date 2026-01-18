import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String invoiceId;
  final double amount;
  final String mode; // 'Cash', 'Card', 'UPI'
  final DateTime date;

  Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.mode,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'amount': amount,
      'mode': mode,
      'date': Timestamp.fromDate(date),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map, String id) {
    return Payment(
      id: id,
      invoiceId: map['invoiceId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      mode: map['mode'] ?? 'Cash',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
