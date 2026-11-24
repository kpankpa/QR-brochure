import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Saves PNG bytes through the platform save dialog.
///
/// `file_picker` 11 requires `bytes` on Android/iOS and writes the file itself
/// on desktop, so no manual [File.writeAsBytes] call is needed.
Future<bool> saveQrPng(Uint8List bytes, String suggestedName) async {
  final path = await FilePicker.saveFile(
    dialogTitle: 'Save QR code',
    fileName: suggestedName,
    type: FileType.custom,
    allowedExtensions: const ['png'],
    bytes: bytes,
  );
  return path != null && path.isNotEmpty;
}

/// Saves a generated vCard as a `.vcf` file.
Future<bool> saveTextFile(String content, String suggestedName) async {
  final bytes = Uint8List.fromList(utf8.encode(content));
  final path = await FilePicker.saveFile(
    dialogTitle: 'Save contact',
    fileName: suggestedName,
    type: FileType.custom,
    allowedExtensions: const ['vcf'],
    bytes: bytes,
  );
  return path != null && path.isNotEmpty;
}
