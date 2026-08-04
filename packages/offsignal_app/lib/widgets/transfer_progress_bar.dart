import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/motion.dart';

class TransferProgressBar extends StatelessWidget {
  const TransferProgressBar({
    super.key,
    required this.progress,
    required this.accent,
    this.label,
    this.trailing,
  });

  final double progress;
  final Color accent;
  final String? label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;
    final clamped = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null || trailing != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label ?? '', style: AppTextStyles.readout(context)),
                Text(trailing ?? '', style: AppTextStyles.readout(context)),
              ],
            ),
          ),
        Semantics(
          value: '${(clamped * 100).round()}%',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(color: palette.surfaceFillStrong),
                    child: const SizedBox.expand(),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: clamped),
                    duration: AppMotion.resolve(
                      context,
                      AppMotion.progressIncrement,
                    ),
                    curve: AppMotion.progressCurve,
                    builder: (context, value, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent.withValues(alpha: 0.7), accent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
