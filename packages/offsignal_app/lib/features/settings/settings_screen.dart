import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:offsignal_core/offsignal_core.dart';

import '../../core/app_info.dart';
import '../../core/assets/app_asset_widgets.dart';
import '../../core/assets/app_assets.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/glass_segmented_control.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/pressable.dart';
import '../../widgets/responsive_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return ResponsiveScaffold(
      title: strings.settingsTitle,
      onBack: () => context.pop(),
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
            _SettingsSection(
              title: strings.settingsAppearance,
              children: [
                _SettingsRow(
                  label: strings.settingsTheme,
                  child: GlassSegmentedControl<ThemeMode>(
                    selected: settings.themeMode,
                    onChanged: controller.setThemeMode,
                    options: [
                      SegmentOption(
                        value: ThemeMode.system,
                        label: strings.settingsThemeSystem,
                      ),
                      SegmentOption(
                        value: ThemeMode.light,
                        label: strings.settingsThemeLight,
                      ),
                      SegmentOption(
                        value: ThemeMode.dark,
                        label: strings.settingsThemeDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsSection(
              title: strings.settingsTransfer,
              children: [
                _SettingsRow(
                  label: strings.settingsDefaultSpeed,
                  trailing: Text(
                    strings.broadcastingSpeedValue(
                      settings.cycleInterval.inMilliseconds,
                    ),
                    style: AppTextStyles.readout(context),
                  ),
                  child: Slider(
                    value: settings.cycleInterval.inMilliseconds.toDouble(),
                    min: fastestCycleInterval.inMilliseconds.toDouble(),
                    max: slowestCycleInterval.inMilliseconds.toDouble(),
                    divisions:
                        (slowestCycleInterval.inMilliseconds -
                            fastestCycleInterval.inMilliseconds) ~/
                        10,
                    onChanged: (value) => controller.setCycleInterval(
                      Duration(milliseconds: value.round()),
                    ),
                  ),
                ),
                _SwitchRow(
                  label: strings.settingsHaptics,
                  description: strings.settingsHapticsDescription,
                  value: settings.hapticsEnabled,
                  onChanged: controller.setHapticsEnabled,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsSection(
              title: strings.settingsAbout,
              children: [
                _LinkRow(
                  label: strings.settingsReplayOnboarding,
                  iconPath: AppIcons.lightWave,
                  onTap: () async {
                    await controller.replayOnboarding();
                    if (context.mounted) context.go(AppRoutes.onboarding);
                  },
                ),
                _LinkRow(
                  label: strings.settingsPrivacy,
                  iconPath: AppIcons.radioOff,
                  onTap: () => openExternalUrl(AppInfo.privacyPolicyUrl),
                ),
                _LinkRow(
                  label: strings.settingsSource,
                  iconPath: AppIcons.file,
                  onTap: () => openExternalUrl(AppInfo.sourceUrl),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    strings.settingsVersion(ref.watch(appVersionProvider)),
                    style: AppTextStyles.readout(context).copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              title.toUpperCase(),
              style: AppTextStyles.statLabel(context),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.child,
    this.trailing,
  });

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: palette.signalAccent,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.iconPath,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;

    return Pressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            AppIcon(iconPath, size: 18, color: palette.textMuted),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Transform.flip(
              flipX: true,
              child: AppIcon(
                AppIcons.chevronBack,
                size: 16,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
