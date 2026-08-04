import 'package:flutter_test/flutter_test.dart';
import 'package:offsignal_app/core/errors/app_exception.dart';
import 'package:offsignal_app/core/observability/app_logger.dart';

const _secretMessage = 'gate 32 changed to 47';
const _secretFileName = 'passport-scan.pdf';

void main() {
  setUp(AppLog.clear);

  test('a logged failure records only the screen and the failure type', () {
    AppLog.failure(const CameraUnavailable(), screen: 'receive');

    final entry = AppLog.recent.single;
    expect(entry.screen, 'receive');
    expect(entry.kind, 'CameraUnavailable');
    expect(entry.causeType, isNull);
  });

  test('an underlying cause is reduced to its type, never its message', () {
    AppLog.failure(
      const FileUnreadable(),
      screen: 'compose',
      cause: StateError('failed reading $_secretFileName'),
    );

    final entry = AppLog.recent.single;
    expect(entry.causeType, 'StateError');
    expect(entry.toString(), isNot(contains(_secretFileName)));
    expect(entry.toString(), isNot(contains('failed reading')));
  });

  test('no AppException can carry payload content into a log', () {
    const exceptions = <AppException>[
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

    for (final exception in exceptions) {
      AppLog.failure(exception, screen: 'audit');
    }

    final rendered = AppLog.recent.map((entry) => entry.toString()).join('\n');
    expect(rendered, isNot(contains(_secretMessage)));
    expect(rendered, isNot(contains(_secretFileName)));
    for (final entry in AppLog.recent) {
      expect(entry.toString(), '${entry.kind} on audit');
    }
  });

  test('the recent buffer is bounded so logs cannot grow without limit', () {
    for (var index = 0; index < 200; index++) {
      AppLog.event('frame-$index', screen: 'broadcasting');
    }

    expect(AppLog.recent.length, lessThanOrEqualTo(50));
    expect(AppLog.recent.last.kind, 'frame-199');
  });

  test('the recent buffer is not externally mutable', () {
    AppLog.event('started', screen: 'home');
    expect(
      () => AppLog.recent.add(const LoggedEvent(screen: 'x', kind: 'y')),
      throwsUnsupportedError,
    );
  });
}
