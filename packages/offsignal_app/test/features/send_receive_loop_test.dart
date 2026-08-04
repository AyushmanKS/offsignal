import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offsignal_app/features/receive/receive_providers.dart';
import 'package:offsignal_app/features/send/send_providers.dart';
import 'package:offsignal_core/offsignal_core.dart';

import '../support/harness.dart';

Future<ReceiveState> pumpFramesThrough(
  ReceiveController receiver,
  OutgoingTransfer sender, {
  int maxFrames = 20000,
  bool Function(int index)? drop,
  String Function(String frame, int index)? corrupt,
}) async {
  for (var index = 1; index <= maxFrames; index++) {
    var frame = sender.nextFrame();
    if (corrupt != null) frame = corrupt(frame, index);
    if (drop != null && drop(index)) continue;

    await receiver.onFrameDetected(frame);
    if (receiver.state.phase == ReceivePhase.delivered) break;
    if (receiver.state.phase == ReceivePhase.verifyRetry && index > 200) break;
  }
  return receiver.state;
}

Uint8List incompressibleBytes(int length, int seed) {
  final random = Random(seed);
  final bytes = Uint8List(length);
  for (var index = 0; index < length; index++) {
    bytes[index] = random.nextInt(256);
  }
  return bytes;
}

String corruptFirstPayloadByte(String frame) {
  final bytes = decodeFrame(frame).valueOrNull!;
  final packet = parsePacket(bytes).valueOrNull!;
  final payloadStart = bytes.length - packet.payload.length;
  bytes[payloadStart] ^= 0xA5;
  return encodeFrame(bytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a composed note travels end to end and verifies', () async {
    final container = await testContainer();
    final compose = container.read(composeProvider.notifier)
      ..setText('meet me at gate 32');

    final envelope = envelopeFrom(container.read(composeProvider))!;
    final sender = container
        .read(outgoingTransferProvider.notifier)
        .prepare(envelope)
        .valueOrNull!;

    final receiver = container.read(receiveProvider.notifier)..startScanning();
    final state = await pumpFramesThrough(receiver, sender);

    expect(state.phase, ReceivePhase.delivered);

    final delivered = container.read(receivedPayloadProvider)!;
    expect(utf8.decode(delivered.bytes), 'meet me at gate 32');
    expect(delivered.name, 'message.txt');
    expect(compose, isNotNull);
  });

  test('a file payload survives 50 percent dropped frames', () async {
    final container = await testContainer();
    final bytes = Uint8List.fromList(
      List<int>.generate(24 * 1024, (index) => (index * 31) % 256),
    );

    final sender = container
        .read(outgoingTransferProvider.notifier)
        .prepare(
          PayloadEnvelope(
            name: 'photo.jpg',
            mimeType: 'image/jpeg',
            bytes: bytes,
          ),
        )
        .valueOrNull!;

    final receiver = container.read(receiveProvider.notifier)..startScanning();
    final state = await pumpFramesThrough(
      receiver,
      sender,
      drop: (index) => index.isEven,
    );

    expect(state.phase, ReceivePhase.delivered);
    expect(
      container.read(receivedPayloadProvider)!.bytes,
      orderedEquals(bytes),
    );
  });

  test('progress never decreases while blocks resolve', () async {
    final container = await testContainer();
    final sender = container
        .read(outgoingTransferProvider.notifier)
        .prepare(
          PayloadEnvelope(
            name: 'data.bin',
            mimeType: 'application/octet-stream',
            bytes: Uint8List.fromList(
              List<int>.generate(8 * 1024, (index) => (index * 17) % 256),
            ),
          ),
        )
        .valueOrNull!;

    final receiver = container.read(receiveProvider.notifier)..startScanning();

    var previous = 0.0;
    for (var index = 0; index < 20000; index++) {
      await receiver.onFrameDetected(sender.nextFrame());
      if (receiver.state.phase == ReceivePhase.delivered) break;
      expect(receiver.state.progress, greaterThanOrEqualTo(previous));
      previous = receiver.state.progress;
    }

    expect(receiver.state.phase, ReceivePhase.delivered);
  });

  test('a corrupted frame is caught and never delivered as data', () async {
    final container = await testContainer();
    final original = incompressibleBytes(16 * 1024, 7);
    final sender = container
        .read(outgoingTransferProvider.notifier)
        .prepare(
          PayloadEnvelope(
            name: 'secret.bin',
            mimeType: 'application/octet-stream',
            bytes: original,
          ),
        )
        .valueOrNull!;

    final receiver = container.read(receiveProvider.notifier)..startScanning();

    for (var index = 1; index <= 20000; index++) {
      var frame = sender.nextFrame();
      if (index == 2) frame = corruptFirstPayloadByte(frame);

      await receiver.onFrameDetected(frame);
      expect(
        container.read(receivedPayloadProvider)?.bytes,
        anyOf(isNull, orderedEquals(original)),
        reason: 'corrupted bytes reached the result screen',
      );
      if (receiver.state.phase == ReceivePhase.delivered) break;
    }

    expect(receiver.state.phase, ReceivePhase.delivered);
    expect(
      container.read(receivedPayloadProvider)!.bytes,
      orderedEquals(original),
    );
  });

  test('a permanently corrupted stream never delivers', () async {
    final container = await testContainer();
    final sender = container
        .read(outgoingTransferProvider.notifier)
        .prepare(
          PayloadEnvelope(
            name: 'secret.bin',
            mimeType: 'application/octet-stream',
            bytes: incompressibleBytes(8 * 1024, 11),
          ),
        )
        .valueOrNull!;

    final receiver = container.read(receiveProvider.notifier)..startScanning();

    for (var index = 1; index <= 3000; index++) {
      await receiver.onFrameDetected(
        corruptFirstPayloadByte(sender.nextFrame()),
      );
      if (receiver.state.phase == ReceivePhase.delivered) break;
    }

    expect(receiver.state.phase, isNot(ReceivePhase.delivered));
    expect(container.read(receivedPayloadProvider), isNull);
  });

  test('foreign QR codes never start a session', () async {
    final container = await testContainer();
    final receiver = container.read(receiveProvider.notifier)..startScanning();

    await receiver.onFrameDetected('https://example.com');
    await receiver.onFrameDetected('WIFI:S=home;T=WPA;P=secret;;');

    expect(receiver.state.blockCount, 0);
    expect(receiver.state.phase, ReceivePhase.scanning);
    expect(container.read(receivedPayloadProvider), isNull);
  });

  test('broadcast controller emits frames and stops cleanly', () async {
    final container = await testContainer();
    container
        .read(outgoingTransferProvider.notifier)
        .prepare(
          PayloadEnvelope(
            name: 'message.txt',
            mimeType: 'text/plain',
            bytes: Uint8List.fromList(utf8.encode('hello over light')),
          ),
        );

    final broadcast = container.read(broadcastProvider.notifier)..start();
    expect(container.read(broadcastProvider).isRunning, isTrue);
    expect(container.read(broadcastProvider).frame, isNotNull);

    broadcast.pauseForLifecycle();
    expect(container.read(broadcastProvider).isRunning, isFalse);
    expect(container.read(broadcastProvider).isPausedByLifecycle, isTrue);

    broadcast.resume();
    expect(container.read(broadcastProvider).isRunning, isTrue);

    broadcast.stop();
    expect(container.read(broadcastProvider).isRunning, isFalse);
    expect(container.read(broadcastProvider).isPausedByLifecycle, isFalse);
  });

  test('receive controller releases session state on stop and reset', () async {
    final container = await testContainer();
    final sender = container
        .read(outgoingTransferProvider.notifier)
        .prepare(
          PayloadEnvelope(
            name: 'a.bin',
            mimeType: 'application/octet-stream',
            bytes: Uint8List.fromList(List<int>.generate(4096, (i) => i % 256)),
          ),
        )
        .valueOrNull!;

    final receiver = container.read(receiveProvider.notifier)..startScanning();
    await receiver.onFrameDetected(sender.nextFrame());
    expect(receiver.state.blockCount, greaterThan(0));

    receiver.stopScanning();
    expect(receiver.state.phase, ReceivePhase.idle);
    expect(receiver.state.torchOn, isFalse);

    receiver.reset();
    expect(receiver.state.blockCount, 0);
    expect(receiver.state.framesRead, 0);
    expect(receiver.state.isScanning, isFalse);
  });
}
