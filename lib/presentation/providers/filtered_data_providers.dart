import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autocare_pro/data/models/customer_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:autocare_pro/core/utils/data_filter_helper.dart';
import 'package:autocare_pro/core/services/super_admin_service.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';

/// Filtered customers provider - shows only customers created by current admin
/// Super admins see all customers
final filteredCustomersProvider = StreamProvider<List<Customer>>((ref) async* {
  final userId = ref.watch(currentUserIdProvider);
  // Get current user role
  final userRoleAsync = ref.watch(currentUserRoleProvider);
  final userRole = userRoleAsync.value;

  final isSuperAdminAsync = ref.watch(isSuperAdminProvider);

  // Wait for super admin check
  final isSuperAdmin = isSuperAdminAsync.value ?? false;

  // Determine filter
  // Admin and Super Admin should see all customers
  final isAdmin = userRole == 'admin' || isSuperAdmin;
  final filterBy = isAdmin ? null : userId;

  // Get customers with appropriate filter
  final customersStream = ref
      .watch(garageRepositoryProvider)
      .getCustomers(createdByAdminId: filterBy);

  await for (final customers in customersStream) {
    yield customers;
  }
});
