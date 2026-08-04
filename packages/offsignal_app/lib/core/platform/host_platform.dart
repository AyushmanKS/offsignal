import 'package:flutter/foundation.dart';

enum HostPlatform { iosNative, androidNative, iosWeb, androidWeb, otherWeb, other }

extension HostPlatformTraits on HostPlatform {
  bool get isWeb =>
      this == HostPlatform.iosWeb ||
      this == HostPlatform.androidWeb ||
      this == HostPlatform.otherWeb;

  bool get prefersIosInstallInstructions => this == HostPlatform.iosWeb;
}

HostPlatform detectHostPlatform() {
  if (kIsWeb) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => HostPlatform.iosWeb,
      TargetPlatform.android => HostPlatform.androidWeb,
      _ => HostPlatform.otherWeb,
    };
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => HostPlatform.iosNative,
    TargetPlatform.android => HostPlatform.androidNative,
    _ => HostPlatform.other,
  };
}
