import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/app_asset_widgets.dart';
import '../../core/assets/app_assets.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/platform/host_platform.dart';
import '../../core/router/app_router.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/motion.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/pressable.dart';
import '../../widgets/responsive_scaffold.dart';

@immutable
final class _OnboardingPanel {
  const _OnboardingPanel({
    required this.title,
    required this.body,
    required this.imagePath,
  });

  final String title;
  final String body;
  final String imagePath;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final HostPlatform _host = detectHostPlatform();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_OnboardingPanel> _panels(AppLocalizations strings) => [
    _OnboardingPanel(
      title: strings.onboardingLightTitle,
      body: strings.onboardingLightBody,
      imagePath: AppImages.onboardingLightConcept,
    ),
    _OnboardingPanel(
      title: strings.onboardingPermissionsTitle,
      body: strings.onboardingPermissionsBody,
      imagePath: AppImages.onboardingPermissions,
    ),
    if (_host.isWeb)
      _OnboardingPanel(
        title: strings.onboardingInstallTitle,
        body: _host.prefersIosInstallInstructions
            ? strings.onboardingInstallIosBody
            : strings.onboardingInstallAndroidBody,
        imagePath: _host.prefersIosInstallInstructions
            ? AppImages.onboardingAddToHomeIos
            : AppImages.onboardingAddToHomeAndroid,
      ),
  ];

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).markOnboardingSeen();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _next(int panelCount) {
    if (_index >= panelCount - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: AppMotion.resolve(context, AppMotion.screenTransition),
      curve: AppMotion.screenCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;
    final panels = _panels(strings);
    final isLast = _index >= panels.length - 1;

    return ResponsiveScaffold(
      trailing: isLast
          ? const SizedBox(width: AppSpacing.sm)
          : Pressable(
              onPressed: _finish,
              semanticLabel: strings.actionSkip,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    strings.actionSkip,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: palette.textMuted),
                  ),
                ),
              ),
            ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: panels.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) =>
                  _PanelView(panel: panels[index]),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _PageDots(count: panels.length, index: _index),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
      bottomBar: GlassButton(
        label: isLast ? strings.onboardingGetStarted : strings.actionNext,
        onPressed: () => _next(panels.length),
      ),
    );
  }
}

class _PanelView extends StatelessWidget {
  const _PanelView({required this.panel});

  final _OnboardingPanel panel;

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: AppOnboardingImage(panel.imagePath),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  panel.title,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  panel.body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: palette.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var dot = 0; dot < count; dot++)
          AnimatedContainer(
            duration: AppMotion.resolve(context, AppMotion.segmentSwitch),
            curve: AppMotion.segmentCurve,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            width: dot == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: dot == index
                  ? palette.signalAccent
                  : palette.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
      ],
    );
  }
}
