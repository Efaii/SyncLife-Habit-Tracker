import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

import 'core/constants/supabase_constants.dart';
import 'core/constants/providers/theme_provider.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'core/services/notification_service.dart';
import 'core/services/date_formatting_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DotEnv with fallback
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    debugPrint('Warning: assets/.env file not found. Falling back to dart-define or system environment variables.');
  }

  // Initialize Local Notifications
  try {
    await NotificationService().init(
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          navigatorKey.currentState?.pushNamed('/habit-detail', arguments: response.payload);
        }
      },
    );
  } catch (e) {
    debugPrint('Local Notifications Initialization Error: $e');
  }

  // 1. CLEAN LOCAL STORAGE (Flutter Web Only)
  if (kIsWeb) {
    try {
      final uri = Uri.base;
      // Only clean up if we are NOT currently handling a legitimate auth callback
      final isCallback = uri.queryParameters.containsKey('code') || 
                         uri.queryParameters.containsKey('error') || 
                         uri.fragment.contains('access_token');
                         
      if (!isCallback) {
        // Supabase-Flutter uses SharedPreferences under the hood to store tokens and verifiers.
        // Clearing SharedPreferences is completely safe and won't crash Android/iOS compilations.
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    } catch (e) {
      debugPrint('Web Storage Cleanup Error: $e');
    }
  }

  // 2. ROBUST INITIALIZATION BLOCK
  try {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    // MANUAL DEEPLINK HANDLING
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('code') || uri.queryParameters.containsKey('error')) {
        try {
          await Supabase.instance.client.auth.getSessionFromUrl(uri);
        } catch (e) {
          debugPrint('Manual DeepLink Error: $e');
        }
      }
    }
  } catch (e) {
    if (e is AuthException && e.message.contains('Code verifier')) {
      debugPrint('Auth SDK noise suppressed: Expected during development.');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    } else if (e.toString().contains('Code verifier')) {
      debugPrint('Auth SDK noise suppressed: Expected during development.');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    } else {
      debugPrint('Supabase Initialization Error: $e');
    }
  }

  // Initialize Global Locale Data for DateFormat
  try {
    await DateFormattingService.initialize();
  } catch (e) {
    debugPrint('Date Formatting Initialization Error: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        if (event == AuthChangeEvent.signedOut) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
    } catch (e) {
      debugPrint('Auth listener init error: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SyncLife',

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEEF2FF),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2B3A8C),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFD8E2FF),
          onPrimaryContainer: Color(0xFF00105C),
          surface: Colors.white,
          onSurface: Colors.black87,
          onSurfaceVariant: Color(0xFF606060), // For subtitles in light mode
          error: Colors.redAccent,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
          bodyLarge: GoogleFonts.inter(color: Colors.black87),
          bodyMedium: GoogleFonts.inter(color: Colors.black87),
          bodySmall: GoogleFonts.inter(color: const Color(0xFF606060)),
          titleLarge: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold),
          titleMedium: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.w600),
          titleSmall: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.w500),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2B3A8C),
          unselectedItemColor: Colors.grey.shade400,
          elevation: 8,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD0BCFF), // Bright pastel purple for dark mode
          onPrimary: Color(0xFF381E72),
          primaryContainer: Color(0xFF4F378B),
          onPrimaryContainer: Color(0xFFEADDFF),
          surface: Color(0xFF1E1E1E),
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xFFCACACA), // Light gray for subtitles
          error: Colors.redAccent,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          bodyLarge: GoogleFonts.inter(color: Colors.white),
          bodyMedium: GoogleFonts.inter(color: Colors.white),
          bodySmall: GoogleFonts.inter(color: const Color(0xFFCACACA)),
          titleLarge: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
          titleSmall: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: const Color(0xFFD0BCFF),
          unselectedItemColor: Colors.grey.shade600,
          elevation: 8,
        ),
      ),

      themeMode: themeMode,
      routes: {
        '/login': (context) => const LoginScreen(),
      },
      home: const SplashScreen(),
    );
  }
}