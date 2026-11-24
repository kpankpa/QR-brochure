import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../models/mime_type.dart';
import '../supabase_bootstrap.dart';
import 'storage_upload_service.dart' show StorageUploadFailure;

/// Which image slot is being uploaded.
enum CardAssetKind { profile, logo }

class CardAssetReceipt {
  const CardAssetReceipt({required this.url, required this.path});

  /// Public, non-expiring URL stored on the card document.
  final String url;

  /// Storage object path, useful for later cleanup/replacement.
  final String path;
}

/// Uploads card profile photos and company logos to a public Supabase bucket.
///
/// Unlike brochure files, card images must remain publicly readable forever,
/// so they use `card-assets` rather than the private, expiring `QR-bucket`.
class CardAssetUploadService {
  CardAssetUploadService({String? bucket})
    : _bucket = bucket ?? kSupabaseCardAssetsBucket;

  final String _bucket;

  static const int maxBytes = 5 * 1024 * 1024;
  static const Set<String> allowedExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
  };

  SupabaseClient? _clientOrNull() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Picks an image from the device and uploads it. Returns `null` if cancelled.
  Future<CardAssetReceipt?> pickAndUpload({
    required String uid,
    required CardAssetKind kind,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    if (file.size > maxBytes || (file.bytes?.length ?? 0) > maxBytes) {
      throw StorageUploadFailure(
        'Image is too large. Please choose a file under 5 MB.',
      );
    }

    // The editor passes the signed-in Firebase uid; never let a caller upload
    // into somebody else's folder.
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null || currentUid != uid) {
        throw StorageUploadFailure('Please sign in again before uploading.');
      }
    } catch (e) {
      if (e is StorageUploadFailure) rethrow;
      throw StorageUploadFailure('Please sign in again before uploading.');
    }

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StorageUploadFailure(
        'Could not read that image. Please try again.',
      );
    }
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final decoded = frame.image;
      if (decoded.width <= 0 || decoded.height <= 0) {
        decoded.dispose();
        codec.dispose();
        throw StorageUploadFailure('That image could not be read.');
      }
      decoded.dispose();
      codec.dispose();
    } on StorageUploadFailure {
      rethrow;
    } catch (_) {
      throw StorageUploadFailure(
        'Unsupported image. Use JPG, PNG, WEBP or GIF.',
      );
    }

    final fileName = file.name;
    final ext =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (!allowedExtensions.contains(ext)) {
      throw StorageUploadFailure(
        'Unsupported image. Use JPG, PNG, WEBP or GIF.',
      );
    }
    final slot = kind == CardAssetKind.profile ? 'profile' : 'logo';
    final path = '$uid/$slot/${DateTime.now().millisecondsSinceEpoch}.$ext';

    final sb = _clientOrNull();
    if (!isSupabaseConfigured || sb == null) {
      throw StorageUploadFailure(
        'Supabase is not configured. Add SUPABASE_URL and '
        'SUPABASE_PUBLISHABLE_KEY (or SUPABASE_ANON_KEY) to your build, then '
        'run the card-assets SQL setup.',
      );
    }

    try {
      await sb.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: guessMimeForFileName(fileName),
            ),
          );
      final url = sb.storage.from(_bucket).getPublicUrl(path);
      return CardAssetReceipt(url: url, path: path);
    } catch (e) {
      debugPrint('Image upload failed: $e');
      throw StorageUploadFailure(
        'Image upload failed. Check your connection and that the "$_bucket" '
        'bucket is configured, then try again.',
      );
    }
  }
}
