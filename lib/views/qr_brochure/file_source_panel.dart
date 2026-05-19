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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
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
    );
  }
}
