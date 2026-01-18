import 'package:autocare_pro/core/permissions/permissions.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Permission service that provides permission checking functionality
class PermissionService {
  final String? userRole;
  final bool isSuperAdmin;

  PermissionService(this.userRole, {this.isSuperAdmin = false});

  /// Check if current user has a specific permission
  bool hasPermission(Permission permission) {
    if (userRole == null) return false;
    return RolePermissions.hasPermission(
      userRole!,
      permission,
      isSuperAdmin: isSuperAdmin,
    );
  }

  /// Check if current user has any of the given permissions
  bool hasAnyPermission(List<Permission> permissions) {
    if (userRole == null) return false;
    return RolePermissions.hasAnyPermission(
      userRole!,
      permissions,
      isSuperAdmin: isSuperAdmin,
    );
  }

  /// Check if current user has all of the given permissions
  bool hasAllPermissions(List<Permission> permissions) {
    if (userRole == null) return false;
    return RolePermissions.hasAllPermissions(
      userRole!,
      permissions,
      isSuperAdmin: isSuperAdmin,
    );
  }

  /// Get all permissions for current user
  Set<Permission> getAllPermissions() {
    if (userRole == null) return {};
    return RolePermissions.getPermissionsForRole(
      userRole!,
      isSuperAdmin: isSuperAdmin,
    );
  }

  /// Check if user is admin
  bool get isAdmin => userRole?.toLowerCase() == 'admin';

  /// Check if user is mechanic
  bool get isMechanic => userRole?.toLowerCase() == 'mechanic';

  /// Check if user is customer
  bool get isCustomer => userRole?.toLowerCase() == 'customer';
}

/// Provider for permission service
/// This automatically updates when user role changes
final permissionServiceProvider = FutureProvider<PermissionService>((
  ref,
) async {
  final userRoleAsync = ref.watch(currentUserRoleProvider);
  final userRole = userRoleAsync.value;

  if (userRole == null) {
    return PermissionService(null);
  }

  // Check if user is super admin
  bool isSuperAdmin = false;
  if (userRole == 'admin') {
    final currentUser = ref.watch(authStateProvider).value;
    if (currentUser != null) {
      try {
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(currentUser.uid)
            .get();
        isSuperAdmin = adminDoc.data()?['isSuperAdmin'] ?? false;
      } catch (e) {
        // Ignore error, default to false
      }
    }
  }

  return PermissionService(userRole, isSuperAdmin: isSuperAdmin);
});

/// Helper provider to check specific permission
/// Usage: ref.watch(hasPermissionProvider(Permission.manageUsers))
final hasPermissionProvider = FutureProvider.family<bool, Permission>((
  ref,
  permission,
) async {
  final permissionService = await ref.watch(permissionServiceProvider.future);
  return permissionService.hasPermission(permission);
});

/// Helper provider to check if user is admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final permissionService = await ref.watch(permissionServiceProvider.future);
  return permissionService.isAdmin;
});

/// Helper provider to check if user is mechanic
final isMechanicProvider = FutureProvider<bool>((ref) async {
  final permissionService = await ref.watch(permissionServiceProvider.future);
  return permissionService.isMechanic;
});

/// Helper provider to check if user is customer
final isCustomerProvider = FutureProvider<bool>((ref) async {
  final permissionService = await ref.watch(permissionServiceProvider.future);
  return permissionService.isCustomer;
});
