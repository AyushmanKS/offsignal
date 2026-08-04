import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offsignal_app/core/errors/app_exception.dart';
import 'package:offsignal_app/core/errors/error_messages.dart';
import 'package:offsignal_core/offsignal_core.dart';

import '../support/harness.dart';

const _allExceptions = <AppException>[
  CameraPermissionDenied(),
  CameraPermissionDenied(isPermanent: true),
  CameraUnavailable(),
  TransferCorrupted(),
  PayloadTooLargeToSend(),
  PayloadEmptyToSend(),
  FileUnreadable(),
  SaveFailed(),
  ShareFailed(),
  UnknownError(),
];

const _allCodecErrors = <CodecError>[
  EmptyPayload(),
  PayloadTooLarge(1, 2),
  MalformedPacket(),
  SessionMismatch(),
  TransferIncomplete(1, 2),
  DecompressionFailed(),
  MetadataMalformed(),
  ChecksumMismatch(),
];

final _forbiddenFragments = <String>[
  'Exception',
  'Error:',
  'PlatformException',
  'StackTrace',
  '#0',
  'null',
  'Instance of',
];

void main() {
  testWidgets('every AppException renders plain-language copy', (tester) async {
    final messages = <String>[];

    await tester.pumpWidget(
      await wrapScreen(
        Builder(
          builder: (context) {
            for (final exception in _allExceptions) {
              messages.add(userFacingMessage(context, exception));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(messages, hasLength(_allExceptions.length));

    for (final message in messages) {
      expect(message.trim(), isNotEmpty);
      expect(message.length, greaterThan(15));
      expect(
        message.endsWith('.') || message.endsWith('!'),
        isTrue,
        reason: 'Copy should be a complete sentence: $message',
      );
      for (final fragment in _forbiddenFragments) {
        expect(
          message.contains(fragment),
          isFalse,
          reason: 'Raw error detail "$fragment" leaked into: $message',
        );
      }
    }
  });

  test('every CodecError maps to an AppException', () {
    for (final error in _allCodecErrors) {
      expect(
        appExceptionFromCodec(error),
        isA<AppException>(),
        reason: 'Unmapped codec error: $error',
      );
    }
  });

  test('corruption-shaped codec failures surface as TransferCorrupted', () {
    expect(
      appExceptionFromCodec(const ChecksumMismatch()),
      isA<TransferCorrupted>(),
    );
    expect(
      appExceptionFromCodec(const DecompressionFailed()),
      isA<TransferCorrupted>(),
    );
    expect(
      appExceptionFromCodec(const TransferIncomplete(3, 9)),
      isA<TransferCorrupted>(),
    );
  });
}
