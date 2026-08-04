#!/bin/sh
# Lists the permissions an APK actually requests. PRD section 12.1 requires
# CAMERA and nothing else, so this makes a regression visible at build time.
set -u

APK="${1:-}"
[ -f "$APK" ] || { echo "unknown (no APK at $APK)"; exit 0; }

AAPT=$(ls "$HOME"/Library/Android/sdk/build-tools/*/aapt2 2>/dev/null | tail -1)
[ -n "$AAPT" ] || AAPT=$(command -v aapt2 2>/dev/null)
[ -n "${AAPT:-}" ] || { echo "unknown (aapt2 not found)"; exit 0; }

PERMS=$("$AAPT" dump permissions "$APK" 2>/dev/null \
  | sed -n "s/^uses-permission: name='android.permission.\([^']*\)'/\1/p" \
  | sort)

[ -n "$PERMS" ] || { echo "none"; exit 0; }

printf '%s' "$(printf '%s\n' "$PERMS" | paste -sd, - | tr -d ' ')"

if printf '%s\n' "$PERMS" | grep -q '^INTERNET$'; then
  printf '  <-- INTERNET present, PRD section 12.1 forbids it'
fi
echo ""
