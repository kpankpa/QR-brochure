import 'package:flutter_test/flutter_test.dart';

import 'package:qr_brochure/config/editor_allowlist.dart';

void main() {
  test('only the approved Google emails can edit', () {
    for (final email in kAllowedEditorEmails) {
      expect(isAllowedEditorEmail(email), isTrue, reason: email);
    }

    expect(isAllowedEditorEmail('WHITEBEAMDESIGN@GMAIL.COM'), isTrue);
    expect(isAllowedEditorEmail('  kaylonprince@gmail.com '), isTrue);

    expect(isAllowedEditorEmail(null), isFalse);
    expect(isAllowedEditorEmail(''), isFalse);
    expect(isAllowedEditorEmail('someone.else@gmail.com'), isFalse);
    expect(isAllowedEditorEmail('whitebeamdesign@gmail.com.evil.com'), isFalse);
  });
}
