import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:offsignal_core/offsignal_core.dart';
import 'package:test/test.dart';

PayloadEnvelope textEnvelope(String text) => PayloadEnvelope(
  name: 'message.txt',
  mimeType: 'text/plain',
  bytes: Uint8List.fromList(utf8.encode(text)),
);

({IncomingTransfer receiver, int framesEmitted}) runOverLight(
  PayloadEnvelope envelope,
  Random random, {
  double dropRate = 0,
  double duplicateRate = 0,
  String Function(String frame, int index)? corrupt,
  int maxFrames = 200000,
}) {
  final sender = OutgoingTransfer.prepare(envelope, seed: 99).valueOrNull!;
  final receiver = IncomingTransfer();

  var emitted = 0;
  while (emitted < maxFrames && !receiver.isComplete) {
    var frame = sender.nextFrame();
    emitted++;
    if (corrupt != null) frame = corrupt(frame, emitted);
    if (random.nextDouble() < dropRate) continue;
    receiver.ingestFrame(frame);
    if (random.nextDouble() < duplicateRate) receiver.ingestFrame(frame);
  }

  return (receiver: receiver, framesEmitted: emitted);
}

void main() {
  group('frame encoding', () {
    test('carries the protocol prefix', () {
      final frame = encodeFrame(Uint8List.fromList([1, 2, 3]));
      expect(frame, startsWith(frameProtocolPrefix));
      expect(decodeFrame(frame).valueOrNull, orderedEquals([1, 2, 3]));
    });

    test('ignores QR text that is not an OffSignal frame', () {
      expect(
        decodeFrame('https://example.com').errorOrNull,
        isA<MalformedPacket>(),
      );
      expect(decodeFrame('OS1:not base64!!').errorOrNull, isA<MalformedPacket>());
    });

    test('a foreign QR code never enters the decoder session', () {
      final receiver = IncomingTransfer();
      final result = receiver.ingestFrame('WIFI:S=home;T=WPA;P=secret;;');

      expect(result.accepted, isFalse);
      expect(receiver.hasSession, isFalse);
      expect(receiver.solvedBlocks, 0);
    });
  });

  group('send to receive round trip', () {
    test('delivers a short note over a clean channel', () {
      final envelope = textEnvelope('meet me at gate 32');
      final outcome = runOverLight(envelope, Random(1));

      final delivered = outcome.receiver.finish().valueOrNull!;
      expect(utf8.decode(delivered.bytes), 'meet me at gate 32');
      expect(delivered.name, 'message.txt');
    });

    test('delivers a file payload through 60 percent packet loss', () {
      final random = Random(2);
      final bytes = Uint8List.fromList(
        List<int>.generate(64 * 1024, (_) => random.nextInt(256)),
      );
      final envelope = PayloadEnvelope(
        name: 'photo.jpg',
        mimeType: 'image/jpeg',
        bytes: bytes,
      );

      final outcome = runOverLight(envelope, random, dropRate: 0.6);
      final delivered = outcome.receiver.finish().valueOrNull!;

      expect(delivered.bytes, orderedEquals(bytes));
      expect(delivered.mimeType, 'image/jpeg');
    });

    test('duplicate scans of the same frame do not corrupt decoding', () {
      final envelope = textEnvelope('a' * 5000);
      final outcome = runOverLight(envelope, Random(3), duplicateRate: 0.8);

      final delivered = outcome.receiver.finish().valueOrNull!;
      expect(utf8.decode(delivered.bytes), 'a' * 5000);
      expect(outcome.receiver.framesRead, greaterThan(outcome.receiver.framesAccepted));
    });

    test('progress only ever increases', () {
      final sender = OutgoingTransfer.prepare(
        textEnvelope('x' * 8000),
        seed: 5,
      ).valueOrNull!;
      final receiver = IncomingTransfer();

      var previous = 0.0;
      while (!receiver.isComplete) {
        receiver.ingestFrame(sender.nextFrame());
        expect(receiver.progress, greaterThanOrEqualTo(previous));
        previous = receiver.progress;
      }
      expect(receiver.progress, 1.0);
    });
  });

  group('corrupted transfer never reports success', () {
    test('a tampered frame body cannot produce a delivered payload', () {
      final random = Random(7);
      final envelope = PayloadEnvelope(
        name: 'secret.bin',
        mimeType: 'application/octet-stream',
        bytes: Uint8List.fromList(
          List<int>.generate(32 * 1024, (_) => random.nextInt(256)),
        ),
      );

      final outcome = runOverLight(
        envelope,
        random,
        corrupt: (frame, index) {
          if (index != 2) return frame;
          final bytes = decodeFrame(frame).valueOrNull!;
          bytes[bytes.length - 1] ^= 0xFF;
          return encodeFrame(bytes);
        },
      );

      final result = outcome.receiver.finish();
      expect(result.isSuccess, isFalse);
      expect(result.valueOrNull, isNull);
      expect(
        result.errorOrNull,
        anyOf(isA<ChecksumMismatch>(), isA<DecompressionFailed>()),
      );
    });

    test('finishing an incomplete transfer reports remaining blocks', () {
      final random = Random(8);
      final sender = OutgoingTransfer.prepare(
        PayloadEnvelope(
          name: 'big.bin',
          mimeType: 'application/octet-stream',
          bytes: Uint8List.fromList(
            List<int>.generate(16 * 1024, (_) => random.nextInt(256)),
          ),
        ),
        seed: 8,
      ).valueOrNull!;
      final receiver = IncomingTransfer()..ingestFrame(sender.nextFrame());

      expect(receiver.isComplete, isFalse);
      final error = receiver.finish().errorOrNull;
      expect(error, isA<TransferIncomplete>());
      expect((error! as TransferIncomplete).totalBlocks, receiver.blockCount);
    });
  });

  group('transfer planning surfaces to the sender', () {
    test('exposes block count and size before broadcasting', () {
      final sender = OutgoingTransfer.prepare(
        textEnvelope('z' * 20000),
        seed: 9,
      ).valueOrNull!;

      expect(sender.plan.blockCount, greaterThan(0));
      expect(sender.plan.compressedBytes, lessThan(20000));
      expect(sender.plan.expectedPacketCount, greaterThan(sender.plan.blockCount));
      expect(sender.packetsEmitted, 0);

      sender.nextFrame();
      expect(sender.packetsEmitted, 1);
    });

    test('refuses to prepare an empty payload', () {
      final result = OutgoingTransfer.prepare(
        PayloadEnvelope(name: 'a', mimeType: 'text/plain', bytes: Uint8List(0)),
      );
      expect(result.errorOrNull, isA<EmptyPayload>());
    });
  });
}
