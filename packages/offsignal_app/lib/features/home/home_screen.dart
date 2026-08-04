import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/app_asset_widgets.dart';
import '../../core/assets/app_assets.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/platform/haptics.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/light_ring.dart';
import '../../widgets/pressable.dart';
import '../../widgets/responsive_scaffold.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;

    return ResponsiveScaffold(
      trailing: Pressable(
        onPressed: () => context.push(AppRoutes.settings),
        semanticLabel: strings.homeSettingsLabel,
        child: SizedBox(
          width: AppSizes.minTapTarget,
          height: AppSizes.minTapTarget,
          child: Center(
            child: AppIcon(
              AppIcons.settings,
              size: 22,
              color: palette.textMuted,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.appName,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Text(
              strings.appTagline,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ModeCard(
              title: strings.homeSendTitle,
              description: strings.homeSendDescription,
              iconPath: AppIcons.send,
              accent: palette.signalAccent,
              onTap: () {
                ref.read(hapticsProvider).press();
                context.push(AppRoutes.send);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _ModeCard(
              title: strings.homeReceiveTitle,
              description: strings.homeReceiveDescription,
              iconPath: AppIcons.receive,
              accent: palette.amberAccent,
              onTap: () {
                ref.read(hapticsProvider).press();
                context.push(AppRoutes.receive);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.iconPath,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String description;
  final String iconPath;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;

    return Pressable(
      onPressed: onTap,
      semanticLabel: '$title. $description',
      child: LightRing(
        accent: accent,
        isIdle: true,
        inset: 6,
        thickness: 1.6,
        child: GlassSurface(
          accent: accent,
          accentStrength: 0.6,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: AppIcon(iconPath, size: 24, color: accent),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
