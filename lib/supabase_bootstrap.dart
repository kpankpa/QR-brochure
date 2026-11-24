import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _resolvedUrl = '';
String _resolvedAnonKey = '';
String _resolvedBucket = 'QR-bucket';
String _resolvedCardAssetsBucket = 'card-assets';

/// Supabase project URL after [initSupabase] runs.
///
/// Firebase Remote Config is checked first, then `--dart-define`, then the
/// optional `.env` asset for local development.
String get kSupabaseUrl => _resolvedUrl;

/// Publishable (`sb_publishable_…`) or legacy anon JWT — passed to
/// [Supabase.initialize] as `anonKey`.
String get kSupabaseAnonKey => _resolvedAnonKey;

/// Storage bucket id (default `QR-bucket`).
String get kSupabaseStorageBucket => _resolvedBucket;

/// Public bucket for digital card photos and logos (default `card-assets`).
String get kSupabaseCardAssetsBucket => _resolvedCardAssetsBucket;

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
  put(
    'SUPABASE_CARD_ASSETS_BUCKET',
    const String.fromEnvironment('SUPABASE_CARD_ASSETS_BUCKET'),
  );
  return m;
}

/// Call after Firebase is initialized. Safe no-op if config is missing.
///
/// [remoteConfig] should come from `RemoteConfigService.loadSupabaseConfig()`.
/// Values are resolved in this order: Remote Config → `--dart-define` → `.env`.
Future<void> initSupabase({Map<String, String>? remoteConfig}) async {
  await dotenv.load(
    fileName: '.env',
    isOptional: true,
    mergeWith: _dartDefineMerge(),
  );

  String read(String key) {
    final fromRemote = remoteConfig?[key]?.trim();
    if (fromRemote != null && fromRemote.isNotEmpty) return fromRemote;
    return dotenv.maybeGet(key)?.trim() ?? '';
  }

  _resolvedUrl = read('SUPABASE_URL');

  final publishable = read('SUPABASE_PUBLISHABLE_KEY');
  final anon = read('SUPABASE_ANON_KEY');
  _resolvedAnonKey = publishable.isNotEmpty ? publishable : anon;

  final bucketRaw = read('SUPABASE_STORAGE_BUCKET');
  _resolvedBucket = bucketRaw.isNotEmpty ? bucketRaw : 'QR-bucket';

  final cardBucketRaw = read('SUPABASE_CARD_ASSETS_BUCKET');
  _resolvedCardAssetsBucket =
      cardBucketRaw.isNotEmpty ? cardBucketRaw : 'card-assets';

  if (!isSupabaseConfigured) return;
  await Supabase.initialize(url: _resolvedUrl, anonKey: _resolvedAnonKey);
}
