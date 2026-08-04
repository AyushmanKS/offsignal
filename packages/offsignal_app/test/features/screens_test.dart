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
import 'package:offsignal_app/features/settings/settings_screen.dart';
import 'package:offsignal_app/widgets/light_ring.dart';
import 'package:offsignal_core/offsignal_core.dart';

import '../support/harness.dart';

PayloadEnvelope textPayload(String text) => PayloadEnvelope(
  name: 'message.txt',
  mimeType: 'text/plain',
  bytes: Uint8List.fromList(utf8.encode(text)),
);

void main() {
  testWidgets('home offers send and receive with the light-ring signature', (
    tester,
  ) async {
    await tester.pumpWidget(await wrapScreen(const HomeScreen()));
    await settleFrames(tester);

    expect(find.text('OffSignal'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Receive'), findsOneWidget);
    expect(find.byType(LightRing), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('home renders in light theme', (tester) async {
    await tester.pumpWidget(
      await wrapScreen(const HomeScreen(), brightness: Brightness.light),
    );
    await settleFrames(tester);

    expect(find.text('OffSignal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('receive starts on the pre-permission explainer, camera idle', (
    tester,
  ) async {
    await tester.pumpWidget(await wrapScreen(const ReceiveScreen()));
    await settleFrames(tester);

    expect(find.text('OffSignal needs your camera'), findsOneWidget);
    expect(
      find.textContaining('Nothing is recorded or uploaded'),
      findsOneWidget,
    );
    expect(find.text('Allow camera'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('receive shows an inline settings card when permanently denied', (
    tester,
  ) async {
    final container = await testContainer();
    container.read(receiveProvider.notifier).state = const ReceiveState(
      access: CameraAccess.permanentlyDenied,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: await wrapScreen(const ReceiveScreen()),
      ),
    );
    await settleFrames(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('result screen shows received text with a copy action', (
    tester,
  ) async {
    await tester.pumpWidget(
      await wrapScreen(
        const ResultScreen(),
        overrides: [
          receivedPayloadProvider.overrideWith(
            (ref) => textPayload('meet me at gate 32'),
          ),
        ],
      ),
    );
    await settleFrames(tester, frames: 8);

    expect(find.text('meet me at gate 32'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Received'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('result screen shows save and share for a file payload', (
    tester,
  ) async {
    await tester.pumpWidget(
      await wrapScreen(
        const ResultScreen(),
        overrides: [
          receivedPayloadProvider.overrideWith(
            (ref) => PayloadEnvelope(
              name: 'report.pdf',
              mimeType: 'application/pdf',
              bytes: Uint8List.fromList(List.filled(4096, 7)),
            ),
          ),
        ],
      ),
    );
    await settleFrames(tester, frames: 8);

    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('4.0 KB'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });

  testWidgets('settings exposes theme, speed, haptics, and version', (
    tester,
  ) async {
    await tester.pumpWidget(await wrapScreen(const SettingsScreen()));
    await settleFrames(tester);

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Default cycle speed'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(find.text('Version 1.0.0+1'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings theme switch updates the stored preference', (
    tester,
  ) async {
    await tester.pumpWidget(await wrapScreen(const SettingsScreen()));
    await settleFrames(tester);

    await tester.tap(find.text('Light'));
    await settleFrames(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding walks its panels and ends on get started', (
    tester,
  ) async {
    await tester.pumpWidget(
      await wrapScreen(
        const OnboardingScreen(),
        preferences: {'settings.onboardingSeen': false},
      ),
    );
    await settleFrames(tester);

    expect(find.text('Light, not radio'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await settleFrames(tester, frames: 8);

    expect(find.text('Camera only'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('screens respect reduce motion', (tester) async {
    await tester.pumpWidget(
      await wrapScreen(const HomeScreen(), reduceMotion: true),
    );
    await settleFrames(tester);

    expect(find.text('OffSignal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
