import 'package:sentry_flutter/sentry_flutter.dart';

const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

bool get isCrashReportingEnabled => _sentryDsn.isNotEmpty;

Future<void> runWithCrashReporting(Future<void> Function() body) async {
  if (!isCrashReportingEnabled) {
    await body();
    return;
  }

  await SentryFlutter.init((options) {
    options.dsn = _sentryDsn;
    options.sendDefaultPii = false;
    options.attachScreenshot = false;
    options.maxRequestBodySize = MaxRequestBodySize.never;
    options.beforeSend = _scrubEvent;
    options.beforeBreadcrumb = _scrubBreadcrumb;
  }, appRunner: body);
}

SentryEvent? _scrubEvent(SentryEvent event, Hint hint) {
  return event
    ..user = null
    ..request = null
    ..breadcrumbs = const <Breadcrumb>[];
}

Breadcrumb? _scrubBreadcrumb(Breadcrumb? breadcrumb, Hint hint) {
  if (breadcrumb == null) return null;
  return Breadcrumb(
    category: breadcrumb.category,
    type: breadcrumb.type,
    level: breadcrumb.level,
    timestamp: breadcrumb.timestamp,
    message: breadcrumb.category == 'navigation' ? breadcrumb.message : null,
    data: null,
  );
}
