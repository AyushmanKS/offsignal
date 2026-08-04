import 'package:flutter/material.dart';

import '../core/assets/app_asset_widgets.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/motion.dart';
import 'pressable.dart';

enum GlassButtonVariant { primary, secondary, danger }

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.iconPath,
    this.isProcessing = false,
    this.helperText,
    this.accent,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final String? iconPath;
  final bool isProcessing;
  final String? helperText;
  final Color? accent;
  final bool expand;

  bool get _isEnabled => onPressed != null && !isProcessing;

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;
    final tone = switch (variant) {
      GlassButtonVariant.primary => accent ?? palette.signalAccent,
      GlassButtonVariant.secondary => accent ?? palette.textPrimary,
      GlassButtonVariant.danger => palette.danger,
    };
    final isFilled = variant == GlassButtonVariant.primary;
    final foreground = !_isEnabled
        ? palette.textMuted
        : isFilled
        ? (palette.isDark ? palette.backgroundBase : Colors.white)
        : tone;

    final button = Pressable(
      onPressed: _isEnabled ? onPressed : null,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppMotion.resolve(context, AppMotion.segmentSwitch),
        curve: AppMotion.segmentCurve,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.control),
          color: !_isEnabled
              ? palette.surfaceFillStrong
              : isFilled
              ? tone
              : tone.withValues(alpha: 0.10),
          border: isFilled && _isEnabled
              ? null
              : Border.all(
                  color: _isEnabled
                      ? tone.withValues(alpha: 0.35)
                      : palette.borderHighlight,
                  width: 1,
                ),
          boxShadow: isFilled && _isEnabled
              ? [
                  BoxShadow(
                    color: tone.withValues(alpha: 0.28),
                    blurRadius: 24,
                    spreadRadius: -8,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isProcessing)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              else if (iconPath != null)
                AppIcon(iconPath!, size: 20, color: foreground),
              if (isProcessing || iconPath != null)
                const SizedBox(width: AppSpacing.sm + 2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (helperText == null) return button;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        const SizedBox(height: AppSpacing.sm),
        Text(
          helperText!,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.iconPath,
    required this.onPressed,
    required this.semanticLabel,
    this.accent,
    this.isActive = false,
  });

  final String iconPath;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final Color? accent;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;
    final tone = accent ?? palette.textPrimary;

    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: AnimatedContainer(
        duration: AppMotion.resolve(context, AppMotion.segmentSwitch),
        width: AppSizes.minTapTarget,
        height: AppSizes.minTapTarget,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? tone.withValues(alpha: 0.20)
              : palette.surfaceFillStrong,
          border: Border.all(
            color: isActive
                ? tone.withValues(alpha: 0.45)
                : palette.borderHighlight,
            width: 1,
          ),
        ),
        child: Center(child: AppIcon(iconPath, size: 20, color: tone)),
      ),
    );
  }
}
