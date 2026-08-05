import 'dart:math' as math;

import 'result.dart';

enum QrDensity {
  compact(400),
  balanced(900),
  dense(1400);

  const QrDensity(this.blockSizeBytes);

  final int blockSizeBytes;

  static QrDensity fromName(String? name) => QrDensity.values.firstWhere(
    (density) => density.name == name,
    orElse: () => QrDensity.balanced,
  );
}

const defaultDensity = QrDensity.balanced;
const defaultBlockSizeBytes = 900;
const minBlockSizeBytes = 180;
const maxBlockSizeBytes = 1400;
const maxBlockCount = 0xFFFF;
const targetBlockCount = 900;
const maxPacketDegree = 32;

const defaultCycleInterval = Duration(milliseconds: 120);
const fastestCycleInterval = Duration(milliseconds: 50);
const slowestCycleInterval = Duration(milliseconds: 400);

const softPayloadWarningBytes = 2 * 1024 * 1024;
const maxPayloadBytes = maxBlockCount * maxBlockSizeBytes;

const _distinctPacketOverhead = 1.3;
const _distinctPacketFloor = 4;
const _optimisticFactor = 0.8;
const _pessimisticFactor = 3.0;

final class TransferPlan {
  const TransferPlan({
    required this.compressedBytes,
    required this.blockSize,
    required this.blockCount,
    required this.distinctPacketsNeeded,
  });

  final int compressedBytes;
  final int blockSize;
  final int blockCount;
  final int distinctPacketsNeeded;

  bool get exceedsSoftWarning => compressedBytes > softPayloadWarningBytes;

  int get expectedPacketCount => distinctPacketsNeeded;

  TransferDurationBand durationBand(Duration cycleInterval) {
    final nominalMs = distinctPacketsNeeded * 2 * cycleInterval.inMilliseconds;
    return TransferDurationBand(
      fastest: Duration(milliseconds: (nominalMs * _optimisticFactor).round()),
      slowest: Duration(milliseconds: (nominalMs * _pessimisticFactor).round()),
    );
  }
}

final class TransferDurationBand {
  const TransferDurationBand({required this.fastest, required this.slowest});

  final Duration fastest;
  final Duration slowest;
}

Result<TransferPlan> planTransfer(
  int compressedBytes, {
  int blockSize = defaultBlockSizeBytes,
}) {
  if (compressedBytes <= 0) return const Failure(EmptyPayload());
  if (compressedBytes > maxPayloadBytes) {
    return Failure(PayloadTooLarge(compressedBytes, maxPayloadBytes));
  }

  var chosenSize = blockSize.clamp(minBlockSizeBytes, maxBlockSizeBytes);
  while (_blockCountFor(compressedBytes, chosenSize) > targetBlockCount &&
      chosenSize < maxBlockSizeBytes) {
    chosenSize = math.min(chosenSize * 2, maxBlockSizeBytes);
  }

  final blockCount = _blockCountFor(compressedBytes, chosenSize);
  if (blockCount > maxBlockCount) {
    return Failure(PayloadTooLarge(compressedBytes, maxPayloadBytes));
  }

  return Success(
    TransferPlan(
      compressedBytes: compressedBytes,
      blockSize: chosenSize,
      blockCount: blockCount,
      distinctPacketsNeeded:
          (blockCount * _distinctPacketOverhead).ceil() + _distinctPacketFloor,
    ),
  );
}

int _blockCountFor(int totalBytes, int blockSize) =>
    (totalBytes + blockSize - 1) ~/ blockSize;

abstract interface class SpeedController {
  Duration get cycleInterval;

  void onPacketEmitted(int packetId);

  void onReceiverProgressReported(int blocksSolved, int blockCount);
}

final class ManualSpeedController implements SpeedController {
  ManualSpeedController([this._cycleInterval = defaultCycleInterval]);

  Duration _cycleInterval;

  @override
  Duration get cycleInterval => _cycleInterval;

  set cycleInterval(Duration value) {
    final clampedMs = value.inMilliseconds.clamp(
      fastestCycleInterval.inMilliseconds,
      slowestCycleInterval.inMilliseconds,
    );
    _cycleInterval = Duration(milliseconds: clampedMs);
  }

  @override
  void onPacketEmitted(int packetId) {}

  @override
  void onReceiverProgressReported(int blocksSolved, int blockCount) {}
}
