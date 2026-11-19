import 'package:flutter/material.dart';

import '../core/api/models.dart';
import '../core/format.dart';
import '../theme/tokens.dart';
import 'net_image.dart';

/// Photo-first listing card. Lifts and glows on hover; the cover is a Hero into the detail page.
class ListingCard extends StatefulWidget {
  const ListingCard({super.key, required this.listing, required this.onTap, this.onSaveToggle, this.aspectRatio = 4 / 3});

  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback? onSaveToggle;
  final double aspectRatio;

  static String heroTag(int id) => 'listing-cover-$id';

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${l.title}, ${formatPrice(l.price)}, ${l.condition}${l.isSold ? ', sold' : ''}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            color: scheme.surfaceContainerLow,
            border: Border.all(color: _hover ? AppTokens.violet.withValues(alpha: 0.6) : scheme.outlineVariant),
            boxShadow: [
              if (_hover) BoxShadow(color: AppTokens.violet.withValues(alpha: 0.28), blurRadius: 28, offset: const Offset(0, 12)),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              onTap: widget.onTap,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radius)),
                  child: AspectRatio(
                    aspectRatio: widget.aspectRatio,
                    child: Stack(fit: StackFit.expand, children: [
                      Hero(
                        tag: ListingCard.heroTag(l.id),
                        child: AnimatedScale(
                          scale: _hover ? 1.06 : 1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          child: NetImage(l.coverUrl),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.55, 1],
                            colors: [Colors.transparent, Color(0xB3000000)],
                          ),
                        ),
                      ),
                      Positioned(left: 12, bottom: 10, child: _PriceChip(price: l.price)),
                      if (widget.onSaveToggle != null && !l.isOwner)
                        Positioned(top: 8, right: 8, child: SaveHeart(saved: l.isSaved, onPressed: widget.onSaveToggle!)),
                      if (l.isSold) const Positioned(top: 12, left: 12, child: SoldBadge()),
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.25)),
                    const SizedBox(height: 8),
                    Row(children: [
                      ConditionPill(l.condition),
                      const Spacer(),
                      Text(timeAgo(l.createdAt), style: t.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.price});
  final num price;

  @override
  Widget build(BuildContext context) => Text(
        formatPrice(price),
        style: const TextStyle(
          color: Colors.white,
          fontFamily: AppTokens.display,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          shadows: [Shadow(color: Color(0x99000000), blurRadius: 8)],
        ),
      );
}

class ConditionPill extends StatelessWidget {
  const ConditionPill(this.condition, {super.key});
  final String condition;

  Color get _color => switch (condition) {
        'Brand new' => AppTokens.mint,
        'Like new' => AppTokens.cyan,
        'Lightly used' => AppTokens.violet,
        'Well used' => AppTokens.amber,
        _ => AppTokens.pink,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _color.withValues(alpha: 0.4)),
        ),
        child: Text(condition, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color)),
      );
}

class SoldBadge extends StatelessWidget {
  const SoldBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppTokens.pink, borderRadius: BorderRadius.circular(999)),
        child: const Text('Sold', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

/// Heart with a springy pop when saved.
class SaveHeart extends StatelessWidget {
  const SaveHeart({super.key, required this.saved, required this.onPressed, this.size = 20});
  final bool saved;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: saved ? 'Remove from saved' : 'Save',
          onPressed: onPressed,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: child),
            child: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(saved),
              size: size,
              color: saved ? AppTokens.pink : Colors.white,
            ),
          ),
        ),
      );
}
