#!/usr/bin/env bash
# Upload .ipa via App Store Connect API (.p8).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

: "${APPSTORE_ISSUER_ID:?APPSTORE_ISSUER_ID is required}"
: "${APPSTORE_KEY_ID:?APPSTORE_KEY_ID is required}"
: "${APPSTORE_AUTH_KEY_BASE64:?APPSTORE_AUTH_KEY_BASE64 is required}"

IPA_PATH="${IOS_IPA_PATH:-}"
if [[ -z "$IPA_PATH" ]]; then
  IPA_DIR="$ROOT/build/ios/ipa"
  IPA_PATH="$(find "$IPA_DIR" -maxdepth 1 -name '*.ipa' | head -n1)"
fi
[[ -f "$IPA_PATH" ]] || { echo "IPA not found: $IPA_PATH"; exit 1; }

KEY_DIR="$HOME/.private_keys"
mkdir -p "$KEY_DIR"
KEY_FILE="$KEY_DIR/AuthKey_${APPSTORE_KEY_ID}.p8"
printf '%s' "$APPSTORE_AUTH_KEY_BASE64" | tr -d ' \t\r\n' | base64 -D >"$KEY_FILE"
chmod 600 "$KEY_FILE"

echo "Uploading $(basename "$IPA_PATH") with API key $APPSTORE_KEY_ID"
xcrun altool --upload-app \
  --type ios \
  --file "$IPA_PATH" \
  --apiKey "$APPSTORE_KEY_ID" \
  --apiIssuer "$APPSTORE_ISSUER_ID"
