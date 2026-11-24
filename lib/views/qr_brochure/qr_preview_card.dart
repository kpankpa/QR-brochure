import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/qr_render_service.dart';
import '../../view_models/qr_brochure_view_model.dart';

class QrPreviewCard extends StatefulWidget {
  const QrPreviewCard({super.key, required this.viewModel});

  final QrBrochureViewModel viewModel;

  @override
  State<QrPreviewCard> createState() => _QrPreviewCardState();
}

class _QrPreviewCardState extends State<QrPreviewCard> {
  String? _previewKey;
  Future<Uint8List?>? _previewFuture;

  String _keyFor(QrBrochureViewModel vm) =>
      '${vm.qrPayload}|${vm.qrLogoBytes?.hashCode ?? 0}|'
      '${vm.qrLogoFraction.toStringAsFixed(3)}|'
      '${vm.qrModuleStyle.name}|${vm.qrExportSize}';

  /// Memoised so a rebuild never starts a second render for the same settings.
  Future<Uint8List?> _previewFor(String key) {
    final existing = _previewFuture;
    if (_previewKey == key && existing != null) return existing;

    final vm = widget.viewModel;
    final future = QrRenderService.renderPng(
      payload: vm.qrPayload!,
      logo: vm.qrLogoImage,
      size: vm.qrExportSize,
      logoFraction: vm.qrLogoFraction,
      style: vm.qrModuleStyle,
    );
    _previewKey = key;
    _previewFuture = future;
    return future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final vm = widget.viewModel;
    final payload = vm.qrPayload;
    final expired = vm.selectedHistoryExpired;
    final hasLogo = vm.qrLogoBytes != null;
    final previewKey = payload != null ? _keyFor(vm) : null;
    final exportSize = QrRenderService.sizeOptions.firstWhere(
      (option) => option.pixels == vm.qrExportSize,
      orElse: () => QrRenderService.sizeOptions[1],
    );

    return Card(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE5EAF2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 324,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primaryContainer.withValues(alpha: 0.75),
                        const Color(0xFFF8FAFC),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child:
                        payload != null
                            ? Opacity(
                              opacity: expired ? 0.42 : 1,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1A0F172A),
                                      blurRadius: 30,
                                      offset: Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: FutureBuilder<Uint8List?>(
                                  future: _previewFor(previewKey!),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        width: 236,
                                        height: 236,
                                        gaplessPlayback: true,
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return SizedBox(
                                        width: 236,
                                        height: 236,
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: SelectableText(
                                              'Could not render QR: ${snapshot.error}',
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox(
                                      width: 236,
                                      height: 236,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
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
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE5EAF2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'WBC QR',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (expired)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          'Expired',
                          style: theme.textTheme.labelSmall?.copyWith(
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
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5EAF2)),
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5EAF2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.style_rounded,
                          size: 17,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'QR style',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<QrModuleStyle>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: QrModuleStyle.classic,
                          label: Text('Classic'),
                        ),
                        ButtonSegment(
                          value: QrModuleStyle.modern,
                          label: Text('Modern'),
                        ),
                      ],
                      selected: <QrModuleStyle>{vm.qrModuleStyle},
                      onSelectionChanged:
                          expired
                              ? null
                              : (selection) =>
                                  vm.setQrModuleStyle(selection.first),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vm.qrModuleStyle == QrModuleStyle.classic
                          ? 'Square modules scan most reliably in every app.'
                          : 'Softly rounded modules for a modern look.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.photo_size_select_actual_rounded,
                          size: 17,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Export size',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${vm.qrExportSize} px',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          QrRenderService.sizeOptions.map((option) {
                            return ChoiceChip(
                              label: Text('${option.pixels}'),
                              selected: vm.qrExportSize == option.pixels,
                              showCheckmark: false,
                              onSelected:
                                  expired || vm.qrExportSize == option.pixels
                                      ? null
                                      : (_) =>
                                          vm.setQrExportSize(option.pixels),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${exportSize.detail} · The preview and download use this '
                      'exact size at 300 DPI.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasLogo) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5EAF2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.center_focus_strong_rounded,
                            size: 17,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Logo size',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${(vm.qrLogoFraction * 100).round()}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: vm.qrLogoFraction,
                        min: QrRenderService.minLogoFraction,
                        max: QrRenderService.maxLogoFraction,
                        divisions: 8,
                        label: '${(vm.qrLogoFraction * 100).round()}%',
                        onChanged: expired ? null : vm.setQrLogoFraction,
                      ),
                      Text(
                        'Drag to resize. The logo always stays centred and the '
                        'error correction adapts automatically.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed:
                        expired ? null : () => widget.viewModel.pickQrLogo(),
                    icon:
                        vm.loadingQrLogo
                            ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.primary,
                              ),
                            )
                            : Icon(Icons.image_outlined, size: 18),
                    label: Text(hasLogo ? 'Change logo' : 'Add logo'),
                  ),
                  if (hasLogo)
                    TextButton.icon(
                      onPressed: () => widget.viewModel.clearQrLogo(),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Remove'),
                    ),
                  FilledButton.icon(
                    onPressed:
                        expired
                            ? null
                            : () => widget.viewModel.downloadQrCode(),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download QR'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed:
                        expired
                            ? null
                            : () => widget.viewModel.openQrPayloadExternally(),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        expired ? null : () => widget.viewModel.copyQrPayload(),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy URL'),
                  ),
                  if (vm.selectedCard != null)
                    OutlinedButton.icon(
                      onPressed: () => widget.viewModel.downloadSelectedVCard(),
                      icon: const Icon(Icons.contacts_outlined, size: 18),
                      label: const Text('Save contact'),
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
