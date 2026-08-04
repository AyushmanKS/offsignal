import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/design_tokens.dart';
import '../core/theme/motion.dart';

class GlassBackdrop extends StatefulWidget {
  const GlassBackdrop({super.key, required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  State<GlassBackdrop> createState() => _GlassBackdropState();
}

class _GlassBackdropState extends State<GlassBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;
    final accent = widget.accent ?? palette.signalAccent;
    final reduceMotion = AppMotion.reduceMotionOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: palette.backgroundBase),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _OrbPainter(
                progress: reduceMotion ? 0 : _controller.value,
                accent: accent,
                secondary: palette.amberAccent,
                tint: palette.backgroundTint,
                isDark: palette.isDark,
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter({
    required this.progress,
    required this.accent,
    required this.secondary,
    required this.tint,
    required this.isDark,
  });

  final double progress;
  final Color accent;
  final Color secondary;
  final Color tint;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final sweep = progress * 2 * math.pi;
    final baseOpacity = isDark ? 0.30 : 0.36;

    _orb(
      canvas,
      size,
      Offset(
        size.width * (0.18 + 0.10 * _wave(sweep)),
        size.height * (0.16 + 0.06 * _wave(sweep + 1.1)),
      ),
      size.shortestSide * 0.85,
      accent.withValues(alpha: baseOpacity),
    );
    _orb(
      canvas,
      size,
      Offset(
        size.width * (0.86 + 0.08 * _wave(sweep + 2.4)),
        size.height * (0.32 + 0.08 * _wave(sweep + 0.6)),
      ),
      size.shortestSide * 0.70,
      secondary.withValues(alpha: baseOpacity * 0.55),
    );
    _orb(
      canvas,
      size,
      Offset(
        size.width * (0.50 + 0.14 * _wave(sweep + 3.9)),
        size.height * (0.92 + 0.05 * _wave(sweep + 2.0)),
      ),
      size.shortestSide * 0.95,
      tint.withValues(alpha: isDark ? 0.75 : 0.62),
    );
  }

  double _wave(double radians) => 0.5 * (1 + math.sin(radians));

  void _orb(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
        stops: const [0, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.tint != tint;
}
