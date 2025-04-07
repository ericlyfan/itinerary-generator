import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/landing_screen.dart';
import 'services/supabase_service.dart';

final supabaseService = SupabaseService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: './.env');
  await supabaseService.initialize();
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
      home: const LandingScreen(),
    );
  }
}
