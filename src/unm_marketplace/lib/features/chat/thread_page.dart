import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/models.dart';
import '../../core/format.dart';
import '../../state/auth.dart';
import '../../theme/tokens.dart';
import '../../widgets/avatar.dart';
import '../../widgets/net_image.dart';
import 'chat_controller.dart';
import 'inbox_page.dart';
import 'message_bubble.dart';
import 'typing_dots.dart';

/// Route target for /messages/:id: full screen on phones, two-pane on wide screens.
class ThreadPage extends StatelessWidget {
  const ThreadPage({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context) => InboxPage(selectedId: id);
}

class ThreadView extends ConsumerStatefulWidget {
  const ThreadView({super.key, required this.id});
  final int id;

  @override
  ConsumerState<ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends ConsumerState<ThreadView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  DateTime _lastTyping = DateTime(2000);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      // The list is reversed: the top of the history is the end of the scroll extent.
      if (_scroll.position.extentAfter < 200) ref.read(threadProvider(widget.id).notifier).loadOlder();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    ref.read(threadProvider(widget.id).notifier).send(text);
    _focus.requestFocus();
  }

  void _onChanged(String _) {
    final now = DateTime.now();
    if (now.difference(_lastTyping) > const Duration(seconds: 2)) {
      _lastTyping = now;
      ref.read(threadProvider(widget.id).notifier).typing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(threadProvider(widget.id));
    final me = ref.watch(authProvider).value?.id;
    final narrow = MediaQuery.sizeOf(context).width < 1000;
    final s = async.value;
    final removed = s?.removed ?? false;

    return Column(children: [
      _Header(conversation: s?.conversation, removed: removed, showBack: narrow),
      Expanded(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text("Couldn't load this chat.")),
          data: (s) {
            final items = s.messages.reversed.toList();
            ThreadMessage? lastMine;
            for (final t in s.messages) {
              if (t.message.senderId == me) lastMine = t;
            }
            return ListView.builder(
              controller: _scroll,
              reverse: true,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: items.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: s.otherTyping
                        ? const Align(
                            key: Key('typing-dots'),
                            alignment: Alignment.centerLeft,
                            child: Padding(padding: EdgeInsets.only(top: 8), child: TypingDots()),
                          )
                        : const SizedBox.shrink(),
                  );
                }
                final idx = i - 1;
                final item = items[idx];
                final mine = item.message.senderId == me;
                final older = idx + 1 < items.length ? items[idx + 1] : null;
                final first = older == null || older.message.senderId != item.message.senderId;
                return MessageBubble(
                  key: ValueKey(item.localId ?? item.message.id),
                  item: item,
                  mine: mine,
                  firstInGroup: first,
                  showSeen: mine && identical(item, lastMine) && item.message.isRead,
                  onRetry: () => ref.read(threadProvider(widget.id).notifier).send(item.message.body, retryLocalId: item.localId),
                ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.15, curve: Curves.easeOutCubic);
              },
            );
          },
        ),
      ),
      _Composer(
        key: const Key('composer'),
        controller: _input,
        focusNode: _focus,
        enabled: s != null && !removed && s.conversation?.listing.status != 'sold',
        hint: removed ? 'This chat is closed' : 'Write a message…',
        onSend: _send,
        onChanged: _onChanged,
      ),
    ]);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.conversation, required this.removed, required this.showBack});
  final Conversation? conversation;
  final bool removed;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = conversation;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
      child: Row(children: [
        if (showBack) IconButton(tooltip: 'Back to messages', onPressed: () => context.go('/messages'), icon: const Icon(Icons.arrow_back_rounded)),
        if (removed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 10),
                const Expanded(child: Text('This listing was removed.')),
              ]),
            ),
          )
        else if (c != null) ...[
          UserAvatar(c.otherUser, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.otherUser.displayName, style: t.titleMedium, overflow: TextOverflow.ellipsis),
              Text('@${c.otherUser.username}', style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push('/listing/${c.listing.id}'),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                ClipRRect(borderRadius: BorderRadius.circular(9), child: SizedBox(width: 38, height: 38, child: NetImage(c.listing.coverUrl))),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.listing.title, overflow: TextOverflow.ellipsis, style: t.labelLarge),
                    Text(c.listing.status == 'sold' ? 'Sold' : formatPrice(c.listing.price),
                        style: t.labelMedium?.copyWith(color: c.listing.status == 'sold' ? AppTokens.pink : AppTokens.cyan, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(width: 4),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hint,
    required this.onSend,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String hint;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                onChanged: onChanged,
                decoration: InputDecoration(hintText: hint, counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(gradient: enabled ? AppTokens.accent : null, shape: BoxShape.circle),
              child: IconButton(
                tooltip: 'Send',
                onPressed: enabled ? onSend : null,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ]),
        ),
      );
}
