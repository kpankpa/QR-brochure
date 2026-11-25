import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qr_brochure/models/digital_card.dart';
import 'package:qr_brochure/services/digital_card_service.dart';
import 'package:qr_brochure/services/qr_render_service.dart';
import 'package:qr_brochure/view_models/qr_brochure_view_model.dart';
import 'package:qr_brochure/views/public/public_card_screen.dart';

class _FakeCardService extends DigitalCardService {
  _FakeCardService(this.card);

  final DigitalCard card;

  @override
  Future<DigitalCard?> getPublicCard(String slug) async => card;

  @override
  Future<void> logEvent(String slug, String type) async {}
}

void main() {
  test('a published card becomes a hosted vCard QR payload', () async {
    final vm = QrBrochureViewModel();
    final card = DigitalCard(
      id: 'card-1',
      ownerId: 'user-1',
      fullName: 'Jane Doe',
      companyName: 'Whitebeam Concept',
      primaryPhone: '+15551234567',
      slug: 'jane-doe-abc123',
      isPublished: true,
    );

    vm.useDigitalCard(card);

    expect(vm.qrPayload, equals('https://wbc-qr.web.app/c/jane-doe-abc123'));

    final png = await QrRenderService.renderPng(payload: vm.qrPayload!);
    expect(png, isNotNull);
    expect(png!.length, greaterThan(1000));
    vm.dispose();
  });

  testWidgets('scanning that URL renders the vCard on the web page', (
    tester,
  ) async {
    final card = DigitalCard(
      id: 'card-1',
      ownerId: 'user-1',
      fullName: 'Jane Doe',
      companyName: 'Whitebeam Concept',
      primaryPhone: '+15551234567',
      slug: 'jane-doe-abc123',
      isPublished: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PublicCardScreen(
          slug: 'jane-doe-abc123',
          service: _FakeCardService(card),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Whitebeam Concept'), findsOneWidget);
    expect(find.text('Save contact'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });
}
