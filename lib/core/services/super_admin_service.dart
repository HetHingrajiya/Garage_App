import 'package:autocare_pro/data/models/admin_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to initialize and manage super admin
class SuperAdminService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Default super admin credentials
  static const String defaultSuperAdminEmail = 'superadmin@garageapp.com';
  static const String defaultSuperAdminPassword = 'SuperAdmin@123';
  static const String defaultSuperAdminName = 'Super Administrator';

  SuperAdminService(this._firestore, this._auth);

  /// Initialize default super admin account
  /// This should be called once when the app first starts
  Future<void> initializeSuperAdmin() async {
    try {
      // Try to sign in first to check if account exists
      UserCredential? userCredential;
      User? superAdminUser;

      try {
        // Try to sign in with existing credentials
        userCredential = await _auth.signInWithEmailAndPassword(
          email: defaultSuperAdminEmail,
          password: defaultSuperAdminPassword,
        );
        superAdminUser = userCredential.user;
        debugPrint('Super admin auth account found');
      } catch (e) {
        // If sign in fails, create new account
        if (e.toString().contains('user-not-found') ||
            e.toString().contains('wrong-password') ||
            e.toString().contains('invalid-credential')) {
          try {
            userCredential = await _auth.createUserWithEmailAndPassword(
              email: defaultSuperAdminEmail,
              password: defaultSuperAdminPassword,
            );
            superAdminUser = userCredential.user;
            debugPrint('Created new super admin auth account');
          } catch (createError) {
            debugPrint('Error creating super admin: $createError');
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      if (superAdminUser == null) {
        debugPrint('Failed to get super admin user');
        return;
      }

      final uid = superAdminUser.uid;

      // Check if super admin document already exists in Firestore
      final adminDoc = await _firestore.collection('admins').doc(uid).get();

      if (adminDoc.exists) {
        debugPrint('Super admin document already exists in Firestore');
        // Sign out after initialization
        await _auth.signOut();
        return;
      }

      // Create super admin document in Firestore using the actual Firebase Auth UID
      final superAdmin = AdminModel(
        id: uid,
        email: defaultSuperAdminEmail,
        name: defaultSuperAdminName,
        createdAt: DateTime.now(),
        status: 'Active',
        permissions: ['all'],
        isSuperAdmin: true,
      );

      await _firestore.collection('admins').doc(uid).set(superAdmin.toMap());

      // Also add to users collection for backward compatibility
      await _firestore.collection('users').doc(uid).set(superAdmin.toMap());

      debugPrint('✅ Super admin initialized successfully');
      debugPrint('Email: $defaultSuperAdminEmail');
      debugPrint('Password: $defaultSuperAdminPassword');
      debugPrint('UID: $uid');
      debugPrint('⚠️ IMPORTANT: Change the password after first login!');

      // Sign out after initialization
      await _auth.signOut();
    } catch (e) {
      debugPrint('❌ Error initializing super admin: $e');
      // Don't rethrow - allow app to continue even if super admin init fails
    }
  }

  /// Check if a user is super admin
  Future<bool> isSuperAdmin(String userId) async {
    try {
      final adminDoc = await _firestore.collection('admins').doc(userId).get();
      if (!adminDoc.exists) return false;

      final data = adminDoc.data();
      return data?['isSuperAdmin'] ?? false;
    } catch (e) {
      debugPrint('Error checking super admin status: $e');
      return false;
    }
  }

  /// Prevent super admin deletion
  Future<bool> canDeleteAdmin(String adminId) async {
    final isSuperAdminUser = await isSuperAdmin(adminId);
    return !isSuperAdminUser; // Cannot delete any super admin
  }

  /// Get super admin email
  static String getSuperAdminEmail() => defaultSuperAdminEmail;
}

/// Provider for super admin service
final superAdminServiceProvider = Provider<SuperAdminService>((ref) {
  return SuperAdminService(FirebaseFirestore.instance, FirebaseAuth.instance);
});

/// Provider to check if current user is super admin
final isSuperAdminProvider = FutureProvider<bool>((ref) async {
  final auth = FirebaseAuth.instance;
  final currentUser = auth.currentUser;

  if (currentUser == null) return false;

  final superAdminService = ref.read(superAdminServiceProvider);
  return await superAdminService.isSuperAdmin(currentUser.uid);
});
