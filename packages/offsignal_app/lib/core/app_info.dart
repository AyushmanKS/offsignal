import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class AppInfo {
  static const privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://offsignal.app/privacy.html',
  );

  static const sourceUrl = String.fromEnvironment(
    'SOURCE_URL',
    defaultValue: 'https://github.com/offsignal/offsignal',
  );

  static const apkDownloadUrl = String.fromEnvironment(
    'APK_DOWNLOAD_URL',
    defaultValue: 'https://github.com/offsignal/offsignal/releases/latest',
  );
}

final appVersionProvider = Provider<String>(
  (ref) => throw UnimplementedError('appVersionProvider must be overridden'),
);

Future<void> openExternalUrl(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } on Object {
    return;
  }
}
