import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autocare_pro/data/models/customer_model.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:autocare_pro/core/utils/data_filter_helper.dart';
import 'package:autocare_pro/core/services/super_admin_service.dart';

/// Filtered customers provider - shows only customers created by current admin
/// Super admins see all customers
final filteredCustomersProvider = StreamProvider<List<Customer>>((ref) async* {
  final userId = ref.watch(currentUserIdProvider);
  final isSuperAdminAsync = ref.watch(isSuperAdminProvider);

  // Wait for super admin check
  final isSuperAdmin = await isSuperAdminAsync.when(
    data: (value) => Future.value(value),
    loading: () => Future.value(false),
    error: (_, __) => Future.value(false),
  );

  // Determine filter
  final filterBy = DataFilterHelper.getDataFilter(userId, isSuperAdmin);

  // Get customers with appropriate filter
  final customersStream = ref
      .watch(garageRepositoryProvider)
      .getCustomers(createdByAdminId: filterBy);

  await for (final customers in customersStream) {
    yield customers;
  }
});
