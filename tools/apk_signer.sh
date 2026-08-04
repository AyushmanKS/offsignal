#!/bin/sh
# Reports which key an APK was signed with, so a debug-signed build is never
# mistaken for a release-signed one. Prints a plain-language answer, never fails
# the build.
set -u

APK="${1:-}"
[ -f "$APK" ] || { echo "unknown (no APK at $APK)"; exit 0; }

APKSIGNER=$(ls "$HOME"/Library/Android/sdk/build-tools/*/apksigner 2>/dev/null | tail -1)
[ -n "$APKSIGNER" ] || APKSIGNER=$(command -v apksigner 2>/dev/null)
[ -n "${APKSIGNER:-}" ] || { echo "unknown (apksigner not found)"; exit 0; }

CERTS=$("$APKSIGNER" verify --print-certs "$APK" 2>/dev/null) || {
  echo "UNSIGNED"
  exit 0
}

SUBJECT=$(printf '%s\n' "$CERTS" | grep -m1 'certificate DN:' | sed 's/.*certificate DN: //')

case "$SUBJECT" in
  *"Android Debug"*)
    echo "DEBUG KEY — fine for your own testing, do not distribute ($SUBJECT)"
    ;;
  "")
    echo "signed, but the certificate subject could not be read"
    ;;
  *)
    echo "release key ($SUBJECT)"
    ;;
esac
