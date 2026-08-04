import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'OffSignal'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Move a note, link, or small file between phones using only light.'**
  String get appTagline;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get actionOpenSettings;

  /// No description provided for @actionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get actionDismiss;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @homeSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get homeSendTitle;

  /// No description provided for @homeSendDescription.
  ///
  /// In en, this message translates to:
  /// **'Show a stream of codes for another phone to read.'**
  String get homeSendDescription;

  /// No description provided for @homeReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get homeReceiveTitle;

  /// No description provided for @homeReceiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the other phone\'s screen.'**
  String get homeReceiveDescription;

  /// No description provided for @homeSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettingsLabel;

  /// No description provided for @composeTitle.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get composeTitle;

  /// No description provided for @composeSegmentText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get composeSegmentText;

  /// No description provided for @composeSegmentFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get composeSegmentFile;

  /// No description provided for @composeTextHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message or paste a link'**
  String get composeTextHint;

  /// No description provided for @composeTextFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Message to send'**
  String get composeTextFieldLabel;

  /// No description provided for @composeCharacterCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 character} other{{count} characters}}'**
  String composeCharacterCount(int count);

  /// No description provided for @composeChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get composeChooseFile;

  /// No description provided for @composeChooseFileHint.
  ///
  /// In en, this message translates to:
  /// **'An image, PDF, or small document'**
  String get composeChooseFileHint;

  /// No description provided for @composeRemoveFile.
  ///
  /// In en, this message translates to:
  /// **'Remove file'**
  String get composeRemoveFile;

  /// No description provided for @composeEstimateBlocks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 block} other{{count} blocks}}'**
  String composeEstimateBlocks(int count);

  /// No description provided for @composeEstimateBand.
  ///
  /// In en, this message translates to:
  /// **'~{from}–{to}s'**
  String composeEstimateBand(int from, int to);

  /// No description provided for @composeStart.
  ///
  /// In en, this message translates to:
  /// **'Start broadcasting'**
  String get composeStart;

  /// No description provided for @composeDisabledHelp.
  ///
  /// In en, this message translates to:
  /// **'Type a message or choose a file'**
  String get composeDisabledHelp;

  /// No description provided for @composeSwitchToTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to text?'**
  String get composeSwitchToTextTitle;

  /// No description provided for @composeSwitchToFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to a file?'**
  String get composeSwitchToFileTitle;

  /// No description provided for @composeSwitchBody.
  ///
  /// In en, this message translates to:
  /// **'The content you already added will be cleared.'**
  String get composeSwitchBody;

  /// No description provided for @composeSwitchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get composeSwitchConfirm;

  /// No description provided for @composeLargePayloadWarning.
  ///
  /// In en, this message translates to:
  /// **'OffSignal is best for notes, links, and small files. This one may take a while.'**
  String get composeLargePayloadWarning;

  /// No description provided for @broadcastingTitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcasting'**
  String get broadcastingTitle;

  /// No description provided for @broadcastingHint.
  ///
  /// In en, this message translates to:
  /// **'Point the other phone\'s camera at this screen.'**
  String get broadcastingHint;

  /// No description provided for @broadcastingStatBlocks.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get broadcastingStatBlocks;

  /// No description provided for @broadcastingStatFramesSent.
  ///
  /// In en, this message translates to:
  /// **'Frames sent'**
  String get broadcastingStatFramesSent;

  /// No description provided for @broadcastingStatElapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed'**
  String get broadcastingStatElapsed;

  /// No description provided for @broadcastingSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Cycle speed'**
  String get broadcastingSpeedLabel;

  /// No description provided for @broadcastingSpeedValue.
  ///
  /// In en, this message translates to:
  /// **'{milliseconds} ms'**
  String broadcastingSpeedValue(int milliseconds);

  /// No description provided for @broadcastingSpeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Slow this down if the other phone isn\'t picking frames up.'**
  String get broadcastingSpeedHelp;

  /// No description provided for @broadcastingPausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get broadcastingPausedTitle;

  /// No description provided for @broadcastingPausedBody.
  ///
  /// In en, this message translates to:
  /// **'Broadcasting stopped while OffSignal was in the background.'**
  String get broadcastingPausedBody;

  /// No description provided for @broadcastingResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get broadcastingResume;

  /// No description provided for @broadcastingLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop broadcasting?'**
  String get broadcastingLeaveTitle;

  /// No description provided for @broadcastingLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'The other device hasn\'t finished receiving.'**
  String get broadcastingLeaveBody;

  /// No description provided for @receiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receiveTitle;

  /// No description provided for @receivePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'OffSignal needs your camera'**
  String get receivePermissionTitle;

  /// No description provided for @receivePermissionBody.
  ///
  /// In en, this message translates to:
  /// **'OffSignal uses your camera to read the light signal from another device. Nothing is recorded or uploaded.'**
  String get receivePermissionBody;

  /// No description provided for @receiveAllowCamera.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get receiveAllowCamera;

  /// No description provided for @receivePermissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off'**
  String get receivePermissionDeniedTitle;

  /// No description provided for @receivePermissionDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on camera access for OffSignal in your device settings, then come back.'**
  String get receivePermissionDeniedBody;

  /// No description provided for @receiveStartListening.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get receiveStartListening;

  /// No description provided for @receiveScanningHint.
  ///
  /// In en, this message translates to:
  /// **'Point at the other phone\'s screen'**
  String get receiveScanningHint;

  /// No description provided for @receiveWaiting.
  ///
  /// In en, this message translates to:
  /// **'Looking for a signal…'**
  String get receiveWaiting;

  /// No description provided for @receiveVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get receiveVerifying;

  /// No description provided for @receiveVerifyRetry.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t verify yet. Hold both phones steady — still listening.'**
  String get receiveVerifyRetry;

  /// No description provided for @receiveStatBlocks.
  ///
  /// In en, this message translates to:
  /// **'{solved} / {total} blocks'**
  String receiveStatBlocks(int solved, int total);

  /// No description provided for @receiveStatFramesRead.
  ///
  /// In en, this message translates to:
  /// **'{count} frames read'**
  String receiveStatFramesRead(int count);

  /// No description provided for @receiveTorchOn.
  ///
  /// In en, this message translates to:
  /// **'Turn the flash on'**
  String get receiveTorchOn;

  /// No description provided for @receiveTorchOff.
  ///
  /// In en, this message translates to:
  /// **'Turn the flash off'**
  String get receiveTorchOff;

  /// No description provided for @receiveLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop listening?'**
  String get receiveLeaveTitle;

  /// No description provided for @receiveLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'This transfer isn\'t finished yet.'**
  String get receiveLeaveBody;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get resultTitle;

  /// No description provided for @resultMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get resultMessageLabel;

  /// No description provided for @resultCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get resultCopy;

  /// No description provided for @resultCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get resultCopied;

  /// No description provided for @resultSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get resultSave;

  /// No description provided for @resultShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get resultShare;

  /// No description provided for @resultSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to your files'**
  String get resultSaved;

  /// No description provided for @resultAnother.
  ///
  /// In en, this message translates to:
  /// **'Send or receive another'**
  String get resultAnother;

  /// No description provided for @onboardingLightTitle.
  ///
  /// In en, this message translates to:
  /// **'Light, not radio'**
  String get onboardingLightTitle;

  /// No description provided for @onboardingLightBody.
  ///
  /// In en, this message translates to:
  /// **'One phone shows a fast stream of codes. The other reads them with its camera. No WiFi, no Bluetooth, no account, no internet.'**
  String get onboardingLightBody;

  /// No description provided for @onboardingPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera only'**
  String get onboardingPermissionsTitle;

  /// No description provided for @onboardingPermissionsBody.
  ///
  /// In en, this message translates to:
  /// **'Receiving needs camera access. Nothing is recorded, stored, or uploaded — what you send never leaves the two phones.'**
  String get onboardingPermissionsBody;

  /// No description provided for @onboardingInstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Add OffSignal to your home screen'**
  String get onboardingInstallTitle;

  /// No description provided for @onboardingInstallIosBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the Share button in Safari, then choose Add to Home Screen. OffSignal keeps working with no signal once it\'s installed.'**
  String get onboardingInstallIosBody;

  /// No description provided for @onboardingInstallAndroidBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the menu in Chrome, then choose Install app. OffSignal keeps working with no signal once it\'s installed.'**
  String get onboardingInstallAndroidBody;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get settingsTransfer;

  /// No description provided for @settingsDefaultSpeed.
  ///
  /// In en, this message translates to:
  /// **'Default cycle speed'**
  String get settingsDefaultSpeed;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on success and key actions.'**
  String get settingsHapticsDescription;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsReplayOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Replay the intro'**
  String get settingsReplayOnboarding;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsSource.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get settingsSource;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @errorCameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off. Turn it on in Settings, then try again.'**
  String get errorCameraPermissionDenied;

  /// No description provided for @errorCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The camera couldn\'t start. Check another app isn\'t using it, then try again.'**
  String get errorCameraUnavailable;

  /// No description provided for @errorTransferCorrupted.
  ///
  /// In en, this message translates to:
  /// **'That transfer didn\'t come through cleanly. Ask the other phone to start again.'**
  String get errorTransferCorrupted;

  /// No description provided for @errorPayloadTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is too large to send over light. Try something smaller.'**
  String get errorPayloadTooLarge;

  /// No description provided for @errorPayloadEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a message or choose a file to send.'**
  String get errorPayloadEmpty;

  /// No description provided for @errorFileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'That file couldn\'t be read. Try choosing it again.'**
  String get errorFileUnreadable;

  /// No description provided for @errorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the file. Try again, or use Share instead.'**
  String get errorSaveFailed;

  /// No description provided for @errorShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the share sheet. Try again.'**
  String get errorShareFailed;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorUnknown;

  /// No description provided for @unitBytes.
  ///
  /// In en, this message translates to:
  /// **'{count} B'**
  String unitBytes(int count);

  /// No description provided for @unitKilobytes.
  ///
  /// In en, this message translates to:
  /// **'{count} KB'**
  String unitKilobytes(String count);

  /// No description provided for @unitMegabytes.
  ///
  /// In en, this message translates to:
  /// **'{count} MB'**
  String unitMegabytes(String count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
