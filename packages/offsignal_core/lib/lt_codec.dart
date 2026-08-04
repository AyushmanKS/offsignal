import 'dart:math' as math;
import 'dart:typed_data';

import 'block_sizing.dart';
import 'result.dart';

const _packetHeaderBytes = 13;
const _maxPendingPackets = 4096;

final class LTPacket {
  const LTPacket({
    required this.packetId,
    required this.blockCount,
    required this.blockSize,
    required this.totalLength,
    required this.indices,
    required this.payload,
  });

  final int packetId;
  final int blockCount;
  final int blockSize;
  final int totalLength;
  final List<int> indices;
  final Uint8List payload;
}

final class LTEncoder {
  LTEncoder._(
    this._blocks,
    this._random,
    this.blockCount,
    this.blockSize,
    this.totalLength,
  );

  static Result<LTEncoder> create(Uint8List compressedPayload, {int? seed}) =>
      planTransfer(compressedPayload.length).fold(
        (plan) => Success(fromPlan(compressedPayload, plan, seed: seed)),
        (error) => Failure(error),
      );

  static LTEncoder fromPlan(
    Uint8List compressedPayload,
    TransferPlan plan, {
    int? seed,
  }) {
    final blocks = List<Uint8List>.generate(plan.blockCount, (index) {
      final block = Uint8List(plan.blockSize);
      final start = index * plan.blockSize;
      final end = math.min(start + plan.blockSize, compressedPayload.length);
      block.setRange(0, end - start, compressedPayload, start);
      return block;
    }, growable: false);

    return LTEncoder._(
      blocks,
      seed == null ? math.Random() : math.Random(seed),
      plan.blockCount,
      plan.blockSize,
      compressedPayload.length,
    );
  }

  final List<Uint8List> _blocks;
  final math.Random _random;

  final int blockCount;
  final int blockSize;
  final int totalLength;

  int _packetId = 0;

  int get packetsEmitted => _packetId;

  Uint8List nextPacket() {
    _packetId++;
    final indices = _pickIndices(_sampleDegree());
    final payload = Uint8List(blockSize);
    for (final index in indices) {
      _xorInto(payload, _blocks[index]);
    }
    return _serialize(_packetId, indices, payload);
  }

  int _sampleDegree() {
    final ceiling = math.min(blockCount, maxPacketDegree);
    final u = _random.nextDouble();
    if (u < 1 / blockCount) return 1;
    final degree = (1 / (1 + 1 / blockCount - u)).ceil();
    return degree.clamp(1, ceiling);
  }

  List<int> _pickIndices(int degree) {
    if (degree >= blockCount) {
      return List<int>.generate(blockCount, (index) => index, growable: false);
    }
    if (degree * 2 > blockCount) {
      final pool = List<int>.generate(blockCount, (index) => index)
        ..shuffle(_random);
      return pool.take(degree).toList(growable: false)..sort();
    }
    final picked = <int>{};
    while (picked.length < degree) {
      picked.add(_random.nextInt(blockCount));
    }
    return picked.toList(growable: false)..sort();
  }

  Uint8List _serialize(int packetId, List<int> indices, Uint8List payload) {
    final bytes = Uint8List(
      _packetHeaderBytes + indices.length * 2 + blockSize,
    );
    final view = ByteData.sublistView(bytes);
    view.setUint32(0, packetId);
    view.setUint16(4, blockCount);
    view.setUint16(6, blockSize);
    view.setUint32(8, totalLength);
    view.setUint8(12, indices.length);
    for (var i = 0; i < indices.length; i++) {
      view.setUint16(_packetHeaderBytes + i * 2, indices[i]);
    }
    bytes.setRange(
      _packetHeaderBytes + indices.length * 2,
      bytes.length,
      payload,
    );
    return bytes;
  }
}

Result<LTPacket> parsePacket(Uint8List bytes) {
  if (bytes.length < _packetHeaderBytes) {
    return const Failure(MalformedPacket());
  }

  final view = ByteData.sublistView(bytes);
  final packetId = view.getUint32(0);
  final blockCount = view.getUint16(4);
  final blockSize = view.getUint16(6);
  final totalLength = view.getUint32(8);
  final degree = view.getUint8(12);

  if (blockCount == 0 || blockSize == 0 || degree == 0) {
    return const Failure(MalformedPacket());
  }
  if (totalLength == 0 || totalLength > blockCount * blockSize) {
    return const Failure(MalformedPacket());
  }
  if (totalLength <= (blockCount - 1) * blockSize) {
    return const Failure(MalformedPacket());
  }

  final indicesEnd = _packetHeaderBytes + degree * 2;
  if (bytes.length != indicesEnd + blockSize) {
    return const Failure(MalformedPacket());
  }

  final indices = List<int>.filled(degree, 0);
  for (var i = 0; i < degree; i++) {
    final index = view.getUint16(_packetHeaderBytes + i * 2);
    if (index >= blockCount) return const Failure(MalformedPacket());
    indices[i] = index;
  }
  if (indices.toSet().length != degree) return const Failure(MalformedPacket());

  return Success(
    LTPacket(
      packetId: packetId,
      blockCount: blockCount,
      blockSize: blockSize,
      totalLength: totalLength,
      indices: indices,
      payload: Uint8List.sublistView(bytes, indicesEnd),
    ),
  );
}

final class PacketIngestResult {
  const PacketIngestResult({
    required this.accepted,
    required this.isDuplicate,
    required this.solvedBlocks,
    required this.blockCount,
    this.error,
  });

  final bool accepted;
  final bool isDuplicate;
  final int solvedBlocks;
  final int blockCount;
  final CodecError? error;

  bool get isComplete => blockCount > 0 && solvedBlocks == blockCount;

  double get progress => blockCount == 0 ? 0 : solvedBlocks / blockCount;
}

final class _PendingPacket {
  _PendingPacket(this.missing, this.value);

  final Set<int> missing;
  final Uint8List value;
  bool retired = false;
}

final class LTDecoder {
  final Map<int, Uint8List> _solved = {};
  final List<_PendingPacket> _pending = [];
  final Map<int, Set<int>> _pendingByBlock = {};
  final Set<int> _seenPacketIds = {};

  int? _blockCount;
  int? _blockSize;
  int? _totalLength;

  int _framesRead = 0;
  int _framesAccepted = 0;

  int get framesRead => _framesRead;

  int get framesAccepted => _framesAccepted;

  int get solvedBlocks => _solved.length;

  int get blockCount => _blockCount ?? 0;

  bool get hasSession => _blockCount != null;

  bool get isComplete => _blockCount != null && _solved.length == _blockCount;

  double get progress =>
      _blockCount == null ? 0 : _solved.length / _blockCount!;

  void reset() {
    _solved.clear();
    _pending.clear();
    _pendingByBlock.clear();
    _seenPacketIds.clear();
    _blockCount = null;
    _blockSize = null;
    _totalLength = null;
    _framesRead = 0;
    _framesAccepted = 0;
  }

  PacketIngestResult ingest(Uint8List packetBytes) {
    _framesRead++;
    return parsePacket(packetBytes).fold(_ingestPacket, _rejected);
  }

  PacketIngestResult _rejected(CodecError error) => PacketIngestResult(
    accepted: false,
    isDuplicate: false,
    solvedBlocks: _solved.length,
    blockCount: _blockCount ?? 0,
    error: error,
  );

  PacketIngestResult _ingestPacket(LTPacket packet) {
    if (_blockCount == null) {
      _blockCount = packet.blockCount;
      _blockSize = packet.blockSize;
      _totalLength = packet.totalLength;
    } else if (packet.blockCount != _blockCount ||
        packet.blockSize != _blockSize ||
        packet.totalLength != _totalLength) {
      return _rejected(const SessionMismatch());
    }

    if (!_seenPacketIds.add(packet.packetId)) {
      return PacketIngestResult(
        accepted: false,
        isDuplicate: true,
        solvedBlocks: _solved.length,
        blockCount: _blockCount!,
      );
    }

    _framesAccepted++;
    _absorb(packet);

    return PacketIngestResult(
      accepted: true,
      isDuplicate: false,
      solvedBlocks: _solved.length,
      blockCount: _blockCount!,
    );
  }

  void _absorb(LTPacket packet) {
    final value = Uint8List.fromList(packet.payload);
    final missing = <int>{};
    for (final index in packet.indices) {
      final block = _solved[index];
      if (block == null) {
        missing.add(index);
      } else {
        _xorInto(value, block);
      }
    }

    if (missing.isEmpty) return;
    if (missing.length > 1) {
      _remember(_PendingPacket(missing, value));
      return;
    }

    _propagate(missing.first, value);
  }

  void _remember(_PendingPacket packet) {
    if (_pending.length >= _maxPendingPackets) _compactPending();
    final slot = _pending.length;
    _pending.add(packet);
    for (final index in packet.missing) {
      _pendingByBlock.putIfAbsent(index, () => <int>{}).add(slot);
    }
  }

  void _compactPending() {
    final survivors = <_PendingPacket>[];
    for (final packet in _pending) {
      if (!packet.retired) survivors.add(packet);
    }
    _pending
      ..clear()
      ..addAll(survivors);
    _pendingByBlock.clear();
    for (var slot = 0; slot < _pending.length; slot++) {
      for (final index in _pending[slot].missing) {
        _pendingByBlock.putIfAbsent(index, () => <int>{}).add(slot);
      }
    }
  }

  void _propagate(int startIndex, Uint8List startValue) {
    final queue = <int>[startIndex];
    _solved[startIndex] = startValue;

    while (queue.isNotEmpty) {
      final index = queue.removeLast();
      final block = _solved[index]!;
      final slots = _pendingByBlock.remove(index);
      if (slots == null) continue;

      for (final slot in slots) {
        final packet = _pending[slot];
        if (packet.retired || !packet.missing.remove(index)) continue;
        _xorInto(packet.value, block);

        if (packet.missing.length != 1) continue;
        final resolved = packet.missing.first;
        packet.retired = true;
        if (_solved.containsKey(resolved)) continue;
        _solved[resolved] = Uint8List.fromList(packet.value);
        queue.add(resolved);
      }
    }
  }

  Result<Uint8List> assemble() {
    final count = _blockCount;
    final size = _blockSize;
    final length = _totalLength;
    if (count == null || size == null || length == null) {
      return const Failure(TransferIncomplete(0, 0));
    }
    if (_solved.length != count) {
      return Failure(TransferIncomplete(_solved.length, count));
    }

    final assembled = Uint8List(count * size);
    for (var index = 0; index < count; index++) {
      assembled.setRange(index * size, (index + 1) * size, _solved[index]!);
    }
    return Success(Uint8List.sublistView(assembled, 0, length));
  }
}

void _xorInto(Uint8List target, Uint8List source) {
  for (var i = 0; i < target.length; i++) {
    target[i] ^= source[i];
  }
}
