import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  final String id;
  final String customerId;
  final String customerName;
  final String number; // Reg no
  final String brand;
  final String model;
  final String vehicleType; // Car, Bike, Other
  final String fuelType;
  final String year;
  final int currentKm;
  final String status; // Active, Sold, etc.
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.number,
    required this.brand,
    required this.model,
    required this.vehicleType,
    required this.fuelType,
    required this.year,
    required this.currentKm,
    this.status = 'Active',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'number': number,
      'brand': brand,
      'model': model,
      'vehicleType': vehicleType,
      'fuelType': fuelType,
      'year': year,
      'currentKm': currentKm,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map, String id) {
    return Vehicle(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      number: map['number'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      vehicleType: map['vehicleType'] ?? 'Car',
      fuelType: map['fuelType'] ?? '',
      year: map['year'] ?? '',
      currentKm: map['currentKm'] ?? 0,
      status: map['status'] ?? 'Active',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
 