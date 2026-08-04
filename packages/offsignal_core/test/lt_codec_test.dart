import 'dart:math';
import 'dart:typed_data';

import 'package:offsignal_core/offsignal_core.dart';
import 'package:test/test.dart';

Uint8List randomBytes(Random random, int length) {
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return bytes;
}

Uint8List compressibleBytes(Random random, int length) {
  final bytes = Uint8List(length);
  final alphabet = 'abcdefghij '.codeUnits;
  for (var i = 0; i < length; i++) {
    bytes[i] = alphabet[random.nextInt(alphabet.length)];
  }
  return bytes;
}

({int solved, int total, Uint8List? assembled}) runLossyChannel(
  Uint8List payload,
  double dropRate,
  Random random, {
  int maxPackets = 400000,
}) {
  final encoder = LTEncoder.create(payload, seed: random.nextInt(1 << 31));
  final decoder = LTDecoder();
  final encoderValue = encoder.valueOrNull!;

  for (var emitted = 0; emitted < maxPackets; emitted++) {
    final packet = encoderValue.nextPacket();
    if (random.nextDouble() < dropRate) continue;
    decoder.ingest(packet);
    if (decoder.isComplete) break;
  }

  return (
    solved: decoder.solvedBlocks,
    total: decoder.blockCount,
    assembled: decoder.assemble().valueOrNull,
  );
}

void main() {
  group('wire format', () {
    test('round-trips header fields', () {
      final payload = randomBytes(Random(1), 1000);
      final encoder = LTEncoder.create(payload, seed: 7).valueOrNull!;
      final parsed = parsePacket(encoder.nextPacket()).valueOrNull!;

      expect(parsed.packetId, 1);
      expect(parsed.blockCount, encoder.blockCount);
      expect(parsed.blockSize, encoder.blockSize);
      expect(parsed.totalLength, payload.length);
      expect(parsed.payload.length, encoder.blockSize);
      expect(parsed.indices, isNotEmpty);
      expect(parsed.indices.toSet().length, parsed.indices.length);
    });

    test('rejects truncated packets', () {
      final encoder = LTEncoder.create(randomBytes(Random(2), 500), seed: 3);
      final packet = encoder.valueOrNull!.nextPacket();
      final truncated = Uint8List.sublistView(packet, 0, packet.length - 5);

      expect(parsePacket(truncated).errorOrNull, isA<MalformedPacket>());
    });

    test('rejects garbage that is not a packet', () {
      final garbage = Uint8List.fromList(List.filled(64, 0));
      expect(parsePacket(garbage).errorOrNull, isA<MalformedPacket>());
    });

    test('rejects out-of-range block indices', () {
      final encoder = LTEncoder.create(randomBytes(Random(4), 400), seed: 9);
      final packet = encoder.valueOrNull!.nextPacket();
      final tampered = Uint8List.fromList(packet);
      ByteData.sublistView(tampered).setUint16(13, 0xFFFE);

      expect(parsePacket(tampered).errorOrNull, isA<MalformedPacket>());
    });
  });

  group('degree distribution', () {
    test('ideal soliton histogram is sane over 10k samples', () {
      final encoder = LTEncoder.create(
        randomBytes(Random(5), 180 * 50),
        seed: 11,
      ).valueOrNull!;

      final histogram = <int, int>{};
      const samples = 10000;
      for (var i = 0; i < samples; i++) {
        final degree = parsePacket(encoder.nextPacket()).valueOrNull!.indices.length;
        histogram.update(degree, (value) => value + 1, ifAbsent: () => 1);
      }

      final degreeOne = histogram[1]! / samples;
      final degreeTwo = histogram[2]! / samples;
      final degreeThree = histogram[3]! / samples;

      expect(degreeOne, closeTo(1 / encoder.blockCount, 0.02));
      expect(degreeTwo, closeTo(0.5, 0.03));
      expect(degreeThree, closeTo(1 / 6, 0.03));
      expect(histogram.keys.reduce(max), lessThanOrEqualTo(maxPacketDegree));
      expect(histogram.keys.reduce(min), greaterThanOrEqualTo(1));
    });
  });

  group('lossy channel property test', () {
    final random = Random(20260804);

    for (final dropRate in <double>[0.0, 0.2, 0.45, 0.7]) {
      test('reconstructs exactly at ${(dropRate * 100).round()}% loss', () {
        for (var run = 0; run < 12; run++) {
          final length = 10 + random.nextInt(24000);
          final payload = random.nextBool()
              ? randomBytes(random, length)
              : compressibleBytes(random, length);

          final outcome = runLossyChannel(payload, dropRate, random);

          expect(outcome.solved, outcome.total);
          expect(outcome.assembled, isNotNull);
          expect(outcome.assembled, orderedEquals(payload));
        }
      });
    }

    test('handles a single-block payload', () {
      final payload = randomBytes(random, 10);
      final outcome = runLossyChannel(payload, 0.5, random);
      expect(outcome.assembled, orderedEquals(payload));
    });

    test('handles a 500KB payload', () {
      final payload = compressibleBytes(random, 500 * 1024);
      final outcome = runLossyChannel(payload, 0.15, random);
      expect(outcome.assembled, orderedEquals(payload));
    });
  });

  group('decoder guards', () {
    test('assemble before completion reports incomplete progress', () {
      final encoder = LTEncoder.create(randomBytes(Random(6), 5000), seed: 13);
      final decoder = LTDecoder()..ingest(encoder.valueOrNull!.nextPacket());

      final error = decoder.assemble().errorOrNull;
      expect(error, isA<TransferIncomplete>());
      expect((error! as TransferIncomplete).totalBlocks, decoder.blockCount);
    });

    test('rejects packets from a different session', () {
      final first = LTEncoder.create(randomBytes(Random(7), 5000), seed: 1);
      final second = LTEncoder.create(randomBytes(Random(8), 9000), seed: 2);

      final decoder = LTDecoder()..ingest(first.valueOrNull!.nextPacket());
      final result = decoder.ingest(second.valueOrNull!.nextPacket());

      expect(result.accepted, isFalse);
      expect(result.error, isA<SessionMismatch>());
    });

    test('duplicate frames do not inflate accepted counts', () {
      final encoder = LTEncoder.create(randomBytes(Random(9), 3000), seed: 5);
      final packet = encoder.valueOrNull!.nextPacket();
      final decoder = LTDecoder()..ingest(packet);

      final duplicate = decoder.ingest(packet);

      expect(duplicate.isDuplicate, isTrue);
      expect(decoder.framesAccepted, 1);
      expect(decoder.framesRead, 2);
    });

    test('reset clears session state', () {
      final encoder = LTEncoder.create(randomBytes(Random(10), 2000), seed: 6);
      final decoder = LTDecoder()..ingest(encoder.valueOrNull!.nextPacket());

      decoder.reset();

      expect(decoder.hasSession, isFalse);
      expect(decoder.solvedBlocks, 0);
      expect(decoder.framesRead, 0);
    });
  });
}
