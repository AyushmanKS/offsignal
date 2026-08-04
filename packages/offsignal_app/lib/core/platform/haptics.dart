import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings.dart';

final hapticsProvider = Provider<Haptics>(
  (ref) => Haptics(() => ref.read(settingsProvider).hapticsEnabled),
);

final class Haptics {
  const Haptics(this._isEnabled);

  final bool Function() _isEnabled;

  Future<void> tap() => _run(HapticFeedback.selectionClick);

  Future<void> press() => _run(HapticFeedback.lightImpact);

  Future<void> success() async {
    if (!_isEnabled()) return;
    await _run(HapticFeedback.mediumImpact);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await _run(HapticFeedback.lightImpact);
  }

  Future<void> warning() => _run(HapticFeedback.heavyImpact);

  Future<void> _run(Future<void> Function() action) async {
    if (!_isEnabled()) return;
    try {
      await action();
    } on Object {
      return;
    }
  }
}
