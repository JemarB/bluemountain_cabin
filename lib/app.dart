import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'core/theme_controller.dart'; // ✅ correct import

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ThemeController.loadTheme(); // ✅ Load saved theme before running app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.latoTextTheme();

    // ✅ Use ValueListenableBuilder instead of AnimatedBuilder
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Blue Mountain Cabin',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.brown,
            scaffoldBackgroundColor: const Color(0xFFFAF3E0),
            textTheme: baseTextTheme.copyWith(
              titleLarge: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4E342E),
              ),
              bodyMedium: const TextStyle(
                fontSize: 16,
                color: Color(0xFF5D4037),
              ),
              titleMedium: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF8D6E63),
              foregroundColor: Colors.white,
              elevation: 2,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D6E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.teal[700],
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[900],
              foregroundColor: Colors.white,
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}
