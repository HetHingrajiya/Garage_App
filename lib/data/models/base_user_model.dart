abstract class BaseUserModel {
  final String id;
  final String email;
  final String name;
  final String? mobile;
  final String status; // 'Active', 'Inactive'
  final DateTime createdAt;

  BaseUserModel({
    required this.id,
    required this.email,
    required this.name,
    this.mobile,
    this.status = 'Active',
    required this.createdAt,
  });

  // Common fields for all user types
  Map<String, dynamic> toBaseMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'mobile': mobile,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Each subclass must implement its own toMap
  Map<String, dynamic> toMap();
}
