import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/source_kind.dart';
import '../../view_models/auth_controller.dart';
import '../../view_models/qr_brochure_view_model.dart';
import '../auth/email_auth_sheet.dart';
import 'brochure_history_drawer.dart';
import 'file_source_panel.dart';
import 'link_source_panel.dart';
import 'qr_preview_card.dart';

/// Main workspace UI bound to [QrBrochureViewModel].
class QrBrochureView extends StatelessWidget {
  const QrBrochureView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const BrochureHistoryDrawer(),
      appBar: AppBar(
        title: const Text('QR Brochure'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Account',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) async {
              final messenger = ScaffoldMessenger.of(context);
              final auth = context.read<AuthController>();
              switch (value) {
                case 'email':
                  await showEmailAuthSheet(context);
                  break;
                case 'out':
                  await auth.signOut();
                  if (context.mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Signed out')),
                    );
                  }
                  break;
              }
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(
                    value: 'email',
                    child: Text('Sign in with email'),
                  ),
                  PopupMenuItem(value: 'out', child: Text('Sign out')),
                ],
          ),
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed:
                () => showAboutDialog(
                  context: context,
                  applicationName: 'QR Brochure',
                  applicationLegalese:
                      'Create QR codes that open links, PDFs, or images.',
                ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<QrBrochureViewModel>(
          builder: (context, vm, _) {
            final theme = Theme.of(context);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'What should the QR code open?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<SourceKind>(
                        segments: const [
                          ButtonSegment(
                            value: SourceKind.link,
                            label: Text('Link'),
                            icon: Icon(Icons.link_rounded),
                          ),
                          ButtonSegment(
                            value: SourceKind.file,
                            label: Text('File'),
                            icon: Icon(Icons.upload_file_rounded),
                          ),
                        ],
                        selected: {vm.source},
                        onSelectionChanged: vm.setSource,
                      ),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child:
                            vm.source == SourceKind.link
                                ? LinkSourcePanel(
                                  key: const ValueKey('link'),
                                  viewModel: vm,
                                )
                                : FileSourcePanel(
                                  key: const ValueKey('file'),
                                  viewModel: vm,
                                ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Preview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      QrPreviewCard(viewModel: vm),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
