import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/models.dart';
import '../core/realtime/chat_socket.dart';
import '../core/repositories/auth_repository.dart';
import '../core/repositories/chat_repository.dart';
import '../core/repositories/listings_repository.dart';
import 'auth.dart';

final dioProvider = Provider<Dio>((ref) => createDio());
final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);
final listingsRepositoryProvider = Provider(
  (ref) => ListingsRepository(ref.watch(dioProvider)),
);
final chatRepositoryProvider = Provider(
  (ref) => ChatRepository(ref.watch(dioProvider)),
);

/// One socket for the app, connected while someone is logged in.
final chatSocketProvider = Provider<ChatSocket>((ref) {
  final socket = ChatSocket();
  ref.onDispose(socket.disconnect);
  return socket;
});

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(listingsRepositoryProvider).categories(),
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;
  void toggle() =>
      state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Total unread messages, for the nav badge. Refreshed on login and on live events.
class UnreadController extends Notifier<int> {
  @override
  int build() {
    final user = ref.watch(authProvider).value;
    if (user == null) return 0;
    final socket = ref.watch(chatSocketProvider);
    final sub = socket.messages.listen((e) {
      if (e.message.senderId != user.id) state = state + 1;
    });
    ref.onDispose(sub.cancel);
    refresh();
    return 0;
  }

  Future<void> refresh() async {
    try {
      final n = await ref.read(chatRepositoryProvider).unread();
      if (ref.mounted) state = n;
    } catch (_) {
      // Badge is best-effort.
    }
  }
}

final unreadCountProvider = NotifierProvider<UnreadController, int>(
  UnreadController.new,
);

/// Bumped whenever listings change (save, edit, delete) so lists refetch.
class ListingsVersion extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final listingsVersionProvider = NotifierProvider<ListingsVersion, int>(
  ListingsVersion.new,
);
