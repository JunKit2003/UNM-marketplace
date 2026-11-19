import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/models.dart';
import '../../state/listing_actions.dart';
import '../../state/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/masonry_grid.dart';

final savedListingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) {
  ref.watch(listingsVersionProvider);
  return ref.read(listingsRepositoryProvider).saved();
});

/// A titled page of listing cards, shared by Saved and Profile.
class ListingGrid extends ConsumerWidget {
  const ListingGrid({super.key, required this.listings, this.onChanged});
  final List<Listing> listings;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MasonryGrid<Listing>(
        items: listings,
        heightOf: (_) => 1,
        itemBuilder: (context, l, i) => ListingCard(
          listing: l,
          onTap: () => context.push('/listing/${l.id}'),
          onSaveToggle: () async {
            if (await toggleSave(context, ref, l) != null) {
              ref.read(listingsVersionProvider.notifier).bump();
              onChanged?.call();
            }
          },
        ).animate().fadeIn(delay: (40 * (i % 12)).ms, duration: 400.ms).slideY(begin: 0.06),
      );
}

class SavedPage extends ConsumerWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedListingsProvider);
    final pad = MediaQuery.sizeOf(context).width < 720 ? 16.0 : 40.0;
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(pad, 32, pad, 8),
        sliver: SliverToBoxAdapter(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Saved', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 6),
            Text('Things you have your eye on.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 48),
        sliver: SliverToBoxAdapter(
          child: async.when(
            loading: () => const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => EmptyState(
              icon: Icons.wifi_off_rounded,
              title: "Couldn't load your saved listings",
              action: FilledButton(onPressed: () => ref.invalidate(savedListingsProvider), child: const Text('Try again')),
            ),
            data: (items) => items.isEmpty
                ? EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'No saved listings yet. Tap the heart on anything you like.',
                    action: FilledButton(onPressed: () => context.go('/'), child: const Text('Start browsing')),
                  )
                : ListingGrid(listings: items),
          ),
        ),
      ),
    ]);
  }
}
