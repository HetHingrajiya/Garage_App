import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Database cleanup utility
/// WARNING: This will delete ALL data from Firestore!
class DatabaseCleanup {
  final FirebaseFirestore _firestore;

  DatabaseCleanup(this._firestore);

  /// Delete all documents from a collection
  Future<void> _deleteCollection(String collectionName) async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint(
        '✅ Deleted ${snapshot.docs.length} documents from $collectionName',
      );
    } catch (e) {
      debugPrint('❌ Error deleting $collectionName: $e');
    }
  }

  /// Clean all Firestore collections
  Future<void> cleanFirestore({
    bool keepInventory = true, // Keep default inventory
  }) async {
    debugPrint('🧹 Starting Firestore cleanup...');

    // Delete all collections
    await _deleteCollection('admins');
    await _deleteCollection('customers');
    await _deleteCollection('mechanics');
    await _deleteCollection('users');
    await _deleteCollection('jobCards');
    await _deleteCollection('vehicles');
    await _deleteCollection('invoices');
    await _deleteCollection('payments');
    await _deleteCollection('services');

    if (!keepInventory) {
      await _deleteCollection('inventory');
    }

    debugPrint('✅ Firestore cleanup complete!');
  }

  /// Delete all Firebase Auth users (except current user)
  Future<void> cleanAuthentication({bool keepCurrentUser = true}) async {
    debugPrint('🧹 Starting Authentication cleanup...');
    debugPrint('⚠️ Note: You need Admin SDK to delete users programmatically');
    debugPrint('Please delete users manually from Firebase Console');
    debugPrint('Go to: Firebase Console → Authentication → Users');
  }

  /// Complete database cleanup
  Future<void> cleanAll({
    bool keepInventory = true,
    bool keepCurrentUser = true,
  }) async {
    debugPrint('🧹 Starting complete database cleanup...');
    debugPrint('⚠️ WARNING: This will delete ALL data!');

    await cleanFirestore(keepInventory: keepInventory);
    await cleanAuthentication(keepCurrentUser: keepCurrentUser);

    debugPrint('✅ Database cleanup complete!');
  }
}

/// Example usage:
/// 
/// ```dart
/// final cleanup = DatabaseCleanup(
///   FirebaseFirestore.instance,
/// );
/// 
/// // Clean everything except inventory
/// await cleanup.cleanAll(keepInventory: true);
/// 
/// // Or clean only Firestore
/// await cleanup.cleanFirestore();
/// ```
