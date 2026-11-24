import 'package:flutter_test/flutter_test.dart';

import 'package:qr_brochure/main.dart';

void main() {
  testWidgets('home shows Firebase ready when init succeeds', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const QrBrochureApp(firebaseInitError: null));

    expect(find.textContaining('Sign in to continue'), findsOneWidget);
  });

  testWidgets('home shows setup hint when Firebase failed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const QrBrochureApp(firebaseInitError: 'test error'),
    );

    expect(find.textContaining('not configured'), findsOneWidget);
  });
}
