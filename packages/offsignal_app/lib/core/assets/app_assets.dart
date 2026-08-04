abstract final class AppFonts {
  static const spaceGrotesk = 'SpaceGrotesk';
  static const inter = 'Inter';
  static const jetBrainsMono = 'JetBrainsMono';
}

abstract final class AppIcons {
  static const _base = 'assets/icons';

  static const send = '$_base/send.svg';
  static const receive = '$_base/receive.svg';
  static const camera = '$_base/camera.svg';
  static const file = '$_base/file.svg';
  static const textNote = '$_base/text-note.svg';
  static const copy = '$_base/copy.svg';
  static const share = '$_base/share.svg';
  static const downloadSave = '$_base/download-save.svg';
  static const settings = '$_base/settings.svg';
  static const checkmarkSuccess = '$_base/checkmark-success.svg';
  static const alertError = '$_base/alert-error.svg';
  static const chevronBack = '$_base/chevron-back.svg';
  static const close = '$_base/close.svg';
  static const uploadPicker = '$_base/upload-picker.svg';
  static const stopBroadcast = '$_base/stop-broadcast.svg';
  static const playBroadcast = '$_base/play-broadcast.svg';
  static const radioOff = '$_base/radio-off.svg';
  static const lightWave = '$_base/light-wave.svg';
  static const scanCornerBracket = '$_base/scan-corner-bracket.svg';
  static const flashOn = '$_base/flash-on.svg';
  static const flashOff = '$_base/flash-off.svg';

  static const all = <String>[
    send,
    receive,
    camera,
    file,
    textNote,
    copy,
    share,
    downloadSave,
    settings,
    checkmarkSuccess,
    alertError,
    chevronBack,
    close,
    uploadPicker,
    stopBroadcast,
    playBroadcast,
    radioOff,
    lightWave,
    scanCornerBracket,
    flashOn,
    flashOff,
  ];
}

abstract final class AppImages {
  static const _base = 'assets/images';

  static const onboardingLightConcept = '$_base/onboarding_light_concept.webp';
  static const onboardingPermissions = '$_base/onboarding_permissions.webp';
  static const onboardingAddToHomeIos =
      '$_base/onboarding_add_to_home_ios.webp';
  static const onboardingAddToHomeAndroid =
      '$_base/onboarding_add_to_home_android.webp';

  static const all = <String>[
    onboardingLightConcept,
    onboardingPermissions,
    onboardingAddToHomeIos,
    onboardingAddToHomeAndroid,
  ];
}

abstract final class AppAnimations {
  static const _base = 'assets/animations';
  static const successCheckmark = '$_base/success_checkmark.json';
  static const all = <String>[successCheckmark];
}

abstract final class AppIconSource {
  static const _base = 'assets/icon';
  static const masterIcon = '$_base/app_icon_master.png';
  static const adaptiveForeground = '$_base/app_icon_adaptive_fg.png';
  static const splashLogoLight = '$_base/splash_logo_light.png';
  static const splashLogoDark = '$_base/splash_logo_dark.png';
}
