import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offsignal_app/core/settings/app_settings.dart';
import 'package:offsignal_core/offsignal_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> containerWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final preferences = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an install from before the speed change is migrated forward', () async {
    final container = await containerWith({'settings.cycleIntervalMs': 120});
    addTearDown(container.dispose);

    expect(
      container.read(settingsProvider).cycleInterval,
      defaultCycleInterval,
    );
  });

  test('a speed chosen after the migration is respected', () async {
    final container = await containerWith({
      'settings.schemaVersion': 2,
      'settings.cycleIntervalMs': 150,
    });
    addTearDown(container.dispose);

    expect(container.read(settingsProvider).cycleInterval.inMilliseconds, 150);
  });

  test('a fresh install starts on the current defaults', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);

    final settings = container.read(settingsProvider);
    expect(settings.cycleInterval, defaultCycleInterval);
    expect(settings.density, defaultDensity);
  });

  test('stored speeds are clamped into the supported range', () async {
    final container = await containerWith({
      'settings.schemaVersion': 2,
      'settings.cycleIntervalMs': 5,
    });
    addTearDown(container.dispose);

    expect(
      container.read(settingsProvider).cycleInterval,
      fastestCycleInterval,
    );
  });
}
