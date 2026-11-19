import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/api/models.dart';
import '../../state/auth.dart';
import '../../state/providers.dart';

/// Inbox, refreshed whenever a live message arrives.
class InboxController extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    final sub = ref
        .watch(chatSocketProvider)
        .messages
        .listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    return ref.read(chatRepositoryProvider).list();
  }
}

final inboxProvider =
    AsyncNotifierProvider.autoDispose<InboxController, List<Conversation>>(
      InboxController.new,
    );

enum SendState { sent, sending, failed }

class ThreadMessage {
  const ThreadMessage(
    this.message, {
    this.state = SendState.sent,
    this.localId,
  });
  final Message message;
  final SendState state;
  final int? localId;
}

class ThreadState {
  const ThreadState({
    required this.conversation,
    required this.messages,
    this.removed = false,
    this.otherTyping = false,
    this.hasOlder = true,
    this.loadingOlder = false,
  });

  final Conversation? conversation;
  final List<ThreadMessage> messages;
  final bool removed;
  final bool otherTyping;
  final bool hasOlder;
  final bool loadingOlder;

  ThreadState copyWith({
    List<ThreadMessage>? messages,
    bool? otherTyping,
    bool? hasOlder,
    bool? loadingOlder,
  }) => ThreadState(
    conversation: conversation,
    messages: messages ?? this.messages,
    removed: removed,
    otherTyping: otherTyping ?? this.otherTyping,
    hasOlder: hasOlder ?? this.hasOlder,
    loadingOlder: loadingOlder ?? this.loadingOlder,
  );
}

/// One open conversation: history, live messages, typing, optimistic sends and retries.
class ThreadController extends AsyncNotifier<ThreadState> {
  ThreadController(this.id);
  final int id;
  Timer? _typingTimer;
  int _nextLocal = -1;

  int get _me => ref.read(authProvider).value?.id ?? -1;

  @override
  Future<ThreadState> build() async {
    final repo = ref.read(chatRepositoryProvider);
    final socket = ref.read(chatSocketProvider);
    ref.onDispose(() => _typingTimer?.cancel());

    Conversation conversation;
    try {
      conversation = await repo.get(id);
    } on ApiError catch (e) {
      if (e.isNotFound) {
        return const ThreadState(
          conversation: null,
          messages: [],
          removed: true,
          hasOlder: false,
        );
      }
      rethrow;
    }
    final history = await repo.messages(id);

    final subs = [
      socket.messages
          .where((e) => e.conversationId == id)
          .listen((e) => _incoming(e.message)),
      socket.typing
          .where((e) => e.conversationId == id && e.userId != _me)
          .listen((_) => _showTyping()),
      socket.reads
          .where((e) => e.conversationId == id && e.userId != _me)
          .listen((_) => _markMineRead()),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        s.cancel();
      }
    });

    unawaited(_markRead(initial: true));
    return ThreadState(
      conversation: conversation,
      messages: [for (final m in history) ThreadMessage(m)],
      hasOlder: history.length >= 50,
    );
  }

  Future<void> _markRead({bool initial = false}) async {
    final socket = ref.read(chatSocketProvider);
    try {
      if (!initial && socket.isConnected) {
        socket.markRead(id);
      } else {
        await ref.read(chatRepositoryProvider).read(id);
      }
      await ref.read(unreadCountProvider.notifier).refresh();
    } catch (_) {}
  }

  void _incoming(Message m) {
    final s = state.value;
    if (s == null || s.messages.any((t) => t.message.id == m.id)) return;
    state = AsyncData(
      s.copyWith(
        messages: [...s.messages, ThreadMessage(m)],
        otherTyping: m.senderId == _me ? null : false,
      ),
    );
    if (m.senderId != _me) _markRead();
  }

  void _showTyping() {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(otherTyping: true));
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      final cur = state.value;
      if (cur != null) state = AsyncData(cur.copyWith(otherTyping: false));
    });
  }

  void _markMineRead() {
    final s = state.value;
    if (s == null) return;
    final now = DateTime.now().toUtc();
    state = AsyncData(
      s.copyWith(
        messages: [
          for (final t in s.messages)
            t.message.senderId == _me && !t.message.isRead
                ? ThreadMessage(
                    t.message.markRead(now),
                    state: t.state,
                    localId: t.localId,
                  )
                : t,
        ],
      ),
    );
  }

  void typing() => ref.read(chatSocketProvider).sendTyping(id);

  Future<void> send(String body, {int? retryLocalId}) async {
    final s = state.value;
    if (s == null || s.removed) return;
    final localId = retryLocalId ?? _nextLocal--;
    final draft = Message(
      id: localId,
      conversationId: id,
      senderId: _me,
      body: body,
      createdAt: DateTime.now().toUtc(),
    );
    final pending = ThreadMessage(
      draft,
      state: SendState.sending,
      localId: localId,
    );
    state = AsyncData(
      s.copyWith(
        messages: [...s.messages.where((t) => t.localId != localId), pending],
      ),
    );
    try {
      final sent =
          await ref.read(chatSocketProvider).send(id, body) ??
          await ref.read(chatRepositoryProvider).send(id, body);
      final cur = state.value!;
      final already = cur.messages.any((t) => t.message.id == sent.id);
      state = AsyncData(
        cur.copyWith(
          messages: [
            for (final t in cur.messages)
              if (t.localId == localId) ...[
                if (!already) ThreadMessage(sent),
              ] else
                t,
          ],
        ),
      );
    } catch (_) {
      final cur = state.value!;
      state = AsyncData(
        cur.copyWith(
          messages: [
            for (final t in cur.messages)
              t.localId == localId
                  ? ThreadMessage(
                      draft,
                      state: SendState.failed,
                      localId: localId,
                    )
                  : t,
          ],
        ),
      );
    }
  }

  Future<void> loadOlder() async {
    final s = state.value;
    if (s == null || !s.hasOlder || s.loadingOlder || s.messages.isEmpty) {
      return;
    }
    state = AsyncData(s.copyWith(loadingOlder: true));
    try {
      final firstReal = s.messages
          .firstWhere((t) => t.message.id > 0, orElse: () => s.messages.first)
          .message
          .id;
      final older = await ref
          .read(chatRepositoryProvider)
          .messages(id, before: firstReal);
      final cur = state.value!;
      state = AsyncData(
        cur.copyWith(
          messages: [for (final m in older) ThreadMessage(m), ...cur.messages],
          hasOlder: older.length >= 50,
          loadingOlder: false,
        ),
      );
    } catch (_) {
      state = AsyncData(state.value!.copyWith(loadingOlder: false));
    }
  }
}

final threadProvider = AsyncNotifierProvider.autoDispose
    .family<ThreadController, ThreadState, int>(ThreadController.new);
