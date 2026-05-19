import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Turns on App Check with debug-friendly defaults.
///
/// **Production**
/// - Android: Play Integrity (enable in Play Console / Firebase).
/// - Apple: DeviceCheck (or switch to App Attest in Console).
/// - Web: pass `--dart-define=RECAPTCHA_SITE_KEY=...` from your Firebase Web App Check settings,
///   or rely on debug builds using [WebDebugProvider].
///
/// Register Android/iOS/web **debug tokens** in Firebase Console → App Check → Manage debug tokens
/// while developing.
Future<void> activateFirebaseAppCheck() async {
  try {
    if (kIsWeb) {
      const siteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');
      if (kDebugMode) {
        await FirebaseAppCheck.instance.activate(
          providerWeb: WebDebugProvider(),
        );
      } else if (siteKey.isNotEmpty) {
        await FirebaseAppCheck.instance.activate(
          providerWeb: ReCaptchaV3Provider(siteKey),
        );
      }
      return;
    }

    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );
  } catch (_) {
    // Tokens or Play/App Attest setup may still be pending.
  }
}
