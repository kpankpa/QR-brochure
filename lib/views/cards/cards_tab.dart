import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../models/digital_card.dart';
import '../../services/card_share_service.dart';
import '../../services/digital_card_service.dart';
import '../../services/qr_render_service.dart';
import '../../services/vcard_service.dart';
import '../../services/qr_downloader_stub.dart'
    if (dart.library.io) '../../services/qr_downloader_io.dart'
    if (dart.library.js_interop) '../../services/qr_downloader_web.dart'
    as card_downloader;
import '../../view_models/auth_controller.dart';
import '../auth/access_denied_screen.dart';
import 'card_editor_screen.dart';
import 'digital_card_view.dart';

/// Dashboard tab for creating and managing digital business cards.
class CardsTab extends StatelessWidget {
  const CardsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = context.watch<AuthController>();
    final uid = auth.user?.uid;
    final service = context.read<DigitalCardService>();

    // Defence in depth: every card action is limited to the email allowlist.
    if (!auth.isAllowedEditor) {
      return const AccessDeniedScreen();
    }
    if (uid == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Please sign in to manage your digital cards.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Digital business cards',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'One QR, always up to date. Share phone, email, address, map and more.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CardEditorScreen(),
                ),
              ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New digital card'),
        ),
        const SizedBox(height: 18),
        StreamBuilder<List<DigitalCard>>(
          stream: service.watchCards(uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              if (snapshot.connectionState == ConnectionState.done) {
                return const Center(
                  child: Text('Cards are unavailable right now.'),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }
            final cards = snapshot.data!;
            if (cards.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  border: Border.all(color: const Color(0xFFD9DEE8)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.contacts_outlined,
                      size: 44,
                      color: scheme.outline,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No cards yet',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Create your first card, publish it, then use the '
                      'Contact option in the Upload tab to make a QR.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final card = cards[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(card.brandColorValue),
                      foregroundColor: Colors.white,
                      child: Text(card.initials),
                    ),
                    title: Text(
                      card.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        if (card.jobTitle.trim().isNotEmpty) card.jobTitle,
                        if (card.companyName.trim().isNotEmpty)
                          card.companyName,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Card actions',
                      onSelected:
                          (value) =>
                              _handleAction(context, value, card, uid, service),
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined, size: 18),
                                title: Text('Edit'),
                                dense: true,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'preview',
                              child: ListTile(
                                leading: Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                title: Text('Preview'),
                                dense: true,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'share',
                              enabled: card.isPublished,
                              child: ListTile(
                                leading: Icon(
                                  Icons.ios_share_rounded,
                                  size: 18,
                                ),
                                title: Text('Share to apps'),
                                dense: true,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'copy',
                              enabled: card.isPublished,
                              child: ListTile(
                                leading: Icon(Icons.link_rounded, size: 18),
                                title: Text('Copy link'),
                                dense: true,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'qr',
                              enabled: card.isPublished,
                              child: ListTile(
                                leading: Icon(Icons.qr_code_rounded, size: 18),
                                title: Text('Download QR'),
                                dense: true,
                              ),
                            ),
                            PopupMenuItem(
                              value: card.isPublished ? 'unpublish' : 'publish',
                              child: ListTile(
                                leading: Icon(
                                  card.isPublished
                                      ? Icons.public_off_outlined
                                      : Icons.publish_rounded,
                                  size: 18,
                                ),
                                title: Text(
                                  card.isPublished ? 'Unpublish' : 'Publish',
                                ),
                                dense: true,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                ),
                                title: Text('Delete'),
                                dense: true,
                              ),
                            ),
                          ],
                    ),
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CardEditorScreen(card: card),
                          ),
                        ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    String value,
    DigitalCard card,
    String uid,
    DigitalCardService service,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    switch (value) {
      case 'edit':
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => CardEditorScreen(card: card)),
        );
        break;
      case 'preview':
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder:
              (_) => Dialog(
                insetPadding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 420,
                  height: 680,
                  child: SingleChildScrollView(
                    child: DigitalCardView(
                      card: card,
                      onSaveContact: () => _downloadVCard(context, card),
                      onCopyLink: () async {
                        Navigator.of(context).pop();
                        await _shareCard(context, card);
                      },
                    ),
                  ),
                ),
              ),
        );
        break;
      case 'share':
        await _shareCard(context, card);
        break;
      case 'copy':
        await _copyCardLink(context, card);
        break;
      case 'qr':
        if (!card.isPublished || card.publicSlug.isEmpty) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Publish this card before making a QR.'),
            ),
          );
          break;
        }
        final size = await _pickQrSize(context);
        if (size == null || !context.mounted) break;
        messenger.showSnackBar(
          const SnackBar(content: Text('Rendering QR code…')),
        );
        final ok = await _downloadQr(
          DigitalCardService.cardUrl(card.publicSlug),
          size,
          logoUrl: card.logoUrl,
        );
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'QR code downloaded' : 'Could not download QR code',
            ),
          ),
        );
        break;
      case 'publish':
        try {
          final result = await service.publish(uid: uid, card: card);
          if (!context.mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Published: ${DigitalCardService.cardUrl(result.slug)}',
              ),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          await showDialog<void>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Publish failed'),
                  content: SelectableText(e.toString()),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        }
        break;
      case 'unpublish':
        final unpublishConfirmed = await _confirm(
          context,
          'Unpublish this card? Its public link will stop working.',
        );
        if (!unpublishConfirmed || !context.mounted) return;
        try {
          await service.unpublish(
            uid: uid,
            cardId: card.id,
            slug: card.slug,
            fullName: card.fullName,
          );
          if (!context.mounted) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('Card unpublished')),
          );
        } catch (e) {
          if (!context.mounted) return;
          _showError(context, 'Could not unpublish card', e);
        }
        break;
      case 'delete':
        final deleteConfirmed = await _confirm(
          context,
          'Delete this card and its public link permanently?',
        );
        if (!deleteConfirmed || !context.mounted) return;
        try {
          await service.deleteCard(
            uid: uid,
            cardId: card.id,
            slug: card.slug,
            fullName: card.fullName,
          );
          if (!context.mounted) return;
          messenger.showSnackBar(const SnackBar(content: Text('Card deleted')));
        } catch (e) {
          if (!context.mounted) return;
          _showError(context, 'Could not delete card', e);
        }
        break;
    }
  }

  Future<bool> _confirm(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Please confirm'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  Future<int?> _pickQrSize(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choose download size',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...QrRenderService.sizeOptions.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE5EAF2)),
                        ),
                        title: Text(option.label),
                        subtitle: Text(option.detail),
                        onTap: () => Navigator.of(context).pop(option.pixels),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _shareCard(BuildContext context, DigitalCard card) async {
    if (!card.isPublished || card.publicSlug.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publish this card before sharing it.')),
        );
      }
      return;
    }
    try {
      await CardShareService().shareCard(card);
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Could not open share sheet', e);
    }
  }

  Future<bool> _copyCardLink(BuildContext context, DigitalCard card) async {
    if (!card.isPublished || card.publicSlug.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publish this card before sharing it.')),
        );
      }
      return false;
    }
    try {
      await Clipboard.setData(
        ClipboardData(text: DigitalCardService.cardUrl(card.publicSlug)),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Card link copied')));
      }
      return true;
    } catch (e) {
      if (context.mounted) _showError(context, 'Could not copy link', e);
      return false;
    }
  }

  Future<bool> _downloadVCard(BuildContext context, DigitalCard card) async {
    final safeName = card.displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    try {
      final ok = await card_downloader.saveTextFile(
        VcardService.build(card),
        '${safeName.isEmpty ? 'contact' : safeName}.vcf',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Contact file saved' : 'Could not save contact file',
            ),
          ),
        );
      }
      return ok;
    } catch (e) {
      debugPrint('Could not save contact file: $e');
      if (context.mounted) {
        _showError(context, 'Could not save contact file', e);
      }
      return false;
    }
  }

  void _showError(BuildContext context, String title, Object error) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: SelectableText(error.toString()),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<ui.Image?> _logoImage(String url) async {
    if (url.trim().isEmpty) return null;
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final prepared = await QrRenderService.prepareLogoPng(response.bodyBytes);
      return await decodeImageFromList(prepared);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _downloadQr(
    String payload,
    int size, {
    String logoUrl = '',
  }) async {
    ui.Image? logo;
    try {
      logo = await _logoImage(logoUrl);
      final png = await QrRenderService.renderPng(
        payload: payload,
        logo: logo,
        size: size,
      );
      if (png == null) return false;
      return await card_downloader.saveQrPng(
        png,
        'wbc-card-${DateTime.now().millisecondsSinceEpoch}.png',
      );
    } catch (_) {
      return false;
    } finally {
      logo?.dispose();
    }
  }
}
