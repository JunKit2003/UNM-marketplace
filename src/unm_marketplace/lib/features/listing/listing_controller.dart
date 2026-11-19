import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/models.dart';
import '../../state/auth.dart';
import '../../state/providers.dart';

class ListingController extends AsyncNotifier<Listing> {
  ListingController(this.id);
  final int id;

  @override
  Future<Listing> build() {
    ref.watch(authProvider.select((a) => a.value?.id));
    return ref.read(listingsRepositoryProvider).get(id);
  }

  void set(Listing l) => state = AsyncData(l);

  Future<void> setStatus(String status) async {
    final updated = await ref.read(listingsRepositoryProvider).update(id, {'status': status});
    state = AsyncData(updated);
    ref.read(listingsVersionProvider.notifier).bump();
  }

  Future<void> delete() async {
    await ref.read(listingsRepositoryProvider).delete(id);
    ref.read(listingsVersionProvider.notifier).bump();
  }
}

final listingProvider = AsyncNotifierProvider.autoDispose.family<ListingController, Listing, int>(ListingController.new);
