import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offsignal_core/offsignal_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'settings.themeMode';
const _cycleIntervalKey = 'settings.cycleIntervalMs';
const _densityKey = 'settings.qrDensity';
const _hapticsKey = 'settings.haptics';
const _onboardingSeenKey = 'settings.onboardingSeen';

@immutable
final class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.cycleInterval,
    required this.density,
    required this.hapticsEnabled,
    required this.onboardingSeen,
  });

  const AppSettings.defaults()
    : themeMode = ThemeMode.system,
      cycleInterval = defaultCycleInterval,
      density = defaultDensity,
      hapticsEnabled = true,
      onboardingSeen = false;

  final ThemeMode themeMode;
  final Duration cycleInterval;
  final QrDensity density;
  final bool hapticsEnabled;
  final bool onboardingSeen;

  AppSettings copyWith({
    ThemeMode? themeMode,
    Duration? cycleInterval,
    QrDensity? density,
    bool? hapticsEnabled,
    bool? onboardingSeen,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    cycleInterval: cycleInterval ?? this.cycleInterval,
    density: density ?? this.density,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    onboardingSeen: onboardingSeen ?? this.onboardingSeen,
  );
}

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

final class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      themeMode: _readThemeMode(preferences),
      cycleInterval: _readCycleInterval(preferences),
      density: QrDensity.fromName(preferences.getString(_densityKey)),
      hapticsEnabled: preferences.getBool(_hapticsKey) ?? true,
      onboardingSeen: preferences.getBool(_onboardingSeenKey) ?? false,
    );
  }

  SharedPreferences get _preferences => ref.read(sharedPreferencesProvider);

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _preferences.setString(_themeModeKey, mode.name);
  }

  Future<void> setCycleInterval(Duration interval) async {
    final clamped = Duration(
      milliseconds: interval.inMilliseconds.clamp(
        fastestCycleInterval.inMilliseconds,
        slowestCycleInterval.inMilliseconds,
      ),
    );
    state = state.copyWith(cycleInterval: clamped);
    await _preferences.setInt(_cycleIntervalKey, clamped.inMilliseconds);
  }

  Future<void> setDensity(QrDensity density) async {
    state = state.copyWith(density: density);
    await _preferences.setString(_densityKey, density.name);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    state = state.copyWith(hapticsEnabled: enabled);
    await _preferences.setBool(_hapticsKey, enabled);
  }

  Future<void> markOnboardingSeen() async {
    if (state.onboardingSeen) return;
    state = state.copyWith(onboardingSeen: true);
    await _preferences.setBool(_onboardingSeenKey, true);
  }

  Future<void> replayOnboarding() async {
    state = state.copyWith(onboardingSeen: false);
    await _preferences.setBool(_onboardingSeenKey, false);
  }

  static ThemeMode _readThemeMode(SharedPreferences preferences) {
    final stored = preferences.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  static Duration _readCycleInterval(SharedPreferences preferences) {
    final stored = preferences.getInt(_cycleIntervalKey);
    if (stored == null) return defaultCycleInterval;
    return Duration(
      milliseconds: stored.clamp(
        fastestCycleInterval.inMilliseconds,
        slowestCycleInterval.inMilliseconds,
      ),
    );
  }
}
