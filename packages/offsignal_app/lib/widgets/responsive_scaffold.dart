import 'package:flutter/material.dart';

import '../core/assets/app_asset_widgets.dart';
import '../core/assets/app_assets.dart';
import '../core/l10n/generated/app_localizations.dart';
import '../core/theme/design_tokens.dart';
import 'glass_backdrop.dart';
import 'pressable.dart';

double contentWidthFor(double availableWidth) {
  if (availableWidth < AppSizes.compactBreakpoint) return availableWidth;
  if (availableWidth < AppSizes.expandedBreakpoint) {
    return AppSizes.mediumContentWidth;
  }
  return AppSizes.expandedContentWidth;
}

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.title,
    this.accent,
    this.onBack,
    this.trailing,
    this.bottomBar,
    this.fullBleed = false,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final String? title;
  final Color? accent;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? bottomBar;
  final bool fullBleed;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final width = contentWidthFor(constraints.maxWidth);
        return Center(
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null || onBack != null || trailing != null)
                  _TopBar(title: title, onBack: onBack, trailing: trailing),
                Expanded(child: body),
                if (bottomBar != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: bottomBar,
                  ),
              ],
            ),
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: GlassBackdrop(
        accent: accent,
        child: fullBleed ? content : SafeArea(child: content),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.title, this.onBack, this.trailing});

  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;
    final strings = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (onBack != null)
            Pressable(
              onPressed: onBack,
              semanticLabel: strings.actionBack,
              child: SizedBox(
                width: AppSizes.minTapTarget,
                height: AppSizes.minTapTarget,
                child: Center(
                  child: AppIcon(
                    AppIcons.chevronBack,
                    size: 22,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title ?? '',
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null)
            trailing!
          else
            const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}
