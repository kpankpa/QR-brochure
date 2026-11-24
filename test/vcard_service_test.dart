import 'package:flutter_test/flutter_test.dart';

import 'package:qr_brochure/models/digital_card.dart';
import 'package:qr_brochure/services/vcard_service.dart';

void main() {
  test('VcardService builds a vCard 3.0 contact with all key fields', () {
    final card = DigitalCard(
      id: 'card-1',
      ownerId: 'user-1',
      fullName: 'Jane Doe',
      jobTitle: 'Sales Manager',
      companyName: 'Whitebeam Concept',
      primaryPhone: '+15551234567',
      secondaryPhone: '+15557654321',
      primaryEmail: 'jane@example.com',
      street: '12 Main Street',
      city: 'New York',
      state: 'NY',
      postalCode: '10001',
      country: 'USA',
      website: 'https://example.com',
      summary: 'Helping teams grow.',
    );

    final vcf = VcardService.build(card);

    expect(vcf, startsWith('BEGIN:VCARD\r\nVERSION:3.0\r\n'));
    expect(vcf, contains('N:Doe;Jane;;;'));
    expect(vcf, contains('FN:Jane Doe'));
    expect(vcf, contains('ORG:Whitebeam Concept'));
    expect(vcf, contains('TITLE:Sales Manager'));
    expect(vcf, contains('TEL;TYPE=CELL,VOICE:+15551234567'));
    expect(vcf, contains('TEL;TYPE=WORK,VOICE:+15557654321'));
    expect(vcf, contains('EMAIL;TYPE=INTERNET,WORK:jane@example.com'));
    expect(vcf, contains('ADR;TYPE=WORK'));
    expect(vcf, contains('URL;TYPE=HOME:https://example.com'));
    expect(vcf, contains('NOTE:Helping teams grow.'));
    expect(vcf, endsWith('END:VCARD\r\n'));
  });

  test('blank name falls back to a non-empty FN', () {
    final vcf = VcardService.build(
      const DigitalCard(id: 'c', ownerId: 'u', companyName: 'Acme Ltd'),
    );
    expect(vcf, contains('FN:Acme Ltd'));
  });

  test('WhatsApp is dialable and social profiles/logo are exported', () {
    final vcf = VcardService.build(
      const DigitalCard(
        id: 'c',
        ownerId: 'u',
        fullName: 'A B',
        whatsapp: '+44 7700 900123',
        linkedin: 'https://linkedin.com/in/example',
        instagram: 'https://instagram.com/example',
        twitter: 'https://x.com/example',
        facebook: 'https://facebook.com/example',
        companyWebsite: 'https://company.example',
        logoUrl: 'https://cdn.example/logo.png',
      ),
    );

    expect(vcf, contains('TEL;TYPE=WORK,VOICE:+447700900123'));
    expect(vcf, contains('X-WHATSAPP:+447700900123'));
    expect(vcf, contains('X-SOCIALPROFILE;TYPE=linkedin'));
    expect(vcf, contains('X-SOCIALPROFILE;TYPE=instagram'));
    expect(vcf, contains('X-SOCIALPROFILE;TYPE=twitter'));
    expect(vcf, contains('X-SOCIALPROFILE;TYPE=facebook'));
    expect(vcf, contains('URL;TYPE=WORK:https://company.example'));
    expect(vcf, contains('LOGO;VALUE=URI:https://cdn.example/logo.png'));
  });

  test('WhatsApp URLs are normalised to a dialable number', () {
    for (final url in <String>[
      'https://wa.me/15551234567',
      'https://api.whatsapp.com/send?phone=15551234567',
      'https://web.whatsapp.com/send?phone=15551234567',
    ]) {
      final vcf = VcardService.build(
        DigitalCard(id: 'c', ownerId: 'u', fullName: 'A B', whatsapp: url),
      );
      expect(vcf, contains('X-WHATSAPP:+15551234567'), reason: url);
    }
  });
}
