import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/brochure_catalog_service.dart';
import 'services/digital_card_service.dart';
import 'services/storage_upload_service.dart';
import 'view_models/auth_controller.dart';
import 'view_models/qr_brochure_view_model.dart';

/// App-wide providers live above [MaterialApp]/[Navigator].
///
/// Routes pushed with `Navigator.of(context).push(...)` are inserted under the
/// Navigator, not under the widget that called `push`. Providers created inside
/// a screen are therefore invisible to the pushed screen. Keeping them here
/// makes them available to every route, including the card editor.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => BrochureCatalogService()),
        Provider(create: (_) => DigitalCardService()),
        ChangeNotifierProvider(
          create: (context) => AuthController(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create:
              (context) => QrBrochureViewModel(
                storageUploadService: StorageUploadService(),
                brochureCatalogService: context.read<BrochureCatalogService>(),
              ),
        ),
      ],
      child: child,
    );
  }
}
