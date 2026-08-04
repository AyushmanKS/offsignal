import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/assets/app_asset_widgets.dart';
import '../../core/assets/app_assets.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/platform/haptics.dart';
import '../../core/platform/screen_control.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/light_ring.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/transfer_progress_bar.dart';
import 'receive_providers.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _scanner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(receiveProvider.notifier).checkCameraAccess();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releaseCamera();
    ScreenControl.instance.endScanMode();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    _stopScanning();
  }

  void _releaseCamera() {
    final scanner = _scanner;
    _scanner = null;
    scanner?.dispose();
  }

  Future<void> _requestAndStart() async {
    final access = await ref
        .read(receiveProvider.notifier)
        .requestCameraAccess();
    if (!mounted || access != CameraAccess.granted) return;
    await _startScanning();
  }

  Future<void> _startScanning() async {
    _releaseCamera();

    final scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
      autoStart: false,
    );
    _scanner = scanner;

    ref.read(receiveProvider.notifier).startScanning();
    await ScreenControl.instance.beginScanMode();

    try {
      await scanner.start();
      if (mounted) setState(() {});
    } on Object {
      _releaseCamera();
      if (mounted) ref.read(receiveProvider.notifier).reportCameraFailure();
    }
  }

  Future<void> _stopScanning() async {
    _releaseCamera();
    await ScreenControl.instance.endScanMode();
    if (mounted) {
      ref.read(receiveProvider.notifier).stopScanning();
      setState(() {});
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null) continue;
      await ref.read(receiveProvider.notifier).onFrameDetected(value);
    }
  }

  Future<void> _onDelivered() async {
    await ref.read(hapticsProvider).success();
    _releaseCamera();
    await ScreenControl.instance.endScanMode();
    if (mounted) context.pushReplacement(AppRoutes.result);
  }

  Future<void> _leaveAfterConfirmation() async {
    if (!await _confirmLeave()) return;
    await _stopScanning();
    if (!mounted) return;
    context.pop();
  }

  Future<bool> _confirmLeave() async {
    final strings = AppLocalizations.of(context);
    return AppFeedback.confirm(
      context,
      title: strings.receiveLeaveTitle,
      body: strings.receiveLeaveBody,
      confirmLabel: strings.actionStop,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;
    final receive = ref.watch(receiveProvider);

    ref.listen(receiveProvider.select((state) => state.phase), (
      previous,
      next,
    ) {
      if (next == ReceivePhase.delivered) _onDelivered();
    });

    final isScanning = receive.isScanning && _scanner != null;

    return PopScope(
      canPop: !isScanning,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leaveAfterConfirmation();
      },
      child: ResponsiveScaffold(
        title: strings.receiveTitle,
        accent: palette.amberAccent,
        onBack: () async {
          if (!isScanning) {
            context.pop();
            return;
          }
          await _leaveAfterConfirmation();
        },
        body: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: isScanning
              ? _ScanningView(
                  scanner: _scanner!,
                  state: receive,
                  onDetect: _onDetect,
                  onToggleTorch: () {
                    ref.read(receiveProvider.notifier).toggleTorch();
                    _scanner?.toggleTorch();
                  },
                )
              : _PrePermissionView(
                  state: receive,
                  onAllow: _requestAndStart,
                  onOpenSettings: openAppSettings,
                ),
        ),
        bottomBar: isScanning
            ? GlassButton(
                label: strings.actionStop,
                iconPath: AppIcons.stopBroadcast,
                variant: GlassButtonVariant.danger,
                onPressed: () async {
                  if (await _confirmLeave()) await _stopScanning();
                },
              )
            : null,
      ),
    );
  }
}

class _PrePermissionView extends StatelessWidget {
  const _PrePermissionView({
    required this.state,
    required this.onAllow,
    required this.onOpenSettings,
  });

  final ReceiveState state;
  final Future<void> Function() onAllow;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;

    if (state.access == CameraAccess.permanentlyDenied) {
      return Center(
        child: SingleChildScrollView(
          child: InlineErrorState(
            title: strings.receivePermissionDeniedTitle,
            body: strings.receivePermissionDeniedBody,
            actionLabel: strings.actionOpenSettings,
            onAction: onOpenSettings,
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassSurface(
              accent: palette.amberAccent,
              accentStrength: 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    AppIcons.camera,
                    size: 30,
                    color: palette.amberAccent,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    strings.receivePermissionTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    strings.receivePermissionBody,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: palette.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassButton(
              label: state.access == CameraAccess.granted
                  ? strings.receiveStartListening
                  : strings.receiveAllowCamera,
              iconPath: AppIcons.camera,
              accent: palette.amberAccent,
              onPressed: onAllow,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanningView extends StatelessWidget {
  const _ScanningView({
    required this.scanner,
    required this.state,
    required this.onDetect,
    required this.onToggleTorch,
  });

  final MobileScannerController scanner;
  final ReceiveState state;
  final void Function(BarcodeCapture) onDetect;
  final VoidCallback onToggleTorch;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: AspectRatio(
                aspectRatio: 1,
                child: LightRing(
                  accent: palette.amberAccent,
                  pulseCount: state.pulseCount,
                  inset: 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: scanner,
                          onDetect: onDetect,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error) => ColoredBox(
                            color: palette.backgroundBase,
                            child: Center(
                              child: AppIcon(
                                AppIcons.radioOff,
                                size: 32,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                        ),
                        const _ScanFrameOverlay(),
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: GlassIconButton(
                            iconPath: state.torchOn
                                ? AppIcons.flashOn
                                : AppIcons.flashOff,
                            semanticLabel: state.torchOn
                                ? strings.receiveTorchOff
                                : strings.receiveTorchOn,
                            accent: palette.amberAccent,
                            isActive: state.torchOn,
                            onPressed: onToggleTorch,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassSurface(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TransferProgressBar(
                progress: state.progress,
                accent: palette.amberAccent,
                label: state.hasSignal
                    ? strings.receiveStatBlocks(
                        state.solvedBlocks,
                        state.blockCount,
                      )
                    : strings.receiveWaiting,
                trailing: strings.receiveStatFramesRead(state.framesRead),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                switch (state.phase) {
                  ReceivePhase.verifying => strings.receiveVerifying,
                  ReceivePhase.verifyRetry => strings.receiveVerifyRetry,
                  _ => strings.receiveScanningHint,
                },
                textAlign: TextAlign.center,
                style: AppTextStyles.readout(context).copyWith(
                  color: state.phase == ReceivePhase.verifyRetry
                      ? palette.danger
                      : palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay();

  @override
  Widget build(BuildContext context) {
    final accent = context.glass.amberAccent;

    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Stack(
          children: [
            for (final alignment in const [
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomRight,
              Alignment.bottomLeft,
            ])
              Align(
                alignment: alignment,
                child: Transform.rotate(
                  angle: switch (alignment) {
                    Alignment.topRight => 1.5707963267948966,
                    Alignment.bottomRight => 3.141592653589793,
                    Alignment.bottomLeft => -1.5707963267948966,
                    _ => 0,
                  },
                  child: AppIcon(
                    AppIcons.scanCornerBracket,
                    size: 34,
                    color: accent.withValues(alpha: 0.9),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
