import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

  static const int maxBytes = 25 * 1024 * 1024;
  static const Set<String> allowedExtensions = <String>{
    'pdf',
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
  };

  /// Supabase caps signed URLs at seven days.
  static const int maxSignedUrlSeconds = 7 * 24 * 60 * 60;

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
        'Supabase is not configured. Add SUPABASE_URL and '
        'SUPABASE_PUBLISHABLE_KEY to Remote Config or the build config.',
      );
    }
    if (bytes.isEmpty) {
      throw StorageUploadFailure('That file is empty. Please choose another.');
    }
    if (bytes.length > maxBytes) {
      throw StorageUploadFailure(
        'File is too large. Please choose a file under 25 MB.',
      );
    }
    final extension =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (!allowedExtensions.contains(extension)) {
      throw StorageUploadFailure(
        'Unsupported file type. Use PDF, PNG, JPG, WEBP or GIF.',
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
    final safeName =
        fileName.replaceAll(RegExp(r'[^\w.\-]'), '_').length > 60
            ? fileName.replaceAll(RegExp(r'[^\w.\-]'), '_').substring(0, 60)
            : fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
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
      debugPrint('Supabase upload failed: $e');
      throw StorageUploadFailure(
        'Upload failed. Check your connection and that the "$_bucket" bucket '
        'is configured, then try again.',
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
    final seconds = expiresInSeconds.clamp(1, maxSignedUrlSeconds).toInt();
    try {
      return await sb.storage
          .from(_bucket)
          .createSignedUrl(objectPath, seconds);
    } catch (e) {
      debugPrint('Could not generate signed URL: $e');
      throw StorageUploadFailure(
        'Could not refresh that link. Check your connection and try again.',
      );
    }
  }
}
