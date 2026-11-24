import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Loads non-secret public configuration from Firebase Remote Config.
///
/// Publishable Supabase keys are safe to expose in a client app, so keeping
/// them in Remote Config avoids shipping them inside the compiled JS bundle or
/// relying on a local `.env` file for the live site.
class RemoteConfigService {
  static const Map<String, String> defaults = <String, String>{
    'SUPABASE_URL': '',
    'SUPABASE_PUBLISHABLE_KEY': '',
    'SUPABASE_ANON_KEY': '',
    // Keep fallbacks empty so --dart-define and .env values are not shadowed.
    'SUPABASE_STORAGE_BUCKET': '',
    'SUPABASE_CARD_ASSETS_BUCKET': '',
  };

  Future<Map<String, String>> loadSupabaseConfig() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
      );
      await rc.setDefaults(defaults);
      await rc.fetchAndActivate();

      return defaults.map((key, _) => MapEntry(key, rc.getString(key).trim()));
    } catch (_) {
      return defaults;
    }
  }
}
