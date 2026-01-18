import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_user_model.dart';

class MechanicModel extends BaseUserModel {
  final List<String> skills;
  final int experience; // Years of experience
  final double rating;
  final int completedJobs;

  MechanicModel({
    required super.id,
    required super.email,
    required super.name,
    super.mobile,
    super.status,
    required super.createdAt,
    this.skills = const [],
    this.experience = 0,
    this.rating = 0.0,
    this.completedJobs = 0,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      ...toBaseMap(),
      'role': 'mechanic',
      'skills': skills,
      'experience': experience,
      'rating': rating,
      'completedJobs': completedJobs,
    };
  }

  factory MechanicModel.fromMap(Map<String, dynamic> map, String id) {
    return MechanicModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      mobile: map['mobile'],
      status: map['status'] ?? 'Active',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is String
                ? DateTime.parse(map['createdAt'])
                : DateTime.now()),
      skills: List<String>.from(map['skills'] ?? []),
      experience: map['experience'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      completedJobs: map['completedJobs'] ?? 0,
    );
  }
}
