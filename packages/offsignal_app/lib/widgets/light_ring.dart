import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/motion.dart';

class LightRing extends StatefulWidget {
  const LightRing({
    super.key,
    required this.accent,
    required this.child,
    this.pulseCount = 0,
    this.isIdle = false,
    this.thickness = 2.5,
    this.inset = 10,
  });

  final Color accent;
  final Widget child;
  final int pulseCount;
  final bool isIdle;
  final double thickness;
  final double inset;

  @override
  State<LightRing> createState() => _LightRingState();
}

class _LightRingState extends State<LightRing> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void didUpdateWidget(LightRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseCount != oldWidget.pulseCount) {
      _pulse
        ..stop()
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotionOf(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _sweep]),
      builder: (context, child) => CustomPaint(
        foregroundPainter: _LightRingPainter(
          accent: widget.accent,
          pulse: reduceMotion ? 0 : Curves.easeOut.transform(_pulse.value),
          sweep: reduceMotion ? 0 : _sweep.value,
          idle: widget.isIdle,
          thickness: widget.thickness,
          inset: widget.inset,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _LightRingPainter extends CustomPainter {
  const _LightRingPainter({
    required this.accent,
    required this.pulse,
    required this.sweep,
    required this.idle,
    required this.thickness,
    required this.inset,
  });

  final Color accent;
  final double pulse;
  final double sweep;
  final bool idle;
  final double thickness;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      -inset,
      -inset,
      size.width + inset * 2,
      size.height + inset * 2,
    );
    final radius = RRect.fromRectAndRadius(
      rect,
      Radius.circular(26 + inset * 0.5),
    );

    final baseOpacity = idle ? 0.20 + 0.10 * _breath(sweep) : 0.24;
    canvas.drawRRect(
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..color = accent.withValues(alpha: baseOpacity),
    );

    if (pulse > 0) {
      final expansion = pulse * 10;
      final expanded = RRect.fromRectAndRadius(
        rect.inflate(expansion),
        Radius.circular(26 + inset * 0.5 + expansion),
      );
      canvas.drawRRect(
        expanded,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness * (1 - pulse * 0.5)
          ..color = accent.withValues(alpha: (1 - pulse) * 0.75),
      );
      canvas.drawRRect(
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness + 1.5
          ..color = accent.withValues(alpha: (1 - pulse) * 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    _paintTravellingArc(canvas, radius);
  }

  void _paintTravellingArc(Canvas canvas, RRect bounds) {
    final path = Path()..addRRect(bounds);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final length = metric.length;
    final arcLength = length * 0.16;
    final start = (sweep * length) % length;
    final end = start + arcLength;

    final segment = end <= length
        ? metric.extractPath(start, end)
        : (metric.extractPath(start, length)
            ..addPath(metric.extractPath(0, end - length), Offset.zero));

    canvas.drawPath(
      segment,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: idle ? 0.55 : 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  double _breath(double t) => 0.5 * (1 + math.sin(t * 2 * math.pi));

  @override
  bool shouldRepaint(_LightRingPainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.sweep != sweep ||
      oldDelegate.accent != accent ||
      oldDelegate.idle != idle;
}
