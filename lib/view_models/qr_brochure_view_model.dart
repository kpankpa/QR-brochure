import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/http_uri.dart';
import '../models/brochure_record.dart';
import '../models/digital_card.dart';
import '../models/source_kind.dart';
import '../services/brochure_catalog_service.dart';
import '../services/digital_card_service.dart';
import '../services/qr_downloader_stub.dart'
    if (dart.library.io) '../services/qr_downloader_io.dart'
    if (dart.library.js_interop) '../services/qr_downloader_web.dart'
    as qr_downloader;
import '../services/qr_downloader_stub.dart'
    if (dart.library.io) '../services/qr_downloader_io.dart'
    if (dart.library.js_interop) '../services/qr_downloader_web.dart'
    as card_downloader;
import '../services/qr_render_service.dart';
import '../services/storage_upload_service.dart';
import '../services/vcard_service.dart';

typedef UserNoticeCallback = void Function(String message);

enum ExpiryPreset { oneHour, oneDay, oneWeek, custom }

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
  ExpiryPreset expiryPreset = ExpiryPreset.oneDay;
  int customExpiryHours = 48;
  String? qrPayload;
  DigitalCard? selectedCard;
  bool selectedHistoryExpired = false;
  PlatformFile? pickedFile;

  /// Prepared PNG bytes used by the preview's `MemoryImage`.
  Uint8List? qrLogoBytes;

  /// Decoded image used by the high-resolution PNG renderer.
  ui.Image? qrLogoImage;
  bool loadingQrLogo = false;

  /// Fraction of the QR canvas used by the centred logo plate.
  double qrLogoFraction = QrRenderService.defaultLogoFraction;

  /// Classic squares are the default because they scan most reliably.
  QrModuleStyle qrModuleStyle = QrModuleStyle.classic;

  /// The preview is rendered at this exact resolution, so the downloaded PNG
  /// is pixel-for-pixel identical to what the user sees.
  int qrExportSize = QrRenderService.defaultSize;

  bool busy = false;
  String? urlError;

  static const pickExtensions = ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'gif'];

  void bindUserNotice(UserNoticeCallback callback) {
    onUserNotice = callback;
  }

  void unbindUserNotice() => onUserNotice = null;

  void _toast(String message) => onUserNotice?.call(message);

  void setSource(Set<SourceKind> selection) {
    if (selection.isEmpty) return;
    source = selection.first;
    urlError = null;
    qrPayload = null;
    pickedFile = null;
    selectedCard = null;
    selectedHistoryExpired = false;
    notifyListeners();
  }

  void setExpiryPreset(ExpiryPreset preset) {
    expiryPreset = preset;
    notifyListeners();
  }

  void setCustomExpiryDays(int days) {
    // Supabase signed URLs are capped at 7 days.
    final safeDays = days.clamp(1, 7);
    customExpiryHours = safeDays * 24;
    expiryPreset = ExpiryPreset.custom;
    notifyListeners();
  }

  /// Picks a logo, pads/resizes it, and prepares it for both preview and export.
  Future<void> pickQrLogo() async {
    loadingQrLogo = true;
    notifyListeners();

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      final bytes = result?.files.single.bytes;
      if (bytes == null || bytes.isEmpty) return;
      if (bytes.length > 5 * 1024 * 1024) {
        _toast('Logo is too large. Choose an image under 5 MB.');
        return;
      }

      final prepared = await QrRenderService.prepareLogoPng(bytes);
      qrLogoBytes = prepared;
      qrLogoImage = await decodeImageFromList(prepared);
      qrLogoFraction = QrRenderService.defaultLogoFraction;
      _toast('Logo added — centred and resized automatically.');
    } catch (e) {
      _toast('Could not add logo: $e');
    } finally {
      loadingQrLogo = false;
      notifyListeners();
    }
  }

  void clearQrLogo() {
    qrLogoBytes = null;
    qrLogoImage = null;
    qrLogoFraction = QrRenderService.defaultLogoFraction;
    notifyListeners();
    _toast('QR logo removed.');
  }

  void setQrLogoFraction(double value) {
    final next = QrRenderService.clampLogoFraction(value);
    if (next == qrLogoFraction) return;
    qrLogoFraction = next;
    notifyListeners();
  }

  void setQrModuleStyle(QrModuleStyle value) {
    if (value == qrModuleStyle) return;
    qrModuleStyle = value;
    notifyListeners();
  }

  void setQrExportSize(int pixels) {
    final next = QrRenderService.clampSize(pixels);
    if (next == qrExportSize) return;
    qrExportSize = next;
    notifyListeners();
  }

  int get expiryHours {
    switch (expiryPreset) {
      case ExpiryPreset.oneHour:
        return 1;
      case ExpiryPreset.oneDay:
        return 24;
      case ExpiryPreset.oneWeek:
        return 24 * 7;
      case ExpiryPreset.custom:
        return customExpiryHours;
    }
  }

  DateTime get expiryDate => DateTime.now().add(Duration(hours: expiryHours));

  String get expirySummary {
    switch (expiryPreset) {
      case ExpiryPreset.oneHour:
        return 'Active: 1 hour';
      case ExpiryPreset.oneDay:
        return 'Active: 1 day';
      case ExpiryPreset.oneWeek:
        return 'Active: 1 week';
      case ExpiryPreset.custom:
        final days = (customExpiryHours / 24).round();
        return 'Active: $days day${days == 1 ? '' : 's'}';
    }
  }

  void clearUrlError() {
    if (urlError == null) return;
    urlError = null;
    notifyListeners();
  }

  /// Loads a stored brochure URL into the QR preview (from history).
  void applyBrochureUrl(String downloadUrl) {
    _applyFilePayload(downloadUrl, expired: false);
  }

  void _applyFilePayload(String downloadUrl, {required bool expired}) {
    // Use the File source without calling setSource(), which clears qrPayload.
    source = SourceKind.file;
    urlError = null;
    pickedFile = null;
    selectedCard = null;
    selectedHistoryExpired = expired;
    if (downloadUrl.trim().isNotEmpty) {
      urlController.text = downloadUrl;
    }
    qrPayload = downloadUrl.trim().isEmpty ? null : downloadUrl;
    notifyListeners();
  }

  /// Clears a card selection that is no longer published.
  void clearSelectedCard() {
    selectedCard = null;
    qrPayload = null;
    selectedHistoryExpired = false;
    notifyListeners();
  }

  /// Uses a published digital card as the QR payload.
  void useDigitalCard(DigitalCard card) {
    selectedCard = card;
    qrPayload = DigitalCardService.cardUrl(card.publicSlug);
    selectedHistoryExpired = false;
    notifyListeners();
  }

  Future<void> downloadSelectedVCard() async {
    final card = selectedCard;
    if (card == null) return;
    final safeName = card.displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    try {
      final ok = await card_downloader.saveTextFile(
        VcardService.build(card),
        '${safeName.isEmpty ? 'contact' : safeName}.vcf',
      );
      _toast(ok ? 'Contact file saved' : 'Could not save contact file');
    } catch (e) {
      debugPrint('Could not save contact file: $e');
      _toast('Could not save contact file. Please try again.');
    }
  }

  Future<void> createQrFromUrl() async {
    final uri = parseHttpUrl(urlController.text);
    urlError = uri == null ? 'Enter a valid http(s) URL' : null;
    notifyListeners();
    if (uri == null) return;

    qrPayload = uri.toString();
    selectedCard = null;
    selectedHistoryExpired = false;
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
    selectedCard = null;
    selectedHistoryExpired = false;
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
        expiresInSeconds: expiryHours * 3600,
      );
      qrPayload = receipt.downloadUrl;
      selectedCard = null;
      selectedHistoryExpired = false;
      try {
        final expiresAt = DateTime.now().add(Duration(hours: expiryHours));
        await _catalog.recordUpload(
          userId: receipt.uid,
          downloadUrl: receipt.downloadUrl,
          fileName: file.name,
          objectPath: receipt.objectPath,
          expiresAt: expiresAt,
          expiryHours: expiryHours,
        );
      } catch (_) {
        _toast(
          'Uploaded, but history could not be saved. '
          'Deploy Firestore rules and enable Firestore.',
        );
      }
    } on StorageUploadFailure catch (e) {
      _toast('Upload failed: $e');
    } catch (e) {
      debugPrint('Unexpected upload failure: $e');
      _toast('Upload failed. Please check your connection and try again.');
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

  Future<void> downloadQrCode({int? size}) async {
    final payload = qrPayload;
    if (payload == null) return;

    final outputSize = QrRenderService.clampSize(size ?? qrExportSize);
    try {
      final png = await QrRenderService.renderPng(
        payload: payload,
        logo: qrLogoImage,
        size: outputSize,
        logoFraction: qrLogoFraction,
        style: qrModuleStyle,
      );
      if (png == null) {
        _toast('Could not render QR image.');
        return;
      }

      final ok = await qr_downloader.saveQrPng(
        png,
        'qr_brochure_${outputSize}px_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      _toast(ok ? 'QR code downloaded' : 'Download canceled');
    } catch (_) {
      _toast('Could not download QR code.');
    }
  }

  /// Returns true only when a usable QR payload was actually loaded.
  Future<bool> useBrochureFromHistory(BrochureRecord record) async {
    selectedCard = null;
    if (record.isExpired) {
      _applyFilePayload(record.downloadUrl, expired: true);
      _toast('This QR link has expired.');
      return false;
    }

    if (record.objectPath.isEmpty) {
      // Legacy record fallback.
      if (record.downloadUrl.trim().isEmpty) return false;
      _applyFilePayload(record.downloadUrl, expired: false);
      return true;
    }

    final expiresAt = record.expiresAt;
    if (expiresAt == null) {
      if (record.downloadUrl.trim().isEmpty) return false;
      _applyFilePayload(record.downloadUrl, expired: false);
      return true;
    }

    final remainingSeconds = expiresAt.difference(DateTime.now()).inSeconds;
    if (remainingSeconds <= 0) {
      _applyFilePayload(record.downloadUrl, expired: true);
      _toast('This QR link has expired.');
      return false;
    }

    qrPayload = null;
    selectedHistoryExpired = true;
    notifyListeners();
    try {
      final signedUrl = await _storage.createSignedDownloadUrl(
        objectPath: record.objectPath,
        expiresInSeconds: remainingSeconds,
      );
      if (signedUrl.trim().isEmpty) return false;
      _applyFilePayload(signedUrl, expired: false);
      return true;
    } on StorageUploadFailure catch (e) {
      _toast(e.message);
    } catch (e) {
      debugPrint('Could not refresh signed URL: $e');
      _toast('Could not refresh that link. Please try again.');
    }
    return false;
  }

  @override
  void dispose() {
    onUserNotice = null;
    urlController.dispose();
    super.dispose();
  }
}
