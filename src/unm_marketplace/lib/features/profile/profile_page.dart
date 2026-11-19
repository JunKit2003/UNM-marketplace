import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/api/models.dart';
import '../../state/auth.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/avatar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../saved/saved_page.dart';
import '../sell/photo_picker.dart';
import '../sell/validators.dart';
import 'account_sheets.dart';

final myListingsProvider = FutureProvider.autoDispose.family<List<Listing>, String>((ref, status) {
  ref.watch(listingsVersionProvider);
  return ref.read(listingsRepositoryProvider).mine(status: status);
});

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String _tab = 'active';

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _changePhoto() async {
    final picked = await ref.read(photoPickerProvider)();
    if (picked.isEmpty) return;
    final p = picked.first;
    if (validatePhoto(p) != null) return _snack(photoError);
    try {
      final u = await ref.read(authRepositoryProvider).uploadAvatar(p);
      ref.read(authProvider.notifier).updated(u);
      _snack('Photo updated');
    } on ApiError catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    if (user == null) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final pad = MediaQuery.sizeOf(context).width < 720 ? 16.0 : 40.0;
    final mine = ref.watch(myListingsProvider(_tab));
    final mode = ref.watch(themeModeProvider);

    final header = GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Wrap(spacing: 24, runSpacing: 20, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Stack(children: [
          DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTokens.violet.withValues(alpha: 0.5), blurRadius: 30)]),
            child: UserAvatar(user, size: 96),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton.filled(tooltip: 'Change photo', onPressed: _changePhoto, icon: const Icon(Icons.photo_camera_rounded, size: 18)),
          ),
        ]),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.displayName, style: t.headlineMedium),
            const SizedBox(height: 4),
            Text(user.isGuest ? 'Guest account · resets nightly' : '@${user.username}${user.email == null ? '' : ' · ${user.email}'}',
                style: t.bodyMedium?.copyWith(color: muted)),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [
              OutlinedButton.icon(
                onPressed: () => showEditProfileSheet(context, ref, user),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit profile'),
              ),
              if (!user.isGuest)
                OutlinedButton.icon(
                  onPressed: () => showChangePasswordSheet(context, ref),
                  icon: const Icon(Icons.lock_reset_rounded, size: 18),
                  label: const Text('Change password'),
                ),
            ]),
            if (user.isGuest) ...[
              const SizedBox(height: 10),
              Text("Guest accounts can't set a password.", style: t.bodySmall?.copyWith(color: muted)),
            ],
          ]),
        ),
      ]),
    );

    return CustomScrollView(slivers: [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(pad, 32, pad, 0),
        sliver: SliverList.list(children: [
          header,
          const SizedBox(height: 32),
          Row(children: [
            Text('My listings', style: t.headlineSmall),
            const Spacer(),
            SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'active', label: Text('Active')), ButtonSegment(value: 'sold', label: Text('Sold'))],
              selected: {_tab},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ]),
          const SizedBox(height: 16),
          mine.when(
            loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => EmptyState(icon: Icons.wifi_off_rounded, title: ApiError.from(e).message),
            data: (items) => items.isEmpty
                ? EmptyState(
                    icon: Icons.sell_outlined,
                    title: _tab == 'active' ? 'Nothing for sale yet.' : 'Nothing sold yet.',
                    action: _tab == 'active' ? FilledButton(onPressed: () => context.go('/sell'), child: const Text('Sell something')) : null,
                  )
                : ListingGrid(listings: items),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: Icon(mode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            title: Text(mode == ThemeMode.dark ? 'Switch to light mode' : 'Switch to dark mode'),
            onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About this project'),
            onTap: () => context.go('/about'),
          ),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: Theme.of(context).colorScheme.error),
            title: Text('Log out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: _logout,
          ),
          const SizedBox(height: 48),
        ]),
      ),
    ]);
  }
}
