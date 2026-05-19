import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../models/mime_type.dart';
import '../supabase_bootstrap.dart';

/// Upload failures surfaced to the ViewModel as human-readable messages.
class StorageUploadFailure implements Exception {
  StorageUploadFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Result of a successful Storage upload (URL + Firebase uid for Firestore catalog).
class StorageUploadReceipt {
  const StorageUploadReceipt({
    required this.downloadUrl,
    required this.uid,
    required this.objectPath,
  });

  final String downloadUrl;

  /// Firebase Auth uid — used as `users/{uid}/brochures` in Firestore.
  final String uid;

  /// Supabase Storage object path for signed URL regeneration.
  final String objectPath;
}

/// Uploads files to **Supabase Storage** using a Supabase session, while keeping
/// **Firebase Auth** for the brochure history document path.
class StorageUploadService {
  StorageUploadService({FirebaseAuth? auth, String? bucket})
    : _authOverride = auth,
      _bucket = bucket ?? kSupabaseStorageBucket;

  final FirebaseAuth? _authOverride;
  final String _bucket;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  SupabaseClient? _clientOrNull() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<StorageUploadReceipt> uploadUserBytes({
    required Uint8List bytes,
    required String fileName,
    required int expiresInSeconds,
  }) async {
    final sb = _clientOrNull();
    if (!isSupabaseConfigured || sb == null) {
      throw StorageUploadFailure(
        'Supabase is not configured. Run with '
        '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
      );
    }

    // Firebase Auth: Required for tracking user uploads
    User? fbUser = _auth.currentUser;
    if (fbUser == null) {
      try {
        final cred = await _auth.signInAnonymously();
        fbUser = cred.user;
      } on FirebaseAuthException catch (e) {
        throw StorageUploadFailure(
          'Firebase sign-in failed: ${e.message ?? e.code}. '
          'Enable Anonymous Authentication in Firebase Console.',
        );
      }
    }
    if (fbUser == null) {
      throw StorageUploadFailure('Could not sign in to Firebase.');
    }

    // Supabase Storage: Upload without Supabase auth.
    // Signed URLs provide expiring access for QR scans.
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final objectPath =
        '${fbUser.uid}/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    try {
      await sb.storage
          .from(_bucket)
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              contentType: guessMimeForFileName(fileName),
            ),
          );

      final signedUrl = await createSignedDownloadUrl(
        objectPath: objectPath,
        expiresInSeconds: expiresInSeconds,
      );
      return StorageUploadReceipt(
        downloadUrl: signedUrl,
        uid: fbUser.uid,
        objectPath: objectPath,
      );
    } catch (e) {
      throw StorageUploadFailure(
        'Supabase upload failed: $e. '
        'Check: 1) Bucket "$_bucket" exists, '
        '2) Storage policies allow insert/select, '
        '3) Supabase SQL setup for signed URLs is applied.',
      );
    }
  }

  Future<String> createSignedDownloadUrl({
    required String objectPath,
    required int expiresInSeconds,
  }) async {
    final sb = _clientOrNull();
    if (!isSupabaseConfigured || sb == null) {
      throw StorageUploadFailure('Supabase is not configured.');
    }
    try {
      return await sb.storage
          .from(_bucket)
          .createSignedUrl(objectPath, expiresInSeconds);
    } catch (e) {
      throw StorageUploadFailure(
        'Could not generate signed URL: $e. '
        'Apply Supabase storage policies and verify bucket name.',
      );
    }
  }
}
