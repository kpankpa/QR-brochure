import 'package:flutter/material.dart';

import '../../view_models/qr_brochure_view_model.dart';

class LinkSourcePanel extends StatelessWidget {
  const LinkSourcePanel({super.key, required this.viewModel});

  final QrBrochureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: const Color(0xFFD9DEE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter the page your QR should open',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: viewModel.urlController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Website URL',
              hintText: 'https://example.com or example.com',
              prefixIcon: const Icon(Icons.public_rounded),
              errorText: viewModel.urlError,
            ),
            onSubmitted: (_) {
              if (!viewModel.busy) {
                viewModel.createQrFromUrl();
              }
            },
            onChanged: (_) => viewModel.clearUrlError(),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed:
                viewModel.busy ? null : () => viewModel.createQrFromUrl(),
            icon: const Icon(Icons.qr_code_rounded),
            label: const Text('Create QR code'),
          ),
        ],
      ),
    );
  }
}
