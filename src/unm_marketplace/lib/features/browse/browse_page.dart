import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/models.dart';
import '../../core/repositories/listings_repository.dart';
import '../../state/listing_actions.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/masonry_grid.dart';
import '../../widgets/shimmer.dart';
import 'browse_controller.dart';
import 'category_strip.dart';
import 'filter_sheet.dart';
import 'hero_header.dart';

const _aspects = [4 / 3, 1.0, 4 / 5, 5 / 4];
double _aspectFor(Listing l) => _aspects[l.id % _aspects.length];

class BrowsePage extends ConsumerWidget {
  const BrowsePage({super.key});

  void _apply(BuildContext context, BrowseFilters f) {
    final q = f.toQuery();
    context.go(Uri(path: '/', queryParameters: q.isEmpty ? null : q).toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = BrowseFilters.fromQuery(GoRouterState.of(context).uri.queryParameters);
    final provider = browseProvider(filters);
    final async = ref.watch(provider);
    final width = MediaQuery.sizeOf(context).width;
    final pad = width < 720 ? 16.0 : 40.0;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 800) ref.read(provider.notifier).loadMore();
        return false;
      },
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: HeroHeader(
            initialQuery: filters.q ?? '',
            total: async.value?.total,
            onSearch: (q) => _apply(context, filters.copyWith(q: q.isEmpty ? null : q)),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _ToolbarDelegate(
            child: _Toolbar(filters: filters, onChange: (f) => _apply(context, f)),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 8, pad, 48),
          sliver: SliverToBoxAdapter(
            child: async.when(
              loading: () => _Skeleton(),
              error: (e, _) => EmptyState(
                icon: Icons.wifi_off_rounded,
                title: "Couldn't load listings",
                message: 'Check your connection and try again.',
                action: FilledButton(onPressed: () => ref.invalidate(provider), child: const Text('Try again')),
              ),
              data: (s) => s.items.isEmpty
                  ? EmptyState(
                      icon: Icons.storefront_rounded,
                      title: 'Nothing here yet. Be the first to sell something.',
                      action: filters.isEmpty
                          ? FilledButton(onPressed: () => context.go('/sell'), child: const Text('Sell something'))
                          : OutlinedButton(onPressed: () => context.go('/'), child: const Text('Clear filters')),
                    )
                  : Column(children: [
                      MasonryGrid<Listing>(
                        items: s.items,
                        heightOf: (l) => 1 / _aspectFor(l) + 0.45,
                        itemBuilder: (context, l, i) => ListingCard(
                          listing: l,
                          aspectRatio: _aspectFor(l),
                          onTap: () => context.push('/listing/${l.id}'),
                          onSaveToggle: () async {
                            final saved = await toggleSave(context, ref, l);
                            if (saved != null) ref.read(provider.notifier).replace(l.copyWith(isSaved: saved));
                          },
                        )
                            .animate()
                            .fadeIn(delay: (40 * (i % 12)).ms, duration: 450.ms)
                            .slideY(begin: 0.08, curve: Curves.easeOutCubic),
                      ),
                      if (s.loadingMore)
                        const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
                      else if (!s.hasMore && s.items.length > 8)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text("You've seen everything 🎉", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ),
                    ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.filters, required this.onChange});
  final BrowseFilters filters;
  final ValueChanged<BrowseFilters> onChange;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.sizeOf(context).width < 720 ? 16.0 : 40.0;
    final n = filters.activeFilterCount;
    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 10),
      child: Row(children: [
        Expanded(child: CategoryStrip(selected: filters.categorySlug, onSelect: (c) => onChange(filters.copyWith(categorySlug: c)))),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Sort',
          initialValue: filters.sort,
          onSelected: (s) => onChange(filters.copyWith(sort: s)),
          itemBuilder: (_) => [
            for (final e in BrowseFilters.sorts.entries) PopupMenuItem(value: e.key, child: Text(e.value)),
          ],
          child: Chip(avatar: const Icon(Icons.swap_vert_rounded, size: 18), label: Text(BrowseFilters.sorts[filters.sort]!)),
        ),
        const SizedBox(width: 8),
        Badge(
          isLabelVisible: n > 0,
          label: Text('$n'),
          child: IconButton.filledTonal(
            tooltip: 'Filters',
            onPressed: () async {
              final f = await showFilterSheet(context, filters);
              if (f != null) onChange(f);
            },
            icon: const Icon(Icons.tune_rounded),
          ),
        ),
      ]),
    );
  }
}

class _ToolbarDelegate extends SliverPersistentHeaderDelegate {
  _ToolbarDelegate({required this.child});
  final Widget child;

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_ToolbarDelegate old) => old.child != child;
}

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MasonryGrid<int>(
        items: List.generate(10, (i) => i),
        heightOf: (i) => 1 / _aspects[i % 4] + 0.45,
        itemBuilder: (_, i, _) => Column(children: [
          AspectRatio(aspectRatio: _aspects[i % 4], child: const Shimmer()),
          const SizedBox(height: 10),
          const Shimmer(height: 14),
          const SizedBox(height: 8),
          const Shimmer(height: 12, width: 90),
        ]),
      );
}
