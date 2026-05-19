import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around Firebase Auth with safe access when Firebase is absent (e.g. some tests).
class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web client ID is automatically configured by Firebase on web
    // For Android/iOS, use google-services.json/GoogleService-Info.plist
    scopes: ['email', 'profile'],
  );

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

  Future<void> signInWithGoogle() async {
    final auth = _authOrNull();
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'no-app',
        message: 'Firebase not initialized',
      );
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'sign-in-aborted',
          message: 'Sign in was cancelled',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await auth.signInWithCredential(credential);
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _authOrNull()?.signOut();
  }
}
