import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brochure_record.dart';
import '../../services/brochure_catalog_service.dart';
import '../../view_models/auth_controller.dart';
import '../../view_models/qr_brochure_view_model.dart';

/// Lists Firestore-backed uploads for the signed-in user (guest or email).
class BrochureHistoryDrawer extends StatefulWidget {
  const BrochureHistoryDrawer({super.key});

  @override
  State<BrochureHistoryDrawer> createState() => _BrochureHistoryDrawerState();
}

class _BrochureHistoryDrawerState extends State<BrochureHistoryDrawer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthController>().ensureGuestSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final catalog = context.read<BrochureCatalogService>();
    final vm = context.read<QrBrochureViewModel>();
    final uid = auth.user?.uid;
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(color: scheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'My uploads',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auth.accountSummary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (uid == null)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Enable Anonymous sign-in in Firebase Console, '
                      'or sign in with email from the menu.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: StreamBuilder<List<BrochureRecord>>(
                  stream: catalog.watchBrochures(uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data!;
                    if (items.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No uploads yet. Generate a QR from a file to see it here.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = items[i];
                        return ListTile(
                          leading: Icon(
                            Icons.qr_code_2_rounded,
                            color: scheme.primary,
                          ),
                          title: Text(
                            r.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle:
                              r.createdAt != null
                                  ? Text(
                                    MaterialLocalizations.of(
                                      context,
                                    ).formatShortDate(r.createdAt!),
                                  )
                                  : null,
                          onTap: () {
                            vm.applyBrochureUrl(r.downloadUrl);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
