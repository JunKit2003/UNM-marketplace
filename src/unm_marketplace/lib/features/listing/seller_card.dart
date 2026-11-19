import 'package:flutter/material.dart';

import '../../core/api/models.dart';
import '../../widgets/avatar.dart';
import '../../widgets/glass_panel.dart';

class SellerCard extends StatelessWidget {
  const SellerCard({super.key, required this.seller});
  final PublicUser seller;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        UserAvatar(seller, size: 48),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(seller.displayName, style: t.titleMedium),
            Text('@${seller.username} · UNM community', style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
        const Icon(Icons.verified_rounded, color: Color(0xFF22D3EE), size: 20),
      ]),
    );
  }
}
