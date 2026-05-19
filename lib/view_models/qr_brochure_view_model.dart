import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/http_uri.dart';
import '../models/source_kind.dart';
import '../services/brochure_catalog_service.dart';
import '../services/qr_downloader_stub.dart'
    if (dart.library.io) '../services/qr_downloader_io.dart'
    if (dart.library.html) '../services/qr_downloader_web.dart'
    as qr_downloader;
import '../services/storage_upload_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

typedef UserNoticeCallback = void Function(String message);

/// ViewModel for the QR Brochure workspace (MVVM).
class QrBrochureViewModel extends ChangeNotifier {
  QrBrochureViewModel({
    StorageUploadService? storageUploadService,
    BrochureCatalogService? brochureCatalogService,
  }) : _storage = storageUploadService ?? StorageUploadService(),
       _catalog = brochureCatalogService ?? BrochureCatalogService();

  final StorageUploadService _storage;
  final BrochureCatalogService _catalog;

  final TextEditingController urlController = TextEditingController();

  UserNoticeCallback? onUserNotice;

  SourceKind source = SourceKind.link;
  String? qrPayload;
  PlatformFile? pickedFile;
  bool busy = false;
  String? urlError;

  static const pickExtensions = ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'gif'];

  void bindUserNotice(UserNoticeCallback callback) {
    onUserNotice = callback;
  }

  void _toast(String message) => onUserNotice?.call(message);

  void setSource(Set<SourceKind> selection) {
    source = selection.first;
    urlError = null;
    notifyListeners();
  }

  void clearUrlError() {
    if (urlError == null) return;
    urlError = null;
    notifyListeners();
  }

  /// Loads a stored brochure URL into the QR preview (from history).
  void applyBrochureUrl(String downloadUrl) {
    qrPayload = downloadUrl;
    notifyListeners();
  }

  Future<void> createQrFromUrl() async {
    final uri = parseHttpUrl(urlController.text);
    urlError = uri == null ? 'Enter a valid http(s) URL' : null;
    notifyListeners();
    if (uri == null) return;

    qrPayload = uri.toString();
    notifyListeners();

    if (uri.scheme == 'http') {
      _toast('Using http — prefer https for QR codes when possible.');
    }
  }

  Future<void> pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: pickExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    pickedFile = result.files.single;
    qrPayload = null;
    notifyListeners();
  }

  Future<void> uploadAndCreateQr() async {
    final file = pickedFile;
    if (file == null || file.bytes == null) {
      _toast('Could not read file. Try picking again.');
      return;
    }

    busy = true;
    notifyListeners();
    try {
      final receipt = await _storage.uploadUserBytes(
        bytes: file.bytes!,
        fileName: file.name,
      );
      qrPayload = receipt.downloadUrl;
      try {
        await _catalog.recordUpload(
          userId: receipt.uid,
          downloadUrl: receipt.downloadUrl,
          fileName: file.name,
        );
      } catch (_) {
        _toast(
          'Uploaded, but history could not be saved. '
          'Deploy Firestore rules and enable Firestore.',
        );
      }
    } on StorageUploadFailure catch (e) {
      _toast('Upload failed: $e');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> openQrPayloadExternally() async {
    final payload = qrPayload;
    if (payload == null) return;
    final uri = Uri.tryParse(payload);
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _toast('Could not open link.');
    }
  }

  Future<void> copyQrPayload() async {
    final payload = qrPayload;
    if (payload == null) return;
    await Clipboard.setData(ClipboardData(text: payload));
    _toast('Copied to clipboard');
  }

  Future<void> downloadQrCode() async {
    final payload = qrPayload;
    if (payload == null) return;

    try {
      final painter = QrPainter(
        data: payload,
        version: QrVersions.auto,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      );

      final byteData = await painter.toImageData(
        1024,
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        _toast('Could not render QR image.');
        return;
      }

      final ok = await qr_downloader.saveQrPng(
        byteData.buffer.asUint8List(),
        'qr_brochure_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      _toast(ok ? 'QR code downloaded' : 'Download canceled');
    } catch (_) {
      _toast('Could not download QR code.');
    }
  }

  @override
  void dispose() {
    onUserNotice = null;
    urlController.dispose();
    super.dispose();
  }
}
