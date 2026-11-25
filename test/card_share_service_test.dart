import 'package:flutter_test/flutter_test.dart';

import 'package:qr_brochure/models/digital_card.dart';
import 'package:qr_brochure/services/card_share_service.dart';

void main() {
  test('share text contains the card details and hosted link', () {
    final card = DigitalCard(
      id: 'card-1',
      ownerId: 'user-1',
      fullName: 'Jane Doe',
      jobTitle: 'Designer',
      companyName: 'Acme Studio',
      primaryPhone: '+15551234567',
      primaryEmail: 'jane@example.com',
      website: 'https://example.com',
      slug: 'jane-doe-abc123',
      isPublished: true,
    );

    final text = CardShareService.buildShareText(card);

    expect(text, contains('Jane Doe'));
    expect(text, contains('Designer · Acme Studio'));
    expect(text, contains('Phone: +15551234567'));
    expect(text, contains('Email: jane@example.com'));
    expect(text, contains('Website: https://example.com'));
    expect(text, contains('/c/jane-doe-abc123'));
    expect(text, isNot(contains('Whitebeam')));
  });

  test('draft cards do not share a broken hosted link', () {
    final card = DigitalCard(
      id: 'card-1',
      ownerId: 'user-1',
      fullName: 'Draft User',
    );

    expect(CardShareService.buildShareText(card), isNot(contains('/c/')));
  });
}
