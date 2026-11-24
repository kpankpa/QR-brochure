import 'package:cloud_firestore/cloud_firestore.dart';

/// A digital business card.
///
/// Private editor copies live at `users/{uid}/cards/{cardId}`. When published,
/// a sanitized public snapshot is mirrored to `publicCards/{slug}` and read by
/// the `/c/{slug}` page without requiring sign-in.
class DigitalCard {
  const DigitalCard({
    required this.id,
    required this.ownerId,
    this.slug = '',
    this.fullName = '',
    this.jobTitle = '',
    this.companyName = '',
    this.companyWebsite = '',
    this.photoUrl = '',
    this.logoUrl = '',
    this.primaryPhone = '',
    this.secondaryPhone = '',
    this.whatsapp = '',
    this.primaryEmail = '',
    this.secondaryEmail = '',
    this.street = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.country = '',
    this.website = '',
    this.linkedin = '',
    this.instagram = '',
    this.twitter = '',
    this.facebook = '',
    this.summary = '',
    this.iconName = 'business',
    this.brandColorValue = 0xFF2E6AE6,
    this.isPublished = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String slug;
  final String fullName;
  final String jobTitle;
  final String companyName;
  final String companyWebsite;
  final String photoUrl;
  final String logoUrl;
  final String primaryPhone;
  final String secondaryPhone;
  final String whatsapp;
  final String primaryEmail;
  final String secondaryEmail;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String website;
  final String linkedin;
  final String instagram;
  final String twitter;
  final String facebook;
  final String summary;
  final String iconName;
  final int brandColorValue;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName =>
      fullName.trim().isEmpty ? 'Untitled card' : fullName.trim();

  /// The public `/c/{slug}` path exists only for published cards. Drafts must
  /// never return their private document id here — that would generate broken
  /// links and QR codes.
  String get publicSlug => isPublished && slug.isNotEmpty ? slug : '';

  String get initials {
    final parts = displayName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  String get mapUrl {
    final parts = [
      street,
      city,
      state,
      postalCode,
      country,
    ].map((p) => p.trim()).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(parts.join(', '))}';
  }

  String get addressLine {
    final parts = [
      street,
      city,
      state,
      postalCode,
      country,
    ].map((p) => p.trim()).where((p) => p.isNotEmpty);
    return parts.join(', ');
  }

  bool get hasAddress => addressLine.isNotEmpty;

  DigitalCard copyWith({
    String? id,
    String? ownerId,
    String? slug,
    bool? isPublished,
    DateTime? updatedAt,
  }) {
    return DigitalCard(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      slug: slug ?? this.slug,
      fullName: fullName,
      jobTitle: jobTitle,
      companyName: companyName,
      companyWebsite: companyWebsite,
      photoUrl: photoUrl,
      logoUrl: logoUrl,
      primaryPhone: primaryPhone,
      secondaryPhone: secondaryPhone,
      whatsapp: whatsapp,
      primaryEmail: primaryEmail,
      secondaryEmail: secondaryEmail,
      street: street,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
      website: website,
      linkedin: linkedin,
      instagram: instagram,
      twitter: twitter,
      facebook: facebook,
      summary: summary,
      iconName: iconName,
      brandColorValue: brandColorValue,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DigitalCard.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    // Public snapshots store the private card id in `id`. Falling back to the
    // document id would make the slug look like a card id for old snapshots.
    final storedId = _string(data['id']);
    return DigitalCard(
      id: storedId.isNotEmpty ? storedId : doc.id,
      ownerId: _string(data['ownerId']),
      slug: _string(data['slug']),
      fullName: _string(data['fullName']),
      jobTitle: _string(data['jobTitle']),
      companyName: _string(data['companyName']),
      companyWebsite: _string(data['companyWebsite']),
      photoUrl: _string(data['photoUrl']),
      logoUrl: _string(data['logoUrl']),
      primaryPhone: _string(data['primaryPhone']),
      secondaryPhone: _string(data['secondaryPhone']),
      whatsapp: _string(data['whatsapp']),
      primaryEmail: _string(data['primaryEmail']),
      secondaryEmail: _string(data['secondaryEmail']),
      street: _string(data['street']),
      city: _string(data['city']),
      state: _string(data['state']),
      postalCode: _string(data['postalCode']),
      country: _string(data['country']),
      website: _string(data['website']),
      linkedin: _string(data['linkedin']),
      instagram: _string(data['instagram']),
      twitter: _string(data['twitter']),
      facebook: _string(data['facebook']),
      summary: _string(data['summary']),
      iconName:
          _string(data['iconName']).isEmpty
              ? 'business'
              : _string(data['iconName']),
      brandColorValue: _color(data['brandColorValue']),
      isPublished: _bool(data['isPublished']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'ownerId': ownerId,
      'slug': slug,
      'fullName': fullName,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'companyWebsite': companyWebsite,
      'photoUrl': photoUrl,
      'logoUrl': logoUrl,
      'primaryPhone': primaryPhone,
      'secondaryPhone': secondaryPhone,
      'whatsapp': whatsapp,
      'primaryEmail': primaryEmail,
      'secondaryEmail': secondaryEmail,
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'website': website,
      'linkedin': linkedin,
      'instagram': instagram,
      'twitter': twitter,
      'facebook': facebook,
      'summary': summary,
      'iconName': iconName,
      'brandColorValue': brandColorValue,
      'isPublished': isPublished,
      // Device clocks can be wrong; Firestore's server clock drives ordering.
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static String _string(Object? value) => value is String ? value : '';

  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static int _color(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final hex = value.replaceFirst('#', '');
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        return hex.length <= 6 ? 0xFF000000 | parsed : parsed;
      }
    }
    return 0xFF2E6AE6;
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
