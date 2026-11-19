import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/api/models.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../state/auth.dart';
import '../../state/listing_actions.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/shimmer.dart';
import 'gallery.dart';
import 'listing_controller.dart';
import 'seller_card.dart';

class ListingDetailPage extends ConsumerStatefulWidget {
  const ListingDetailPage({super.key, required this.id, this.openChat = false});
  final int id;
  final bool openChat;

  @override
  ConsumerState<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends ConsumerState<ListingDetailPage> {
  bool _busy = false;
  bool _autoChatDone = false;

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _message() async {
    if (ref.read(authProvider).value == null) {
      context.go(
        '/login?from=${Uri.encodeComponent('/listing/${widget.id}?chat=1')}',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final c = await ref.read(chatRepositoryProvider).start(widget.id);
      if (mounted) context.go('/messages/${c.id}');
    } on ApiError catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleSave(Listing l) async {
    final saved = await toggleSave(context, ref, l);
    if (saved != null) {
      ref
          .read(listingProvider(widget.id).notifier)
          .set(l.copyWith(isSaved: saved));
      ref.read(listingsVersionProvider.notifier).bump();
    }
  }

  Future<void> _share() async {
    await Clipboard.setData(
      ClipboardData(text: '${apiBase()}/listing/${widget.id}'),
    );
    _snack('Link copied');
  }

  Future<void> _setStatus(String status) async {
    try {
      await ref.read(listingProvider(widget.id).notifier).setStatus(status);
      _snack(status == 'sold' ? 'Marked as sold' : 'Back on sale');
    } on ApiError catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete this listing?'),
        content: const Text(
          'It will disappear for everyone, including chats about it. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(c).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(listingProvider(widget.id).notifier).delete();
      if (!mounted) return;
      _snack('Listing deleted');
      context.go('/me');
    } on ApiError catch (e) {
      _snack(e.message);
    }
  }

  void _maybeAutoChat(Listing l) {
    if (!widget.openChat || _autoChatDone || l.isOwner || l.isSold) return;
    if (ref.read(authProvider).value == null) return;
    _autoChatDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _message());
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(listingProvider(widget.id));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: async.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => EmptyState(
          icon: Icons.search_off_rounded,
          title: ApiError.from(e).isNotFound
              ? "This listing doesn't exist or was removed."
              : "Couldn't load this listing",
          action: FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to browse'),
          ),
        ),
        data: (l) {
          _maybeAutoChat(l);
          return SelectionArea(
            child: _DetailBody(
              listing: l,
              busy: _busy,
              onMessage: _message,
              onSave: () => _toggleSave(l),
              onShare: _share,
              onEdit: () => context.push('/listing/${l.id}/edit'),
              onSold: () => _setStatus(l.isSold ? 'active' : 'sold'),
              onDelete: _delete,
            ),
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.listing,
    required this.busy,
    required this.onMessage,
    required this.onSave,
    required this.onShare,
    required this.onEdit,
    required this.onSold,
    required this.onDelete,
  });

  final Listing listing;
  final bool busy;
  final VoidCallback onMessage, onSave, onShare, onEdit, onSold, onDelete;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1000;
    final l = listing;

    final back = Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('Back'),
      ),
    );

    final info = _Info(listing: l);
    final actions = _Actions(
      listing: l,
      busy: busy,
      onMessage: onMessage,
      onSave: onSave,
      onShare: onShare,
      onEdit: onEdit,
      onSold: onSold,
      onDelete: onDelete,
    );

    if (wide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 16, 40, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                back,
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: Gallery(listing: l)),
                    const SizedBox(width: 40),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [info, const SizedBox(height: 24), actions],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              back,
              const SizedBox(height: 8),
              Gallery(listing: l),
              const SizedBox(height: 20),
              info,
            ],
          ),
        ),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: actions,
            ),
          ),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: Icon(categoryIcon(l.category.icon), size: 16),
                  label: Text(l.category.name),
                ),
                ConditionPill(l.condition),
                if (l.isSold) const SoldBadge(),
              ],
            ),
            const SizedBox(height: 14),
            Text(l.title, style: t.headlineMedium),
            const SizedBox(height: 10),
            ShaderMask(
              shaderCallback: (r) => AppTokens.accent.createShader(r),
              blendMode: BlendMode.srcIn,
              child: Text(
                formatPrice(l.price),
                style: t.displaySmall?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Posted ${timeAgo(l.createdAt)}',
              style: t.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 22),
            Text('About this item', style: t.titleMedium),
            const SizedBox(height: 8),
            Text(l.description, style: t.bodyLarge?.copyWith(height: 1.6)),
            const SizedBox(height: 24),
            SellerCard(seller: l.seller),
          ],
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.04, curve: Curves.easeOutCubic);
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.listing,
    required this.busy,
    required this.onMessage,
    required this.onSave,
    required this.onShare,
    required this.onEdit,
    required this.onSold,
    required this.onDelete,
  });

  final Listing listing;
  final bool busy;
  final VoidCallback onMessage, onSave, onShare, onEdit, onSold, onDelete;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final share = IconButton.outlined(
      tooltip: 'Copy link',
      onPressed: onShare,
      icon: const Icon(Icons.ios_share_rounded),
    );
    if (l.isOwner) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit'),
          ),
          OutlinedButton.icon(
            onPressed: onSold,
            icon: Icon(
              l.isSold
                  ? Icons.replay_rounded
                  : Icons.check_circle_outline_rounded,
            ),
            label: Text(l.isSold ? 'Mark as available' : 'Mark as sold'),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete'),
          ),
          share,
        ],
      );
    }
    return Row(
      children: [
        if (!l.isSold)
          Expanded(
            child: FilledButton.icon(
              onPressed: busy ? null : onMessage,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chat_bubble_rounded),
              label: const Text('Message seller'),
            ),
          )
        else
          const Expanded(
            child: OutlinedButton(
              onPressed: null,
              child: Text('This item has been sold'),
            ),
          ),
        const SizedBox(width: 10),
        SaveHeart(saved: l.isSaved, onPressed: onSave, size: 22),
        const SizedBox(width: 6),
        share,
      ],
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(aspectRatio: 16 / 9, child: Shimmer()),
        SizedBox(height: 20),
        Shimmer(height: 28, width: 320),
        SizedBox(height: 12),
        Shimmer(height: 36, width: 160),
      ],
    ),
  );
}
