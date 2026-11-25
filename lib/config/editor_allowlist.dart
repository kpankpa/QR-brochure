/// Google accounts allowed to create or edit cards.
///
/// Keep this list identical to `allowedEditor()` in `firestore.rules`.
/// The client gate is for UX; Firestore rules are the real security boundary.
const Set<String> kAllowedEditorEmails = <String>{
  'whitebeamdesign@gmail.com',
  'kaylonprince@gmail.com',
};

bool isAllowedEditorEmail(String? email) {
  if (email == null) return false;
  return kAllowedEditorEmails.contains(email.trim().toLowerCase());
}
