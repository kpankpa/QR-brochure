import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _resolvedUrl = '';
String _resolvedAnonKey = '';
String _resolvedBucket = 'brochures';

/// Supabase project URL after [initSupabase] runs (`.env` asset + `--dart-define`).
String get kSupabaseUrl => _resolvedUrl;

/// Publishable (`sb_publishable_…`) or legacy anon JWT — passed to
/// [Supabase.initialize] as `anonKey`.
String get kSupabaseAnonKey => _resolvedAnonKey;

/// Storage bucket id (default `brochures`).
String get kSupabaseStorageBucket => _resolvedBucket;

bool get isSupabaseConfigured =>
    _resolvedUrl.isNotEmpty && _resolvedAnonKey.isNotEmpty;

Map<String, String> _dartDefineMerge() {
  final m = <String, String>{};
  void put(String key, String value) {
    if (value.isNotEmpty) m[key] = value;
  }

  put('SUPABASE_URL', const String.fromEnvironment('SUPABASE_URL'));
  put('SUPABASE_ANON_KEY', const String.fromEnvironment('SUPABASE_ANON_KEY'));
  put(
    'SUPABASE_PUBLISHABLE_KEY',
    const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );
  put(
    'SUPABASE_STORAGE_BUCKET',
    const String.fromEnvironment('SUPABASE_STORAGE_BUCKET'),
  );
  return m;
}

/// Call after [WidgetsFlutterBinding.ensureInitialized]. Safe no-op if env missing.
///
/// Loads optional asset `.env` if present (list `- .env` under `flutter: assets:`).
/// Non-empty `--dart-define` entries override the same keys from `.env`.
Future<void> initSupabase() async {
  await dotenv.load(
    fileName: '.env',
    isOptional: true,
    mergeWith: _dartDefineMerge(),
  );

  _resolvedUrl = dotenv.maybeGet('SUPABASE_URL') ?? '';

  final publishable = dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY');
  final anon = dotenv.maybeGet('SUPABASE_ANON_KEY');
  if (publishable != null && publishable.isNotEmpty) {
    _resolvedAnonKey = publishable;
  } else if (anon != null && anon.isNotEmpty) {
    _resolvedAnonKey = anon;
  } else {
    _resolvedAnonKey = '';
  }

  final bucketRaw = dotenv.maybeGet('SUPABASE_STORAGE_BUCKET');
  _resolvedBucket =
      bucketRaw != null && bucketRaw.isNotEmpty ? bucketRaw : 'brochures';

  if (!isSupabaseConfigured) return;
  await Supabase.initialize(url: _resolvedUrl, anonKey: _resolvedAnonKey);
}
