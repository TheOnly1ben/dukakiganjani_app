import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState, AuthUser;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'onboarding.dart';
import 'auth/owner_login.dart';
import 'auth/employee_login.dart';
import 'auth/owner_register.dart';
import 'pages/store_list.dart';
import 'pages/dashboard.dart';
import 'services/auth_service.dart';

// Custom HTTP client that logs all requests and responses
class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;

  LoggingHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Log outgoing request
    debugPrint('🚀 HTTP Request: ${request.method} ${request.url}');
    if (request.headers.isNotEmpty) {
      debugPrint('📋 Headers: ${request.headers}');
    }

    try {
      final response = await _inner.send(request);

      // Log response
      debugPrint('📥 HTTP Response: ${response.statusCode} ${response.reasonPhrase}');
      if (response.headers.isNotEmpty) {
        debugPrint('📋 Response Headers: ${response.headers}');
      }

      // For error responses, log the body content
      if (response.statusCode >= 400) {
        final responseBody = await response.stream.bytesToString();
        debugPrint('❌ Error Response Body: $responseBody');

        // Reconstruct the response for the caller
        final List<int> bytes = responseBody.codeUnits;
        final newResponse = http.StreamedResponse(
          Stream.value(bytes),
          response.statusCode,
          contentLength: bytes.length,
          request: request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
        return newResponse;
      }

      return response;
    } catch (e) {
      debugPrint('❌ HTTP Request Failed: $e');
      rethrow;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Warning: Could not load .env file: $e');
  }

  // Get Supabase credentials from environment variables with fallback
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ??
                     'https://qzeeggpkjqoqwqskxotq.supabase.co';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
                         'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6ZWVnZ3BranFvcXdxc2t4b3RxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc2MjA2MTIsImV4cCI6MjA4MzE5NjYxMn0.V55wn1GdjAMTaI1RqkEd6aW9KLlanEarU0S4kmXwirw';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Supabase credentials not found');
  }

  // Initialize Supabase with debug logging enabled
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true,
    httpClient: LoggingHttpClient(http.Client()),
  );

  await EasyLocalization.ensureInitialized();

  // Initialize AuthService
  final authService = AuthService();
  await authService.initialize();

  // Enable edge-to-edge display
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // Make the nav bar transparent
      systemNavigationBarColor: Colors.transparent,
      // Make the status bar transparent
      statusBarColor: Colors.transparent,
      // Set status bar icon brightness
      statusBarIconBrightness: Brightness.light,
      // Set nav bar icon brightness
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: [const Locale('en'), const Locale('sw')],
      path: 'assets/translations',
      startLocale: const Locale('sw'),
      fallbackLocale: const Locale('sw'),
      child: ChangeNotifierProvider.value(
        value: authService,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Duka Ganjani',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      routes: {
        '/owner_login': (context) => const OwnerLoginPage(),
        '/owner_register': (context) => const OwnerRegisterPage(),
        '/employee_login': (context) =>  EmployeeLoginPage(),
        '/store_list': (context) => const StoreListPage(),
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        switch (authService.authState) {
          case AuthState.initial:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          case AuthState.authenticated:
            return _buildAuthenticatedScreen(authService.currentUser!);
          case AuthState.offlineAuthenticated:
            return _buildOfflineAuthenticatedScreen(context, authService);
          case AuthState.unauthenticated:
          case AuthState.error:
          default:
            return OnboardingPage();
        }
      },
    );
  }

  Widget _buildAuthenticatedScreen(AuthUser user) {
    if (user.isOwner) {
      // Corrected logic: Always go to StoreListPage for owners.
      return const StoreListPage();
    } else {
      // Employee - go to employee dashboard
      if (user.store != null) {
        return EmployeeDashboardPage(store: user.store!, employee: user.employee!);
      } else {
        // No store assigned, go back to login
        return EmployeeLoginPage();
      }
    }
  }

  Widget _buildOfflineAuthenticatedScreen(BuildContext context, AuthService authService) {
    final user = authService.currentUser!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'You are currently offline',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                authService.getOfflineMessage(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await authService.logout();
                  // Clear navigation stack and go back to onboarding page
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Logout'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Try to verify connection
                  authService.initialize();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
