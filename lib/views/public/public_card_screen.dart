import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/digital_card.dart';
import '../../screens/home_screen.dart';
import '../../services/browser_path.dart' as browser_path;
import '../../services/digital_card_service.dart';
import '../../services/qr_downloader_stub.dart'
    if (dart.library.io) '../../services/qr_downloader_io.dart'
    if (dart.library.js_interop) '../../services/qr_downloader_web.dart'
    as card_downloader;
import '../../services/vcard_service.dart';
import '../cards/digital_card_view.dart';

/// Public, no-sign-in page shown when someone scans a card QR code.
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

  static String _fileSafe(String name) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isEmpty ? 'contact' : slug;
  }

  Future<void> _saveContact(DigitalCard card) async {
    var ok = false;
    try {
      ok = await card_downloader.saveTextFile(
        VcardService.build(card),
        '${_fileSafe(card.displayName)}.vcf',
      );
    } catch (e) {
      ok = false;
      debugPrint('Could not save contact file: $e');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Contact file saved. Open it to add the card.'
              : 'Could not save contact file. Please try again.',
        ),
      ),
    );
    if (ok) await _service.logEvent(card.publicSlug, 'save');
  }

  Future<void> _copyLink(DigitalCard card) async {
    try {
      await Clipboard.setData(
        ClipboardData(text: DigitalCardService.cardUrl(card.publicSlug)),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Card link copied')));
      await _service.logEvent(card.publicSlug, 'share');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not copy card link: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.firebaseInitError != null) {
      return FirebaseSetupScaffold(error: widget.firebaseInitError);
    }
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/env/whitebeamconcept.png',
          height: 26,
          fit: BoxFit.contain,
          errorBuilder:
              (_, __, ___) => const Text(
                'WBC-QR',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              browser_path.replaceBrowserPath('/');
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder:
                      (_) => HomeScreen(
                        firebaseInitError: widget.firebaseInitError,
                      ),
                ),
              );
            },
            child: const Text('Create your card'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<DigitalCard?>(
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: DigitalCardView(
                  card: card,
                  onSaveContact: () => _saveContact(card),
                  onCopyLink: () => _copyLink(card),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
