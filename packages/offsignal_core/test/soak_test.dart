@Timeout(Duration(minutes: 20))
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:offsignal_core/offsignal_core.dart';
import 'package:test/test.dart';

const _runs = 1000;

Uint8List _payloadFor(Random random, int length) {
  final bytes = Uint8List(length);
  if (random.nextBool()) {
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }
  final alphabet = utf8.encode('offsignal moves bytes over light ');
  for (var i = 0; i < length; i++) {
    bytes[i] = alphabet[random.nextInt(alphabet.length)];
  }
  return bytes;
}

void main() {
  test('$_runs randomized send-to-receive runs reconstruct exactly', () {
    final random = Random(20260804);
    var totalFramesEmitted = 0;

    for (var run = 0; run < _runs; run++) {
      final length = 10 + random.nextInt(60000);
      final payload = _payloadFor(random, length);
      final dropRate = random.nextDouble() * 0.7;

      final envelope = PayloadEnvelope(
        name: 'run-$run.bin',
        mimeType: 'application/octet-stream',
        bytes: payload,
      );
      final sender = OutgoingTransfer.prepare(
        envelope,
        seed: random.nextInt(1 << 31),
      ).valueOrNull!;
      final receiver = IncomingTransfer();

      var emitted = 0;
      const frameCeiling = 500000;
      while (emitted < frameCeiling && !receiver.isComplete) {
        final frame = sender.nextFrame();
        emitted++;
        if (random.nextDouble() < dropRate) continue;
        receiver.ingestFrame(frame);
      }
      totalFramesEmitted += emitted;

      final delivered = receiver.finish();
      expect(
        delivered.isSuccess,
        isTrue,
        reason:
            'run $run failed: length=$length dropRate=$dropRate '
            'blocks=${receiver.solvedBlocks}/${receiver.blockCount} '
            'error=${delivered.errorOrNull}',
      );
      expect(
        delivered.valueOrNull!.bytes,
        orderedEquals(payload),
        reason: 'run $run reconstructed the wrong bytes',
      );
      expect(delivered.valueOrNull!.name, 'run-$run.bin');
    }

    expect(totalFramesEmitted, greaterThan(0));
  });
}
