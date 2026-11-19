import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/config.dart';
import 'shimmer.dart';

/// Network image for API paths, with a shimmer while loading and a soft fallback.
class NetImage extends StatelessWidget {
  const NetImage(this.path, {super.key, this.fit = BoxFit.cover});
  final String? path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Icon(Icons.image_not_supported_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
    if (path == null) return fallback;
    return CachedNetworkImage(
      imageUrl: resolveUrl(path!),
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, _) => const Shimmer(radius: 0),
      errorWidget: (_, _, _) => fallback,
    );
  }
}
