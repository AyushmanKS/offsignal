import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offsignal_app/features/home/home_screen.dart';
import 'package:offsignal_app/features/onboarding/onboarding_screen.dart';
import 'package:offsignal_app/features/receive/receive_providers.dart';
import 'package:offsignal_app/features/receive/receive_screen.dart';
import 'package:offsignal_app/features/receive/result_screen.dart';
import 'package:offsignal_app/features/send/broadcasting_screen.dart';
import 'package:offsignal_app/features/send/compose_screen.dart';
import 'package:offsignal_app/features/send/send_providers.dart';
import 'package:offsignal_app/features/settings/settings_screen.dart';
import 'package:offsignal_core/offsignal_core.dart';

import '../support/harness.dart';

const _phone = Size(390, 844);

Future<void> captureScreen(
  WidgetTester tester,
  String name,
  Widget screen, {
  Brightness brightness = Brightness.dark,
  List<Override> overrides = const [],
  Map<String, Object> preferences = const {},
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  await tester.binding.setSurfaceSize(_phone);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    await wrapScreen(
      screen,
      brightness: brightness,
      surfaceSize: _phone,
      overrides: overrides,
      preferences: preferences,
      reduceMotion: true,
    ),
  );
  await settleFrames(tester, frames: 6);
  await precacheScreenImages(tester);
  if (afterPump != null) await afterPump(tester);

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/screen_$name.png'),
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('home', (tester) async {
    await captureScreen(tester, 'home', const HomeScreen());
  });

  testWidgets('home light', (tester) async {
    await captureScreen(
      tester,
      'home_light',
      const HomeScreen(),
      brightness: Brightness.light,
    );
  });

  testWidgets('compose with a message', (tester) async {
    await captureScreen(
      tester,
      'compose',
      const ComposeScreen(),
      afterPump: (tester) async {
        await tester.enterText(
          find.byType(TextField),
          'Gate 32 changed to 47 — meet there in ten minutes.',
        );
        await tester.pump(const Duration(milliseconds: 400));
        await settleFrames(tester, frames: 4);
      },
    );
  });

  testWidgets('broadcasting', (tester) async {
    await tester.binding.setSurfaceSize(_phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = await testContainer();
    addTearDown(container.dispose);
    container
        .read(outgoingTransferProvider.notifier)
        .prepare(
          PayloadEnvelope(
            name: 'message.txt',
            mimeType: 'text/plain',
            bytes: Uint8List.fromList(
              utf8.encode('Gate 32 changed to 47 — meet there in ten minutes.'),
            ),
          ),
        );

    await tester.pumpWidget(
      wrapWithContainer(
        container,
        const BroadcastingScreen(),
        surfaceSize: _phone,
        reduceMotion: true,
      ),
    );
    await settleFrames(tester, frames: 6);

    expect(container.read(broadcastProvider).frame, isNotNull);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/screen_broadcasting.png'),
    );
  });

  testWidgets('receive pre-permission', (tester) async {
    await captureScreen(tester, 'receive_permission', const ReceiveScreen());
  });

  testWidgets('result with a received note', (tester) async {
    await captureScreen(
      tester,
      'result',
      const ResultScreen(),
      overrides: [
        receivedPayloadProvider.overrideWith(
          (ref) => PayloadEnvelope(
            name: 'message.txt',
            mimeType: 'text/plain',
            bytes: Uint8List.fromList(
              utf8.encode('Gate 32 changed to 47 — meet there in ten minutes.'),
            ),
          ),
        ),
      ],
    );
  });

  testWidgets('onboarding', (tester) async {
    await captureScreen(
      tester,
      'onboarding',
      const OnboardingScreen(),
      preferences: {'settings.onboardingSeen': false},
    );
  });

  testWidgets('settings', (tester) async {
    await captureScreen(tester, 'settings', const SettingsScreen());
  });
}
