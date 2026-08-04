# OffSignal

Move a note, link, or small file from one phone to another using **only light**. The sender
displays a rapidly cycling sequence of QR codes; the receiver reads them with its camera. No WiFi,
no Bluetooth, no pairing, no server, no internet after install.

The transport is a **Luby Transform fountain code**: the sender emits an endless stream of coded
packets and never waits for a specific missing one, and the receiver reconstructs the payload from
any sufficient subset it manages to scan.

Implements [docs/prd1.md](docs/prd1.md).

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

## Deployment

Set the two external URLs at build time:

```bash
flutter build web --release \
  --dart-define=PRIVACY_POLICY_URL=https://your-host/privacy.html \
  --dart-define=SOURCE_URL=https://github.com/your-org/offsignal
```

`web/privacy.html` deploys alongside the web build. Camera access requires HTTPS in every browser.

Crash reporting is off unless a DSN is supplied:

```bash
--dart-define=SENTRY_DSN=https://...
```

When enabled, `beforeSend` strips users, requests, and breadcrumbs so no message text, file contents,
or file names can leave the device.

## Regenerating brand assets

```bash
python3 tools/generate_brand_assets.py                     # needs Pillow
cd packages/offsignal_app
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Manual QA checklist

Attach to any release PR. The light channel cannot be exercised by automated tests alone.

- [ ] Two-device round trip: iOS <-> Android, iOS <-> iOS, Android <-> Android, web <-> native
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
