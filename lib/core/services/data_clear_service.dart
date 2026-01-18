import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DataClearService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Clear all system data except for the specified Super Admin
  /// This helps in resetting the application state while preserving the super admin account.
  Future<void> clearAllSystemData(String superAdminId) async {
    try {
      debugPrint('⚠️ STARTING SYSTEM RESET ⚠️');
      debugPrint('Preserving Super Admin ID: $superAdminId');

      // 1. Collections to completely wipe
      final collectionsToWipe = [
        'customers',
        'vehicles',
        'job_cards',
        'invoices',
        'inventory',
        'bookings',
        'payments',
        'notifications',
        'mechanics', // Assuming mechanics are separate from users or synced
        'services', // Dynamic services
        'categories', // Inventory categories if any
        'part_categories',
      ];

      for (final collection in collectionsToWipe) {
        debugPrint('Clearing collection: $collection');
        await _clearCollection(collection);
      }

      // 2. Clear Users (Excluding Super Admin)
      debugPrint('Clearing users (excluding super admin)...');
      await _clearCollectionExcluding('users', superAdminId);

      // 3. Clear Admins (Excluding Super Admin)
      debugPrint('Clearing admins (excluding super admin)...');
      await _clearCollectionExcluding('admins', superAdminId);

      debugPrint('✅ SYSTEM RESET COMPLETE');
    } catch (e) {
      debugPrint('❌ Error during system reset: $e');
      throw Exception('Failed to clear system data: $e');
    }
  }

  /// Deletes all documents in a collection
  Future<void> _clearCollection(String collectionPath) async {
    final collection = _firestore.collection(collectionPath);
    final batchSize = 500;

    while (true) {
      final snapshot = await collection.limit(batchSize).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint(
        'Deleted batch of ${snapshot.docs.length} from $collectionPath',
      );
    }
  }

  /// Deletes all documents in a collection EXCEPT the one with [excludeId]
  Future<void> _clearCollectionExcluding(
    String collectionPath,
    String excludeId,
  ) async {
    final collection = _firestore.collection(collectionPath);
    final batchSize = 500;

    while (true) {
      // Get batch of docs
      // Note: We can't easily filter "id != excludeId" in simple queries efficiently
      // without creating complex indexes or reading all.
      // Since this is a reset operation, reading all is acceptable.
      final snapshot = await collection.limit(batchSize).get();

      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      int deleteCount = 0;

      for (final doc in snapshot.docs) {
        if (doc.id == excludeId) {
          debugPrint(
            'Skipping excluded document: ${doc.id} in $collectionPath',
          );
          continue;
        }
        batch.delete(doc.reference);
        deleteCount++;
      }

      if (deleteCount > 0) {
        await batch.commit();
        debugPrint('Deleted $deleteCount docs from $collectionPath');
      }

      // If we only found the excluded doc (or nothing to delete in this batch),
      // and the batch size was full, we might get stuck in a loop if we don't handle pagination.
      // However, since we are deleting, the next query will return the next batch.
      // The only edge case is if the ONLY document left is the excluded one.

      if (snapshot.docs.length < batchSize) {
        // We've reached the end of the collection
        break;
      }

      if (deleteCount == 0 && snapshot.docs.length == batchSize) {
        // We found a full batch but deleted nothing (meaning checking the same excluded doc over and over? or obscure edge case)
        // Since we query by default order, likely document ID, ensuring we delete reduces the set.
        // If strict document ID ordering keeps excludeId at start?
        // To be safe, if we didn't delete anything, we should probably break or skip logic.
        // But practically, 'users' collection usually has the ID as key.
        // If we didn't delete anything, it means the only doc in this batch was the excluded one.
        // And if batch was full (500), that implies 500 copies of same ID? Impossible in Firestore keys.
        // So safe to assume if deleteCount == 0, we can break if size < batch, but if size == batch?
        // Actually, if we don't delete the excluded doc, it remains.
        // Next query will fetch it again if we don't offset or use startAfter.
        // Standard "delete all" loop works because items disappear.
        // If excluded item persists, we will fetch it infinitely.

        // FIX: Use query that excludes the ID? "!=" not supported in all modes easily.
        // Better: Fetch IDs, if ID == excludeId, ignore.
        // To avoid infinite loop on the excluded doc:
        // We can't just limit().get() repeatedly if the first doc is the excluded one and we don't delete it.
        // We must Delete everything except X.
        // Solution: Query everything, delete locally.
        // Or: Query "where(FieldPath.documentId, '!=', excludeId)"? Firestore supports this now?
        // Yes, clean implementation using client filtering might be tricky with "limit".
        // Let's implement robustly: Query all, stream or one-time get (if dataset huge, could be memory issue).
        // Best approach for "Reset": Just read all (assuming reasonable size) or page via startAfter.

        // Let's use standard pagination logic to be safe.
        // BUT wait, if we delete, the next batch effectively changes.
        // If we leave ONE doc, we need to make sure we don't fetch it again as "first result".
        // Simple hack: We only have ONE excluded ID.
        // We can just rely on the fact that eventually only that one is left.

        if (snapshot.docs.length == 1 && snapshot.docs.first.id == excludeId) {
          break; // Only the super admin is left
        }

        // If we have multiple docs left and one is super admin, we deleted others.
        // The one remaining will be fetched again?
        // Yes. So if we fetched 500, deleted 499, kept 1.
        // Next get() returns 1 (the kept one) + 499 others? No, others deleted.
        // So next get() returns the KEPT one + next 499 new ones.
        // So we just need to handle the case where "kept one" is returned.
      }
    }
  }
}
