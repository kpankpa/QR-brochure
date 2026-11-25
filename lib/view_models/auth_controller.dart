import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/editor_allowlist.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._auth);

  final AuthService _auth;

  StreamSubscription<User?>? _subscription;

  User? get user => _auth.currentUser;

  bool get isAllowedEditor => isAllowedEditorEmail(user?.email);

  bool get hasAppAccess {
    final u = user;
    return u != null && !u.isAnonymous && isAllowedEditorEmail(u.email);
  }

  String get accountSummary {
    final u = user;
    if (u == null) return 'Not signed in';
    if (u.isAnonymous) return 'Signed in as guest';
    return u.displayName ?? u.email ?? 'Signed in';
  }

  void startListening() {
    if (_subscription != null) return;
    try {
      _subscription = _auth.authStateChanges().listen((u) {
        // A Google account outside the allowlist must never reach the editor.
        if (u != null && !isAllowedEditorEmail(u.email)) {
          unawaited(_auth.signOut());
        }
        notifyListeners();
      });
    } catch (_) {
      _subscription = null;
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      await _auth.signInWithGoogle();
      if (!isAllowedEditorEmail(user?.email)) {
        await _auth.signOut();
        notifyListeners();
        return 'This Google account is not authorised to create or edit cards.';
      }
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
