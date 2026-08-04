import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/design_tokens.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = AppRadius.card,
    this.blur = AppBlur.panel,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.accent,
    this.accentStrength = 0,
    this.strong = false,
    this.onTap,
  });

  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final double accentStrength;
  final bool strong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;
    final borderRadius = BorderRadius.circular(radius);
    final glowColor = accent ?? palette.signalAccent;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              palette.borderHighlight,
              glowColor,
              accentStrength * 0.6,
            )!,
            palette.borderShadow,
          ],
        ),
        boxShadow: accentStrength <= 0
            ? null
            : [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.18 * accentStrength),
                  blurRadius: 28 * accentStrength,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: strong ? palette.surfaceFillStrong : palette.surfaceFill,
                gradient: accentStrength <= 0
                    ? null
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          glowColor.withValues(alpha: 0.10 * accentStrength),
                          glowColor.withValues(alpha: 0.02 * accentStrength),
                        ],
                      ),
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
