import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';

const _loggerName = 'offsignal';

abstract final class AppLog {
  static final List<LoggedEvent> _recent = <LoggedEvent>[];
  static const _recentLimit = 50;

  static List<LoggedEvent> get recent => List.unmodifiable(_recent);

  static void clear() => _recent.clear();

  static void failure(
    AppException exception, {
    required String screen,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    _record(
      LoggedEvent(
        screen: screen,
        kind: exception.runtimeType.toString(),
        causeType: cause?.runtimeType.toString(),
      ),
    );
    developer.log(
      '${exception.runtimeType} on $screen',
      name: _loggerName,
      level: 1000,
      error: cause?.runtimeType.toString(),
      stackTrace: stackTrace,
    );
  }

  static void event(String message, {required String screen}) {
    _record(LoggedEvent(screen: screen, kind: message));
    developer.log('$message on $screen', name: _loggerName, level: 800);
  }

  static void _record(LoggedEvent entry) {
    _recent.add(entry);
    if (_recent.length > _recentLimit) _recent.removeAt(0);
  }
}

@immutable
final class LoggedEvent {
  const LoggedEvent({required this.screen, required this.kind, this.causeType});

  final String screen;
  final String kind;
  final String? causeType;

  @override
  String toString() =>
      causeType == null ? '$kind on $screen' : '$kind on $screen ($causeType)';
}

Future<void> runGuarded(Future<void> Function() body) async {
  FlutterError.onError = (details) {
    developer.log(
      details.exceptionAsString(),
      name: _loggerName,
      level: 1000,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    developer.log(
      error.runtimeType.toString(),
      name: _loggerName,
      level: 1000,
      stackTrace: stackTrace,
    );
    return true;
  };

  await body();
}
