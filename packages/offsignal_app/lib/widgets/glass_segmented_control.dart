import 'package:flutter/material.dart';

import '../core/assets/app_asset_widgets.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/motion.dart';
import 'pressable.dart';

@immutable
final class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    this.iconPath,
  });

  final T value;
  final String label;
  final String? iconPath;
}

class GlassSegmentedControl<T> extends StatelessWidget {
  const GlassSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.accent,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;
    final tone = accent ?? palette.signalAccent;
    final selectedIndex = options.indexWhere(
      (option) => option.value == selected,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / options.length;

        return Container(
          height: AppSizes.minTapTarget + 4,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: palette.surfaceFill,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: palette.borderHighlight, width: 1),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: AppMotion.resolve(context, AppMotion.segmentSwitch),
                curve: AppMotion.segmentCurve,
                alignment: Alignment(
                  options.length == 1
                      ? 0
                      : (selectedIndex / (options.length - 1)) * 2 - 1,
                  0,
                ),
                child: Container(
                  width: segmentWidth - 8,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.control - 4),
                    border: Border.all(
                      color: tone.withValues(alpha: 0.42),
                      width: 1,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final option in options)
                    Expanded(
                      child: Pressable(
                        onPressed: () => onChanged(option.value),
                        semanticLabel: option.label,
                        minSize: 0,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (option.iconPath != null) ...[
                                AppIcon(
                                  option.iconPath!,
                                  size: 17,
                                  color: option.value == selected
                                      ? tone
                                      : palette.textMuted,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                              ],
                              Text(
                                option.label,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: option.value == selected
                                          ? palette.textPrimary
                                          : palette.textMuted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
