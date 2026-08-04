import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:offsignal_core/offsignal_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/assets/app_assets.dart';
import '../../core/formatting.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/platform/screen_control.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/light_ring.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/stat_readout.dart';
import 'send_providers.dart';

class BroadcastingScreen extends ConsumerStatefulWidget {
  const BroadcastingScreen({super.key});

  @override
  ConsumerState<BroadcastingScreen> createState() => _BroadcastingScreenState();
}

class _BroadcastingScreenState extends ConsumerState<BroadcastingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(broadcastProvider.notifier).start();
      ScreenControl.instance.beginBroadcastMode();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ScreenControl.instance.endBroadcastMode();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    ref.read(broadcastProvider.notifier).pauseForLifecycle();
  }

  Future<void> _stop() async {
    ref.read(broadcastProvider.notifier).stop();
    ref.read(outgoingTransferProvider.notifier).clear();
    await ScreenControl.instance.endBroadcastMode();
    if (mounted) context.pop();
  }

  Future<bool> _confirmLeave() async {
    final strings = AppLocalizations.of(context);
    return AppFeedback.confirm(
      context,
      title: strings.broadcastingLeaveTitle,
      body: strings.broadcastingLeaveBody,
      confirmLabel: strings.actionStop,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;
    final broadcast = ref.watch(broadcastProvider);
    final plan = ref.watch(
      outgoingTransferProvider.select((transfer) => transfer?.plan),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave()) await _stop();
      },
      child: ResponsiveScaffold(
        title: strings.broadcastingTitle,
        accent: palette.signalAccent,
        onBack: () async {
          if (await _confirmLeave()) await _stop();
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _QrStage(frame: broadcast.frame, pulseCount: broadcast.packetsSent),
              const SizedBox(height: AppSpacing.md),
              Text(
                strings.broadcastingHint,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassSurface(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: StatRow(
                  stats: [
                    StatReadout(
                      label: strings.broadcastingStatBlocks,
                      value: '${plan?.blockCount ?? 0}',
                    ),
                    StatReadout(
                      label: strings.broadcastingStatFramesSent,
                      value: formatCount(broadcast.packetsSent),
                      accent: palette.signalAccent,
                    ),
                    StatReadout(
                      label: strings.broadcastingStatElapsed,
                      value: formatElapsed(broadcast.elapsed),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SpeedControl(interval: broadcast.cycleInterval),
              if (broadcast.isPausedByLifecycle) ...[
                const SizedBox(height: AppSpacing.md),
                _ResumeCard(
                  onResume: () {
                    ref.read(broadcastProvider.notifier).resume();
                    ScreenControl.instance.beginBroadcastMode();
                  },
                ),
              ],
            ],
          ),
        ),
        bottomBar: GlassButton(
          label: strings.actionStop,
          iconPath: AppIcons.stopBroadcast,
          variant: GlassButtonVariant.danger,
          onPressed: () async {
            if (await _confirmLeave()) await _stop();
          },
        ),
      ),
    );
  }
}

class _QrStage extends StatelessWidget {
  const _QrStage({required this.frame, required this.pulseCount});

  final String? frame;
  final int pulseCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340, maxHeight: 340),
        child: AspectRatio(
          aspectRatio: 1,
          child: LightRing(
            accent: palette.signalAccent,
            pulseCount: pulseCount,
            inset: 12,
            child: GlassSurface(
              accent: palette.signalAccent,
              accentStrength: 0.8,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: frame == null
                    ? const SizedBox.expand()
                    : QrImageView(
                        data: frame!,
                        version: QrVersions.auto,
                        errorCorrectionLevel: QrErrorCorrectLevel.L,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedControl extends ConsumerWidget {
  const _SpeedControl({required this.interval});

  final Duration interval;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;

    return GlassSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.broadcastingSpeedLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                strings.broadcastingSpeedValue(interval.inMilliseconds),
                style: AppTextStyles.readout(context),
              ),
            ],
          ),
          Slider(
            value: interval.inMilliseconds.toDouble(),
            min: fastestCycleInterval.inMilliseconds.toDouble(),
            max: slowestCycleInterval.inMilliseconds.toDouble(),
            divisions:
                (slowestCycleInterval.inMilliseconds -
                    fastestCycleInterval.inMilliseconds) ~/
                10,
            label: strings.broadcastingSpeedValue(interval.inMilliseconds),
            onChanged: (value) => ref
                .read(broadcastProvider.notifier)
                .setCycleInterval(Duration(milliseconds: value.round())),
          ),
          Text(
            strings.broadcastingSpeedHelp,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;

    return GlassSurface(
      accent: palette.amberAccent,
      accentStrength: 0.6,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.broadcastingPausedTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings.broadcastingPausedBody,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          GlassButton(
            label: strings.broadcastingResume,
            iconPath: AppIcons.playBroadcast,
            accent: palette.amberAccent,
            onPressed: onResume,
          ),
        ],
      ),
    );
  }
}
