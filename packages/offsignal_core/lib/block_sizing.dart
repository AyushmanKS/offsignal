import 'dart:math' as math;

import 'result.dart';

const defaultBlockSizeBytes = 180;
const maxBlockSizeBytes = 512;
const maxBlockCount = 0xFFFF;
const targetBlockCount = 900;
const maxPacketDegree = 32;

const defaultCycleInterval = Duration(milliseconds: 120);
const fastestCycleInterval = Duration(milliseconds: 50);
const slowestCycleInterval = Duration(milliseconds: 400);

const softPayloadWarningBytes = 2 * 1024 * 1024;
const maxPayloadBytes = maxBlockCount * maxBlockSizeBytes;

const _packetOverheadRatio = 1.8;
const _packetOverheadFloor = 8;
const _optimisticFactor = 0.75;
const _pessimisticFactor = 1.5;

final class TransferPlan {
  const TransferPlan({
    required this.compressedBytes,
    required this.blockSize,
    required this.blockCount,
    required this.expectedPacketCount,
  });

  final int compressedBytes;
  final int blockSize;
  final int blockCount;
  final int expectedPacketCount;

  bool get exceedsSoftWarning => compressedBytes > softPayloadWarningBytes;

  TransferDurationBand durationBand(Duration cycleInterval) {
    final nominalMs = expectedPacketCount * cycleInterval.inMilliseconds;
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

Result<TransferPlan> planTransfer(int compressedBytes) {
  if (compressedBytes <= 0) return const Failure(EmptyPayload());
  if (compressedBytes > maxPayloadBytes) {
    return Failure(PayloadTooLarge(compressedBytes, maxPayloadBytes));
  }

  var blockSize = defaultBlockSizeBytes;
  while (_blockCountFor(compressedBytes, blockSize) > targetBlockCount &&
      blockSize < maxBlockSizeBytes) {
    blockSize = math.min(blockSize * 2, maxBlockSizeBytes);
  }

  final blockCount = _blockCountFor(compressedBytes, blockSize);
  if (blockCount > maxBlockCount) {
    return Failure(PayloadTooLarge(compressedBytes, maxPayloadBytes));
  }

  return Success(
    TransferPlan(
      compressedBytes: compressedBytes,
      blockSize: blockSize,
      blockCount: blockCount,
      expectedPacketCount:
          (blockCount * _packetOverheadRatio).ceil() + _packetOverheadFloor,
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
