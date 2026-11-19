import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/models.dart';
import '../../core/format.dart';
import '../../state/auth.dart';
import '../../theme/tokens.dart';
import '../../widgets/avatar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/net_image.dart';
import 'chat_controller.dart';
import 'thread_page.dart';

/// Inbox. From 1000 px wide it shows the inbox and the open thread side by side.
class InboxPage extends StatelessWidget {
  const InboxPage({super.key, this.selectedId});
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    if (!wide) {
      return selectedId == null
          ? const _InboxList()
          : ThreadView(id: selectedId!);
    }
    return Row(
      children: [
        SizedBox(width: 380, child: _InboxList(selectedId: selectedId)),
        VerticalDivider(
          width: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        Expanded(
          child: selectedId == null
              ? const EmptyState(
                  icon: Icons.forum_rounded,
                  title: 'Pick a chat',
                  message:
                      'Your conversations with buyers and sellers show up here.',
                )
              : ThreadView(key: ValueKey(selectedId), id: selectedId!),
        ),
      ],
    );
  }
}

class _InboxList extends ConsumerWidget {
  const _InboxList({this.selectedId});
  final int? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inboxProvider);
    final me = ref.watch(authProvider).value?.id;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          child: Text('Messages', style: t.displaySmall),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => EmptyState(
              icon: Icons.wifi_off_rounded,
              title: "Couldn't load your chats",
              action: FilledButton(
                onPressed: () => ref.invalidate(inboxProvider),
                child: const Text('Try again'),
              ),
            ),
            data: (list) => list.isEmpty
                ? EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title:
                        'No chats yet. Find something you like and message the seller.',
                    action: FilledButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Browse listings'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, i) =>
                        _InboxTile(
                              c: list[i],
                              selected: list[i].id == selectedId,
                              me: me,
                            )
                            .animate()
                            .fadeIn(delay: (30 * i).ms, duration: 300.ms)
                            .slideX(begin: -0.04),
                  ),
          ),
        ),
      ],
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.c, required this.selected, required this.me});
  final Conversation c;
  final bool selected;
  final int? me;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final unread = c.unreadCount > 0;
    final last = c.lastMessage;
    return Material(
      color: selected
          ? AppTokens.violet.withValues(alpha: 0.16)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/messages/${c.id}'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox.expand(
                        child: NetImage(c.listing.coverUrl),
                      ),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: UserAvatar(c.otherUser, size: 26),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.otherUser.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleSmall?.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (last != null)
                          Text(
                            timeAgo(last.createdAt),
                            style: t.labelSmall?.copyWith(color: muted),
                          ),
                      ],
                    ),
                    Text(
                      c.listing.title,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelMedium?.copyWith(color: AppTokens.cyan),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            last == null
                                ? 'Say hi 👋'
                                : '${last.senderId == me ? 'You: ' : ''}${last.body}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall?.copyWith(
                              color: unread ? null : muted,
                              fontWeight: unread ? FontWeight.w600 : null,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            key: Key('unread-${c.id}'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTokens.pink,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${c.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
