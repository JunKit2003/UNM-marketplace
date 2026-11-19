import 'package:flutter/foundation.dart';

/// Where the API lives. On the web the app is served by the same nginx that proxies
/// /api, /images and /socket.io, so the page's own origin is right. Override with
/// `--dart-define=API_BASE=http://localhost:8080` for other setups.
String apiBase() {
  const fromEnv = String.fromEnvironment('API_BASE');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kIsWeb) return Uri.base.origin;
  return 'http://10.0.2.2:8080';
}

/// Turns an API path like `/images/x.webp` into an absolute URL.
String resolveUrl(String path) =>
    path.startsWith('http') ? path : '${apiBase()}$path';

const portfolioUrl = 'https://junkit.my';
const githubUrl = 'https://github.com/JunKit2003/UNM-marketplace';
