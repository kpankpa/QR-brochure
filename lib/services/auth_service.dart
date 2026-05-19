import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firebase Auth with safe access when Firebase is absent (e.g. some tests).
class AuthService {
  FirebaseAuth? _authOrNull() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _authOrNull()?.currentUser;

  Stream<User?> authStateChanges() {
    final auth = _authOrNull();
    if (auth == null) return const Stream<User?>.empty();
    return auth.authStateChanges();
  }

  Future<void> ensureSignedInAnonymouslyIfNeeded() async {
    final auth = _authOrNull();
    if (auth == null) return;
    if (auth.currentUser != null) return;
    await auth.signInAnonymously();
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = _authOrNull();
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'no-app',
        message: 'Firebase not initialized',
      );
    }
    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = _authOrNull();
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'no-app',
        message: 'Firebase not initialized',
      );
    }
    await auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _authOrNull()?.signOut();
  }
}
