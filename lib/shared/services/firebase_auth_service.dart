import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dine_pulse/shared/models/shared_user_model.dart';
import 'package:dine_pulse/shared/services/firestore_collections.dart';

/// Shared Firebase Authentication & Session Service
/// Supports real Firebase Auth with graceful offline/uninitialized fallback.
class SharedFirebaseAuthService extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  SharedUserModel? _currentUser;
  SharedUserModel? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final StreamController<SharedUserModel?> _userStreamCtrl =
      StreamController<SharedUserModel?>.broadcast();
  Stream<SharedUserModel?> get authStateChanges => _userStreamCtrl.stream;

  SharedFirebaseAuthService() {
    _initAuth();
  }

  void _initAuth() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;

        _auth!.authStateChanges().listen((User? fbUser) async {
          if (fbUser != null) {
            await _loadUserData(fbUser.uid);
          } else {
            _currentUser = null;
            _userStreamCtrl.add(null);
            notifyListeners();
          }
        });
      } else {
        // Fallback demo user when Firebase native isn't connected
        _setupFallbackSession();
      }
    } catch (e) {
      debugPrint('Firebase Auth initialization notice: $e (using fallback session)');
      _setupFallbackSession();
    }
  }

  void _setupFallbackSession() {
    _currentUser = SharedUserModel(
      uid: 'user_cust_1',
      email: 'customer@dinepulse.com',
      fullName: 'Kamal Silva',
      phoneNumber: '+94 77 123 4567',
      role: UserRole.customer,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    _userStreamCtrl.add(_currentUser);
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      if (_firestore != null) {
        final doc = await _firestore!
            .collection(FirestoreCollections.users)
            .doc(uid)
            .get();
        if (doc.exists && doc.data() != null) {
          _currentUser = SharedUserModel.fromFirestore(doc.data()!, doc.id);
        } else {
          // Create user document if missing
          final fbUser = _auth?.currentUser;
          _currentUser = SharedUserModel(
            uid: uid,
            email: fbUser?.email ?? '',
            fullName: fbUser?.displayName ?? 'Customer',
            phoneNumber: fbUser?.phoneNumber,
            role: UserRole.customer,
            createdAt: DateTime.now(),
          );
          await _firestore!
              .collection(FirestoreCollections.users)
              .doc(uid)
              .set(_currentUser!.toFirestore());
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile from Firestore: $e');
    }
    _userStreamCtrl.add(_currentUser);
    notifyListeners();
  }

  // ─── Sign In With Email & Password ─────────────────────────────────────────
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_auth != null) {
        final cred = await _auth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        if (cred.user != null) {
          await _loadUserData(cred.user!.uid);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } else {
        // Mock sign-in for testing/demo
        await Future.delayed(const Duration(milliseconds: 500));
        UserRole assignedRole = UserRole.customer;
        if (email.contains('staff')) assignedRole = UserRole.staff;
        if (email.contains('admin')) assignedRole = UserRole.admin;

        _currentUser = SharedUserModel(
          uid: 'uid_${email.hashCode.abs()}',
          email: email.trim(),
          fullName: email.split('@').first,
          role: assignedRole,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        _userStreamCtrl.add(_currentUser);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Authentication failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Register With Email & Password ────────────────────────────────────────
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    UserRole role = UserRole.customer,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_auth != null && _firestore != null) {
        final cred = await _auth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        if (cred.user != null) {
          final newUser = SharedUserModel(
            uid: cred.user!.uid,
            email: email.trim(),
            fullName: fullName.trim(),
            phoneNumber: phoneNumber?.trim(),
            role: role,
            createdAt: DateTime.now(),
          );
          await _firestore!
              .collection(FirestoreCollections.users)
              .doc(cred.user!.uid)
              .set(newUser.toFirestore());
          _currentUser = newUser;
          _userStreamCtrl.add(_currentUser);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        _currentUser = SharedUserModel(
          uid: 'uid_${email.hashCode.abs()}',
          email: email.trim(),
          fullName: fullName.trim(),
          phoneNumber: phoneNumber?.trim(),
          role: role,
          createdAt: DateTime.now(),
        );
        _userStreamCtrl.add(_currentUser);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    if (_auth != null) {
      await _auth!.signOut();
    }
    _currentUser = null;
    _userStreamCtrl.add(null);
    notifyListeners();
  }

  // ─── Update User Role (RBAC) ────────────────────────────────────────────────
  Future<void> updateUserRole(String uid, UserRole newRole) async {
    if (_firestore != null) {
      await _firestore!
          .collection(FirestoreCollections.users)
          .doc(uid)
          .update({'role': newRole.value});
    }
    if (_currentUser?.uid == uid) {
      _currentUser = _currentUser?.copyWith(role: newRole);
      _userStreamCtrl.add(_currentUser);
      notifyListeners();
    }
  }
}
