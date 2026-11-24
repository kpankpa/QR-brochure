import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../view_models/qr_brochure_view_model.dart';

class FileSourcePanel extends StatelessWidget {
  const FileSourcePanel({super.key, required this.viewModel});

  final QrBrochureViewModel viewModel;

  static String? sizeLabel(PlatformFile f) {
    final b = f.size;
    if (b <= 0) return null;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final file = viewModel.pickedFile;

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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: const Color(0xFFD9DEE8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud_upload_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PDF or image is uploaded to Supabase Storage. '
                    'The QR encodes the public download link.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18),
              const SizedBox(width: 8),
              const Text('Expiration Settings'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  viewModel.expirySummary,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<ExpiryPreset>(
            style: ButtonStyle(
              side: WidgetStateProperty.all(
                const BorderSide(color: Color(0xFF35506C)),
              ),
            ),
            segments: const [
              ButtonSegment(value: ExpiryPreset.oneHour, label: Text('1 hour')),
              ButtonSegment(value: ExpiryPreset.oneDay, label: Text('1 day')),
              ButtonSegment(value: ExpiryPreset.oneWeek, label: Text('1 week')),
              ButtonSegment(value: ExpiryPreset.custom, label: Text('Custom')),
            ],
            selected: {viewModel.expiryPreset},
            onSelectionChanged: (set) async {
              // Flutter passes an empty set when the active segment is tapped.
              if (set.isEmpty) return;
              final selected = set.first;
              if (selected == ExpiryPreset.custom) {
                final days = await _showCustomDaysDialog(context);
                if (days != null) {
                  viewModel.setCustomExpiryDays(days);
                }
                return;
              }
              viewModel.setExpiryPreset(selected);
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: viewModel.busy ? null : () => viewModel.pickFile(),
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Choose PDF or image'),
          ),
          if (file != null) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: ListTile(
                leading: Icon(
                  file.extension == 'pdf'
                      ? Icons.picture_as_pdf_rounded
                      : Icons.image_outlined,
                ),
                title: Text(
                  file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(sizeLabel(file) ?? 'Ready to upload'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed:
                  viewModel.busy ? null : () => viewModel.uploadAndCreateQr(),
              icon:
                  viewModel.busy
                      ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                      : const Icon(Icons.qr_code_rounded),
              label: Text(viewModel.busy ? 'Uploading…' : 'Upload & create QR'),
            ),
          ],
        ],
      ),
    );
  }

  Future<int?> _showCustomDaysDialog(BuildContext context) async {
    final controller = TextEditingController(text: '2');
    final result = showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Custom expiry'),
          content: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final days = int.tryParse(value.text.trim());
              final valid = days != null && days >= 1 && days <= 7;
              return TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Days (1-7)',
                  errorText: valid ? null : 'Choose 1 to 7 days',
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final days = int.tryParse(controller.text.trim());
                if (days == null || days < 1 || days > 7) return;
                Navigator.of(context).pop(days);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    return result.whenComplete(controller.dispose);
  }
}
