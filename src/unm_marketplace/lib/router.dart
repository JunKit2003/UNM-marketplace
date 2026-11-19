import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/about/about_page.dart';
import 'features/auth/auth_page.dart';
import 'features/browse/browse_page.dart';
import 'features/chat/inbox_page.dart';
import 'features/chat/thread_page.dart';
import 'features/listing/listing_detail_page.dart';
import 'features/profile/profile_page.dart';
import 'features/saved/saved_page.dart';
import 'features/sell/sell_page.dart';
import 'state/auth.dart';
import 'widgets/app_shell.dart';
import 'widgets/empty_state.dart';

bool isProtected(String path) =>
    path == '/sell' || path == '/saved' || path == '/me' || path.startsWith('/messages') || path.endsWith('/edit');

/// Where a signed-out visitor goes for [location]: login with a return path, or null to stay.
String? authRedirect({required String location, required bool signedIn, required bool loading}) {
  if (loading) return null;
  final uri = Uri.parse(location);
  if (!signedIn && isProtected(uri.path)) return '/login?from=${Uri.encodeComponent(location)}';
  if (signedIn && uri.path == '/login') {
    final from = uri.queryParameters['from'];
    return (from != null && from.startsWith('/') && !from.startsWith('//')) ? from : '/';
  }
  return null;
}

int? _id(GoRouterState s) => int.tryParse(s.pathParameters['id'] ?? '');

Widget _notFound() => const Scaffold(
      body: EmptyState(icon: Icons.explore_off_rounded, title: 'Page not found', message: "That page doesn't exist."),
    );

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      return authRedirect(
        location: state.uri.toString(),
        signedIn: auth.value != null,
        loading: auth.isLoading && !auth.hasValue,
      );
    },
    errorBuilder: (_, _) => _notFound(),
    routes: [
      GoRoute(path: '/login', builder: (_, s) => AuthPage(from: s.uri.queryParameters['from'])),
      ShellRoute(
        builder: (_, s, child) => AppShell(location: s.uri.path, child: child),
        routes: [
          GoRoute(path: '/', pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: const BrowsePage())),
          GoRoute(
            path: '/listing/:id',
            builder: (_, s) {
              final id = _id(s);
              return id == null ? _notFound() : ListingDetailPage(id: id, openChat: s.uri.queryParameters['chat'] == '1');
            },
            routes: [
              GoRoute(path: 'edit', builder: (_, s) => _id(s) == null ? _notFound() : SellPage(editId: _id(s))),
            ],
          ),
          GoRoute(path: '/sell', pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: const SellPage())),
          GoRoute(path: '/saved', pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: const SavedPage())),
          GoRoute(
            path: '/messages',
            pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: const InboxPage()),
            routes: [
              GoRoute(path: ':id', builder: (_, s) => _id(s) == null ? _notFound() : ThreadPage(id: _id(s)!)),
            ],
          ),
          GoRoute(path: '/me', pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: const ProfilePage())),
          GoRoute(path: '/about', builder: (_, _) => const AboutPage()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
