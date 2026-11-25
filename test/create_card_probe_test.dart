import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qr_brochure/app_providers.dart';
import 'package:qr_brochure/models/digital_card.dart';
import 'package:qr_brochure/screens/home_screen.dart';
import 'package:qr_brochure/services/digital_card_service.dart';
import 'package:qr_brochure/views/public/public_card_screen.dart';

void main() {
  testWidgets('create your card route is not blank', (tester) async {
    await tester.pumpWidget(
      const AppProviders(
        child: MaterialApp(home: Scaffold(body: Center(child: Launcher()))),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.text('Generate QR codes for your files and links'),
      findsOneWidget,
    );
  });

  testWidgets('public card shows only the scanned card details', (
    tester,
  ) async {
    await tester.pumpWidget(
      AppProviders(
        child: MaterialApp(
          home: PublicCardScreen(slug: 'test-card', service: FakeCardService()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test User'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Create your card'), findsNothing);
    expect(find.text('WBC-QR'), findsNothing);
  });
}

class Launcher extends StatelessWidget {
  const Launcher({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed:
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const HomeScreen(firebaseInitError: null),
            ),
          ),
      child: const Text('open'),
    );
  }
}

class FakeCardService extends DigitalCardService {
  @override
  Future<DigitalCard?> getPublicCard(String slug) async {
    return DigitalCard(
      id: 'card-1',
      ownerId: 'user-1',
      slug: slug,
      fullName: 'Test User',
      isPublished: true,
    );
  }

  @override
  Future<void> logEvent(String slug, String type) async {}
}
