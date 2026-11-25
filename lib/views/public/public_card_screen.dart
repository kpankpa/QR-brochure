import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/digital_card.dart';
import '../../screens/home_screen.dart' show FirebaseSetupScaffold;
import '../../services/digital_card_service.dart';
import '../cards/digital_card_view.dart';

/// Public, no-sign-in page shown when someone scans a card QR code.
///
/// This is deliberately card-only: no app logo, no top navigation and no
/// "create your card" entry point. Only the card details are rendered.
class PublicCardScreen extends StatefulWidget {
  const PublicCardScreen({
    super.key,
    required this.slug,
    this.firebaseInitError,
    DigitalCardService? service,
  }) : _service = service;

  final String slug;
  final Object? firebaseInitError;
  final DigitalCardService? _service;

  @override
  State<PublicCardScreen> createState() => _PublicCardScreenState();
}

class _PublicCardScreenState extends State<PublicCardScreen> {
  late final DigitalCardService _service;
  late Future<DigitalCard?> _cardFuture;
  bool _viewLogged = false;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? context.read<DigitalCardService>();
    _cardFuture = _loadCard();
  }

  Future<DigitalCard?> _loadCard() async {
    final card = await _service.getPublicCard(widget.slug);
    if (card != null && !_viewLogged) {
      _viewLogged = true;
      await _service.logEvent(widget.slug, 'view');
    }
    return card;
  }

  void _retry() {
    setState(() => _cardFuture = _loadCard());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.firebaseInitError != null) {
      return FirebaseSetupScaffold(error: widget.firebaseInitError);
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: FutureBuilder<DigitalCard?>(
          future: _cardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not load this card. Check your connection and try again.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reload'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final card = snapshot.data;
            if (card == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'This card is not available.\nIt may have been unpublished.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reload'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: DigitalCardView(card: card, showActions: false),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
