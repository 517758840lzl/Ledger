#!/usr/bin/env bash
# Archive + export ipa with xcodebuild directly.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

: "${IOS_TEAM_ID:?IOS_TEAM_ID is required}"
PROFILE_NAME="${IOS_PROVISIONING_PROFILE_NAME:?IOS_PROVISIONING_PROFILE_NAME is required}"
KEYCHAIN_PATH="$(cat "${RUNNER_TEMP}/ios_keychain_path")"
KEYCHAIN_PASSWORD="$(cat "${RUNNER_TEMP}/ios_keychain_password")"

security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" || true

ARCHIVE="$ROOT/build/ios/archive/Ledger.xcarchive"
EXPORT_DIR="$ROOT/build/ios/ipa"
mkdir -p "$(dirname "$ARCHIVE")"
rm -rf "$ARCHIVE" "$EXPORT_DIR"

export NSUnbufferedIO=YES

# Signing is already set on the application target in project.pbxproj.
# Do not pass PROVISIONING_PROFILE_SPECIFIER or CODE_SIGN_STYLE here.
echo "Archiving with xcodebuild (profile: ${PROFILE_NAME})..."
xcodebuild \
  -project "$ROOT/Ledger.xcodeproj" \
  -scheme Ledger \
  -configuration Release \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE" \
  COMPILER_INDEX_STORE_ENABLE=NO \
  DEVELOPMENT_TEAM="$IOS_TEAM_ID" \
  OTHER_CODE_SIGN_FLAGS="--keychain ${KEYCHAIN_PATH}" \
  archive

echo "Exporting ipa..."
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$ROOT/ios/ExportOptions.ci.plist"

ls -lh "$EXPORT_DIR"/*.ipa
echo "IPA ready."
