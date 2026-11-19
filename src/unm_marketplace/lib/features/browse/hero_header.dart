import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/auth.dart';
import '../../theme/tokens.dart';
import '../../widgets/gradient_mesh.dart';
import '../../widgets/glass_panel.dart';

/// Big gradient hero with the headline, search and the one-click demo.
class HeroHeader extends ConsumerStatefulWidget {
  const HeroHeader({
    super.key,
    required this.initialQuery,
    required this.onSearch,
    required this.total,
  });
  final String initialQuery;
  final ValueChanged<String> onSearch;
  final int? total;

  @override
  ConsumerState<HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends ConsumerState<HeroHeader> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  bool _demoBusy = false;

  @override
  void didUpdateWidget(HeroHeader old) {
    super.didUpdateWidget(old);
    if (old.initialQuery != widget.initialQuery &&
        _controller.text != widget.initialQuery) {
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _demo() async {
    setState(() => _demoBusy = true);
    try {
      await ref.read(authProvider.notifier).demo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "You're in! Check Messages, a seller already said hi 👋",
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't start the demo. Please try again."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _demoBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;
    final signedIn = ref.watch(authProvider).value != null;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final headline = ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        colors: [Colors.white, Color(0xFFCFC6FF), AppTokens.cyan],
      ).createShader(r),
      blendMode: BlendMode.srcIn,
      child: Text(
        'Buy, sell and swap on campus.',
        style: (compact ? t.displaySmall : t.displayLarge)?.copyWith(
          color: Colors.white,
        ),
      ),
    );

    return GradientMesh(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 20 : 48,
          compact ? 36 : 72,
          compact ? 20 : 48,
          compact ? 28 : 48,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Eyebrow(total: widget.total)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.4, curve: Curves.easeOutCubic),
                const SizedBox(height: 18),
                headline
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 600.ms)
                    .slideY(begin: 0.25, curve: Curves.easeOutCubic),
                const SizedBox(height: 14),
                Text(
                  'The University of Nottingham Malaysia marketplace. Textbooks, bikes, rooms and everything in between, from people on your campus.',
                  style: t.titleMedium?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 240.ms, duration: 600.ms),
                const SizedBox(height: 28),
                GlassPanel(
                      padding: const EdgeInsets.all(8),
                      radius: 18,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('search-field'),
                              controller: _controller,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (v) => widget.onSearch(v.trim()),
                              decoration: const InputDecoration(
                                hintText: 'What are you looking for?',
                                prefixIcon: Icon(Icons.search_rounded),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: () =>
                                widget.onSearch(_controller.text.trim()),
                            child: const Text('Search'),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 360.ms, duration: 600.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!signedIn)
                      _GlowButton(
                        label: 'Try the demo',
                        icon: Icons.bolt_rounded,
                        busy: _demoBusy,
                        onPressed: _demoBusy ? null : _demo,
                      ),
                    OutlinedButton.icon(
                      onPressed: () => context.go(
                        signedIn ? '/sell' : '/login?from=%2Fsell',
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Sell something'),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/about'),
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('How it was built'),
                    ),
                  ],
                ).animate().fadeIn(delay: 480.ms, duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.total});
  final int? total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: Colors.white.withValues(alpha: 0.07),
      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTokens.mint,
                shape: BoxShape.circle,
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fade(begin: 1, end: 0.3, duration: 900.ms),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            switch (total) {
              null => 'Live on campus',
              1 => '1 listing live on campus',
              final n => '$n listings live on campus',
            },
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: AppTokens.accent,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: AppTokens.violet.withValues(alpha: 0.5),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      onPressed: onPressed,
      icon: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon),
      label: Text(label),
    ),
  );
}
