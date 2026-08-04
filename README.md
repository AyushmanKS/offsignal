# OffSignal

Move a note, link, or small file from one phone to another using **only light**. The sender
displays a rapidly cycling sequence of QR codes; the receiver reads them with its camera. No WiFi,
no Bluetooth, no pairing, no server, no internet after install.

The transport is a **Luby Transform fountain code**: the sender emits an endless stream of coded
packets and never waits for a specific missing one, and the receiver reconstructs the payload from
any sufficient subset it manages to scan.

Implements [docs/prd1.md](docs/prd1.md).

## Quick start

This repo is a pub workspace, so the Flutter app lives in `packages/offsignal_app`, not at the root.
Running `flutter run` from the root fails with `Target file "lib/main.dart" not found` — use the
Makefile instead, which drives everything from the root:

```bash
make setup     # resolve dependencies for the whole workspace
make run       # run the app  (make run DEVICE=chrome to pick a device)
make test      # every suite: codec, tooling, app
make verify    # everything CI runs
make help      # all targets
```

Or work in the app package directly:

```bash
cd packages/offsignal_app && flutter run
```

In VS Code, press F5 — the launch configs in `.vscode/launch.json` already point at the right entry
point and working directory.

## Layout

```
packages/
  offsignal_core/     pure Dart codec, zero Flutter dependency
  offsignal_app/      Flutter app for Android, iOS, and web
  offsignal_tools/    repository guards that run in CI
tools/
  generate_brand_assets.py   regenerates the bundled icon, splash, and onboarding art
```

## Getting started

```bash
flutter pub get                      # resolves the whole workspace
cd packages/offsignal_app
flutter run                          # or: flutter run -d chrome
```

## Tests

```bash
cd packages/offsignal_core && dart test    # codec, including a 1000-run randomized soak
cd packages/offsignal_tools && dart test   # comment guard
cd packages/offsignal_app  && flutter test # widgets, goldens, asset guard, send-to-receive loop
```

Goldens are generated on macOS. Regenerate with `flutter test --update-goldens` if font rendering
differs on your platform.

## How the transport works

A payload is framed, gzipped, split into `K` blocks, and fountain-encoded:

```
[u16 metaLen][metaJSON {name, mimeType}]
[u8  hashLen][sha256 of the uncompressed payload]
[payload bytes]
  -> gzip -> chunk into K blocks -> LT encode -> base64 -> QR
```

The SHA-256 travels *inside* the gzip payload, so it is protected by the fountain code rather than
sent alongside it. The receiver only reports success once it has reassembled every block, gunzipped,
and recomputed a matching hash. A transfer that fails that gate returns to listening instead of
delivering anything — a corrupted payload never reaches the result screen.

Block size adapts to the payload (180 bytes by default, growing to keep the block count workable),
and cycle speed is user-controlled from the send screen. Automatic speed tuning is deliberately out
of scope; `SpeedController` in `offsignal_core` is the extension point for it.

## Conventions

- **No comments in source.** `packages/offsignal_tools` enforces this in CI; restructure code rather
  than explaining it inline.
- **Every user-facing string goes through ARB** (`lib/core/l10n/app_en.arb`), even though v1 ships
  English only. Run `flutter gen-l10n` from `packages/offsignal_app` after editing.
- **Errors never surface raw.** Every catch maps to the `AppException` hierarchy in
  `lib/core/errors/`, and the UI renders only from that.
- **Assets are referenced through `AppIcons` / `AppImages` / `AppAnimations`**, never as inline path
  strings. `test/core/assets/app_assets_test.dart` fails the build if a registered asset is missing.
- **Nothing is fetched at runtime.** Fonts, icons, and animations all ship bundled so the app works
  in airplane mode.

## Distribution

Everything here runs on free tiers, and there is no app store in the loop.

**Android — sideloaded APK.** Generate a release keystore once, locally, and never commit it:

```bash
keytool -genkey -v -keystore offsignal-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias offsignal
cp packages/offsignal_app/android/key.properties.example \
   packages/offsignal_app/android/key.properties   # then fill in your paths and passwords
flutter build apk --release
```

`key.properties`, `*.jks`, and `*.keystore` are gitignored. Without a `key.properties` the release
build falls back to debug signing so `flutter run --release` still works locally; CI restores the
real keystore from the `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`,
and `ANDROID_KEY_ALIAS` secrets and publishes the signed APK to a GitHub Release.

**iOS — via the web build.** There is no native iOS build; iOS users open the site in Safari and add
it to their home screen. Native iOS is deferred until a paid Apple Developer account exists, not
worked around.

**Web.** Deploy `build/web` to any free static host with automatic HTTPS (Cloudflare Pages by
default in CI, via `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ACCOUNT_ID`). Camera access requires HTTPS in
every browser. `web/privacy.html` and `web/download.html` deploy alongside the app.

Set the external URLs at build time:

```bash
flutter build web --release \
  --dart-define=PRIVACY_POLICY_URL=https://your-host/privacy.html \
  --dart-define=SOURCE_URL=https://github.com/your-org/offsignal \
  --dart-define=APK_DOWNLOAD_URL=https://github.com/your-org/offsignal/releases/latest
```

## Error visibility

There is no third-party crash reporting service, and the Android app requests **no INTERNET
permission** — it cannot phone home even in principle, which CI asserts against the merged release
manifest on every build. Errors are caught centrally as `AppException` and logged locally through
`AppLog`, which records only a screen name and a failure type. Read them with `flutter logs`,
Logcat, or Safari's web inspector. Sentry's free tier remains a documented future option; wiring it
in is deliberately not part of v1.

## Regenerating brand assets

```bash
python3 tools/generate_brand_assets.py                     # needs Pillow
cd packages/offsignal_app
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Manual QA checklist

Attach to any release PR. The light channel cannot be exercised by automated tests alone.

- [ ] Two-device round trip: Android <-> Android (native), Android <-> web, web <-> web. Native iOS
      is excluded in v1; test iPhones through Safari
- [ ] **Scanning works on a real device with the release APK**, which ships no INTERNET permission.
      The ML Kit barcode model is bundled, so this should hold — but it is the one behaviour that
      the permission strip could plausibly break, and CI cannot catch it
- [ ] Android app info screen lists Camera as the only permission
- [ ] The APK installs from the download page, following the "install unknown apps" steps as written
- [ ] Bright room and dim room; torch toggle helps in the dim case
- [ ] Close range and arm's length
- [ ] Text payload, image payload, and PDF payload each arrive byte-identical
- [ ] Camera indicator clears after: stop, completion, navigating away, backgrounding, and
      revoking permission mid-session
- [ ] Backgrounding the sender pauses the cycle and offers resume on return
- [ ] Denying camera permission shows the inline Open Settings card, never a crash
- [ ] Airplane mode: full send and receive still works
- [ ] OS reduce-motion on: transitions collapse to fades
- [ ] iPhone Safari and Android Chrome: no horizontal scroll, no desktop-scaled layout, safe areas
      respected, and the compose keyboard does not zoom or jump the layout
