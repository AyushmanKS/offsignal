import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class AppInfo {
  static const privacyPolicyUrl = 'https://offsignal.app/privacy';
  static const sourceUrl = 'https://github.com/offsignal/offsignal';
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
