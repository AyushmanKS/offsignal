import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const card = 20.0;
  static const control = 14.0;
  static const pill = 999.0;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppBlur {
  static const panel = 20.0;
  static const modal = 24.0;
  static const subtle = 18.0;
}

abstract final class AppSizes {
  static const minTapTarget = 44.0;
  static const compactBreakpoint = 600.0;
  static const expandedBreakpoint = 1024.0;
  static const mediumContentWidth = 560.0;
  static const expandedContentWidth = 480.0;
}

@immutable
final class GlassPalette extends ThemeExtension<GlassPalette> {
  const GlassPalette({
    required this.backgroundBase,
    required this.backgroundTint,
    required this.surfaceFill,
    required this.surfaceFillStrong,
    required this.borderHighlight,
    required this.borderShadow,
    required this.signalAccent,
    required this.amberAccent,
    required this.success,
    required this.danger,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
  });

  final Color backgroundBase;
  final Color backgroundTint;
  final Color surfaceFill;
  final Color surfaceFillStrong;
  final Color borderHighlight;
  final Color borderShadow;
  final Color signalAccent;
  final Color amberAccent;
  final Color success;
  final Color danger;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;

  static const dark = GlassPalette(
    backgroundBase: Color(0xFF0A0E14),
    backgroundTint: Color(0xFF121A26),
    surfaceFill: Color(0x0FFFFFFF),
    surfaceFillStrong: Color(0x1AFFFFFF),
    borderHighlight: Color(0x24FFFFFF),
    borderShadow: Color(0x0AFFFFFF),
    signalAccent: Color(0xFF4FD8FF),
    amberAccent: Color(0xFFFFB454),
    success: Color(0xFF5EEA9E),
    danger: Color(0xFFFF6B6B),
    textPrimary: Color(0xFFEDEEF3),
    textMuted: Color(0xFF8A94A6),
    isDark: true,
  );

  static const light = GlassPalette(
    backgroundBase: Color(0xFFF4F6FA),
    backgroundTint: Color(0xFFE3EAF5),
    surfaceFill: Color(0x8CFFFFFF),
    surfaceFillStrong: Color(0xB8FFFFFF),
    borderHighlight: Color(0x14141E2D),
    borderShadow: Color(0x08141E2D),
    signalAccent: Color(0xFF0EA5C4),
    amberAccent: Color(0xFFB4700E),
    success: Color(0xFF128A4C),
    danger: Color(0xFFC23A3A),
    textPrimary: Color(0xFF12151C),
    textMuted: Color(0xFF5B6472),
    isDark: false,
  );

  Color accentFor(TransferDirection direction) =>
      direction == TransferDirection.send ? signalAccent : amberAccent;

  @override
  GlassPalette copyWith({
    Color? backgroundBase,
    Color? backgroundTint,
    Color? surfaceFill,
    Color? surfaceFillStrong,
    Color? borderHighlight,
    Color? borderShadow,
    Color? signalAccent,
    Color? amberAccent,
    Color? success,
    Color? danger,
    Color? textPrimary,
    Color? textMuted,
    bool? isDark,
  }) => GlassPalette(
    backgroundBase: backgroundBase ?? this.backgroundBase,
    backgroundTint: backgroundTint ?? this.backgroundTint,
    surfaceFill: surfaceFill ?? this.surfaceFill,
    surfaceFillStrong: surfaceFillStrong ?? this.surfaceFillStrong,
    borderHighlight: borderHighlight ?? this.borderHighlight,
    borderShadow: borderShadow ?? this.borderShadow,
    signalAccent: signalAccent ?? this.signalAccent,
    amberAccent: amberAccent ?? this.amberAccent,
    success: success ?? this.success,
    danger: danger ?? this.danger,
    textPrimary: textPrimary ?? this.textPrimary,
    textMuted: textMuted ?? this.textMuted,
    isDark: isDark ?? this.isDark,
  );

  @override
  GlassPalette lerp(ThemeExtension<GlassPalette>? other, double t) {
    if (other is! GlassPalette) return this;
    return GlassPalette(
      backgroundBase: Color.lerp(backgroundBase, other.backgroundBase, t)!,
      backgroundTint: Color.lerp(backgroundTint, other.backgroundTint, t)!,
      surfaceFill: Color.lerp(surfaceFill, other.surfaceFill, t)!,
      surfaceFillStrong: Color.lerp(
        surfaceFillStrong,
        other.surfaceFillStrong,
        t,
      )!,
      borderHighlight: Color.lerp(borderHighlight, other.borderHighlight, t)!,
      borderShadow: Color.lerp(borderShadow, other.borderShadow, t)!,
      signalAccent: Color.lerp(signalAccent, other.signalAccent, t)!,
      amberAccent: Color.lerp(amberAccent, other.amberAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

enum TransferDirection { send, receive }

extension GlassPaletteLookup on BuildContext {
  GlassPalette get glass => Theme.of(this).extension<GlassPalette>()!;
}
