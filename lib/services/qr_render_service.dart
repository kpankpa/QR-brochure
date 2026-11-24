import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Module shape used when drawing the QR matrix.
enum QrModuleStyle {
  /// Crisp standard squares — scans most reliably in every reader.
  classic,

  /// Softly rounded squares and finder eyes for a modern look.
  modern,
}

/// A selectable output resolution for downloaded QR images.
class QrSizeOption {
  const QrSizeOption({
    required this.label,
    required this.pixels,
    required this.detail,
  });

  final String label;
  final int pixels;
  final String detail;
}

/// Renders QR codes with clean, predictable output.
///
/// The preview and the downloaded PNG use this same renderer at the same
/// resolution, so the exported file is identical to what is shown on screen.
/// PNGs are tagged at 300 DPI so they open at a sensible physical size in
/// Word, WhatsApp, email and print dialogs instead of appearing enormous.
class QrRenderService {
  static const int defaultSize = 1024;

  static const List<QrSizeOption> sizeOptions = <QrSizeOption>[
    QrSizeOption(
      label: 'Web / screen',
      pixels: 512,
      detail: '512 × 512 px · chat, email, social',
    ),
    QrSizeOption(
      label: 'Print / share',
      pixels: 1024,
      detail: '1024 × 1024 px · recommended',
    ),
    QrSizeOption(
      label: 'High resolution',
      pixels: 2048,
      detail: '2048 × 2048 px · large print & signage',
    ),
  ];

  static const double defaultLogoFraction = 0.22;
  static const double minLogoFraction = 0.16;
  static const double maxLogoFraction = 0.32;

  static const int quietZoneModules = 4;
  static const int logoCanvas = 512;
  static const int exportDpi = 300;

  static const Color ink = Color(0xFF0B1220);
  static const Color plateBorder = Color(0x220B1220);

  static int clampSize(int size) => size.clamp(256, 4096);

  static double clampLogoFraction(double value) =>
      value.clamp(minLogoFraction, maxLogoFraction);

  /// Renders a square PNG tagged at [exportDpi].
  static Future<Uint8List?> renderPng({
    required String payload,
    ui.Image? logo,
    int size = defaultSize,
    double logoFraction = defaultLogoFraction,
    QrModuleStyle style = QrModuleStyle.classic,
  }) async {
    final output = clampSize(size);
    final matrix = QrImage(
      QrCode.fromData(
        data: payload,
        errorCorrectLevel:
            logo != null ? QrErrorCorrectLevel.H : QrErrorCorrectLevel.Q,
      ),
    );

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    _draw(canvas, matrix, logo, output, clampLogoFraction(logoFraction), style);

    final picture = recorder.endRecording();
    ui.Image? image;
    try {
      image = await picture.toImage(output, output);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      return withDpi(bytes.buffer.asUint8List(), exportDpi);
    } finally {
      image?.dispose();
      picture.dispose();
    }
  }

  static void _draw(
    ui.Canvas canvas,
    QrImage matrix,
    ui.Image? logo,
    int size,
    double logoFraction,
    QrModuleStyle style,
  ) {
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      ui.Paint()..color = Colors.white,
    );

    final count = matrix.moduleCount;
    final total = count + quietZoneModules * 2;
    final unit = size / total;
    final origin = quietZoneModules * unit;

    final inkPaint =
        ui.Paint()
          ..color = ink
          ..isAntiAlias = true;

    ui.Rect cell(int col, int row, [int span = 1]) {
      return ui.Rect.fromLTRB(
        (origin + col * unit).roundToDouble(),
        (origin + row * unit).roundToDouble(),
        (origin + (col + span) * unit).roundToDouble(),
        (origin + (row + span) * unit).roundToDouble(),
      );
    }

    void shape(ui.Rect rect, double radius) {
      if (radius <= 0) {
        canvas.drawRect(rect, inkPaint);
      } else {
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(radius)),
          inkPaint,
        );
      }
    }

    bool inFinder(int row, int col) {
      bool box(int r, int c) =>
          row >= r && row < r + 7 && col >= c && col < c + 7;
      return box(0, 0) || box(0, count - 7) || box(count - 7, 0);
    }

    final moduleRadius = style == QrModuleStyle.modern ? unit * 0.22 : 0.0;
    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (matrix.isDark(row, col) && !inFinder(row, col)) {
          shape(cell(col, row), moduleRadius);
        }
      }
    }

    void finder(int row, int col) {
      final outerRadius = style == QrModuleStyle.modern ? unit * 7 * 0.12 : 0.0;
      shape(cell(col, row, 7), outerRadius);

      final white = ui.Paint()..color = Colors.white;
      final whiteRect = cell(col + 1, row + 1, 5);
      if (outerRadius > 0) {
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            whiteRect,
            ui.Radius.circular(unit * 5 * 0.10),
          ),
          white,
        );
      } else {
        canvas.drawRect(whiteRect, white);
      }
      shape(cell(col + 2, row + 2, 3), 0);
    }

    finder(0, 0);
    finder(0, count - 7);
    finder(count - 7, 0);

    if (logo != null) {
      _drawLogoPlate(canvas, logo, size, logoFraction);
    }
  }

  static void _drawLogoPlate(
    ui.Canvas canvas,
    ui.Image logo,
    int size,
    double logoFraction,
  ) {
    final plate = size * logoFraction;
    final rect = ui.Rect.fromLTWH(
      (size - plate) / 2,
      (size - plate) / 2,
      plate,
      plate,
    );
    final shape = ui.RRect.fromRectAndRadius(
      rect,
      ui.Radius.circular(plate * 0.16),
    );

    canvas.drawRRect(shape, ui.Paint()..color = Colors.white);
    canvas.drawRRect(
      shape,
      ui.Paint()
        ..color = plateBorder
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, size / 512),
    );

    final maxLogo = plate * 0.70;
    final scale = math.min(maxLogo / logo.width, maxLogo / logo.height);
    final width = logo.width * scale;
    final height = logo.height * scale;
    canvas.drawImageRect(
      logo,
      ui.Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
      ui.Rect.fromLTWH((size - width) / 2, (size - height) / 2, width, height),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
  }

  /// Normalises any uploaded logo to a transparent, aspect-correct PNG.
  static Future<Uint8List> prepareLogoPng(Uint8List sourceBytes) async {
    final source = await decodeImageFromList(sourceBytes);
    ui.Image? prepared;
    ui.Picture? picture;
    try {
      final size = logoCanvas.toDouble();
      final longest =
          source.width > source.height
              ? source.width.toDouble()
              : source.height.toDouble();
      final scale = longest > 0 ? size / longest : 1.0;
      final width = source.width * scale;
      final height = source.height * scale;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        source,
        ui.Rect.fromLTWH(
          0,
          0,
          source.width.toDouble(),
          source.height.toDouble(),
        ),
        ui.Rect.fromLTWH(
          (size - width) / 2,
          (size - height) / 2,
          width,
          height,
        ),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );

      picture = recorder.endRecording();
      prepared = await picture.toImage(logoCanvas, logoCanvas);
      final bytes = await prepared.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Could not encode the prepared logo image.');
      }
      return bytes.buffer.asUint8List();
    } finally {
      prepared?.dispose();
      picture?.dispose();
      source.dispose();
    }
  }

  /// Adds or replaces the pHYs chunk so viewers use a sensible physical size.
  static Uint8List withDpi(Uint8List png, int dpi) {
    const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
    if (png.length < 33) return png;
    for (var i = 0; i < signature.length; i++) {
      if (png[i] != signature[i]) return png;
    }

    final pixelsPerMetre = (dpi / 0.0254).round();
    final body = <int>[..._be32(pixelsPerMetre), ..._be32(pixelsPerMetre), 1];
    final type = <int>[0x70, 0x48, 0x59, 0x73]; // pHYs
    final chunk = <int>[
      ..._be32(body.length),
      ...type,
      ...body,
      ..._be32(_crc32(<int>[...type, ...body])),
    ];

    var offset = signature.length;
    var insertAt = -1;
    var existingStart = -1;
    var existingEnd = -1;
    while (offset + 12 <= png.length) {
      final length = _readBe32(png, offset);
      if (length < 0 || offset + 12 + length > png.length) return png;
      final chunkType = png.sublist(offset + 4, offset + 8);
      final chunkEnd = offset + 12 + length;
      if (_isChunkType(chunkType, const <int>[0x49, 0x48, 0x44, 0x52]) &&
          insertAt < 0) {
        // Insert immediately after IHDR.
        insertAt = chunkEnd;
      }
      if (_isChunkType(chunkType, type)) {
        existingStart = offset;
        existingEnd = chunkEnd;
        break;
      }
      if (_isChunkType(chunkType, const <int>[0x49, 0x44, 0x41, 0x54])) {
        // pHYs must come before IDAT.
        break;
      }
      offset = chunkEnd;
    }

    if (existingStart >= 0) {
      return Uint8List.fromList(<int>[
        ...png.sublist(0, existingStart),
        ...chunk,
        ...png.sublist(existingEnd),
      ]);
    }
    if (insertAt < 0) return png;
    return Uint8List.fromList(<int>[
      ...png.sublist(0, insertAt),
      ...chunk,
      ...png.sublist(insertAt),
    ]);
  }

  static bool _isChunkType(List<int> actual, List<int> expected) {
    for (var i = 0; i < expected.length; i++) {
      if (actual[i] != expected[i]) return false;
    }
    return true;
  }

  static int _readBe32(List<int> bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];

  static List<int> _be32(int value) => <int>[
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];

  static int _crc32(List<int> bytes) {
    var crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    return crc ^ 0xFFFFFFFF;
  }
}
