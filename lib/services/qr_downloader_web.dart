import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Saves bytes with a Blob URL instead of a base64 data URL so large QR images
/// are not limited by browser data-URL length restrictions.
Future<bool> _download({
  required JSAny part,
  required String mimeType,
  required String suggestedName,
}) async {
  final body = web.document.body;
  if (body == null) return false;

  final parts = <JSAny>[part].toJS;
  final blob = web.Blob(parts, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = suggestedName;
  anchor.style.display = 'none';
  body.appendChild(anchor);
  anchor.click();
  anchor.remove();

  // Revoking immediately races the browser's download start in Firefox/Safari.
  Future<void>.delayed(
    const Duration(seconds: 2),
    () => web.URL.revokeObjectURL(url),
  );
  return true;
}

Future<bool> saveQrPng(Uint8List bytes, String suggestedName) {
  return _download(
    part: bytes.toJS,
    mimeType: 'image/png',
    suggestedName: suggestedName,
  );
}

/// Saves a generated vCard as a `.vcf` file.
Future<bool> saveTextFile(String content, String suggestedName) {
  return _download(
    part: content.toJS,
    mimeType: 'text/vcard;charset=utf-8',
    suggestedName: suggestedName,
  );
}
