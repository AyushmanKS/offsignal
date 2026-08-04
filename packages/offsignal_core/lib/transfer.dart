import 'dart:convert';
import 'dart:typed_data';

import 'block_sizing.dart';
import 'lt_codec.dart';
import 'packing.dart';
import 'result.dart';

const frameProtocolPrefix = 'OS1:';

String encodeFrame(Uint8List packetBytes) =>
    '$frameProtocolPrefix${base64.encode(packetBytes)}';

Result<Uint8List> decodeFrame(String frameText) {
  if (!frameText.startsWith(frameProtocolPrefix)) {
    return const Failure(MalformedPacket());
  }
  try {
    return Success(
      base64.decode(frameText.substring(frameProtocolPrefix.length)),
    );
  } on FormatException {
    return const Failure(MalformedPacket());
  }
}

Result<TransferPlan> estimateTransfer(PayloadEnvelope envelope) =>
    packPayload(envelope).fold(
      (compressed) => planTransfer(compressed.length),
      (error) => Failure(error),
    );

Result<PayloadEnvelope> verifyAssembledPayload(Uint8List compressed) =>
    unpackPayload(compressed);

final class OutgoingTransfer {
  OutgoingTransfer._(this.plan, this._encoder);

  static Result<OutgoingTransfer> prepare(
    PayloadEnvelope envelope, {
    int? seed,
  }) => packPayload(envelope).fold(
    (compressed) => planTransfer(compressed.length).fold(
      (plan) => Success(
        OutgoingTransfer._(
          plan,
          LTEncoder.fromPlan(compressed, plan, seed: seed),
        ),
      ),
      (error) => Failure(error),
    ),
    (error) => Failure(error),
  );

  final TransferPlan plan;
  final LTEncoder _encoder;

  int get packetsEmitted => _encoder.packetsEmitted;

  String nextFrame() => encodeFrame(_encoder.nextPacket());
}

final class IncomingTransfer {
  final LTDecoder _decoder = LTDecoder();

  int get framesRead => _decoder.framesRead;

  int get framesAccepted => _decoder.framesAccepted;

  int get solvedBlocks => _decoder.solvedBlocks;

  int get blockCount => _decoder.blockCount;

  bool get hasSession => _decoder.hasSession;

  bool get isComplete => _decoder.isComplete;

  double get progress => _decoder.progress;

  void reset() => _decoder.reset();

  PacketIngestResult ingestFrame(String frameText) =>
      decodeFrame(frameText).fold(
        _decoder.ingest,
        (error) => PacketIngestResult(
          accepted: false,
          isDuplicate: false,
          solvedBlocks: _decoder.solvedBlocks,
          blockCount: _decoder.blockCount,
          error: error,
        ),
      );

  Result<Uint8List> assembleCompressed() => _decoder.assemble();

  Result<PayloadEnvelope> finish() =>
      _decoder.assemble().fold(unpackPayload, (error) => Failure(error));
}
