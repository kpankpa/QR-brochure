import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_providers.dart';
import 'firebase_app_check_support.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/remote_config_service.dart';
import 'supabase_bootstrap.dart';
import 'views/public/public_card_screen.dart';

/// On web, `/c/{slug}` opens a public card without going through sign-in.
String? _initialCardSlug() {
  if (!kIsWeb) return null;
  final segments =
      Uri.base.path.split('/').where((part) => part.isNotEmpty).toList();
  if (segments.length >= 2 &&
      segments[segments.length - 2].toLowerCase() == 'c') {
    return Uri.decodeComponent(segments.last);
  }
  return null;
}

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

  Map<String, String> remoteConfig = <String, String>{};
  if (firebaseInitError == null) {
    try {
      await activateFirebaseAppCheck();
    } catch (e) {
      debugPrint('App Check activation failed: $e');
    }
    try {
      remoteConfig = await RemoteConfigService().loadSupabaseConfig();
    } catch (e) {
      debugPrint('Remote Config load failed: $e');
    }
  }

  // Supabase can still work from --dart-define/.env if Firebase is unavailable.
  try {
    await initSupabase(remoteConfig: remoteConfig);
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  // A build failure should always show a readable error instead of a blank
  // screen. This made the original "New digital card" bug very hard to spot.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint(details.toString());
  };
  ErrorWidget.builder = (details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF7F7),
        appBar: AppBar(
          title: const Text('Something went wrong'),
          backgroundColor: const Color(0xFFFDECEC),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SelectableText(
            kDebugMode
                ? '${details.exception}\n\n${details.stack ?? ''}'
                : 'The app hit an unexpected error. Please restart it and try again.',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFF8B1E1E),
            ),
          ),
        ),
      ),
    );
  };

  runApp(
    QrBrochureApp(
      firebaseInitError: firebaseInitError,
      publicCardSlug: _initialCardSlug(),
    ),
  );
}

class QrBrochureApp extends StatelessWidget {
  const QrBrochureApp({super.key, this.firebaseInitError, this.publicCardSlug});

  final Object? firebaseInitError;
  final String? publicCardSlug;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E6AE6),
      brightness: Brightness.light,
    );

    return AppProviders(
      child: MaterialApp(
        title: 'WBC-QR',
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
              borderSide: const BorderSide(
                color: Color(0xFF2E6AE6),
                width: 1.4,
              ),
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
        home:
            publicCardSlug != null
                ? PublicCardScreen(
                  slug: publicCardSlug!,
                  firebaseInitError: firebaseInitError,
                )
                : HomeScreen(firebaseInitError: firebaseInitError),
      ),
    );
  }
}
