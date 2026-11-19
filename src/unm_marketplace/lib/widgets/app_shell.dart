import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/auth.dart';
import '../state/providers.dart';
import '../theme/tokens.dart';
import 'avatar.dart';
import 'demo_banner.dart';

class _Dest {
  const _Dest(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _dests = [
  _Dest('/', 'Browse', Icons.explore_outlined, Icons.explore_rounded),
  _Dest(
    '/sell',
    'Sell',
    Icons.add_circle_outline_rounded,
    Icons.add_circle_rounded,
  ),
  _Dest(
    '/messages',
    'Messages',
    Icons.chat_bubble_outline_rounded,
    Icons.chat_bubble_rounded,
  ),
  _Dest(
    '/saved',
    'Saved',
    Icons.favorite_border_rounded,
    Icons.favorite_rounded,
  ),
  _Dest('/me', 'Profile', Icons.person_outline_rounded, Icons.person_rounded),
];

int _indexFor(String location) {
  if (location.startsWith('/sell')) return 1;
  if (location.startsWith('/messages')) return 2;
  if (location.startsWith('/saved')) return 3;
  if (location.startsWith('/me')) return 4;
  return 0;
}

/// Bottom navigation on phones, a side rail from 720 px, with the demo banner on top.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _indexFor(location);
    final unread = ref.watch(unreadCountProvider);
    final wide = MediaQuery.sizeOf(context).width >= 720;

    Widget icon(_Dest d, bool selected) {
      final i = Icon(selected ? d.selectedIcon : d.icon);
      if (d.path != '/messages' || unread == 0) return i;
      return Badge(
        label: Text('$unread'),
        backgroundColor: AppTokens.pink,
        child: i,
      );
    }

    void go(int i) => context.go(_dests[i].path);

    final body = Column(
      children: [
        const DemoBanner(),
        Expanded(child: child),
      ],
    );

    if (!wide) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: go,
          destinations: [
            for (final (i, d) in _dests.indexed)
              NavigationDestination(
                icon: icon(d, false),
                selectedIcon: icon(d, i == index),
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: NavigationRail(
              selectedIndex: index,
              onDestinationSelected: go,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: Tooltip(
                  message: 'Nott-A-Marketplace',
                  child: InkWell(
                    onTap: () => context.go('/'),
                    child: const BrandMark(),
                  ),
                ),
              ),
              trailing: const Expanded(child: _RailFooter()),
              destinations: [
                for (final (i, d) in _dests.indexed)
                  NavigationRailDestination(
                    icon: icon(d, false),
                    selectedIcon: icon(d, i == index),
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _RailFooter extends ConsumerWidget {
  const _RailFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final mode = ref.watch(themeModeProvider);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'About this project',
              onPressed: () => context.go('/about'),
              icon: const Icon(Icons.info_outline_rounded),
            ),
            IconButton(
              tooltip: mode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
              onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
              icon: Icon(
                mode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),
            if (user != null) ...[
              const SizedBox(height: 8),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.go('/me'),
                child: UserAvatar(user, size: 36),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gradient "N" logo.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: AppTokens.accent,
      borderRadius: BorderRadius.circular(size * 0.3),
      boxShadow: [
        BoxShadow(
          color: AppTokens.violet.withValues(alpha: 0.45),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Center(
      child: Text(
        'N',
        style: TextStyle(
          fontFamily: AppTokens.display,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: size * 0.5,
        ),
      ),
    ),
  );
}
