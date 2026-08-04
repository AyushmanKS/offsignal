import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offsignal_core/offsignal_core.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/app_exception.dart';
import '../../core/observability/app_logger.dart';

enum CameraAccess { unknown, granted, denied, permanentlyDenied, unavailable }

enum ReceivePhase { idle, scanning, verifying, verifyRetry, delivered }

@immutable
final class ReceiveState {
  const ReceiveState({
    this.phase = ReceivePhase.idle,
    this.access = CameraAccess.unknown,
    this.solvedBlocks = 0,
    this.blockCount = 0,
    this.framesRead = 0,
    this.framesAccepted = 0,
    this.packetsNeeded = 0,
    this.estimatedProgress = 0,
    this.scanRatePerSecond = 0,
    this.secondsRemaining,
    this.pulseCount = 0,
    this.torchOn = false,
    this.error,
  });

  final ReceivePhase phase;
  final CameraAccess access;
  final int solvedBlocks;
  final int blockCount;
  final int framesRead;
  final int framesAccepted;
  final int packetsNeeded;
  final double estimatedProgress;
  final double scanRatePerSecond;
  final int? secondsRemaining;
  final int pulseCount;
  final bool torchOn;
  final AppException? error;

  bool get isScanning =>
      phase == ReceivePhase.scanning ||
      phase == ReceivePhase.verifying ||
      phase == ReceivePhase.verifyRetry;

  bool get hasSignal => blockCount > 0;

  double get progress => blockCount == 0 ? 0 : solvedBlocks / blockCount;

  bool get isStalled => hasSignal && scanRatePerSecond < 0.4;

  ReceiveState copyWith({
    ReceivePhase? phase,
    CameraAccess? access,
    int? solvedBlocks,
    int? blockCount,
    int? framesRead,
    int? framesAccepted,
    int? packetsNeeded,
    double? estimatedProgress,
    double? scanRatePerSecond,
    int? secondsRemaining,
    bool clearRemaining = false,
    int? pulseCount,
    bool? torchOn,
    AppException? error,
    bool clearError = false,
  }) => ReceiveState(
    phase: phase ?? this.phase,
    access: access ?? this.access,
    solvedBlocks: solvedBlocks ?? this.solvedBlocks,
    blockCount: blockCount ?? this.blockCount,
    framesRead: framesRead ?? this.framesRead,
    framesAccepted: framesAccepted ?? this.framesAccepted,
    packetsNeeded: packetsNeeded ?? this.packetsNeeded,
    estimatedProgress: estimatedProgress ?? this.estimatedProgress,
    scanRatePerSecond: scanRatePerSecond ?? this.scanRatePerSecond,
    secondsRemaining: clearRemaining
        ? null
        : (secondsRemaining ?? this.secondsRemaining),
    pulseCount: pulseCount ?? this.pulseCount,
    torchOn: torchOn ?? this.torchOn,
    error: clearError ? null : (error ?? this.error),
  );
}

final receivedPayloadProvider = StateProvider<PayloadEnvelope?>((ref) => null);

final receiveProvider = NotifierProvider<ReceiveController, ReceiveState>(
  ReceiveController.new,
);

final class ReceiveController extends Notifier<ReceiveState> {
  IncomingTransfer _transfer = IncomingTransfer();
  bool _isDisposed = false;
  bool _isVerifying = false;
  final Stopwatch _sinceStart = Stopwatch();
  DateTime? _firstAcceptedAt;

  @override
  ReceiveState build() {
    ref.onDispose(() => _isDisposed = true);
    return const ReceiveState();
  }

  Future<CameraAccess> requestCameraAccess() async {
    if (kIsWeb) {
      state = state.copyWith(access: CameraAccess.granted);
      return CameraAccess.granted;
    }

    try {
      final status = await Permission.camera.request();
      final access = switch (status) {
        PermissionStatus.granted ||
        PermissionStatus.limited => CameraAccess.granted,
        PermissionStatus.permanentlyDenied ||
        PermissionStatus.restricted => CameraAccess.permanentlyDenied,
        _ => CameraAccess.denied,
      };
      state = state.copyWith(
        access: access,
        error: access == CameraAccess.granted
            ? null
            : CameraPermissionDenied(
                isPermanent: access == CameraAccess.permanentlyDenied,
              ),
        clearError: access == CameraAccess.granted,
      );
      return access;
    } on Object {
      state = state.copyWith(
        access: CameraAccess.unavailable,
        error: const CameraUnavailable(),
      );
      return CameraAccess.unavailable;
    }
  }

  Future<CameraAccess> checkCameraAccess() async {
    if (kIsWeb) return CameraAccess.unknown;
    try {
      final status = await Permission.camera.status;
      final access = switch (status) {
        PermissionStatus.granted ||
        PermissionStatus.limited => CameraAccess.granted,
        PermissionStatus.permanentlyDenied ||
        PermissionStatus.restricted => CameraAccess.permanentlyDenied,
        PermissionStatus.denied => CameraAccess.unknown,
        _ => CameraAccess.denied,
      };
      if (!_isDisposed) state = state.copyWith(access: access);
      return access;
    } on Object {
      return CameraAccess.unknown;
    }
  }

  void startScanning() {
    _transfer = IncomingTransfer();
    _isVerifying = false;
    _firstAcceptedAt = null;
    _sinceStart
      ..reset()
      ..start();
    state = state.copyWith(
      phase: ReceivePhase.scanning,
      solvedBlocks: 0,
      blockCount: 0,
      framesRead: 0,
      framesAccepted: 0,
      packetsNeeded: 0,
      estimatedProgress: 0,
      scanRatePerSecond: 0,
      clearRemaining: true,
      clearError: true,
    );
  }

  void stopScanning() {
    _isVerifying = false;
    _sinceStart.stop();
    state = state.copyWith(phase: ReceivePhase.idle, torchOn: false);
  }

  void toggleTorch() => state = state.copyWith(torchOn: !state.torchOn);

  void reportCameraFailure() {
    const failure = CameraUnavailable();
    AppLog.failure(failure, screen: 'receive');
    state = state.copyWith(phase: ReceivePhase.idle, error: failure);
  }

  Future<void> onFrameDetected(String frameText) async {
    if (!state.isScanning || _isVerifying) return;

    final result = _transfer.ingestFrame(frameText);
    if (result.error is MalformedPacket) return;

    if (result.accepted) _firstAcceptedAt ??= DateTime.now();

    final accepted = _transfer.framesAccepted;
    final needed = _transfer.distinctPacketsNeeded;
    final rate = _acceptedPerSecond(accepted);

    state = state.copyWith(
      solvedBlocks: _transfer.solvedBlocks,
      blockCount: _transfer.blockCount,
      framesRead: _transfer.framesRead,
      framesAccepted: accepted,
      packetsNeeded: needed,
      estimatedProgress: _transfer.estimatedProgress,
      scanRatePerSecond: rate,
      secondsRemaining: _secondsRemaining(accepted, needed, rate),
      clearRemaining: rate <= 0,
      pulseCount: result.accepted ? state.pulseCount + 1 : state.pulseCount,
    );

    if (result.isComplete) await _verify();
  }

  double _acceptedPerSecond(int accepted) {
    final startedAt = _firstAcceptedAt;
    if (startedAt == null || accepted < 2) return 0;
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    if (elapsed < 1500) return 0;
    return (accepted - 1) * 1000 / elapsed;
  }

  int? _secondsRemaining(int accepted, int needed, double rate) {
    if (rate <= 0 || needed <= 0) return null;
    final outstanding = needed - accepted;
    if (outstanding <= 0) return 0;
    return (outstanding / rate).ceil();
  }

  Future<void> _verify() async {
    _isVerifying = true;
    state = state.copyWith(phase: ReceivePhase.verifying);

    final assembled = _transfer.assembleCompressed();
    final compressed = assembled.valueOrNull;
    if (compressed == null) {
      _failVerification();
      return;
    }

    final verified = await _runVerification(compressed);
    if (_isDisposed) return;

    verified.fold((envelope) {
      ref.read(receivedPayloadProvider.notifier).state = envelope;
      state = state.copyWith(phase: ReceivePhase.delivered);
    }, (_) => _failVerification());
  }

  void _failVerification() {
    AppLog.failure(const TransferCorrupted(), screen: 'receive');
    _transfer = IncomingTransfer();
    _isVerifying = false;
    state = state.copyWith(
      phase: ReceivePhase.verifyRetry,
      solvedBlocks: 0,
      blockCount: 0,
      error: const TransferCorrupted(),
    );
  }

  Future<Result<PayloadEnvelope>> _runVerification(Uint8List compressed) {
    if (kIsWeb || compressed.length < 32 * 1024) {
      return Future.value(verifyAssembledPayload(compressed));
    }
    return compute(verifyAssembledPayload, compressed);
  }

  void reset() {
    _transfer = IncomingTransfer();
    _isVerifying = false;
    state = const ReceiveState();
  }
}
