import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../model/store.dart';
import '../model/employees.dart';
import 'supabase_service.dart';

enum AuthState {
  initial,
  authenticated,
  unauthenticated,
  offlineAuthenticated, // Authenticated but offline
  error
}

enum UserType { owner, employee }

class AuthUser {
  final String id;
  final String email;
  final UserType type;
  final Store? store; // For employees - their assigned store
  final Employee? employee; // For employees
  final List<Store>? stores; // For owners - their stores

  AuthUser({
    required this.id,
    required this.email,
    required this.type,
    this.store,
    this.employee,
    this.stores,
  });

  bool get isOwner => type == UserType.owner;
  bool get isEmployee => type == UserType.employee;
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final Connectivity _connectivity = Connectivity();

  AuthState _authState = AuthState.initial;
  AuthUser? _currentUser;
  String? _lastError;

  AuthState get authState => _authState;
  AuthUser? get currentUser => _currentUser;
  String? get lastError => _lastError;
  bool get isAuthenticated =>
      _authState == AuthState.authenticated ||
      _authState == AuthState.offlineAuthenticated;
  bool get isOnline => _authState != AuthState.offlineAuthenticated;

  void _logError(String context, Object error, [StackTrace? stackTrace]) {
    debugPrint('[AuthService] $context: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> initialize() async {
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult.isNotEmpty &&
          !connectivityResult.contains(ConnectivityResult.none);

      // Try to restore auth state from cache
      await _restoreAuthState();

      if (_currentUser != null) {
        if (isOnline) {
          // Verify auth with server with timeout
          try {
            await _verifyAuthWithServer().timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                debugPrint(
                    '[AuthService] Auth verification timed out - treating as offline');
                throw TimeoutException('Auth verification timeout');
              },
            );
            _authState = AuthState.authenticated;
          } catch (e) {
            _logError('verify auth on initialize failed', e);
            // If server verification fails but we have cached auth, treat as offline authenticated
            _authState = AuthState.offlineAuthenticated;
            _lastError =
                'Unable to verify authentication with server. You are offline.';
          }
        } else {
          _authState = AuthState.offlineAuthenticated;
        }
      } else {
        _authState = AuthState.unauthenticated;
      }
    } catch (e) {
      _authState = AuthState.error;
      _lastError = e.toString();
      _logError('initialize failed', e);
    }

    notifyListeners();

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      _handleConnectivityChange(result);
    });

    // Listen to auth state changes from Supabase
    _client.auth.onAuthStateChange.listen((data) {
      _handleAuthStateChange(data.event);
    });
  }

  Future<void> _restoreAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getString('auth_user_id');
      final userEmail = prefs.getString('auth_user_email');
      final userType = prefs.getString('auth_user_type');

      if (userId != null && userEmail != null && userType != null) {
        UserType type =
            userType == 'owner' ? UserType.owner : UserType.employee;

        if (type == UserType.owner) {
          // Restore owner data
          final storesJson = prefs.getStringList('auth_owner_stores');
          List<Store>? stores;
          if (storesJson != null) {
            try {
              stores = storesJson.map((json) {
                final decoded = jsonDecode(json);
                return Store.fromJson(decoded);
              }).toList();
            } catch (e) {
              _logError('restore owner stores failed', e);
              // Invalid cached data
              stores = null;
            }
          }

          _currentUser = AuthUser(
            id: userId,
            email: userEmail,
            type: type,
            stores: stores,
          );
        } else {
          // Restore employee data
          final employeeJson = prefs.getString('auth_employee_data');
          final storeJson = prefs.getString('auth_employee_store');
          Employee? employee;
          Store? store;

          if (employeeJson != null) {
            try {
              final decoded = jsonDecode(employeeJson);
              employee = Employee.fromJson(decoded);
            } catch (e) {
              _logError('restore employee data failed', e);
              employee = null;
            }
          }

          if (storeJson != null) {
            try {
              final decoded = jsonDecode(storeJson);
              store = Store.fromJson(decoded);
            } catch (e) {
              _logError('restore employee store failed', e);
              store = null;
            }
          }

          _currentUser = AuthUser(
            id: userId,
            email: userEmail,
            type: type,
            employee: employee,
            store: store,
          );
        }
      }
    } catch (e) {
      _logError('restore auth state failed', e);
      // Clear corrupted cache
      await clearAuthCache();
    }
  }

  Future<void> _verifyAuthWithServer() async {
    if (_currentUser == null) return;

    // Try to refresh the session
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('No valid session');
    }

    // Verify user still exists and is active
    if (_currentUser!.isEmployee) {
      await _checkEmployeeActivation();
    }
  }

  Future<void> _checkEmployeeActivation() async {
    if (_currentUser == null || !_currentUser!.isEmployee) return;

    try {
      // Check if employee is still active
      final response = await _client
          .from('employees')
          .select('is_active')
          .eq('id', _currentUser!.id)
          .single();

      if (!response['is_active']) {
        // Employee is deactivated - sign them out immediately
        debugPrint(
            'Employee account deactivated - signing out user: ${_currentUser!.id}');
        await _client.auth.signOut();
        await clearAuthCache();
        _currentUser = null;
        _authState = AuthState.unauthenticated;
        _lastError = 'Account deactivated. Contact owner.';
        notifyListeners();
        throw Exception('Employee account is deactivated');
      }
    } catch (e) {
      if (e.toString().contains('Employee account is deactivated')) {
        rethrow;
      }
      _logError('check employee activation failed', e);
      // For other errors, don't sign out but log the error
    }
  }

  void _handleConnectivityChange(dynamic result) {
    final wasOffline = _authState == AuthState.offlineAuthenticated;
    ConnectivityResult? status;

    if (result is List<ConnectivityResult>) {
      status = result.isNotEmpty ? result.first : ConnectivityResult.none;
    } else if (result is ConnectivityResult) {
      status = result;
    }

    final connectivityStatus = status ?? ConnectivityResult.none;
    final isOnline = connectivityStatus != ConnectivityResult.none;

    if (wasOffline && isOnline && _currentUser != null) {
      // Try to verify auth when coming back online
      _verifyAuthWithServer().then((_) {
        _authState = AuthState.authenticated;
        _lastError = null;
        notifyListeners();
      }).catchError((e) {
        _logError('verify auth on connectivity change failed', e);
        _authState = AuthState.offlineAuthenticated;
        _lastError =
            'Unable to verify authentication with server. You are offline.';
        notifyListeners();
      });
    } else if (!wasOffline && !isOnline && _currentUser != null) {
      // Going offline while authenticated
      _authState = AuthState.offlineAuthenticated;
      _lastError = 'You are now offline. Some features may be limited.';
      notifyListeners();
    }
  }

  void _handleAuthStateChange(AuthChangeEvent event) {
    if (event == AuthChangeEvent.signedOut) {
      clearAuthCache();
      _currentUser = null;
      _authState = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> clearAuthCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user_id');
      await prefs.remove('auth_user_email');
      await prefs.remove('auth_user_type');
      await prefs.remove('auth_owner_stores');
      await prefs.remove('auth_employee_data');
      await prefs.remove('auth_employee_store');
    } catch (e) {
      _logError('clear auth cache failed', e);
      // Ignore errors when clearing cache
    }
  }

  // Authentication methods
  Future<bool> loginOwner(String phone, String pin) async {
    try {
      _authState = AuthState.initial;
      _lastError = null;
      notifyListeners();

      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.isEmpty ||
          connectivityResult.contains(ConnectivityResult.none)) {
        _authState = AuthState.error;
        _lastError = 'No internet connection. Please connect and try again.';
        notifyListeners();
        return false;
      }

      // Normalize phone number - remove +255 prefix if present
      String normalizedPhone = phone;
      if (phone.startsWith('+255')) {
        normalizedPhone = phone.substring(4); // Remove +255
      } else if (phone.startsWith('255')) {
        normalizedPhone = phone.substring(3); // Remove 255
      }
      // Ensure phone starts with 7 or 6 for Tanzanian numbers
      if (!normalizedPhone.startsWith('7') &&
          !normalizedPhone.startsWith('6')) {
        _authState = AuthState.error;
        _lastError = 'Please enter a valid Tanzanian phone number';
        notifyListeners();
        return false;
      }

      final email = '$normalizedPhone@dukakiganjani.com';
      final session = _client.auth.currentSession;
      if (session?.user != null && session!.user.email == email) {
        final stores = await SupabaseService.getStoresForUser();
        _currentUser = AuthUser(
          id: session.user.id,
          email: session.user.email ?? email,
          type: UserType.owner,
          stores: stores,
        );
        await _cacheAuthData();
        _authState = AuthState.authenticated;
        notifyListeners();
        return true;
      } else if (session?.user != null) {
        await _client.auth.signOut();
      }

      AuthResponse? authResponse;
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          authResponse = await _client.auth.signInWithPassword(
            email: email,
            password: '$pin@$normalizedPhone',
          );
          break;
        } catch (e, stackTrace) {
          final errorText = e.toString();
          final isRetryable =
              errorText.contains('AuthRetryableFetchException') ||
                  errorText.contains(
                      'Connection closed before full header was received');
          _logError('owner login attempt ${attempt + 1} failed', e, stackTrace);
          if (!isRetryable || attempt == 1) {
            rethrow;
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (authResponse?.user != null) {
        // Get owner's stores
        final stores = await SupabaseService.getStoresForUser();

        _currentUser = AuthUser(
          id: authResponse!.user!.id,
          email: authResponse.user!.email!,
          type: UserType.owner,
          stores: stores,
        );

        // Cache auth data
        await _cacheAuthData();

        _authState = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _authState = AuthState.unauthenticated;
        _lastError = 'Invalid credentials';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _authState = AuthState.error;
      _lastError = _getUserFriendlyError(e.toString());
      _logError('owner login failed', e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginEmployee(String identifier, String pin) async {
    try {
      _authState = AuthState.initial;
      _lastError = null;
      notifyListeners();

      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.isEmpty ||
          connectivityResult.contains(ConnectivityResult.none)) {
        _authState = AuthState.error;
        _lastError = 'No internet connection. Please connect and try again.';
        notifyListeners();
        return false;
      }

      // Normalize phone number - remove +255 prefix if present
      String normalizedIdentifier = identifier;
      if (identifier.startsWith('+255')) {
        normalizedIdentifier = identifier.substring(4); // Remove +255
      } else if (identifier.startsWith('255')) {
        normalizedIdentifier = identifier.substring(3); // Remove 255
      }

      // Try to authenticate with Supabase
      String email;
      if (normalizedIdentifier.contains('@')) {
        email = normalizedIdentifier;
      } else {
        // Assume it's a phone number or username
        email = '$normalizedIdentifier@dukakiganjani.com';
      }

      final session = _client.auth.currentSession;
      if (session?.user != null && session!.user.email == email) {
        final employee = await SupabaseService.authenticateEmployee(
          username: identifier,
          pin: pin,
        );

        final stores = employee != null
            ? await SupabaseService.getEmployeeStores(employee.id)
            : <Store>[];

        _currentUser = AuthUser(
          id: session.user.id,
          email: session.user.email ?? email,
          type: UserType.employee,
          employee: employee,
          stores: stores,
          store: stores.isNotEmpty ? stores.first : null,
        );
        await _cacheAuthData();
        _authState = AuthState.authenticated;
        notifyListeners();
        return true;
      } else if (session?.user != null) {
        await _client.auth.signOut();
      }

      AuthResponse? authResponse;
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          authResponse = await _client.auth.signInWithPassword(
            email: email,
            password: '$pin@dukakiganjani',
          );
          break;
        } catch (e, stackTrace) {
          final errorText = e.toString();
          final isRetryable =
              errorText.contains('AuthRetryableFetchException') ||
                  errorText.contains(
                      'Connection closed before full header was received');
          _logError(
              'employee login attempt ${attempt + 1} failed', e, stackTrace);
          if (!isRetryable || attempt == 1) {
            rethrow;
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (authResponse?.user != null) {
        // Get employee data
        final employee = await SupabaseService.authenticateEmployee(
          username: identifier,
          pin: pin,
        );

        // Get employee's stores
        final stores = employee != null
            ? await SupabaseService.getEmployeeStores(employee.id)
            : <Store>[];

        _currentUser = AuthUser(
          id: authResponse!.user!.id,
          email: authResponse.user!.email!,
          type: UserType.employee,
          employee: employee,
          stores: stores,
          store: stores.isNotEmpty ? stores.first : null,
        );

        // Check if employee is still active after login
        await _checkEmployeeActivation();

        // Cache auth data
        await _cacheAuthData();

        _authState = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _authState = AuthState.unauthenticated;
        _lastError = 'Invalid credentials';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _authState = AuthState.error;
      _lastError = _getUserFriendlyError(e.toString());
      _logError('employee login failed', e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _client.auth.signOut();
      await clearAuthCache();
      _currentUser = null;
      _authState = AuthState.unauthenticated;
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _logError('logout failed', e);
      // Even if sign out fails, clear local state
      await clearAuthCache();
      _currentUser = null;
      _authState = AuthState.unauthenticated;
      _lastError = null;
      notifyListeners();
    }
  }

  Future<void> _cacheAuthData() async {
    if (_currentUser == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('auth_user_id', _currentUser!.id);
      await prefs.setString('auth_user_email', _currentUser!.email);
      await prefs.setString(
          'auth_user_type', _currentUser!.isOwner ? 'owner' : 'employee');

      if (_currentUser!.isOwner && _currentUser!.stores != null) {
        final storesJson = _currentUser!.stores!
            .map((store) => jsonEncode(store.toJson()))
            .toList();
        await prefs.setStringList('auth_owner_stores', storesJson);
      }

      if (_currentUser!.isEmployee) {
        if (_currentUser!.employee != null) {
          await prefs.setString('auth_employee_data',
              jsonEncode(_currentUser!.employee!.toJson()));
        }
        if (_currentUser!.store != null) {
          await prefs.setString(
              'auth_employee_store', jsonEncode(_currentUser!.store!.toJson()));
        }
      }
    } catch (e) {
      _logError('cache auth data failed', e);
      // Ignore caching errors
    }
  }

  String _getUserFriendlyError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid username/phone or PIN. Please check and try again.';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.contains('deactivated')) {
      return 'Your account has been deactivated. Please contact your administrator.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  // Check if user can perform offline operations
  bool canPerformOfflineOperation() {
    return _authState == AuthState.offlineAuthenticated && _currentUser != null;
  }

  // Get offline message
  String getOfflineMessage() {
    if (_authState == AuthState.offlineAuthenticated) {
      return 'You are currently offline. Some features may be limited.';
    }
    return '';
  }
}
