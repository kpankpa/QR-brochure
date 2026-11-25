import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:qr_brochure/services/auth_service.dart';
import 'package:qr_brochure/services/digital_card_service.dart';
import 'package:qr_brochure/view_models/auth_controller.dart';
import 'package:qr_brochure/views/cards/card_editor_screen.dart';

void main() {
  testWidgets('allowed editor can open the card editor', (tester) async {
    await _pumpEditor(tester, _FakeAuthController(allowed: true));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('New digital card'), findsWidgets);
    expect(find.text('Full name'), findsOneWidget);
  });

  testWidgets('non-allowlisted account cannot open the card editor', (
    tester,
  ) async {
    await _pumpEditor(tester, _FakeAuthController(allowed: false));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Access restricted'), findsOneWidget);
    expect(find.text('Full name'), findsNothing);
  });
}

Future<void> _pumpEditor(WidgetTester tester, AuthController auth) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider(create: (_) => DigitalCardService()),
        ChangeNotifierProvider<AuthController>.value(value: auth),
      ],
      child: const MaterialApp(
        home: Scaffold(body: Center(child: NavigatorLauncher())),
      ),
    ),
  );
}

class _FakeAuthController extends AuthController {
  _FakeAuthController({required this.allowed}) : super(AuthService());

  final bool allowed;

  @override
  bool get isAllowedEditor => allowed;
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
