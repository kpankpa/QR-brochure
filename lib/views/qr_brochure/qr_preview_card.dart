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
    final expired = viewModel.selectedHistoryExpired;

    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 256,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: const Color(0xFFD9DEE8)),
                  ),
                  child: Center(
                    child:
                        payload != null
                            ? Opacity(
                              opacity: expired ? 0.42 : 1,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.zero,
                                  border: Border.all(
                                    color: const Color(0xFFD9DEE8),
                                  ),
                                ),
                                child: QrImageView(
                                  data: payload,
                                  version: QrVersions.auto,
                                  size: 210,
                                  backgroundColor: Colors.white,
                                  eyeStyle: QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: scheme.onSurface,
                                  ),
                                  dataModuleStyle: QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            )
                            : Column(
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
                if (expired)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.error,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          'Expired',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onError,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (payload != null) ...[
              if (expired) ...[
                const SizedBox(height: 12),
                Text(
                  'This history link is expired. Select another item or create a new QR.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: const Color(0xFFD9DEE8)),
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
                    onPressed:
                        expired ? null : () => viewModel.downloadQrCode(),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download QR'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed:
                        expired
                            ? null
                            : () => viewModel.openQrPayloadExternally(),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open'),
                  ),
                  OutlinedButton.icon(
                    onPressed: expired ? null : () => viewModel.copyQrPayload(),
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
