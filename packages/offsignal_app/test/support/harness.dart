import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offsignal_app/core/app_info.dart';
import 'package:offsignal_app/core/l10n/generated/app_localizations.dart';
import 'package:offsignal_app/core/settings/app_settings.dart';
import 'package:offsignal_app/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> testContainer({
  Map<String, Object> preferences = const {},
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    'settings.onboardingSeen': true,
    ...preferences,
  });
  final storedPreferences = await SharedPreferences.getInstance();

  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(storedPreferences),
      appVersionProvider.overrideWithValue('1.0.0+1'),
      ...overrides,
    ],
  );
}

Future<Widget> wrapScreen(
  Widget screen, {
  Brightness brightness = Brightness.dark,
  Map<String, Object> preferences = const {},
  List<Override> overrides = const [],
  Size surfaceSize = const Size(390, 844),
  bool reduceMotion = false,
}) async => wrapWithContainer(
  await testContainer(preferences: preferences, overrides: overrides),
  screen,
  brightness: brightness,
  surfaceSize: surfaceSize,
  reduceMotion: reduceMotion,
);

Widget wrapWithContainer(
  ProviderContainer container,
  Widget screen, {
  Brightness brightness = Brightness.dark,
  Size surfaceSize = const Size(390, 844),
  bool reduceMotion = false,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: surfaceSize,
          disableAnimations: reduceMotion,
        ),
        child: screen,
      ),
    ),
  );
}

Future<void> loadAppFonts() async {
  final families = {
    'SpaceGrotesk': [
      'SpaceGrotesk-Medium',
      'SpaceGrotesk-SemiBold',
      'SpaceGrotesk-Bold',
    ],
    'Inter': ['Inter-Regular', 'Inter-Medium', 'Inter-SemiBold'],
    'JetBrainsMono': [
      'JetBrainsMono-Regular',
      'JetBrainsMono-Medium',
      'JetBrainsMono-SemiBold',
    ],
  };

  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final face in entry.value) {
      loader.addFont(
        File(
          'assets/fonts/$face.ttf',
        ).readAsBytes().then((bytes) => bytes.buffer.asByteData()),
      );
    }
    await loader.load();
  }
}

Future<void> precacheScreenImages(WidgetTester tester) async {
  final imageElements = find.byType(Image).evaluate().toList();
  if (imageElements.isEmpty) return;

  await tester.runAsync(() async {
    for (final element in imageElements) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> settleFrames(WidgetTester tester, {int frames = 4}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}
