import 'package:flutter_test/flutter_test.dart';
import 'package:offsignal_app/core/platform/host_platform.dart';

void main() {
  test('web hosts are recognised as web', () {
    expect(HostPlatform.iosWeb.isWeb, isTrue);
    expect(HostPlatform.androidWeb.isWeb, isTrue);
    expect(HostPlatform.otherWeb.isWeb, isTrue);
  });

  test('native hosts are not treated as web', () {
    expect(HostPlatform.androidNative.isWeb, isFalse);
    expect(HostPlatform.iosNative.isWeb, isFalse);
    expect(HostPlatform.other.isWeb, isFalse);
  });

  test('only iOS web gets the add-to-home-screen instructions', () {
    expect(HostPlatform.iosWeb.prefersIosInstallInstructions, isTrue);

    for (final host in HostPlatform.values.where(
      (candidate) => candidate != HostPlatform.iosWeb,
    )) {
      expect(
        host.prefersIosInstallInstructions,
        isFalse,
        reason: '$host should get the Android install instructions instead',
      );
    }
  });
}
