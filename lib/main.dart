import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_app_check_support.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseInitError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    firebaseInitError = e;
  } catch (e) {
    firebaseInitError = e;
  }

  if (firebaseInitError == null) {
    try {
      await activateFirebaseAppCheck();
    } catch (_) {}
    try {
      await initSupabase();
    } catch (_) {}
  }

  runApp(QrBrochureApp(firebaseInitError: firebaseInitError));
}

class QrBrochureApp extends StatelessWidget {
  const QrBrochureApp({super.key, this.firebaseInitError});

  final Object? firebaseInitError;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E6AE6),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'QR Brochure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          foregroundColor: Color(0xFF1A1A1A),
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: const BorderSide(color: Color(0xFFD9DEE8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: Color(0xFFCDD4E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: Color(0xFFCDD4E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: Color(0xFF2E6AE6), width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFAEB9CB)),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
      home: HomeScreen(firebaseInitError: firebaseInitError),
    );
  }
}
