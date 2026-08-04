import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offsignal_core/offsignal_core.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/app_exception.dart';

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
  final int pulseCount;
  final bool torchOn;
  final AppException? error;

  bool get isScanning =>
      phase == ReceivePhase.scanning ||
      phase == ReceivePhase.verifying ||
      phase == ReceivePhase.verifyRetry;

  bool get hasSignal => blockCount > 0;

  double get progress => blockCount == 0 ? 0 : solvedBlocks / blockCount;

  ReceiveState copyWith({
    ReceivePhase? phase,
    CameraAccess? access,
    int? solvedBlocks,
    int? blockCount,
    int? framesRead,
    int? framesAccepted,
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
    state = state.copyWith(
      phase: ReceivePhase.scanning,
      solvedBlocks: 0,
      blockCount: 0,
      framesRead: 0,
      framesAccepted: 0,
      clearError: true,
    );
  }

  void stopScanning() {
    _isVerifying = false;
    state = state.copyWith(phase: ReceivePhase.idle, torchOn: false);
  }

  void toggleTorch() => state = state.copyWith(torchOn: !state.torchOn);

  void reportCameraFailure() {
    state = state.copyWith(
      phase: ReceivePhase.idle,
      error: const CameraUnavailable(),
    );
  }

  Future<void> onFrameDetected(String frameText) async {
    if (!state.isScanning || _isVerifying) return;

    final result = _transfer.ingestFrame(frameText);
    if (result.error is MalformedPacket) return;

    state = state.copyWith(
      solvedBlocks: _transfer.solvedBlocks,
      blockCount: _transfer.blockCount,
      framesRead: _transfer.framesRead,
      framesAccepted: _transfer.framesAccepted,
      pulseCount: result.accepted ? state.pulseCount + 1 : state.pulseCount,
    );

    if (result.isComplete) await _verify();
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
