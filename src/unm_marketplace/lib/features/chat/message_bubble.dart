import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../theme/tokens.dart';
import 'chat_controller.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.item,
    required this.mine,
    required this.senderName,
    required this.showSeen,
    required this.firstInGroup,
    this.onRetry,
  });
  final ThreadMessage item;
  final String senderName;
  final bool mine;
  final bool showSeen;
  final bool firstInGroup;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final m = item.message;
    final failed = item.state == SendState.failed;
    final r = const Radius.circular(20);
    final tight = const Radius.circular(6);
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.72 > 520
            ? 520
            : MediaQuery.sizeOf(context).width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: mine && !failed ? AppTokens.accent : null,
        color: mine
            ? (failed ? scheme.error.withValues(alpha: 0.25) : null)
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.only(
          topLeft: mine || firstInGroup ? r : tight,
          topRight: !mine || firstInGroup ? r : tight,
          bottomLeft: mine ? r : tight,
          bottomRight: mine ? tight : r,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            m.body,
            style: TextStyle(
              color: mine ? Colors.white : scheme.onSurface,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clockTime(m.createdAt),
                style: TextStyle(
                  fontSize: 10.5,
                  color: (mine ? Colors.white : scheme.onSurfaceVariant)
                      .withValues(alpha: 0.8),
                ),
              ),
              if (mine && item.state == SendState.sending) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.schedule_rounded,
                  size: 12,
                  color: Colors.white70,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(top: firstInGroup ? 10 : 2),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // One readable label per message instead of separate body/time fragments.
          Semantics(
            container: true,
            label:
                '$senderName: ${m.body}, ${clockTime(m.createdAt)}${item.state == SendState.sending ? ', sending' : ''}',
            child: ExcludeSemantics(child: bubble),
          ),
          if (failed)
            TextButton.icon(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: scheme.error,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.error_outline_rounded, size: 16),
              label: const Text('Not sent. Tap to retry.'),
            ),
          if (showSeen)
            Padding(
              padding: const EdgeInsets.only(top: 3, right: 4),
              child: Text(
                'Seen',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
