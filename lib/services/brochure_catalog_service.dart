import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/brochure_record.dart';

/// Persists and streams upload metadata per Firebase Auth user.
class BrochureCatalogService {
  FirebaseFirestore? _firestoreOrNull() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> recordUpload({
    required String userId,
    required String downloadUrl,
    required String fileName,
  }) async {
    final fs = _firestoreOrNull();
    if (fs == null) return;
    await fs.collection('users').doc(userId).collection('brochures').add({
      'downloadUrl': downloadUrl,
      'fileName': fileName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<BrochureRecord>> watchBrochures(String userId) {
    final fs = _firestoreOrNull();
    if (fs == null) {
      return const Stream<List<BrochureRecord>>.empty();
    }
    return fs
        .collection('users')
        .doc(userId)
        .collection('brochures')
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(BrochureRecord.fromSnapshot)
              .toList(growable: false),
        );
  }
}
