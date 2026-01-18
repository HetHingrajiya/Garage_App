import 'package:autocare_pro/core/router/app_router.dart';
import 'package:autocare_pro/core/services/super_admin_service.dart';
import 'package:autocare_pro/core/theme/app_theme.dart';
import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:autocare_pro/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;

  try {
    debugPrint("🚀 Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    debugPrint("✅ Firebase initialized successfully");
  } catch (e, stackTrace) {
    debugPrint("❌ Firebase initialization failed: $e");
    debugPrint("Stack trace: $stackTrace");
    // Continue app execution even if Firebase fails
    // This allows the app to at least open and show an error message
  }

  // Run the app first, then initialize data in background
  runApp(const ProviderScope(child: AutoCareApp()));

  // Initialize database in background after app starts
  if (firebaseInitialized) {
    _initializeDataInBackground();
  }
}

// Initialize data in background to avoid blocking app startup
Future<void> _initializeDataInBackground() async {
  try {
    debugPrint("🔄 Initializing default inventory...");
    final garageRepo = GarageRepository(FirebaseFirestore.instance);
    await garageRepo.initializeDefaultInventory();
    debugPrint("✅ Default inventory initialized");

    debugPrint("🔄 Initializing super admin...");
    final superAdminService = SuperAdminService(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
    await superAdminService.initializeSuperAdmin();
    debugPrint("✅ Super admin initialized");
  } catch (e, stackTrace) {
    debugPrint("❌ Background initialization failed: $e");
    debugPrint("Stack trace: $stackTrace");
  }
}

class AutoCareApp extends ConsumerWidget {
  const AutoCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AutoCare Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
