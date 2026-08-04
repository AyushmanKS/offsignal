import 'package:flutter/material.dart';

import '../assets/app_assets.dart';
import 'design_tokens.dart';
import 'motion.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(GlassPalette.dark, Brightness.dark);

  static ThemeData light() => _build(GlassPalette.light, Brightness.light);

  static ThemeData _build(GlassPalette palette, Brightness brightness) {
    final textTheme = _textTheme(palette);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: palette.signalAccent,
          brightness: brightness,
        ).copyWith(
          primary: palette.signalAccent,
          secondary: palette.amberAccent,
          error: palette.danger,
          surface: palette.backgroundBase,
          onSurface: palette.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.backgroundBase,
      canvasColor: palette.backgroundBase,
      textTheme: textTheme,
      fontFamily: AppFonts.inter,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: palette.surfaceFill,
      dividerTheme: DividerThemeData(color: palette.borderHighlight, space: 1),
      extensions: <ThemeExtension<dynamic>>[palette],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeThroughPageTransition(),
          TargetPlatform.iOS: FadeThroughPageTransition(),
          TargetPlatform.macOS: FadeThroughPageTransition(),
          TargetPlatform.windows: FadeThroughPageTransition(),
          TargetPlatform.linux: FadeThroughPageTransition(),
          TargetPlatform.fuchsia: FadeThroughPageTransition(),
        },
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.signalAccent,
        inactiveTrackColor: palette.surfaceFillStrong,
        thumbColor: palette.signalAccent,
        overlayColor: palette.signalAccent.withValues(alpha: 0.14),
        trackHeight: 4,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.signalAccent,
        selectionColor: palette.signalAccent.withValues(alpha: 0.28),
        selectionHandleColor: palette.signalAccent,
      ),
    );
  }

  static TextTheme _textTheme(GlassPalette palette) {
    const display = AppFonts.spaceGrotesk;
    const body = AppFonts.inter;

    return TextTheme(
      displayLarge: const TextStyle(
        fontFamily: display,
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.8,
      ),
      displayMedium: const TextStyle(
        fontFamily: display,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.6,
      ),
      headlineLarge: const TextStyle(
        fontFamily: display,
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.4,
      ),
      headlineMedium: const TextStyle(
        fontFamily: display,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.3,
      ),
      titleLarge: const TextStyle(
        fontFamily: display,
        fontSize: 19,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      titleMedium: const TextStyle(
        fontFamily: body,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: const TextStyle(
        fontFamily: body,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        fontFamily: body,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: const TextStyle(
        fontFamily: body,
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      labelLarge: const TextStyle(
        fontFamily: body,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.1,
      ),
      labelMedium: const TextStyle(
        fontFamily: body,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.2,
      ),
      labelSmall: const TextStyle(
        fontFamily: body,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.4,
      ),
    ).apply(bodyColor: palette.textPrimary, displayColor: palette.textPrimary);
  }
}

abstract final class AppTextStyles {
  static TextStyle counter(BuildContext context) => TextStyle(
    fontFamily: AppFonts.jetBrainsMono,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.1,
    letterSpacing: -0.5,
    color: context.glass.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle readout(BuildContext context) => TextStyle(
    fontFamily: AppFonts.jetBrainsMono,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: context.glass.textMuted,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle statLabel(BuildContext context) => TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: context.glass.textMuted,
  );
}
