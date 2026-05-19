import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._auth);

  final AuthService _auth;

  StreamSubscription<User?>? _subscription;

  User? get user => _auth.currentUser;

  String get accountSummary {
    final u = user;
    if (u == null) return 'Not signed in';
    if (u.isAnonymous) return 'Signed in as guest';
    return u.displayName ?? u.email ?? 'Signed in';
  }

  void startListening() {
    if (_subscription != null) return;
    try {
      _subscription = _auth.authStateChanges().listen((_) => notifyListeners());
    } catch (_) {
      _subscription = null;
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      await _auth.signInWithGoogle();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
