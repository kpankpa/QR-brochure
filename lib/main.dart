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
    return MaterialApp(
      title: 'QR Brochure',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: HomeScreen(firebaseInitError: firebaseInitError),
    );
  }
}
