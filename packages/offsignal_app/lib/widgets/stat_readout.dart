import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';

class StatReadout extends StatelessWidget {
  const StatReadout({
    super.key,
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: value,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.counter(
              context,
            ).copyWith(color: accent, fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label.toUpperCase(), style: AppTextStyles.statLabel(context)),
        ],
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.stats});

  final List<StatReadout> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final stat in stats) Flexible(child: stat),
      ],
    );
  }
}
