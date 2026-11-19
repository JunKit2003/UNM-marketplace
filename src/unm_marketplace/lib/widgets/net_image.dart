import 'package:flutter/material.dart';

import '../core/config.dart';
import 'shimmer.dart';

/// Network image for API paths, with a shimmer while loading, a fade-in and a soft fallback.
/// The browser's HTTP cache does the caching (nginx sends Cache-Control for /images).
class NetImage extends StatelessWidget {
  const NetImage(this.path, {super.key, this.fit = BoxFit.cover});
  final String? path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Center(child: Icon(Icons.image_not_supported_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
    if (path == null) return fallback;
    return Image.network(
      resolveUrl(path!),
      fit: fit,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, sync) => sync
          ? child
          : Stack(fit: StackFit.expand, children: [
              if (frame == null) const Shimmer(radius: 0),
              AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 300), child: child),
            ]),
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
