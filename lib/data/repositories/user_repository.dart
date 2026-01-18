import 'package:autocare_pro/data/models/user_model.dart';
import 'package:autocare_pro/data/models/admin_model.dart';
import 'package:autocare_pro/data/models/customer_model.dart';
import 'package:autocare_pro/data/models/mechanic_model.dart';
import 'package:autocare_pro/data/models/base_user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  // ========== LEGACY METHODS (for backward compatibility) ==========

  Future<void> saveUser(UserModel user) async {
    // Write to old collection for backward compatibility
    await _firestore.collection('users').doc(user.id).set(user.toMap());

    // Also write to new role-specific collection (gradual migration)
    await _saveToRoleCollection(user);
  }

  Future<void> updateUser(UserModel user) async {
    // Update in old collection
    await _firestore.collection('users').doc(user.id).update(user.toMap());

    // Also update in new role-specific collection
    await _updateInRoleCollection(user);
  }

  Future<void> deleteUser(String uid) async {
    // Delete from old collection
    await _firestore.collection('users').doc(uid).delete();

    // Also delete from role-specific collections
    await _deleteFromRoleCollections(uid);
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // ========== NEW ROLE-SPECIFIC METHODS ==========

  /// Get user from role-specific collection
  Future<BaseUserModel?> getUserByRole(String uid, String role) async {
    final collection = _getCollectionForRole(role);
    final doc = await _firestore.collection(collection).doc(uid).get();

    if (!doc.exists) return null;

    switch (role) {
      case 'admin':
        return AdminModel.fromMap(doc.data()!, doc.id);
      case 'customer':
        return Customer.fromMap(doc.data()!, doc.id);
      case 'mechanic':
        return MechanicModel.fromMap(doc.data()!, doc.id);
      default:
        return null;
    }
  }

  /// Get admin by ID
  Future<AdminModel?> getAdmin(String uid) async {
    final doc = await _firestore.collection('admins').doc(uid).get();
    if (doc.exists) {
      return AdminModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Get customer user by ID
  Future<Customer?> getCustomerUser(String uid) async {
    final doc = await _firestore.collection('customers').doc(uid).get();
    if (doc.exists) {
      return Customer.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Get mechanic by ID
  Future<MechanicModel?> getMechanic(String uid) async {
    final doc = await _firestore.collection('mechanics').doc(uid).get();
    if (doc.exists) {
      return MechanicModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Get all mechanics
  Future<List<MechanicModel>> getAllMechanics() async {
    final snapshot = await _firestore.collection('mechanics').get();
    return snapshot.docs
        .map((doc) => MechanicModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Get all admins
  Future<List<AdminModel>> getAllAdmins() async {
    final snapshot = await _firestore.collection('admins').get();
    return snapshot.docs
        .map((doc) => AdminModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Save to role-specific collection
  Future<void> saveToRoleCollection(BaseUserModel user) async {
    final collection = _getCollectionForRole(_getRoleFromModel(user));
    await _firestore.collection(collection).doc(user.id).set(user.toMap());
  }

  /// Update in role-specific collection
  Future<void> updateInRoleCollection(BaseUserModel user) async {
    final collection = _getCollectionForRole(_getRoleFromModel(user));
    await _firestore.collection(collection).doc(user.id).update(user.toMap());
  }

  // ========== PRIVATE HELPER METHODS ==========

  Future<void> _saveToRoleCollection(UserModel user) async {
    final collection = _getCollectionForRole(user.role);
    await _firestore.collection(collection).doc(user.id).set(user.toMap());
  }

  Future<void> _updateInRoleCollection(UserModel user) async {
    final collection = _getCollectionForRole(user.role);
    await _firestore.collection(collection).doc(user.id).update(user.toMap());
  }

  Future<void> _deleteFromRoleCollections(String uid) async {
    // Try deleting from all possible collections
    final collections = ['admins', 'customers', 'mechanics'];
    for (final collection in collections) {
      try {
        await _firestore.collection(collection).doc(uid).delete();
      } catch (e) {
        // Ignore if document doesn't exist
      }
    }
  }

  String _getCollectionForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'admins';
      case 'customer':
        return 'customers';
      case 'mechanic':
        return 'mechanics';
      default:
        return 'users'; // Fallback to old collection
    }
  }

  String _getRoleFromModel(BaseUserModel user) {
    if (user is AdminModel) return 'admin';
    if (user is Customer) return 'customer';
    if (user is MechanicModel) return 'mechanic';
    return 'mechanic'; // Default
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});
