// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'OffSignal';

  @override
  String get appTagline =>
      'Move a note, link, or small file between phones using only light.';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionOpenSettings => 'Open Settings';

  @override
  String get actionDismiss => 'Dismiss';

  @override
  String get actionBack => 'Back';

  @override
  String get actionClose => 'Close';

  @override
  String get actionNext => 'Next';

  @override
  String get actionSkip => 'Skip';

  @override
  String get homeSendTitle => 'Send';

  @override
  String get homeSendDescription =>
      'Show a stream of codes for another phone to read.';

  @override
  String get homeReceiveTitle => 'Receive';

  @override
  String get homeReceiveDescription =>
      'Point your camera at the other phone\'s screen.';

  @override
  String get homeSettingsLabel => 'Settings';

  @override
  String get composeTitle => 'Send';

  @override
  String get composeSegmentText => 'Text';

  @override
  String get composeSegmentFile => 'File';

  @override
  String get composeTextHint => 'Type a message or paste a link';

  @override
  String get composeTextFieldLabel => 'Message to send';

  @override
  String composeCharacterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters',
      one: '1 character',
    );
    return '$_temp0';
  }

  @override
  String get composeChooseFile => 'Choose a file';

  @override
  String get composeChooseFileHint => 'An image, PDF, or small document';

  @override
  String get composeRemoveFile => 'Remove file';

  @override
  String composeEstimateBlocks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocks',
      one: '1 block',
    );
    return '$_temp0';
  }

  @override
  String composeEstimateBand(int from, int to) {
    return '~$from–${to}s';
  }

  @override
  String get composeStart => 'Start broadcasting';

  @override
  String get composeDisabledHelp => 'Type a message or choose a file';

  @override
  String get composeSwitchToTextTitle => 'Switch to text?';

  @override
  String get composeSwitchToFileTitle => 'Switch to a file?';

  @override
  String get composeSwitchBody =>
      'The content you already added will be cleared.';

  @override
  String get composeSwitchConfirm => 'Switch';

  @override
  String get composeLargePayloadWarning =>
      'OffSignal is best for notes, links, and small files. This one may take a while.';

  @override
  String get broadcastingTitle => 'Broadcasting';

  @override
  String get broadcastingHint =>
      'Point the other phone\'s camera at this screen.';

  @override
  String get broadcastingStatBlocks => 'Blocks';

  @override
  String get broadcastingStatFramesSent => 'Frames sent';

  @override
  String get broadcastingStatElapsed => 'Elapsed';

  @override
  String get broadcastingSpeedLabel => 'Cycle speed';

  @override
  String broadcastingSpeedValue(int milliseconds) {
    return '$milliseconds ms';
  }

  @override
  String get broadcastingSpeedHelp =>
      'Slow this down if the other phone isn\'t picking frames up.';

  @override
  String get broadcastingPausedTitle => 'Paused';

  @override
  String get broadcastingPausedBody =>
      'Broadcasting stopped while OffSignal was in the background.';

  @override
  String get broadcastingResume => 'Resume';

  @override
  String get broadcastingLeaveTitle => 'Stop broadcasting?';

  @override
  String get broadcastingLeaveBody =>
      'The other device hasn\'t finished receiving.';

  @override
  String get receiveTitle => 'Receive';

  @override
  String get receivePermissionTitle => 'OffSignal needs your camera';

  @override
  String get receivePermissionBody =>
      'OffSignal uses your camera to read the light signal from another device. Nothing is recorded or uploaded.';

  @override
  String get receiveAllowCamera => 'Allow camera';

  @override
  String get receivePermissionDeniedTitle => 'Camera access is off';

  @override
  String get receivePermissionDeniedBody =>
      'Turn on camera access for OffSignal in your device settings, then come back.';

  @override
  String get receiveStartListening => 'Start listening';

  @override
  String get receiveScanningHint => 'Point at the other phone\'s screen';

  @override
  String get receiveWaiting => 'Looking for a signal…';

  @override
  String get receiveVerifying => 'Verifying…';

  @override
  String get receiveVerifyRetry =>
      'That didn\'t verify yet. Hold both phones steady — still listening.';

  @override
  String receiveStatBlocks(int solved, int total) {
    return '$solved / $total blocks';
  }

  @override
  String receiveStatFramesRead(int count) {
    return '$count frames read';
  }

  @override
  String get receiveTorchOn => 'Turn the flash on';

  @override
  String get receiveTorchOff => 'Turn the flash off';

  @override
  String get receiveLeaveTitle => 'Stop listening?';

  @override
  String get receiveLeaveBody => 'This transfer isn\'t finished yet.';

  @override
  String get resultTitle => 'Received';

  @override
  String get resultMessageLabel => 'Message';

  @override
  String get resultCopy => 'Copy';

  @override
  String get resultCopied => 'Copied to clipboard';

  @override
  String get resultSave => 'Save';

  @override
  String get resultShare => 'Share';

  @override
  String get resultSaved => 'Saved to your files';

  @override
  String get resultAnother => 'Send or receive another';

  @override
  String get onboardingLightTitle => 'Light, not radio';

  @override
  String get onboardingLightBody =>
      'One phone shows a fast stream of codes. The other reads them with its camera. No WiFi, no Bluetooth, no account, no internet.';

  @override
  String get onboardingPermissionsTitle => 'Camera only';

  @override
  String get onboardingPermissionsBody =>
      'Receiving needs camera access. Nothing is recorded, stored, or uploaded — what you send never leaves the two phones.';

  @override
  String get onboardingInstallTitle => 'Keep OffSignal one tap away';

  @override
  String get onboardingInstallIosBody =>
      'Tap the Share button in Safari, then choose Add to Home Screen. OffSignal keeps working with no signal once it\'s on your home screen.';

  @override
  String get onboardingInstallAndroidBody =>
      'Tap the menu in Chrome, then choose Install app. For the smoothest experience you can also download the Android app directly — no Play Store account needed.';

  @override
  String get onboardingDownloadAndroidApp => 'Download the Android app';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsTransfer => 'Transfer';

  @override
  String get settingsDefaultSpeed => 'Default cycle speed';

  @override
  String get settingsHaptics => 'Haptics';

  @override
  String get settingsHapticsDescription =>
      'Vibrate on success and key actions.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsReplayOnboarding => 'Replay the intro';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsSource => 'Source code';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get errorCameraPermissionDenied =>
      'Camera access is off. Turn it on in Settings, then try again.';

  @override
  String get errorCameraUnavailable =>
      'The camera couldn\'t start. Check another app isn\'t using it, then try again.';

  @override
  String get errorTransferCorrupted =>
      'That transfer didn\'t come through cleanly. Ask the other phone to start again.';

  @override
  String get errorPayloadTooLarge =>
      'That file is too large to send over light. Try something smaller.';

  @override
  String get errorPayloadEmpty => 'Add a message or choose a file to send.';

  @override
  String get errorFileUnreadable =>
      'That file couldn\'t be read. Try choosing it again.';

  @override
  String get errorSaveFailed =>
      'Couldn\'t save the file. Try again, or use Share instead.';

  @override
  String get errorShareFailed => 'Couldn\'t open the share sheet. Try again.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';

  @override
  String unitBytes(int count) {
    return '$count B';
  }

  @override
  String unitKilobytes(String count) {
    return '$count KB';
  }

  @override
  String unitMegabytes(String count) {
    return '$count MB';
  }
}
