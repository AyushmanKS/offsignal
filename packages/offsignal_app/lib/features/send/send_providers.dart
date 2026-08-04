import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offsignal_core/offsignal_core.dart';

import '../../core/errors/app_exception.dart';
import '../../core/settings/app_settings.dart';

enum ComposeMode { text, file }

@immutable
final class PickedFilePayload {
  const PickedFilePayload({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;

  int get sizeBytes => bytes.length;

  bool get isImage => mimeType.startsWith('image/');
}

@immutable
final class ComposeState {
  const ComposeState({
    this.mode = ComposeMode.text,
    this.text = '',
    this.file,
    this.plan,
    this.error,
    this.isEstimating = false,
    this.largePayloadNoticeDismissed = false,
  });

  final ComposeMode mode;
  final String text;
  final PickedFilePayload? file;
  final TransferPlan? plan;
  final AppException? error;
  final bool isEstimating;
  final bool largePayloadNoticeDismissed;

  bool get hasContent =>
      mode == ComposeMode.text ? text.trim().isNotEmpty : file != null;

  bool get canBroadcast => hasContent && plan != null && error == null;

  bool get showsLargePayloadNotice =>
      !largePayloadNoticeDismissed && (plan?.exceedsSoftWarning ?? false);

  int get rawSizeBytes => switch (mode) {
    ComposeMode.text => utf8.encode(text).length,
    ComposeMode.file => file?.sizeBytes ?? 0,
  };

  ComposeState copyWith({
    ComposeMode? mode,
    String? text,
    PickedFilePayload? file,
    TransferPlan? plan,
    AppException? error,
    bool? isEstimating,
    bool? largePayloadNoticeDismissed,
    bool clearFile = false,
    bool clearPlan = false,
    bool clearError = false,
  }) => ComposeState(
    mode: mode ?? this.mode,
    text: text ?? this.text,
    file: clearFile ? null : (file ?? this.file),
    plan: clearPlan ? null : (plan ?? this.plan),
    error: clearError ? null : (error ?? this.error),
    isEstimating: isEstimating ?? this.isEstimating,
    largePayloadNoticeDismissed:
        largePayloadNoticeDismissed ?? this.largePayloadNoticeDismissed,
  );
}

PayloadEnvelope? envelopeFrom(ComposeState state) {
  if (state.mode == ComposeMode.text) {
    final trimmed = state.text.trim();
    if (trimmed.isEmpty) return null;
    return PayloadEnvelope(
      name: 'message.txt',
      mimeType: 'text/plain',
      bytes: Uint8List.fromList(utf8.encode(trimmed)),
    );
  }
  final file = state.file;
  if (file == null) return null;
  return PayloadEnvelope(
    name: file.name,
    mimeType: file.mimeType,
    bytes: file.bytes,
  );
}

final composeProvider = NotifierProvider<ComposeController, ComposeState>(
  ComposeController.new,
);

final class ComposeController extends Notifier<ComposeState> {
  Timer? _debounce;
  bool _isDisposed = false;

  @override
  ComposeState build() {
    ref.onDispose(() {
      _isDisposed = true;
      _debounce?.cancel();
    });
    return const ComposeState();
  }

  void setMode(ComposeMode mode) {
    if (state.mode == mode) return;
    state = state.copyWith(
      mode: mode,
      text: '',
      clearFile: true,
      clearPlan: true,
      clearError: true,
      largePayloadNoticeDismissed: false,
    );
  }

  void setText(String text) {
    state = state.copyWith(text: text, clearError: true);
    _scheduleEstimate();
  }

  void setFile(PickedFilePayload file) {
    state = state.copyWith(
      mode: ComposeMode.file,
      file: file,
      clearError: true,
      largePayloadNoticeDismissed: false,
    );
    _scheduleEstimate();
  }

  void clearFile() {
    state = state.copyWith(clearFile: true, clearPlan: true, clearError: true);
  }

  void reportError(AppException exception) {
    state = state.copyWith(error: exception, clearPlan: true);
  }

  void dismissLargePayloadNotice() {
    state = state.copyWith(largePayloadNoticeDismissed: true);
  }

  void _scheduleEstimate() {
    _debounce?.cancel();
    if (!state.hasContent) {
      state = state.copyWith(clearPlan: true, isEstimating: false);
      return;
    }
    state = state.copyWith(isEstimating: true);
    _debounce = Timer(const Duration(milliseconds: 220), _estimate);
  }

  Future<void> _estimate() async {
    final envelope = envelopeFrom(state);
    if (envelope == null) {
      state = state.copyWith(clearPlan: true, isEstimating: false);
      return;
    }

    final result = await _runEstimate(envelope);
    if (_isDisposed) return;

    result.fold(
      (plan) => state = state.copyWith(
        plan: plan,
        isEstimating: false,
        clearError: true,
      ),
      (error) => state = state.copyWith(
        error: appExceptionFromCodec(error),
        isEstimating: false,
        clearPlan: true,
      ),
    );
  }

  Future<Result<TransferPlan>> _runEstimate(PayloadEnvelope envelope) {
    if (kIsWeb || envelope.bytes.length < 64 * 1024) {
      return Future.value(estimateTransfer(envelope));
    }
    return compute(estimateTransfer, envelope);
  }
}

final outgoingTransferProvider =
    NotifierProvider<OutgoingTransferController, OutgoingTransfer?>(
      OutgoingTransferController.new,
    );

final class OutgoingTransferController extends Notifier<OutgoingTransfer?> {
  @override
  OutgoingTransfer? build() => null;

  Result<OutgoingTransfer> prepare(PayloadEnvelope envelope) {
    final result = OutgoingTransfer.prepare(envelope);
    result.fold((transfer) => state = transfer, (_) {});
    return result;
  }

  void clear() => state = null;
}

@immutable
final class BroadcastState {
  const BroadcastState({
    this.frame,
    this.packetsSent = 0,
    this.elapsed = Duration.zero,
    this.isRunning = false,
    this.isPausedByLifecycle = false,
    this.cycleInterval = defaultCycleInterval,
  });

  final String? frame;
  final int packetsSent;
  final Duration elapsed;
  final bool isRunning;
  final bool isPausedByLifecycle;
  final Duration cycleInterval;

  BroadcastState copyWith({
    String? frame,
    int? packetsSent,
    Duration? elapsed,
    bool? isRunning,
    bool? isPausedByLifecycle,
    Duration? cycleInterval,
  }) => BroadcastState(
    frame: frame ?? this.frame,
    packetsSent: packetsSent ?? this.packetsSent,
    elapsed: elapsed ?? this.elapsed,
    isRunning: isRunning ?? this.isRunning,
    isPausedByLifecycle: isPausedByLifecycle ?? this.isPausedByLifecycle,
    cycleInterval: cycleInterval ?? this.cycleInterval,
  );
}

final broadcastProvider = NotifierProvider<BroadcastController, BroadcastState>(
  BroadcastController.new,
);

final class BroadcastController extends Notifier<BroadcastState> {
  Timer? _cycleTimer;
  Timer? _elapsedTimer;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  BroadcastState build() {
    ref.onDispose(_disposeTimers);
    return BroadcastState(cycleInterval: ref.read(settingsProvider).cycleInterval);
  }

  void start() {
    final transfer = ref.read(outgoingTransferProvider);
    if (transfer == null || state.isRunning) return;

    _stopwatch
      ..reset()
      ..start();
    state = state.copyWith(
      isRunning: true,
      isPausedByLifecycle: false,
      packetsSent: 0,
      elapsed: Duration.zero,
      frame: transfer.nextFrame(),
    );
    _restartTimers();
  }

  void stop() {
    _disposeTimers();
    _stopwatch.stop();
    state = state.copyWith(isRunning: false, isPausedByLifecycle: false);
  }

  void pauseForLifecycle() {
    if (!state.isRunning) return;
    _disposeTimers();
    _stopwatch.stop();
    state = state.copyWith(isRunning: false, isPausedByLifecycle: true);
  }

  void resume() {
    if (state.isRunning || ref.read(outgoingTransferProvider) == null) return;
    _stopwatch.start();
    state = state.copyWith(isRunning: true, isPausedByLifecycle: false);
    _restartTimers();
  }

  void setCycleInterval(Duration interval) {
    final clamped = Duration(
      milliseconds: interval.inMilliseconds.clamp(
        fastestCycleInterval.inMilliseconds,
        slowestCycleInterval.inMilliseconds,
      ),
    );
    state = state.copyWith(cycleInterval: clamped);
    if (state.isRunning) _restartTimers();
  }

  void _restartTimers() {
    _cycleTimer?.cancel();
    _elapsedTimer?.cancel();
    _cycleTimer = Timer.periodic(state.cycleInterval, (_) => _emit());
    _elapsedTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => state = state.copyWith(elapsed: _stopwatch.elapsed),
    );
  }

  void _emit() {
    final transfer = ref.read(outgoingTransferProvider);
    if (transfer == null) {
      stop();
      return;
    }
    state = state.copyWith(
      frame: transfer.nextFrame(),
      packetsSent: transfer.packetsEmitted,
    );
  }

  void _disposeTimers() {
    _cycleTimer?.cancel();
    _elapsedTimer?.cancel();
    _cycleTimer = null;
    _elapsedTimer = null;
  }
}
