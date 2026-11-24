import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qr_brochure/app_providers.dart';
import 'package:qr_brochure/views/cards/card_editor_screen.dart';

void main() {
  testWidgets('new card editor renders fields', (tester) async {
    await tester.pumpWidget(
      const AppProviders(
        child: MaterialApp(
          home: Scaffold(body: Center(child: NavigatorLauncher())),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('New digital card'), findsWidgets);
    expect(find.text('Full name'), findsOneWidget);
  });
}

class NavigatorLauncher extends StatelessWidget {
  const NavigatorLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed:
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CardEditorScreen()),
          ),
      child: const Text('open'),
    );
  }
}
