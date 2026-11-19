import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../theme/tokens.dart';

/// Slim strip telling visitors this is a showcase that resets nightly.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  static const text = 'Demo site. Data resets nightly. Built by Jun Kit';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppTokens.violet.withValues(alpha: 0.9),
            AppTokens.cyan.withValues(alpha: 0.9),
          ]),
        ),
        child: InkWell(
          onTap: () => launchUrl(Uri.parse(portfolioUrl), webOnlyWindowName: '_blank'),
          child: Semantics(
            link: true,
            label: '$text. Opens the portfolio.',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(text,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.north_east, size: 14, color: Colors.white),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
