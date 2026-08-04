import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:offsignal_app/core/assets/app_assets.dart';

void main() {
  group('AppIcons', () {
    for (final path in AppIcons.all) {
      test('$path exists', () {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'Missing icon asset: $path',
        );
      });
    }
  });

  group('AppImages', () {
    for (final path in AppImages.all) {
      test('$path exists', () {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'Missing image asset: $path',
        );
      });
    }
  });

  group('AppAnimations', () {
    for (final path in AppAnimations.all) {
      test('$path exists', () {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'Missing animation asset: $path',
        );
      });
    }
  });
}
