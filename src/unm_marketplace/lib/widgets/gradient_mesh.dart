import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Slowly drifting colour blobs with a gentle parallax that follows the pointer.
class GradientMesh extends StatefulWidget {
  const GradientMesh({super.key, this.child, this.intensity = 1});
  final Widget? child;
  final double intensity;

  @override
  State<GradientMesh> createState() => _GradientMeshState();
}

class _GradientMeshState extends State<GradientMesh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();
  Offset _pointer = Offset.zero;

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion && _t.isAnimating) _t.stop();
    return MouseRegion(
      onHover: (e) {
        final size = context.size;
        if (size == null || size.isEmpty) return;
        setState(
          () => _pointer = Offset(
            e.localPosition.dx / size.width - 0.5,
            e.localPosition.dy / size.height - 0.5,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) => CustomPaint(
          painter: _MeshPainter(_t.value, _pointer, dark, widget.intensity),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter(this.t, this.pointer, this.dark, this.intensity);
  final double t;
  final Offset pointer;
  final bool dark;
  final double intensity;

  static const _blobs = [
    (AppTokens.violet, 0.18, 0.25, 0.55, 0.0),
    (AppTokens.cyan, 0.82, 0.30, 0.45, 1.7),
    (AppTokens.pink, 0.60, 0.85, 0.40, 3.1),
    (AppTokens.navy, 0.30, 0.80, 0.60, 4.4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = dark ? AppTokens.ink : AppTokens.paper,
    );
    final a = t * 2 * math.pi;
    for (final (i, b) in _blobs.indexed) {
      final (color, x, y, r, phase) = b;
      final depth = (i + 1) * 14.0;
      final c = Offset(
        size.width * (x + 0.06 * math.sin(a + phase)) + pointer.dx * depth,
        size.height * (y + 0.08 * math.cos(a * 0.8 + phase)) +
            pointer.dy * depth,
      );
      final radius = size.longestSide * r;
      final alpha = (dark ? 0.55 : 0.28) * intensity;
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) =>
      old.t != t || old.pointer != pointer || old.dark != dark;
}
