import 'l10n/generated/app_localizations.dart';

const _kilobyte = 1024;
const _megabyte = 1024 * 1024;

String formatBytes(AppLocalizations strings, int bytes) {
  if (bytes < _kilobyte) return strings.unitBytes(bytes);
  if (bytes < _megabyte) {
    return strings.unitKilobytes((bytes / _kilobyte).toStringAsFixed(1));
  }
  return strings.unitMegabytes((bytes / _megabyte).toStringAsFixed(2));
}

String formatElapsed(Duration elapsed) {
  final minutes = elapsed.inMinutes;
  final seconds = elapsed.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String formatCount(int value) {
  if (value < 1000) return '$value';
  if (value < 10000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return '${value ~/ 1000}k';
}
