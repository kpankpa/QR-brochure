import 'package:flutter/material.dart';

import '../models/card_icon.dart';
import '../models/digital_card.dart';
import '../services/card_asset_upload_service.dart';
import '../services/digital_card_service.dart';

typedef CardNoticeCallback = void Function(String message);

/// Editor state for a single digital business card.
class DigitalCardViewModel extends ChangeNotifier {
  DigitalCardViewModel({
    DigitalCard? card,
    DigitalCardService? service,
    CardAssetUploadService? assetService,
  }) : _service = service ?? DigitalCardService(),
       _assetService = assetService ?? CardAssetUploadService() {
    for (final key in _fieldKeys) {
      _controllers[key] = TextEditingController();
    }
    // Initialise synchronously without notifying: this constructor runs while
    // the ChangeNotifierProvider is still mounting. Calling notifyListeners()
    // here marks the provider dirty mid-build and leaves the route blank.
    _applyCard(card);
  }

  static const List<String> _fieldKeys = <String>[
    'fullName',
    'jobTitle',
    'companyName',
    'companyWebsite',
    'photoUrl',
    'logoUrl',
    'primaryPhone',
    'secondaryPhone',
    'whatsapp',
    'primaryEmail',
    'secondaryEmail',
    'street',
    'city',
    'state',
    'postalCode',
    'country',
    'website',
    'linkedin',
    'instagram',
    'twitter',
    'facebook',
    'summary',
    'brandColor',
  ];

  final DigitalCardService _service;
  final CardAssetUploadService _assetService;
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  String? editingId;
  String slug = '';
  String iconName = CardIcons.defaultName;
  bool isPublished = false;
  bool busy = false;
  bool uploadingPhoto = false;
  bool uploadingLogo = false;
  String? error;

  bool get isUploadingImage => uploadingPhoto || uploadingLogo;
  CardNoticeCallback? onNotice;

  TextEditingController controller(String key) => _controllers[key]!;

  void bindNotice(CardNoticeCallback callback) => onNotice = callback;

  void unbindNotice() => onNotice = null;

  void _notice(String message) => onNotice?.call(message);

  /// Reloads the editor with a different card (notifies listeners).
  void load(DigitalCard? card) {
    _applyCard(card);
    notifyListeners();
  }

  void _applyCard(DigitalCard? card) {
    final values = <String, String>{
      'fullName': card?.fullName ?? '',
      'jobTitle': card?.jobTitle ?? '',
      'companyName': card?.companyName ?? '',
      'companyWebsite': card?.companyWebsite ?? '',
      'photoUrl': card?.photoUrl ?? '',
      'logoUrl': card?.logoUrl ?? '',
      'primaryPhone': card?.primaryPhone ?? '',
      'secondaryPhone': card?.secondaryPhone ?? '',
      'whatsapp': card?.whatsapp ?? '',
      'primaryEmail': card?.primaryEmail ?? '',
      'secondaryEmail': card?.secondaryEmail ?? '',
      'street': card?.street ?? '',
      'city': card?.city ?? '',
      'state': card?.state ?? '',
      'postalCode': card?.postalCode ?? '',
      'country': card?.country ?? '',
      'website': card?.website ?? '',
      'linkedin': card?.linkedin ?? '',
      'instagram': card?.instagram ?? '',
      'twitter': card?.twitter ?? '',
      'facebook': card?.facebook ?? '',
      'summary': card?.summary ?? '',
      'brandColor': card == null ? '#2E6AE6' : hexColor(card.brandColorValue),
    };
    for (final entry in values.entries) {
      _controllers[entry.key]!.text = entry.value;
    }
    editingId = card?.id;
    slug = card?.slug ?? '';
    iconName = card?.iconName ?? CardIcons.defaultName;
    isPublished = card?.isPublished ?? false;
    uploadingPhoto = false;
    uploadingLogo = false;
    error = null;
  }

  static String hexColor(int argb) {
    final rgb = argb & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static int? parseColor(String input) {
    final cleaned = input.trim().replaceAll('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return 0xFF000000 | value;
  }

  void selectIcon(String name) {
    iconName = name;
    notifyListeners();
  }

  void setBrandColor(Color color) {
    _controllers['brandColor']!.text = hexColor(color.toARGB32());
    notifyListeners();
  }

  void removeImage(String key) {
    _controllers[key]!.text = '';
    notifyListeners();
  }

  /// Picks and uploads a profile photo or company logo, then stores the public
  /// URL in the matching form field.
  Future<void> uploadImage(String key, {required String uid}) async {
    final isPhoto = key == 'photoUrl';
    if (!isPhoto && key != 'logoUrl') return;

    void setBusy(bool value) {
      if (isPhoto) {
        uploadingPhoto = value;
      } else {
        uploadingLogo = value;
      }
    }

    setBusy(true);
    error = null;
    notifyListeners();

    try {
      final receipt = await _assetService.pickAndUpload(
        uid: uid,
        kind: isPhoto ? CardAssetKind.profile : CardAssetKind.logo,
      );
      if (receipt == null) return;
      _controllers[key]!.text = receipt.url;
      _notice(isPhoto ? 'Profile photo uploaded.' : 'Company logo uploaded.');
    } catch (e) {
      error = e.toString();
      _notice(error!);
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  String _text(String key) => _controllers[key]!.text.trim();

  DigitalCard buildCard(String uid) {
    return DigitalCard(
      id: editingId ?? '',
      ownerId: uid,
      slug: slug,
      fullName: _text('fullName'),
      jobTitle: _text('jobTitle'),
      companyName: _text('companyName'),
      companyWebsite: _text('companyWebsite'),
      photoUrl: _text('photoUrl'),
      logoUrl: _text('logoUrl'),
      primaryPhone: _text('primaryPhone'),
      secondaryPhone: _text('secondaryPhone'),
      whatsapp: _text('whatsapp'),
      primaryEmail: _text('primaryEmail'),
      secondaryEmail: _text('secondaryEmail'),
      street: _text('street'),
      city: _text('city'),
      state: _text('state'),
      postalCode: _text('postalCode'),
      country: _text('country'),
      website: _text('website'),
      linkedin: _text('linkedin'),
      instagram: _text('instagram'),
      twitter: _text('twitter'),
      facebook: _text('facebook'),
      summary: _text('summary'),
      iconName: iconName,
      brandColorValue: parseColor(_text('brandColor')) ?? 0xFF2E6AE6,
      isPublished: isPublished,
    );
  }

  String? _validationError() {
    if (_text('fullName').isEmpty) {
      return 'Please enter a name for the card.';
    }
    if (parseColor(_text('brandColor')) == null) {
      return 'Brand colour must be a 6-digit hex value, for example #2E6AE6.';
    }
    for (final key in ['primaryEmail', 'secondaryEmail']) {
      final value = _text(key);
      if (value.isNotEmpty &&
          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
        return 'Enter a valid $key address.';
      }
    }
    for (final key in [
      'website',
      'companyWebsite',
      'linkedin',
      'instagram',
      'twitter',
      'facebook',
    ]) {
      final value = _text(key);
      if (value.isEmpty) continue;
      final uri = Uri.tryParse(value);
      if (uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.host.isEmpty) {
        return 'Enter a valid http(s) URL for $key.';
      }
    }
    for (final key in ['primaryPhone', 'secondaryPhone', 'whatsapp']) {
      final value = _text(key);
      if (value.isEmpty) continue;
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 7 || digits.length > 15) {
        return 'Enter a valid phone number for $key.';
      }
    }
    return null;
  }

  /// Saves the card. When [publish] is true also mirrors it to `publicCards`
  /// and returns the slug used in `/c/{slug}`.
  Future<String?> save({required String uid, required bool publish}) async {
    if (uid.trim().isEmpty) {
      error = 'You must be signed in to create a card.';
      _notice(error!);
      notifyListeners();
      return null;
    }
    final validationError = _validationError();
    if (validationError != null) {
      error = validationError;
      _notice(error!);
      notifyListeners();
      return null;
    }

    busy = true;
    error = null;
    notifyListeners();

    try {
      final card = buildCard(uid);
      if (publish) {
        final result = await _service.publish(uid: uid, card: card);
        editingId = result.id;
        slug = result.slug;
        isPublished = true;
        notifyListeners();
        _notice('Card published: ${DigitalCardService.cardUrl(result.slug)}');
        return result.slug;
      }

      final wasPublished = isPublished;
      editingId = await _service.saveCard(uid: uid, card: card);
      notifyListeners();
      _notice(wasPublished ? 'Published card updated.' : 'Draft saved.');
      return null;
    } catch (e) {
      error = 'Could not save card: $e';
      _notice(error!);
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    onNotice = null;
    super.dispose();
  }
}
