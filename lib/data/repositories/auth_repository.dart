import 'package:autocare_pro/data/models/user_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:autocare_pro/data/models/customer_model.dart';
import 'package:autocare_pro/data/models/mechanic_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Add Firestore instance

  AuthRepository(this._firebaseAuth, this._googleSignIn);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Database-based login - checks Firestore first, creates Auth account if needed
  Future<UserCredential> signInWithDatabase(
    String email,
    String password,
  ) async {
    try {
      // First try normal Firebase Auth login
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (authError) {
      // If Auth login fails, check if user exists in database
      debugPrint('Auth login failed, checking database...');

      // Search in all collections for this email
      final collections = ['admins', 'mechanics', 'users', 'customers'];

      for (final collection in collections) {
        final querySnapshot = await _firestore
            .collection(collection)
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data();
          final storedPassword = userData['password'];

          // Check if password matches (stored in plain text - NOT SECURE!)
          if (storedPassword == password) {
            // Create Firebase Auth account for this user
            try {
              final userCredential = await _firebaseAuth
                  .createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

              debugPrint('✅ Created Auth account for database user');
              return userCredential;
            } catch (createError) {
              debugPrint('Error creating Auth account: $createError');
              rethrow;
            }
          } else {
            throw Exception('Invalid password');
          }
        }
      }

      // User not found in any collection
      throw Exception('User not found in database');
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String role, // 'admin', 'customer', 'mechanic'
    required String name,
    String? mobile,
    String? address,
    String? gender,
    List<String> skills = const [],
    int experience = 0,
  }) async {
    FirebaseApp? tempApp;
    UserCredential? userCredential;
    String? uid;

    try {
      debugPrint('🔄 Creating Firebase Auth account for: $email');

      // Create a secondary Firebase App to avoid logging out the current user
      final FirebaseApp defaultApp = Firebase.app();
      tempApp = await Firebase.initializeApp(
        name: 'tempAuthApp-${DateTime.now().millisecondsSinceEpoch}',
        options: defaultApp.options,
      );

      final FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      uid = userCredential.user!.uid;
      final now = DateTime.now();

      debugPrint('✅ Firebase Auth account created with UID: $uid');
      debugPrint('🔄 Saving to Firestore...');

      // Save to role-specific collection
      if (role == 'customer') {
        // Save to customers collection with unified model
        final customer = Customer(
          id: uid,
          email: email,
          name: name,
          mobile: mobile,
          address: address, // Add address
          gender: gender, // Add gender
          createdAt: now,
          status: 'Active',
          vehicleIds: [],
          hasAuthAccount: true, // Self-registered customer can login
          createdBy: 'self',
        );
        await _firestore.collection('customers').doc(uid).set(customer.toMap());
        debugPrint('✅ Customer saved to Firestore');
      } else {
        // Save to old users collection for backward compatibility
        // (Admin, Mechanic)
        if (role == 'mechanic') {
          // Use MechanicModel for mechanics to include all fields
          final mechanic = MechanicModel(
            id: uid,
            email: email,
            name: name,
            mobile: mobile,
            createdAt: now,
            skills: skills,
            experience: experience,
            rating: 0.0,
            completedJobs: 0,
          );
          await _firestore.collection('users').doc(uid).set(mechanic.toMap());
          await _firestore
              .collection('mechanics')
              .doc(uid)
              .set(mechanic.toMap());
          debugPrint('✅ Mechanic saved to Firestore');
        } else {
          // For admin and other roles, use UserModel
          UserModel newUser = UserModel(
            id: uid,
            email: email,
            name: name,
            role: role,
            mobile: mobile,
            createdAt: now,
            skills: skills,
            experience: experience,
          );
          await _firestore.collection('users').doc(uid).set(newUser.toMap());

          // Also save to new role-specific collection
          final collection = _getCollectionForRole(role);
          await _firestore.collection(collection).doc(uid).set(newUser.toMap());
          debugPrint('✅ $role saved to Firestore');
        }
      }

      debugPrint('✅ User creation complete!');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Error in signUpWithEmail: $e');

      // If Firestore save failed but Auth account was created, delete the Auth account
      if (uid != null && userCredential != null) {
        try {
          debugPrint('🔄 Cleaning up Auth account due to Firestore error...');
          await userCredential.user?.delete();
          debugPrint('✅ Auth account cleaned up');
        } catch (deleteError) {
          debugPrint('❌ Failed to cleanup Auth account: $deleteError');
        }
      }

      throw Exception(e.toString());
    } finally {
      // Always delete the temporary app
      if (tempApp != null) {
        try {
          await tempApp.delete();
          debugPrint('✅ Temporary Firebase App deleted');
        } catch (e) {
          debugPrint('⚠️ Warning: Failed to delete temporary app: $e');
        }
      }
    }
  }

  String _getCollectionForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'admins';
      case 'mechanic':
        return 'mechanics';
      case 'customer':
        return 'customers';
      default:
        return 'users';
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<String?> getUserRole(String uid) async {
    try {
      // 1. Check main 'users' collection first (Primary source for Admins/Mechanics)
      // This avoids potential permission errors if other collections check fails
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        if (data.containsKey('role')) {
          return data['role'] as String?;
        }
      }

      // 2. Check customers collection (for customers who might not be in users)
      final customerDoc = await _firestore
          .collection('customers')
          .doc(uid)
          .get();
      if (customerDoc.exists) {
        final data = customerDoc.data();
        // Check if role field exists first (preferred)
        if (data != null && data.containsKey('role')) {
          return data['role'] as String?;
        }
        // Fallback: Allow login if hasAuthAccount is true (both self-registered and admin-created)
        if (data != null && (data['hasAuthAccount'] ?? false)) {
          return 'customer';
        }
      }

      // 3. Fallback: Check other role-specific collections
      final collections = {'admins': 'admin', 'mechanics': 'mechanic'};

      for (final entry in collections.entries) {
        try {
          final doc = await _firestore.collection(entry.key).doc(uid).get();
          if (doc.exists) return entry.value;
        } catch (_) {
          // Ignore errors from specific collections and continue
          continue;
        }
      }
    } catch (e) {
      // Handle global error - rethrow to show error to user
      rethrow;
    }
    return null;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      // Check if user doc exists, if not create it (auto-signup for Google)
      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        if (!userDoc.exists) {
          final userModel = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? 'User',
            role: 'mechanic',
            createdAt: DateTime.now(),
            status: 'Active',
          );
          await _firestore
              .collection('users')
              .doc(userModel.id)
              .set(userModel.toMap());
        }
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, GoogleSignIn());
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserRoleProvider = StreamProvider<String?>((ref) async* {
  final authStateStream = ref.watch(authStateProvider.future);
  final user = await authStateStream;

  if (user == null) {
    yield null;
    return;
  }

  // Get role once when user changes
  final role = await ref.read(authRepositoryProvider).getUserRole(user.uid);
  yield role;

  // Keep yielding the same role (stream stays alive)
  // This ensures the provider stays active and doesn't reload unnecessarily
});
