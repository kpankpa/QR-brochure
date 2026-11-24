import 'package:web/web.dart' as web;

/// Keeps the browser URL in sync when the app is entered through a public
/// `/c/{slug}` deep link and the user navigates into the dashboard.
void replaceBrowserPath(String path) {
  web.window.history.replaceState(null, '', path);
}
