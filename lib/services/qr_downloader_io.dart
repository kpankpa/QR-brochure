import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> saveQrPng(Uint8List bytes, String suggestedName) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save QR code',
    fileName: suggestedName,
    type: FileType.custom,
    allowedExtensions: const ['png'],
  );
  if (path == null || path.isEmpty) return false;

  final out = File(path);
  await out.writeAsBytes(bytes, flush: true);
  return true;
}
