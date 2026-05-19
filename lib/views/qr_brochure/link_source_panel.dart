import 'package:flutter/material.dart';

import '../../view_models/qr_brochure_view_model.dart';

class LinkSourcePanel extends StatelessWidget {
  const LinkSourcePanel({super.key, required this.viewModel});

  final QrBrochureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            if (!viewModel.busy) {
              viewModel.createQrFromUrl();
            }
          },
          onChanged: (_) => viewModel.clearUrlError(),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: viewModel.busy ? null : () => viewModel.createQrFromUrl(),
          icon: const Icon(Icons.qr_code_rounded),
          label: const Text('Create QR code'),
        ),
      ],
    );
  }
}
