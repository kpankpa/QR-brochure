import 'package:cloud_firestore/cloud_firestore.dart';

class BrochureRecord {
  BrochureRecord({
    required this.id,
    required this.downloadUrl,
    required this.fileName,
    this.createdAt,
  });

  final String id;
  final String downloadUrl;
  final String fileName;
  final DateTime? createdAt;

  factory BrochureRecord.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return BrochureRecord(
      id: doc.id,
      downloadUrl: data['downloadUrl'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
