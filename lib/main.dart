import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/landing_screen.dart';
import 'screens/itineraries_list_screen.dart';
import 'services/supabase_service.dart';

final supabaseService = SupabaseService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey, debug: false);
  runApp(const TravelItineraryApp());
}

class TravelItineraryApp extends StatelessWidget {
  const TravelItineraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color offWhite = Color(0xFFF5F5F5);
    const Color beige = Color(0xFFE6D5C7);

    return MaterialApp(
      title: 'Intellinary',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: offWhite,
        scaffoldBackgroundColor: offWhite,
        appBarTheme: const AppBarTheme(backgroundColor: offWhite, foregroundColor: Colors.black, elevation: 0),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w900),
          displayMedium: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w800),
          displaySmall: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w700),
          titleLarge: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold),
          bodyLarge: GoogleFonts.nunito(fontSize: 18),
          bodyMedium: GoogleFonts.nunito(fontSize: 16),
          bodySmall: GoogleFonts.nunito(fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: beige,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Colors.black)),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Colors.black26,
          selectionHandleColor: Colors.black,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(),
          hintStyle: TextStyle(color: Colors.grey),
          focusedBorder: OutlineInputBorder(),
        ),
      ),
      home: const SupabaseInitializer(), // Use a new widget to handle initialization
    );
  }
}

class SupabaseInitializer extends StatefulWidget {
  const SupabaseInitializer({super.key});

  @override
  State<SupabaseInitializer> createState() => _SupabaseInitializerState();
}

class _SupabaseInitializerState extends State<SupabaseInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSupabase();
  }

  Future<void> _initializeSupabase() async {
    await Future.delayed(Duration.zero); // Ensure build context is available
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _initialized ? const AuthWrapper() : const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    setState(() {
      _isLoading = true;
    });

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      setState(() {
        _isSignedIn = true;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      return _isSignedIn ? const ItinerariesListScreen() : const LandingScreen();
    }
  }
}
