import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';

/// Provider to get current user ID for data filtering
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser?.uid;
});

/// Provider to check if current user is super admin (reuse from super_admin_service)
/// Note: We use the existing isSuperAdminProvider from super_admin_service.dart

/// Data filtering helper
class DataFilterHelper {
  /// Check if user should see all data (super admin)
  static bool shouldShowAllData(bool isSuperAdmin) {
    return isSuperAdmin;
  }

  /// Get filter for Firestore queries
  /// Returns null if should show all data, otherwise returns userId to filter by
  static String? getDataFilter(String? userId, bool isSuperAdmin) {
    if (isSuperAdmin) return null; // Show all data
    return userId; // Filter by this user
  }
}
