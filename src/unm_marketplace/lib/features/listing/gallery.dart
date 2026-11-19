import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/net_image.dart';

/// Swipeable photo gallery: dots, arrow buttons and keys, tap for fullscreen.
/// The first photo continues the card's Hero animation.
class Gallery extends StatefulWidget {
  const Gallery({super.key, required this.listing, this.aspectRatio = 4 / 3});
  final Listing listing;
  final double aspectRatio;

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  final _controller = PageController();
  int _index = 0;

  List<ListingImage> get _images => widget.listing.images;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i < 0 || i >= _images.length) return;
    _controller.animateToPage(i, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final many = _images.length > 1;
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
          _go(_index + 1);
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _go(_index - 1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Stack(fit: StackFit.expand, children: [
            PageView.builder(
              controller: _controller,
              itemCount: _images.isEmpty ? 1 : _images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final img = NetImage(_images.isEmpty ? null : _images[i].url);
                return GestureDetector(
                  onTap: _images.isEmpty ? null : () => showFullscreenGallery(context, _images, i),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.zoomIn,
                    child: i == 0 ? Hero(tag: ListingCard.heroTag(widget.listing.id), child: img) : img,
                  ),
                );
              },
            ),
            if (widget.listing.isSold) const Positioned(top: 16, left: 16, child: SoldBadge()),
            if (many) ...[
              Positioned(left: 12, top: 0, bottom: 0, child: Center(child: _Arrow(Icons.chevron_left_rounded, 'Previous photo', _index > 0 ? () => _go(_index - 1) : null))),
              Positioned(right: 12, top: 0, bottom: 0, child: Center(child: _Arrow(Icons.chevron_right_rounded, 'Next photo', _index < _images.length - 1 ? () => _go(_index + 1) : null))),
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < _images.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: i == _index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow(this.icon, this.tooltip, this.onPressed);
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: onPressed == null ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: IconButton.filled(
          tooltip: tooltip,
          style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.45), foregroundColor: Colors.white),
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      );
}

/// Fullscreen, zoomable, swipeable photos. Escape or the close button exits.
Future<void> showFullscreenGallery(BuildContext context, List<ListingImage> images, int start) {
  return showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.95),
    barrierDismissible: true,
    barrierLabel: 'Close photos',
    pageBuilder: (context, _, _) {
      final controller = PageController(initialPage: start);
      return Stack(children: [
        PageView(
          controller: controller,
          children: [
            for (final img in images) InteractiveViewer(maxScale: 4, child: Center(child: NetImage(img.url, fit: BoxFit.contain))),
          ],
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton.filled(
            tooltip: 'Close',
            style: IconButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ]);
    },
  );
}
