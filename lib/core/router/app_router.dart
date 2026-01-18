import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';
import 'package:autocare_pro/data/models/mechanic_model.dart';
import 'package:autocare_pro/presentation/screens/auth/login_screen.dart';
import 'package:autocare_pro/presentation/screens/customers/add_customer_screen.dart';
import 'package:autocare_pro/presentation/screens/customers/customer_list_screen.dart';
import 'package:autocare_pro/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:autocare_pro/presentation/screens/job_cards/add_job_card_screen.dart';
import 'package:autocare_pro/presentation/screens/job_cards/job_card_list_screen.dart';
import 'package:autocare_pro/presentation/screens/vehicles/vehicle_list_screen.dart';
import 'package:autocare_pro/presentation/screens/settings/settings_screen.dart';
import 'package:autocare_pro/presentation/screens/inventory/inventory_list_screen.dart';
import 'package:autocare_pro/presentation/screens/mechanics/mechanics_list_screen.dart';
import 'package:autocare_pro/presentation/screens/mechanics/add_mechanic_screen.dart';
import 'package:autocare_pro/presentation/screens/admin/add_user_screen.dart';
import 'package:autocare_pro/presentation/screens/admin/admin_booking_list_screen.dart';

// Customer Screens
import 'package:autocare_pro/presentation/screens/customer/customer_dashboard_screen.dart';
import 'package:autocare_pro/presentation/screens/customer/profile/customer_profile_screen.dart';
import 'package:autocare_pro/presentation/screens/customer/profile/edit_profile_screen.dart';
import 'package:autocare_pro/presentation/screens/customer/profile/change_password_screen.dart';
import 'package:autocare_pro/presentation/screens/customer/vehicles/customer_vehicles_screen.dart';
import 'package:autocare_pro/presentation/screens/customer/vehicles/customer_add_vehicle_screen.dart';
import 'package:autocare_pro/presentation/screens/customer/vehicles/customer_vehicle_detail_screen.dart';
import 'package:autocare_pro/presentation/screens/customer/booking/book_service_screen.dart';
import 'package:autocare_pro/presentation/screens/customer/jobs/customer_jobs_screen.dart';
import 'package:autocare_pro/presentation/screens/customer/jobs/customer_job_detail_screen.dart';
import 'package:autocare_pro/presentation/screens/customer/invoices/customer_invoices_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRoleAsync = ref.watch(currentUserRoleProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final path = state.uri.toString();

      // 1. Not logged in - redirect to login
      if (!isLoggedIn) return isLoggingIn ? null : '/login';

      // 2. Get user role (handle loading state gracefully)
      final userRole = userRoleAsync.value;

      // If role is still loading, allow navigation temporarily
      if (userRoleAsync.isLoading) {
        return null;
      }

      // If there's an error loading role, redirect to login
      if (userRoleAsync.hasError) {
        return '/login';
      }

      // 3. Enforce role-based access control
      if (userRole == 'customer') {
        // Customers MUST stay in /customer routes
        if (path != '/customer' && !path.startsWith('/customer/')) {
          return '/customer/dashboard';
        }
      } else if (userRole != null) {
        // Admins/Mechanics MUST stay out of /customer routes
        // Allow /customers (plural) for admin
        if (path == '/customer' || path.startsWith('/customer/')) {
          return '/';
        }
      }

      // 4. Handle login redirect
      if (isLoggingIn) {
        if (userRole == 'customer') return '/customer/dashboard';
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomerListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddCustomerScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/job-cards',
        builder: (context, state) => const JobCardListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddJobCardScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/vehicles',
        builder: (context, state) => const VehicleListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text("Add Vehicle Placeholder")),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryListScreen(),
      ),
      GoRoute(
        path: '/mechanics',
        builder: (context, state) => const MechanicsListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) {
              final mechanic = state.extra as MechanicModel?;
              return AddMechanicScreen(mechanicToEdit: mechanic);
            },
          ),
        ],
      ),
      // Admin management routes (Super Admin only)
      GoRoute(
        path: '/admin',
        redirect: (context, state) {
          if (state.uri.toString() == '/admin') {
            return '/admin/add-user';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'add-user',
            builder: (context, state) => const AddUserScreen(),
          ),
          GoRoute(
            path: 'bookings',
            builder: (context, state) =>
                const AdminBookingListScreen(), // New Route
          ),
        ],
      ),
      // Customer Routes
      GoRoute(
        path: '/customer',
        redirect: (context, state) {
          if (state.uri.toString() == '/customer') {
            return '/customer/dashboard';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'dashboard',
            builder: (context, state) => const CustomerDashboardScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const CustomerProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'change-password',
                builder: (context, state) => const ChangePasswordScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'vehicles',
            builder: (context, state) => const CustomerVehiclesScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const CustomerAddVehicleScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final vehicleId = state.pathParameters['id']!;
                  final vehicle = state.extra as Map<String, dynamic>?;
                  return CustomerVehicleDetailScreen(
                    vehicle: vehicle ?? {'id': vehicleId},
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'jobs',
            builder: (context, state) => const CustomerJobsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final jobId = state.pathParameters['id']!;
                  final job = state.extra as Map<String, dynamic>?;
                  return CustomerJobDetailScreen(
                    jobId: jobId,
                    initialJobData: job,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'invoices',
            builder: (context, state) => const CustomerInvoicesScreen(),
          ),
          GoRoute(
            path: 'book-service',
            builder: (context, state) => const BookServiceScreen(),
          ),
        ],
      ),
    ],
  );
});
