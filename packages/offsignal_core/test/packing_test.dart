import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:offsignal_core/offsignal_core.dart';
import 'package:test/test.dart';

PayloadEnvelope envelopeOf(String name, String mimeType, List<int> bytes) =>
    PayloadEnvelope(
      name: name,
      mimeType: mimeType,
      bytes: Uint8List.fromList(bytes),
    );

Uint8List framedWithDigest(PayloadEnvelope envelope, Uint8List digest) {
  final metadata = utf8.encode(
    jsonEncode({'name': envelope.name, 'mimeType': envelope.mimeType}),
  );
  final header = ByteData(2)..setUint16(0, metadata.length);
  final builder = BytesBuilder()
    ..add(header.buffer.asUint8List())
    ..add(metadata)
    ..addByte(digest.length)
    ..add(digest)
    ..add(envelope.bytes);
  return Uint8List.fromList(GZipEncoder().encode(builder.takeBytes()));
}

void main() {
  group('packing round trip', () {
    test('preserves name, mime type, and bytes', () {
      final original = envelopeOf(
        'notes.txt',
        'text/plain',
        utf8.encode('the signal is light'),
      );

      final packed = packPayload(original).valueOrNull!;
      final restored = unpackPayload(packed).valueOrNull!;

      expect(restored.name, 'notes.txt');
      expect(restored.mimeType, 'text/plain');
      expect(restored.bytes, orderedEquals(original.bytes));
    });

    test('survives unicode names and binary content', () {
      final random = Random(42);
      final bytes = List<int>.generate(4096, (_) => random.nextInt(256));
      final original = envelopeOf('照片 — copy (1).png', 'image/png', bytes);

      final restored = unpackPayload(
        packPayload(original).valueOrNull!,
      ).valueOrNull!;

      expect(restored.name, '照片 — copy (1).png');
      expect(restored.bytes, orderedEquals(bytes));
    });

    test('compresses repetitive payloads', () {
      final repetitive = utf8.encode('offsignal ' * 2000);
      final packed = packPayload(
        envelopeOf('a.txt', 'text/plain', repetitive),
      ).valueOrNull!;

      expect(packed.length, lessThan(repetitive.length ~/ 4));
    });

    test('rejects an empty payload', () {
      final result = packPayload(envelopeOf('empty.bin', 'application/octet-stream', []));
      expect(result.errorOrNull, isA<EmptyPayload>());
    });
  });

  group('integrity gate', () {
    test('a wrong digest is caught, never silently accepted', () {
      final envelope = envelopeOf('doc.pdf', 'application/pdf', [1, 2, 3, 4, 5]);
      final wrongDigest = computeChecksum(utf8.encode('not the payload'));

      final result = unpackPayload(framedWithDigest(envelope, wrongDigest));

      expect(result.isSuccess, isFalse);
      expect(result.errorOrNull, isA<ChecksumMismatch>());
      expect(result.valueOrNull, isNull);
    });

    test('a single flipped payload byte is caught', () {
      final bytes = List<int>.generate(2048, (i) => i % 251);
      final correctDigest = computeChecksum(bytes);

      final tampered = List<int>.from(bytes);
      tampered[900] ^= 0x01;

      final result = unpackPayload(
        framedWithDigest(
          envelopeOf('data.bin', 'application/octet-stream', tampered),
          correctDigest,
        ),
      );

      expect(result.errorOrNull, isA<ChecksumMismatch>());
    });

    test('a truncated digest field is rejected as malformed', () {
      final envelope = envelopeOf('x.txt', 'text/plain', [9, 9, 9]);
      final shortDigest = Uint8List.fromList(List.filled(16, 0));

      final result = unpackPayload(framedWithDigest(envelope, shortDigest));

      expect(result.errorOrNull, isA<MetadataMalformed>());
    });

    test('non-gzip input fails to decompress rather than throwing', () {
      final result = unpackPayload(Uint8List.fromList(List.filled(200, 7)));
      expect(result.errorOrNull, isA<DecompressionFailed>());
    });

    test('checksumMatches is length-safe', () {
      expect(checksumMatches([1, 2, 3], [1, 2, 3]), isTrue);
      expect(checksumMatches([1, 2, 3], [1, 2]), isFalse);
      expect(checksumMatches([1, 2, 3], [1, 2, 4]), isFalse);
    });
  });

  group('block planning', () {
    test('uses the default block size for small payloads', () {
      final plan = planTransfer(900).valueOrNull!;
      expect(plan.blockSize, defaultBlockSizeBytes);
      expect(plan.blockCount, 5);
    });

    test('grows the block size to hold the block count down', () {
      final plan = planTransfer(400 * 1024).valueOrNull!;
      expect(plan.blockSize, greaterThan(defaultBlockSizeBytes));
      expect(plan.blockSize, lessThanOrEqualTo(maxBlockSizeBytes));
      expect(plan.blockCount, lessThanOrEqualTo(targetBlockCount));
    });

    test('block count always covers the payload exactly once', () {
      for (final length in <int>[1, 179, 180, 181, 5000, 100000, 1000000]) {
        final plan = planTransfer(length).valueOrNull!;
        expect(plan.blockCount * plan.blockSize, greaterThanOrEqualTo(length));
        expect((plan.blockCount - 1) * plan.blockSize, lessThan(length));
      }
    });

    test('rejects empty and oversized payloads', () {
      expect(planTransfer(0).errorOrNull, isA<EmptyPayload>());
      expect(
        planTransfer(maxPayloadBytes + 1).errorOrNull,
        isA<PayloadTooLarge>(),
      );
    });

    test('flags the soft warning threshold without blocking', () {
      final plan = planTransfer(softPayloadWarningBytes + 1).valueOrNull!;
      expect(plan.exceedsSoftWarning, isTrue);
      expect(planTransfer(1000).valueOrNull!.exceedsSoftWarning, isFalse);
    });

    test('duration band widens around the nominal estimate', () {
      final plan = planTransfer(20000).valueOrNull!;
      final band = plan.durationBand(defaultCycleInterval);
      expect(band.fastest, lessThan(band.slowest));
      expect(band.fastest.inMilliseconds, greaterThan(0));
    });
  });

  group('manual speed controller', () {
    test('clamps to the supported cycle range', () {
      final controller = ManualSpeedController()
        ..cycleInterval = const Duration(milliseconds: 5);
      expect(controller.cycleInterval, fastestCycleInterval);

      controller.cycleInterval = const Duration(seconds: 10);
      expect(controller.cycleInterval, slowestCycleInterval);

      controller.cycleInterval = const Duration(milliseconds: 200);
      expect(controller.cycleInterval.inMilliseconds, 200);
    });
  });
}
