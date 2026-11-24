import 'dart:convert';

import '../models/digital_card.dart';

/// Builds a vCard 3.0 payload from a [DigitalCard].
///
/// The output is saved as a `.vcf` file by the platform downloader and is
/// understood by iOS Contacts, Android Contacts, Google Contacts and Outlook.
class VcardService {
  const VcardService._();

  static String build(DigitalCard card) {
    final fullName = card.fullName.trim();
    final fallbackName =
        card.companyName.trim().isNotEmpty
            ? card.companyName.trim()
            : 'Contact';
    final displayName = fullName.isNotEmpty ? fullName : fallbackName;
    final nameParts =
        fullName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final first = nameParts.isEmpty ? '' : nameParts.first;
    final last = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      _line('N', [last, first, '', '', ''].map(_escape).join(';')),
      _line('FN', _escape(displayName)),
      if (card.companyName.trim().isNotEmpty)
        _line('ORG', _escape(card.companyName.trim())),
      if (card.jobTitle.trim().isNotEmpty)
        _line('TITLE', _escape(card.jobTitle.trim())),
      if (card.primaryPhone.trim().isNotEmpty)
        _line('TEL;TYPE=CELL,VOICE', _escape(card.primaryPhone.trim())),
      if (card.secondaryPhone.trim().isNotEmpty)
        _line('TEL;TYPE=WORK,VOICE', _escape(card.secondaryPhone.trim())),
      if (_whatsappNumber(card.whatsapp).isNotEmpty)
        _line('TEL;TYPE=WORK,VOICE', _escape(_whatsappNumber(card.whatsapp))),
      if (card.primaryEmail.trim().isNotEmpty)
        _line('EMAIL;TYPE=INTERNET,WORK', _escape(card.primaryEmail.trim())),
      if (card.secondaryEmail.trim().isNotEmpty)
        _line('EMAIL;TYPE=INTERNET,WORK', _escape(card.secondaryEmail.trim())),
      if (card.hasAddress)
        _line(
          'ADR;TYPE=WORK',
          [
            '',
            '',
            card.street.trim(),
            card.city.trim(),
            card.state.trim(),
            card.postalCode.trim(),
            card.country.trim(),
          ].map(_escape).join(';'),
        ),
      if (_whatsappNumber(card.whatsapp).isNotEmpty)
        _line('X-WHATSAPP', _escape(_whatsappNumber(card.whatsapp))),
      if (card.website.trim().isNotEmpty)
        _line('URL;TYPE=HOME', _escape(card.website.trim())),
      if (card.companyWebsite.trim().isNotEmpty)
        _line('URL;TYPE=WORK', _escape(card.companyWebsite.trim())),
      if (card.linkedin.trim().isNotEmpty)
        _line('X-SOCIALPROFILE;TYPE=linkedin', _escape(card.linkedin.trim())),
      if (card.instagram.trim().isNotEmpty)
        _line('X-SOCIALPROFILE;TYPE=instagram', _escape(card.instagram.trim())),
      if (card.twitter.trim().isNotEmpty)
        _line('X-SOCIALPROFILE;TYPE=twitter', _escape(card.twitter.trim())),
      if (card.facebook.trim().isNotEmpty)
        _line('X-SOCIALPROFILE;TYPE=facebook', _escape(card.facebook.trim())),
      if (card.summary.trim().isNotEmpty)
        _line('NOTE', _escape(card.summary.trim())),
      if (card.photoUrl.trim().isNotEmpty)
        _line('PHOTO;VALUE=URI', _escape(card.photoUrl.trim())),
      if (card.logoUrl.trim().isNotEmpty)
        _line('LOGO;VALUE=URI', _escape(card.logoUrl.trim())),
      'END:VCARD',
    ];

    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  static String _line(String key, String value) => '$key:$value';

  /// Accepts a raw number or a WhatsApp share URL and returns a dialable number.
  static String _whatsappNumber(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    if (uri != null) {
      final host = uri.host.toLowerCase();
      if (host.endsWith('wa.me')) {
        return _normalisePhone(uri.path, forceInternational: true);
      }
      if (host.endsWith('whatsapp.com')) {
        final phone = uri.queryParameters['phone'];
        if (phone != null && phone.trim().isNotEmpty) {
          return _normalisePhone(phone, forceInternational: true);
        }
      }
    }
    return _normalisePhone(value);
  }

  static String _normalisePhone(
    String value, {
    bool forceInternational = false,
  }) {
    final trimmed = value.trim();
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    if (forceInternational) {
      return digits.startsWith('00') ? '+${digits.substring(2)}' : '+$digits';
    }
    return trimmed.startsWith('+') ? '+$digits' : digits;
  }

  static String _escape(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('\r\n', r'\n')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\n')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;');
  }

  /// Folds lines to the vCard 3.0 limit of 75 octets per physical line.
  static String _fold(String line) {
    if (utf8.encode(line).length <= 75) return line;

    final buffer = StringBuffer();
    var length = 0;
    for (final rune in line.runes) {
      final char = String.fromCharCode(rune);
      final byteLength = utf8.encode(char).length;
      final limit = length == 0 ? 75 : 74;
      if (length + byteLength > limit) {
        buffer.write('\r\n ');
        buffer.write(char);
        length = 1 + byteLength;
      } else {
        buffer.write(char);
        length += byteLength;
      }
    }
    return buffer.toString();
  }
}
