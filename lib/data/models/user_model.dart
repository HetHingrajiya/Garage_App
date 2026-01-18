class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'admin', 'mechanic'
  final String? mobile;
  final String status; // 'Active', 'Inactive'
  final DateTime createdAt;
  final List<String> skills; // For mechanics: 'Engine', 'Electrical', etc.
  final int experience; // Years of experience
  final bool isSuperAdmin; // Super admin flag

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.mobile,
    this.status = 'Active',
    required this.createdAt,
    this.skills = const [],
    this.experience = 0,
    this.isSuperAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'mobile': mobile,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'skills': skills,
      'experience': experience,
      'isSuperAdmin': isSuperAdmin,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'mechanic',
      mobile: map['mobile'],
      status: map['status'] ?? 'Active',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      skills: List<String>.from(map['skills'] ?? []),
      experience: map['experience'] ?? 0,
      isSuperAdmin: map['isSuperAdmin'] ?? false,
    );
  }
}
