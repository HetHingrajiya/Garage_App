import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_user_model.dart';

/// Unified Customer Model
/// Supports both:
/// 1. Authenticated customers (self-registered, can login)
/// 2. Admin-created customers (no auth, cannot login)
class Customer extends BaseUserModel {
  final String? address;
  final String? gender;
  final List<String> vehicleIds;

  // New fields for unified model
  final bool hasAuthAccount; // Can this customer login?
  final String createdBy; // "self" or "admin"
  final String? createdByAdminId; // Admin ID if created by admin

  Customer({
    required super.id,
    required super.email,
    required super.name,
    super.mobile,
    super.status,
    required super.createdAt,
    this.address,
    this.gender,
    this.vehicleIds = const [],
    this.hasAuthAccount =
        true, // Changed to true - all customers can login by default
    this.createdBy = 'admin',
    this.createdByAdminId,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      ...toBaseMap(),
      'role': 'customer', // Add role field for consistency
      'address': address,
      'gender': gender,
      'vehicleIds': vehicleIds,
      'hasAuthAccount': hasAuthAccount,
      'createdBy': createdBy,
      'createdByAdminId': createdByAdminId,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    // Parse createdAt - handle both Timestamp and String formats
    DateTime parsedCreatedAt;
    final createdAtValue = map['createdAt'];
    if (createdAtValue is Timestamp) {
      parsedCreatedAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      parsedCreatedAt = DateTime.parse(createdAtValue);
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return Customer(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      mobile: map['mobile'],
      address: map['address'],
      gender: map['gender'],
      status:
          map['status'] ?? (map['isActive'] == true ? 'Active' : 'Inactive'),
      createdAt: parsedCreatedAt,
      vehicleIds: List<String>.from(map['vehicleIds'] ?? []),
      hasAuthAccount: map['hasAuthAccount'] ?? false,
      createdBy: map['createdBy'] ?? 'admin',
      createdByAdminId: map['createdByAdminId'],
    );
  }

  /// Create a copy with updated fields
  Customer copyWith({
    String? id,
    String? email,
    String? name,
    String? mobile,
    String? address,
    String? gender,
    String? status,
    DateTime? createdAt,
    List<String>? vehicleIds,
    bool? hasAuthAccount,
    String? createdBy,
    String? createdByAdminId,
  }) {
    return Customer(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      vehicleIds: vehicleIds ?? this.vehicleIds,
      hasAuthAccount: hasAuthAccount ?? this.hasAuthAccount,
      createdBy: createdBy ?? this.createdBy,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
    );
  }
}
