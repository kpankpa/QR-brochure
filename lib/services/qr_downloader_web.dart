import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> saveQrPng(Uint8List bytes, String suggestedName) async {
  final href = 'data:image/png;base64,${base64Encode(bytes)}';
  final anchor =
      html.AnchorElement()
        ..href = href
        ..download = suggestedName
        ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return true;
}
