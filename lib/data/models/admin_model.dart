import 'base_user_model.dart';

class AdminModel extends BaseUserModel {
  final List<String> permissions;
  final bool
  isSuperAdmin; // Super admin cannot be deleted and can create admins

  AdminModel({
    required super.id,
    required super.email,
    required super.name,
    super.mobile,
    super.status,
    required super.createdAt,
    this.permissions = const ['all'], // Default: full access
    this.isSuperAdmin = false, // Default: regular admin
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      ...toBaseMap(),
      'role': 'admin',
      'permissions': permissions,
      'isSuperAdmin': isSuperAdmin,
    };
  }

  factory AdminModel.fromMap(Map<String, dynamic> map, String id) {
    return AdminModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      mobile: map['mobile'],
      status: map['status'] ?? 'Active',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      permissions: List<String>.from(map['permissions'] ?? ['all']),
      isSuperAdmin: map['isSuperAdmin'] ?? false,
    );
  }

  /// Create a copy with updated fields
  AdminModel copyWith({
    String? id,
    String? email,
    String? name,
    String? mobile,
    String? status,
    DateTime? createdAt,
    List<String>? permissions,
    bool? isSuperAdmin,
  }) {
    return AdminModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      permissions: permissions ?? this.permissions,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
    );
  }
}
