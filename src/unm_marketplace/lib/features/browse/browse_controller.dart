import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/models.dart';
import '../../core/repositories/listings_repository.dart';
import '../../state/auth.dart';
import '../../state/providers.dart';

class BrowseState {
  const BrowseState({required this.items, required this.page, required this.hasMore, required this.total, this.loadingMore = false});
  final List<Listing> items;
  final int page;
  final bool hasMore;
  final int total;
  final bool loadingMore;

  BrowseState copyWith({List<Listing>? items, int? page, bool? hasMore, bool? loadingMore}) => BrowseState(
        items: items ?? this.items,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        total: total,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

/// Listings for one set of filters (the page URL), with infinite scroll.
class BrowseController extends AsyncNotifier<BrowseState> {
  BrowseController(this.filters);
  final BrowseFilters filters;

  ListingsRepository get _repo => ref.read(listingsRepositoryProvider);

  @override
  Future<BrowseState> build() async {
    ref.watch(listingsVersionProvider);
    ref.watch(authProvider.select((a) => a.value?.id)); // isSaved / isOwner depend on who's looking
    final first = await _repo.search(filters);
    return BrowseState(items: first.items, page: 1, hasMore: first.hasMore, total: first.total);
  }

  Future<void> loadMore() async {
    final s = state.value;
    if (s == null || !s.hasMore || s.loadingMore) return;
    state = AsyncData(s.copyWith(loadingMore: true));
    try {
      final next = await _repo.search(filters, page: s.page + 1);
      state = AsyncData(s.copyWith(items: [...s.items, ...next.items], page: next.page, hasMore: next.hasMore, loadingMore: false));
    } catch (_) {
      state = AsyncData(s.copyWith(loadingMore: false));
    }
  }

  void replace(Listing updated) {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(items: [for (final l in s.items) l.id == updated.id ? updated : l]));
  }
}

final browseProvider = AsyncNotifierProvider.autoDispose.family<BrowseController, BrowseState, BrowseFilters>(BrowseController.new);
