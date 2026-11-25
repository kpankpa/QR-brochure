import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_controller.dart';
import '../view_models/qr_brochure_view_model.dart';
import '../views/auth/access_denied_screen.dart';
import '../views/auth/google_sign_in_screen.dart';
import '../views/qr_brochure/qr_brochure_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.firebaseInitError});

  final Object? firebaseInitError;

  @override
  Widget build(BuildContext context) {
    if (firebaseInitError != null) {
      return FirebaseSetupScaffold(error: firebaseInitError);
    }
    return const _NoticeBinder(child: _AuthGate());
  }
}

/// Routes to login or main app based on auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    // Only allowlisted Google accounts may reach the dashboard/editor.
    if (user == null || user.isAnonymous) {
      return const GoogleSignInScreen();
    }
    if (!auth.isAllowedEditor) {
      return const AccessDeniedScreen();
    }

    return const QrBrochureView();
  }
}

/// Connects ViewModel notices + starts auth listener.
class _NoticeBinder extends StatefulWidget {
  const _NoticeBinder({required this.child});

  final Widget child;

  @override
  State<_NoticeBinder> createState() => _NoticeBinderState();
}

class _NoticeBinderState extends State<_NoticeBinder> {
  late final QrBrochureViewModel _vm;
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _vm = context.read<QrBrochureViewModel>();
    _auth = context.read<AuthController>();
    // Bind immediately so early notices are not lost. Reading providers in
    // initState is safe and does not depend on a post-frame callback.
    _vm.bindUserNotice(_showSnack);
    _auth.startListening();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _vm.unbindUserNotice();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class FirebaseSetupScaffold extends StatelessWidget {
  const FirebaseSetupScaffold({super.key, required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/env/whitebeamconcept.png',
          height: 28,
          fit: BoxFit.contain,
          errorBuilder:
              (_, __, ___) => const Text(
                'WBC-QR',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 56,
                  color: scheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Firebase is not configured yet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Create a Firebase project, install the FlutterFire CLI, then run:\n\n'
                  'dart pub global activate flutterfire_cli\n'
                  'flutterfire configure --project=YOUR_PROJECT_ID -y',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SelectableText(
                  error.toString(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
