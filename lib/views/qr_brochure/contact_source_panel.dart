import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/digital_card.dart';
import '../../services/digital_card_service.dart';
import '../../view_models/auth_controller.dart';
import '../../view_models/qr_brochure_view_model.dart';

/// Lets the user pick a published digital card as the QR payload.
class ContactSourcePanel extends StatelessWidget {
  const ContactSourcePanel({super.key, required this.viewModel});

  final QrBrochureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final uid = context.watch<AuthController>().user?.uid;
    final service = context.read<DigitalCardService>();

    if (uid == null) {
      return _info('Sign in and publish a digital card to use this option.');
    }

    return StreamBuilder<List<DigitalCard>>(
      stream: service.watchCards(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _info('Could not load cards: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _info('Cards are unavailable right now. Please try again.');
          }
          return const Center(child: CircularProgressIndicator());
        }

        final published =
            snapshot.data!.where((card) => card.isPublished).toList();
        if (published.isEmpty) {
          if (viewModel.selectedCard != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) viewModel.clearSelectedCard();
            });
          }
          return _info(
            'No published cards yet. Open the Cards tab, create a card and '
            'tap Publish — then come back here to generate its QR.',
          );
        }

        final selected = viewModel.selectedCard;
        final selectedValid =
            selected != null && published.any((c) => c.id == selected.id);
        if (!selectedValid && selected != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) viewModel.clearSelectedCard();
          });
        }

        final selectedId = selectedValid ? selected!.id : null;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: const Color(0xFFD9DEE8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose the card your QR should open',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Published card',
                  prefixIcon: Icon(Icons.contacts_outlined),
                ),
                items:
                    published
                        .map(
                          (card) => DropdownMenuItem<String>(
                            value: card.id,
                            child: Text(
                              '${card.displayName}${card.companyName.trim().isEmpty ? '' : ' · ${card.companyName}'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  final card = published.firstWhere((c) => c.id == id);
                  viewModel.useDigitalCard(card);
                },
              ),
              if (selectedValid) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    border: Border.all(color: const Color(0xFFD9DEE8)),
                  ),
                  child: SelectableText(
                    DigitalCardService.cardUrl(
                      viewModel.selectedCard!.publicSlug,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => viewModel.downloadSelectedVCard(),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download contact file (.vcf)'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _info(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9DEE8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
