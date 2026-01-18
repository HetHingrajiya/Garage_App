import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceItem {
  final String name;
  final double price;
  final int quantity;
  final String type; // 'Service' or 'Part'

  InvoiceItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'quantity': quantity,
    'type': type,
  };
  factory InvoiceItem.fromMap(Map<String, dynamic> map) => InvoiceItem(
    name: map['name'] ?? '',
    price: (map['price'] ?? 0).toDouble(),
    quantity: map['quantity'] ?? 1,
    type: map['type'] ?? 'Service',
  );
}

class Invoice {
  final String id;
  final String jobCardId;
  final String invoiceNumber;
  final DateTime date;
  final double subtotal;
  final double tax; // GST Amount
  final double discount;
  final double total;
  final String? url;
  final String paymentStatus; // 'Pending', 'Partial', 'Paid'
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.jobCardId,
    required this.invoiceNumber,
    required this.date,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    this.url,
    this.paymentStatus = 'Pending',
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'jobCardId': jobCardId,
      'invoiceNumber': invoiceNumber,
      'date': Timestamp.fromDate(date),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'url': url,
      'paymentStatus': paymentStatus,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, String id) {
    return Invoice(
      id: id,
      jobCardId: map['jobCardId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      url: map['url'],
      paymentStatus: map['paymentStatus'] ?? 'Pending',
      items:
          (map['items'] as List<dynamic>?)
              ?.map((e) => InvoiceItem.fromMap(e))
              .toList() ??
          [],
    );
  }
}
