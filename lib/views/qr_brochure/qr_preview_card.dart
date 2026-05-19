import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../view_models/qr_brochure_view_model.dart';

class QrPreviewCard extends StatelessWidget {
  const QrPreviewCard({super.key, required this.viewModel});

  final QrBrochureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final payload = viewModel.qrPayload;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 248,
              child:
                  payload != null
                      ? QrImageView(
                        data: payload,
                        version: QrVersions.auto,
                        size: 248,
                        backgroundColor: Colors.white,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: scheme.onSurface,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: scheme.onSurface,
                        ),
                      )
                      : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 56,
                              color: scheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your QR code will appear here',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: scheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
            if (payload != null) ...[
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    payload,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => viewModel.downloadQrCode(),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download QR'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => viewModel.openQrPayloadExternally(),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => viewModel.copyQrPayload(),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy URL'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
