import 'package:cloud_firestore/cloud_firestore.dart';

class BrochureRecord {
  BrochureRecord({
    required this.id,
    required this.downloadUrl,
    required this.fileName,
    required this.objectPath,
    this.createdAt,
    this.expiresAt,
    this.expiryHours,
  });

  final String id;
  final String downloadUrl;
  final String fileName;
  final String objectPath;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final int? expiryHours;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory BrochureRecord.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return BrochureRecord(
      id: doc.id,
      downloadUrl: data['downloadUrl'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      objectPath: data['objectPath'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      expiryHours: data['expiryHours'] as int?,
    );
  }
}
