import 'package:flutter/foundation.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final class ScreenControl {
  ScreenControl._();

  static final instance = ScreenControl._();

  bool _brightnessBoosted = false;
  bool _wakelockHeld = false;

  Future<void> beginBroadcastMode() async {
    await _boostBrightness();
    await _holdWakelock();
  }

  Future<void> endBroadcastMode() async {
    await _restoreBrightness();
    await _releaseWakelock();
  }

  Future<void> beginScanMode() => _holdWakelock();

  Future<void> endScanMode() => _releaseWakelock();

  Future<void> _boostBrightness() async {
    if (kIsWeb || _brightnessBoosted) return;
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(1);
      _brightnessBoosted = true;
    } on Object {
      _brightnessBoosted = false;
    }
  }

  Future<void> _restoreBrightness() async {
    if (kIsWeb || !_brightnessBoosted) return;
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } on Object {
      return;
    } finally {
      _brightnessBoosted = false;
    }
  }

  Future<void> _holdWakelock() async {
    if (_wakelockHeld) return;
    try {
      await WakelockPlus.enable();
      _wakelockHeld = true;
    } on Object {
      _wakelockHeld = false;
    }
  }

  Future<void> _releaseWakelock() async {
    if (!_wakelockHeld) return;
    try {
      await WakelockPlus.disable();
    } on Object {
      return;
    } finally {
      _wakelockHeld = false;
    }
  }
}
