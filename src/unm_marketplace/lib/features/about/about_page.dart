import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../theme/tokens.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_mesh.dart';

/// The story behind the project, for visitors coming from the Portfolio.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _stack = [
    ('Flutter 3 · Dart 3', Icons.flutter_dash_rounded),
    ('Riverpod · go_router', Icons.account_tree_rounded),
    ('Node 24 · Express 5', Icons.dns_rounded),
    ('Socket.IO chat', Icons.bolt_rounded),
    ('MySQL 8.4', Icons.storage_rounded),
    ('Docker Compose', Icons.inventory_2_rounded),
    ('nginx', Icons.alt_route_rounded),
    ('GitHub Actions CI/CD', Icons.rocket_launch_rounded),
  ];

  static const _changes = [
    ('Own real-time chat', 'Replaced a paid third-party chat SDK with Socket.IO and MySQL: typing indicators, read receipts, unread badges.'),
    ('Rebuilt API', '23 ad-hoc POST endpoints became a validated REST API. Identity comes only from the session, and owners alone can change their listings.'),
    ('Containers everywhere', 'nginx, Node and MySQL run in Docker Compose, the same on a laptop as on the server.'),
    ('Ships itself', 'Every push is linted, tested and built. Green builds deploy automatically and roll back if the health check fails.'),
    ('Redesigned from scratch', 'A dark-first design system, masonry browsing, shared-element photo transitions and a three-step sell flow.'),
    ('Showcase mode', 'One-click guest accounts, demo sellers who reply, and a nightly reset.'),
  ];

  Future<void> _open(String url) => launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final narrow = MediaQuery.sizeOf(context).width < 720;
    return SingleChildScrollView(
      child: Column(children: [
        GradientMesh(
          intensity: 0.8,
          child: Padding(
            padding: EdgeInsets.fromLTRB(narrow ? 20 : 48, 56, narrow ? 20 : 48, 40),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('How it was built', style: t.labelLarge?.copyWith(color: AppTokens.cyan, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Text('From a 2024 group project to a 2026 rebuild.', style: narrow ? t.displaySmall : t.displayMedium),
                  const SizedBox(height: 16),
                  Text(
                    'Nott-A-Marketplace started as a Software Engineering group project at the University of Nottingham Malaysia: '
                    'a place for students to buy and sell within campus. In 2026 Jun Kit revived it end to end, '
                    'keeping the original idea and stack (Flutter + Node) and rebuilding everything else.',
                    style: t.titleMedium?.copyWith(color: muted, fontWeight: FontWeight.w400, height: 1.55),
                  ),
                  const SizedBox(height: 24),
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    FilledButton.icon(onPressed: () => _open(portfolioUrl), icon: const Icon(Icons.north_east_rounded), label: const Text('View the Portfolio')),
                    OutlinedButton.icon(onPressed: () => _open(githubUrl), icon: const Icon(Icons.code_rounded), label: const Text('Source on GitHub')),
                  ]),
                ]).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(narrow ? 16 : 48, 32, narrow ? 16 : 48, 64),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Stack', style: t.headlineSmall),
                const SizedBox(height: 14),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final (label, icon) in _stack) Chip(avatar: Icon(icon, size: 18, color: AppTokens.cyan), label: Text(label)),
                ]),
                const SizedBox(height: 36),
                Text('Architecture', style: t.headlineSmall),
                const SizedBox(height: 14),
                const _Architecture(),
                const SizedBox(height: 36),
                Text('What changed', style: t.headlineSmall),
                const SizedBox(height: 14),
                LayoutBuilder(builder: (context, c) {
                  final cols = c.maxWidth > 900 ? 3 : c.maxWidth > 560 ? 2 : 1;
                  final w = (c.maxWidth - (cols - 1) * 16) / cols;
                  return Wrap(spacing: 16, runSpacing: 16, children: [
                    for (final (i, (title, body)) in _changes.indexed)
                      SizedBox(
                        width: w,
                        child: GlassPanel(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(title, style: t.titleMedium),
                            const SizedBox(height: 8),
                            Text(body, style: t.bodyMedium?.copyWith(color: muted, height: 1.5)),
                          ]),
                        ).animate().fadeIn(delay: (60 * i).ms, duration: 400.ms).slideY(begin: 0.1),
                      ),
                  ]);
                }),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Architecture extends StatelessWidget {
  const _Architecture();

  @override
  Widget build(BuildContext context) {
    Widget box(String title, String sub, IconData icon) => GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: AppTokens.cyan),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(sub, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ]),
        );
    const arrow = Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Icon(Icons.arrow_forward_rounded, color: AppTokens.violet));
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 12, children: [
      box('Browser', 'Flutter web app', Icons.public_rounded),
      arrow,
      box('nginx', 'web container · /api /images /socket.io', Icons.alt_route_rounded),
      arrow,
      box('Express 5', 'REST + Socket.IO', Icons.dns_rounded),
      arrow,
      box('MySQL 8.4', 'listings · chats · sessions', Icons.storage_rounded),
    ]);
  }
}
