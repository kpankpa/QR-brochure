import 'package:flutter_test/flutter_test.dart';

import 'package:qr_brochure/services/digital_card_service.dart';

void main() {
  test('generated publish slugs are URL-safe and lowercase', () {
    final slug = DigitalCardService.slugForCard(
      'Prince Dornu',
      'JDGCXPIDz7roHIwW1yr8',
    );

    expect(slug, equals('prince-dornu-ww1yr8'));
    expect(RegExp(r'^[a-zA-Z0-9-]{1,40}$').hasMatch(slug), isTrue);
  });
}
