// Smoke-test Supabase reachability and API keys (Auth + Storage).
//
// From repo root, with `.env` filled and listed under `flutter: assets:` for the
// app — this tool reads the file directly from disk:
//   dart run tool/supabase_ping.dart
//
// Or set env vars (override `.env`):
//   SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY or SUPABASE_ANON_KEY,
//   optional SUPABASE_STORAGE_BUCKET
//
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final root = Directory.current.path;
  final fromFile = _loadDotEnv(File('$root/.env'));
  final url = _pickEnv(fromFile, 'SUPABASE_URL');
  final key = _pickKey(fromFile);
  final bucket = _pickEnv(fromFile, 'SUPABASE_STORAGE_BUCKET');

  if (url.isEmpty || key.isEmpty) {
    stderr.writeln(
      'Missing SUPABASE_URL or key (SUPABASE_PUBLISHABLE_KEY / SUPABASE_ANON_KEY).\n'
      'Copy .env.example → .env and fill values, or set those environment variables.',
    );
    exitCode = 1;
    return;
  }

  final base = url.replaceAll(RegExp(r'/+$'), '');
  final headers = {'apikey': key, 'Authorization': 'Bearer $key'};

  print('Supabase URL: $base');

  final host = Uri.tryParse(base)?.host ?? '';
  if (host.endsWith('.supabase.com')) {
    stderr.writeln(
      'Fix SUPABASE_URL: Supabase hosts use .supabase.co (not .supabase.com).',
    );
    exitCode = 1;
    return;
  }

  int authCode;
  try {
    authCode = await _httpStatus(Uri.parse('$base/auth/v1/health'), headers);
  } on SocketException catch (e) {
    stderr.writeln('Network error: ${e.message}');
    if (host.endsWith('supabase.co') || host.contains('supabase')) {
      stderr.writeln('Double-check SUPABASE_URL (project ref + .supabase.co).');
    }
    exitCode = 1;
    return;
  }
  print(
    authCode == HttpStatus.ok
        ? 'Auth API: OK ($authCode)'
        : 'Auth API: unexpected status $authCode (expected ${HttpStatus.ok})',
  );

  final storageCode = await _httpStatus(
    Uri.parse('$base/storage/v1/bucket'),
    headers,
  );
  if (storageCode == HttpStatus.ok) {
    print('Storage API: OK ($storageCode), listing buckets…');
    await _printBuckets(base, headers);
  } else if (storageCode == HttpStatus.forbidden) {
    print(
      'Storage API: HTTP $storageCode — reached Supabase but anon cannot list buckets '
      '(normal if RLS/storage policies block listing).',
    );
  } else {
    print('Storage API: HTTP $storageCode');
  }

  if (bucket.isNotEmpty) {
    final bCode = await _httpStatus(
      Uri.parse('$base/storage/v1/bucket/$bucket'),
      headers,
    );
    print(
      bCode == HttpStatus.ok
          ? 'Configured bucket "$bucket": OK ($bCode)'
          : 'Configured bucket "$bucket": HTTP $bCode '
              '(check name and storage policies)',
    );
  }

  if (authCode != HttpStatus.ok) {
    exitCode = 1;
  }
}

String _pickEnv(Map<String, String> file, String name) {
  final fromOs = Platform.environment[name]?.trim();
  if (fromOs != null && fromOs.isNotEmpty) return fromOs;
  return file[name]?.trim() ?? '';
}

String _pickKey(Map<String, String> file) {
  final pub = _pickEnv(file, 'SUPABASE_PUBLISHABLE_KEY');
  if (pub.isNotEmpty) return pub;
  return _pickEnv(file, 'SUPABASE_ANON_KEY');
}

Map<String, String> _loadDotEnv(File file) {
  if (!file.existsSync()) return {};
  final map = <String, String>{};
  for (final raw in file.readAsLinesSync()) {
    var line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final exportPrefix = RegExp(r'^export\s+');
    line = line.replaceFirst(exportPrefix, '');
    final i = line.indexOf('=');
    if (i <= 0) continue;
    final k = line.substring(0, i).trim();
    var v = line.substring(i + 1).trim();
    if ((v.startsWith('"') && v.endsWith('"')) ||
        (v.startsWith("'") && v.endsWith("'"))) {
      v = v.substring(1, v.length - 1);
    }
    map[k] = v;
  }
  return map;
}

Future<int> _httpStatus(Uri uri, Map<String, String> headers) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(uri);
    headers.forEach(req.headers.set);
    final res = await req.close();
    await res.drain<void>();
    return res.statusCode;
  } finally {
    client.close(force: true);
  }
}

Future<void> _printBuckets(String base, Map<String, String> headers) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('$base/storage/v1/bucket');
    final req = await client.getUrl(uri);
    headers.forEach(req.headers.set);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != HttpStatus.ok) return;
    try {
      final list = jsonDecode(body) as List<dynamic>;
      final names =
          list
              .map((e) => (e as Map<String, dynamic>)['name'] as String?)
              .whereType<String>()
              .toList();
      print(
        '  buckets: ${names.isEmpty ? '(none visible)' : names.join(', ')}',
      );
    } catch (_) {
      print('  (could not parse bucket list)');
    }
  } finally {
    client.close(force: true);
  }
}
