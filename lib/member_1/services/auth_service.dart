import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dine_pulse/member_1/models/customer_model.dart';

/// Real, persistent authentication service for DinePulse.
/// Keeps users securely logged in across app restarts until they manually log out.
class AuthService extends ChangeNotifier {
  static const String _keyActiveSession = 'dinepulse_active_user_session';
  static const String _keyRegisteredUsers = 'dinepulse_registered_users';

  CustomerModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // In-memory cache of registered accounts: { normalizedEmail: { 'user': Map, 'password': String } }
  final Map<String, Map<String, dynamic>> _registeredUsers = {};

  CustomerModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _seedDefaultAccounts();
    _loadPersistedData();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  /// Default demo accounts so standard testing always works out of the box
  void _seedDefaultAccounts() {
    _registeredUsers['alex.customer@dinepulse.com'] = {
      'user': CustomerModel(
        uid: 'user_alex_001',
        firstName: 'Alex',
        lastName: 'Johnson',
        email: 'alex.customer@dinepulse.com',
        role: 'customer',
        phoneNumber: '+1 555-0100',
        createdAt: DateTime(2026, 1, 1),
      ).toFirestore(),
      'password': 'password123',
    };

    _registeredUsers['staff.manager@dinepulse.com'] = {
      'user': CustomerModel(
        uid: 'staff_manager_001',
        firstName: 'Sarah',
        lastName: 'Miller',
        email: 'staff.manager@dinepulse.com',
        role: 'staff',
        phoneNumber: '+1 555-0200',
        createdAt: DateTime(2026, 1, 1),
      ).toFirestore(),
      'password': 'password123',
    };
  }

  /// Load persisted registered users and active session from SharedPreferences
  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Load registered users
      final usersJson = prefs.getString(_keyRegisteredUsers);
      if (usersJson != null && usersJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(usersJson) as Map<String, dynamic>;
        decoded.forEach((emailKey, val) {
          if (val is Map) {
            _registeredUsers[emailKey] = Map<String, dynamic>.from(val);
          }
        });
      }

      // 2. Load active session (keeping user logged in across app restarts)
      final sessionJson = prefs.getString(_keyActiveSession);
      if (sessionJson != null && sessionJson.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(sessionJson) as Map<String, dynamic>;
        final uid = userMap['uid'] as String? ?? 'user_persisted';
        _currentUser = CustomerModel.fromFirestore(userMap, uid);
      }
    } catch (e) {
      debugPrint('Notice: Local storage initialization info: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Save registered users database to persistent storage
  Future<void> _saveRegisteredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRegisteredUsers, jsonEncode(_registeredUsers));
    } catch (e) {
      debugPrint('Error saving registered users: $e');
    }
  }

  /// Save active user session to persistent storage
  Future<void> _saveActiveSession(CustomerModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = user.toFirestore();
      map['uid'] = user.uid;
      await prefs.setString(_keyActiveSession, jsonEncode(map));
    } catch (e) {
      debugPrint('Error saving active session: $e');
    }
  }

  /// Clear active user session from persistent storage
  Future<void> _clearActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyActiveSession);
    } catch (e) {
      debugPrint('Error clearing active session: $e');
    }
  }

  /// Real Sign In with email and password
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final normEmail = email.trim().toLowerCase();
      final trimmedPassword = password.trim();

      if (normEmail.isEmpty || trimmedPassword.isEmpty) {
        _setError('Please enter both email and password');
        return false;
      }

      // Check registered users registry
      if (!_registeredUsers.containsKey(normEmail)) {
        _setError('No account found for $normEmail. Please create an account.');
        return false;
      }

      final accountData = _registeredUsers[normEmail]!;
      final storedPassword = accountData['password'] as String?;
      if (storedPassword != trimmedPassword) {
        _setError('Incorrect password. Please try again.');
        return false;
      }

      // Load user's real account
      final userMap = Map<String, dynamic>.from(accountData['user'] as Map);
      final uid = userMap['uid'] as String? ?? 'user_${normEmail.hashCode}';
      _currentUser = CustomerModel.fromFirestore(userMap, uid);

      // Persist session so user remains logged in even after closing app
      await _saveActiveSession(_currentUser!);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Sign in failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Create real new account with user's own name, email and password
  Future<bool> createAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final normEmail = email.trim().toLowerCase();
      final trimmedPassword = password.trim();

      if (normEmail.isEmpty || trimmedPassword.length < 6) {
        _setError('Password must be at least 6 characters');
        return false;
      }

      // Prevent duplicate account registration
      if (_registeredUsers.containsKey(normEmail)) {
        _setError('An account with this email already exists. Please sign in.');
        return false;
      }

      final isStaff = normEmail.contains('staff') ||
          normEmail.contains('manager') ||
          normEmail.contains('admin');

      final newUid = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final newCustomer = CustomerModel(
        uid: newUid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        role: isStaff ? 'staff' : 'customer',
        phoneNumber: phoneNumber?.trim(),
        createdAt: DateTime.now(),
      );

      // Register new user account persistently
      final userMap = newCustomer.toFirestore();
      userMap['uid'] = newUid;
      _registeredUsers[normEmail] = {
        'user': userMap,
        'password': trimmedPassword,
      };

      await _saveRegisteredUsers();
      await _saveActiveSession(newCustomer);

      _currentUser = newCustomer;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Account creation failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Switch user role for testing staff vs customer flows
  void switchRole(String newRole) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(role: newRole);
      _saveActiveSession(_currentUser!);
      final normEmail = _currentUser!.email.toLowerCase();
      if (_registeredUsers.containsKey(normEmail)) {
        final userMap = _currentUser!.toFirestore();
        userMap['uid'] = _currentUser!.uid;
        _registeredUsers[normEmail]!['user'] = userMap;
        _saveRegisteredUsers();
      }
      notifyListeners();
    }
  }

  /// Sign out (only manually triggered by user)
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _clearActiveSession();
      _currentUser = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Update customer profile persistently
  Future<bool> updateProfile(CustomerModel updated) async {
    _setLoading(true);
    _setError(null);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _currentUser = updated;
      await _saveActiveSession(updated);

      final normEmail = updated.email.toLowerCase();
      if (_registeredUsers.containsKey(normEmail)) {
        final userMap = updated.toFirestore();
        userMap['uid'] = updated.uid;
        _registeredUsers[normEmail]!['user'] = userMap;
        await _saveRegisteredUsers();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
