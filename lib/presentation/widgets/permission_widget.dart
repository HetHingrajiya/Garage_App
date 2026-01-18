import 'package:autocare_pro/core/permissions/permission_service.dart';
import 'package:autocare_pro/core/permissions/permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget that shows/hides content based on permission
class PermissionBuilder extends ConsumerWidget {
  final Permission permission;
  final Widget child;
  final Widget? fallback;

  const PermissionBuilder({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionServiceAsync = ref.watch(permissionServiceProvider);

    return permissionServiceAsync.when(
      data: (permissionService) {
        if (permissionService.hasPermission(permission)) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
      loading: () => fallback ?? const SizedBox.shrink(),
      error: (error, stack) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Widget that shows/hides content based on multiple permissions (ANY)
class AnyPermissionBuilder extends ConsumerWidget {
  final List<Permission> permissions;
  final Widget child;
  final Widget? fallback;

  const AnyPermissionBuilder({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionServiceAsync = ref.watch(permissionServiceProvider);

    return permissionServiceAsync.when(
      data: (permissionService) {
        if (permissionService.hasAnyPermission(permissions)) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
      loading: () => fallback ?? const SizedBox.shrink(),
      error: (error, stack) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Widget that shows/hides content based on multiple permissions (ALL)
class AllPermissionsBuilder extends ConsumerWidget {
  final List<Permission> permissions;
  final Widget child;
  final Widget? fallback;

  const AllPermissionsBuilder({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionServiceAsync = ref.watch(permissionServiceProvider);

    return permissionServiceAsync.when(
      data: (permissionService) {
        if (permissionService.hasAllPermissions(permissions)) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
      loading: () => fallback ?? const SizedBox.shrink(),
      error: (error, stack) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Widget that shows content only for admin users
class AdminOnly extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOnly({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return isAdminAsync.when(
      data: (isAdmin) {
        if (isAdmin) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
      loading: () => fallback ?? const SizedBox.shrink(),
      error: (error, stack) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Widget that shows content only for mechanic users
class MechanicOnly extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const MechanicOnly({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMechanicAsync = ref.watch(isMechanicProvider);

    return isMechanicAsync.when(
      data: (isMechanic) {
        if (isMechanic) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
      loading: () => fallback ?? const SizedBox.shrink(),
      error: (error, stack) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Widget that shows content only for customer users
class CustomerOnly extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const CustomerOnly({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCustomerAsync = ref.watch(isCustomerProvider);

    return isCustomerAsync.when(
      data: (isCustomer) {
        if (isCustomer) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
      loading: () => fallback ?? const SizedBox.shrink(),
      error: (error, stack) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Widget that shows content for admin and mechanic users
class AdminOrMechanicOnly extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOrMechanicOnly({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);
    final isMechanicAsync = ref.watch(isMechanicProvider);

    return isAdminAsync.when(
      data: (isAdmin) {
        return isMechanicAsync.when(
          data: (isMechanic) {
            if (isAdmin || isMechanic) {
              return child;
            }
            return fallback ?? const SizedBox.shrink();
          },
          loading: () => fallback ?? const SizedBox.shrink(),
          error: (error, stack) => fallback ?? const SizedBox.shrink(),
        );
      },
      loading: () => fallback ?? const SizedBox.shrink(),
      error: (error, stack) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Builder widget that provides role information
class RoleBuilder extends ConsumerWidget {
  final Widget Function(BuildContext context, String? role) builder;

  const RoleBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionServiceAsync = ref.watch(permissionServiceProvider);

    return permissionServiceAsync.when(
      data: (permissionService) => builder(context, permissionService.userRole),
      loading: () => builder(context, null),
      error: (error, stack) => builder(context, null),
    );
  }
}
