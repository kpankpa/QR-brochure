import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brochure_record.dart';
import '../../models/source_kind.dart';
import '../../services/brochure_catalog_service.dart';
import '../../view_models/auth_controller.dart';
import '../../view_models/qr_brochure_view_model.dart';
import '../cards/cards_tab.dart';
import 'contact_source_panel.dart';
import 'file_source_panel.dart';
import 'link_source_panel.dart';
import 'qr_preview_card.dart';

/// Main workspace UI bound to [QrBrochureViewModel].
class QrBrochureView extends StatefulWidget {
  const QrBrochureView({super.key});

  @override
  State<QrBrochureView> createState() => _QrBrochureViewState();
}

class _QrBrochureViewState extends State<QrBrochureView> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/env/whitebeamconcept.png',
          height: 30,
          fit: BoxFit.contain,
          errorBuilder:
              (_, __, ___) => const Text(
                'WBC-QR',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
        ),
        actions: [
          Consumer<AuthController>(
            builder: (context, auth, _) {
              final user = auth.user;
              return PopupMenuButton<String>(
                tooltip: 'Account',
                icon:
                    user?.photoURL != null
                        ? CircleAvatar(
                          backgroundImage: NetworkImage(user!.photoURL!),
                          radius: 16,
                          onBackgroundImageError: (_, __) {},
                          child:
                              user.photoURL == null
                                  ? const Icon(
                                    Icons.account_circle_outlined,
                                    size: 20,
                                  )
                                  : null,
                        )
                        : const Icon(Icons.account_circle_outlined),
                onSelected: (value) async {
                  if (value == 'out') {
                    try {
                      final error = await auth.signOut();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error == null
                                ? 'Signed out'
                                : 'Sign out failed: $error',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sign out failed: $e')),
                      );
                    }
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'User',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'out',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Sign out'),
                          ],
                        ),
                      ),
                    ],
              );
            },
          ),
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed:
                () => showAboutDialog(
                  context: context,
                  applicationName: 'WBC-QR',
                  applicationLegalese:
                      'Create QR codes for links, files and digital business cards.',
                ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.upload_rounded),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<QrBrochureViewModel>(
          builder: (context, vm, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      border: Border.all(color: const Color(0xFFD9DEE8)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child:
                          _tabIndex == 0
                              ? _UploadTab(vm: vm)
                              : _tabIndex == 1
                              ? const CardsTab()
                              : _tabIndex == 2
                              ? _HistoryTab(
                                onUse: () => setState(() => _tabIndex = 0),
                              )
                              : const _SettingsTab(),
                    ),
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

class _UploadTab extends StatelessWidget {
  const _UploadTab({required this.vm});

  final QrBrochureViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Share with precision.',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Share a link, a secure temporary file, or a professional digital business card.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<SourceKind>(
          style: ButtonStyle(
            side: WidgetStateProperty.all(
              const BorderSide(color: Color(0xFF35506C)),
            ),
          ),
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
            ButtonSegment(
              value: SourceKind.contact,
              label: Text('Contact'),
              icon: Icon(Icons.contacts_outlined),
            ),
          ],
          selected: {vm.source},
          onSelectionChanged: vm.setSource,
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child:
              vm.source == SourceKind.link
                  ? LinkSourcePanel(key: const ValueKey('link'), viewModel: vm)
                  : vm.source == SourceKind.file
                  ? FileSourcePanel(key: const ValueKey('file'), viewModel: vm)
                  : ContactSourcePanel(
                    key: const ValueKey('contact'),
                    viewModel: vm,
                  ),
        ),
        const SizedBox(height: 22),
        Text(
          'QR Code Ready',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        QrPreviewCard(viewModel: vm),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.onUse});

  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final catalog = context.read<BrochureCatalogService>();
    final vm = context.read<QrBrochureViewModel>();
    final uid = auth.user?.uid;

    if (uid == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Please sign in to view your upload history.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return StreamBuilder<List<BrochureRecord>>(
      stream: catalog.watchBrochures(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
        if (!snapshot.hasData) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const Center(
              child: Text('History is unavailable right now.'),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(
            child: Text('No uploads yet. Create one from the Upload tab.'),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = items[i];
            final expired = r.isExpired;
            return Card(
              child: ListTile(
                leading: Icon(
                  expired
                      ? Icons.timer_off_rounded
                      : Icons.check_circle_outline_rounded,
                  color:
                      expired
                          ? Theme.of(context).colorScheme.error
                          : const Color(0xFF3DDC97),
                ),
                title: Text(
                  r.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  r.expiresAt == null
                      ? 'No expiry set'
                      : '${expired ? 'Expired' : 'Expires'} ${MaterialLocalizations.of(context).formatShortDate(r.expiresAt!)}',
                ),
                trailing: IconButton(
                  tooltip: 'Use this QR',
                  icon: const Icon(Icons.open_in_new_rounded),
                  onPressed: () async {
                    final loaded = await vm.useBrochureFromHistory(r);
                    if (!loaded || !context.mounted) return;
                    onUse();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('QR loaded in Upload tab')),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Account'),
            subtitle: Text(auth.accountSummary),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy'),
            subtitle: const Text(
              'Your files and QR codes are private and linked to your Google account.',
            ),
          ),
        ),
      ],
    );
  }
}
