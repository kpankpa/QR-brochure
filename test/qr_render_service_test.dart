import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qr_brochure/services/qr_render_service.dart';

void main() {
  test('renderPng exports the selected size with 300 DPI metadata', () async {
    for (final option in QrRenderService.sizeOptions) {
      final png = await QrRenderService.renderPng(
        payload: 'https://wbc-qr.web.app/c/test-card',
        size: option.pixels,
      );

      expect(png, isNotNull);
      final chunks = _pngChunks(png!);
      final ihdr = chunks['IHDR']!;
      final phys = chunks['pHYs'];

      expect(_readUint32(ihdr, 0), option.pixels);
      expect(_readUint32(ihdr, 4), option.pixels);
      expect(phys, isNotNull, reason: '${option.label} is missing pHYs');
      expect(_readUint32(phys!, 0), 11811); // 300 DPI in pixels/metre
      expect(_readUint32(phys, 4), 11811);
      expect(phys[8], 1); // unit specifier: metre
    }
  });

  test('classic and modern styles render distinct images', () async {
    const payload = 'https://wbc-qr.web.app/c/test-card';
    final classic = await QrRenderService.renderPng(
      payload: payload,
      style: QrModuleStyle.classic,
    );
    final modern = await QrRenderService.renderPng(
      payload: payload,
      style: QrModuleStyle.modern,
    );

    expect(classic, isNotNull);
    expect(modern, isNotNull);
    expect(_bytesEqual(classic!, modern!), isFalse);
  });
}

Map<String, Uint8List> _pngChunks(Uint8List png) {
  const signature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  for (var i = 0; i < signature.length; i++) {
    expect(png[i], signature[i]);
  }

  final chunks = <String, Uint8List>{};
  var offset = signature.length;
  while (offset + 12 <= png.length) {
    final length = _readUint32(png, offset);
    final type = String.fromCharCodes(png.sublist(offset + 4, offset + 8));
    final dataOffset = offset + 8;
    chunks[type] = png.sublist(dataOffset, dataOffset + length);
    offset = dataOffset + length + 4; // skip CRC
    if (type == 'IEND') break;
  }
  return chunks;
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int _readUint32(Uint8List bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];
