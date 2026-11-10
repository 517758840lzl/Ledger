#!/usr/bin/env bash
# Import Distribution cert + provisioning profile on GitHub Actions macOS runner.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

: "${IOS_DIST_P12_BASE64:?IOS_DIST_P12_BASE64 is required}"
: "${IOS_DIST_P12_PASSWORD:?IOS_DIST_P12_PASSWORD is required}"
: "${IOS_PROVISION_PROFILE_BASE64:?IOS_PROVISION_PROFILE_BASE64 is required}"
: "${IOS_TEAM_ID:?IOS_TEAM_ID is required}"
: "${IOS_PROVISIONING_PROFILE_NAME:?IOS_PROVISIONING_PROFILE_NAME is required}"

PROFILE_NAME="$IOS_PROVISIONING_PROFILE_NAME"
KEYCHAIN_NAME="${IOS_KEYCHAIN_NAME:-build.keychain-db}"
KEYCHAIN_PATH="$HOME/Library/Keychains/$KEYCHAIN_NAME"
KEYCHAIN_PASSWORD="${IOS_KEYCHAIN_PASSWORD:-$(openssl rand -base64 32)}"

WORKDIR="${RUNNER_TEMP:-/tmp}/ios-sign"
mkdir -p "$WORKDIR"
P12_PATH="$WORKDIR/dist.p12"
PROFILE_PATH="$WORKDIR/profile.mobileprovision"

decode_base64_to_file() {
  local data="$1" out="$2"
  printf '%s' "$data" | tr -d ' \t\r\n' | base64 -D >"$out"
}

P12_PASSWORD="$(printf '%s' "$IOS_DIST_P12_PASSWORD" | tr -d '\r\n')"

decode_base64_to_file "$IOS_DIST_P12_BASE64" "$P12_PATH"
decode_base64_to_file "$IOS_PROVISION_PROFILE_BASE64" "$PROFILE_PATH"

# -legacy keeps a p12 made on another Mac readable by openssl and accepted by
# the macOS keychain import.
if ! openssl pkcs12 -in "$P12_PATH" -noout -passin "pass:${P12_PASSWORD}" -legacy 2>/dev/null; then
  echo "error: p12 does not match IOS_DIST_P12_PASSWORD (check base64 and password secret)"
  exit 1
fi
echo "p12 password OK ($(wc -c <"$P12_PATH" | tr -d ' ') bytes)"

P12_APPLE="$WORKDIR/dist-apple.p12"
openssl pkcs12 -in "$P12_PATH" -passin "pass:${P12_PASSWORD}" -legacy -nocerts -nodes -out "$WORKDIR/key.pem"
openssl pkcs12 -in "$P12_PATH" -passin "pass:${P12_PASSWORD}" -legacy -clcerts -nokeys -out "$WORKDIR/cert.pem"
openssl pkcs12 -export -legacy -inkey "$WORKDIR/key.pem" -in "$WORKDIR/cert.pem" \
  -passout "pass:${P12_PASSWORD}" -out "$P12_APPLE"
P12_PATH="$P12_APPLE"
echo "repacked p12 for macOS keychain ($(wc -c <"$P12_PATH" | tr -d ' ') bytes)"

WWDR_PATH="$WORKDIR/AppleWWDRCAG3.cer"
curl -fsSL "https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer" -o "$WWDR_PATH"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security list-keychains -d user -s "$KEYCHAIN_PATH" login.keychain-db
security default-keychain -s "$KEYCHAIN_PATH"

security import "$WWDR_PATH" -k "$KEYCHAIN_PATH" -T /usr/bin/codesign -T /usr/bin/security
security import "$P12_PATH" -k "$KEYCHAIN_PATH" -P "$P12_PASSWORD" \
  -T /usr/bin/codesign -T /usr/bin/security -T /usr/bin/xcodebuild
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" || true

PROFILE_UUID="$(
  security cms -D -i "$PROFILE_PATH" 2>/dev/null | plutil -extract UUID raw -o - -
)"
PROFILE_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILE_DIR"
cp "$PROFILE_PATH" "$PROFILE_DIR/${PROFILE_UUID}.mobileprovision"

export IOS_TEAM_ID PROFILE_NAME
BUNDLE_ID="$(
python3 - <<'PY'
import os
import re
from pathlib import Path

team = os.environ["IOS_TEAM_ID"]
profile = os.environ["PROFILE_NAME"].replace("\\", "\\\\").replace('"', '\\"')
path = Path("Ledger.xcodeproj/project.pbxproj")
text = path.read_text()

parts = text.split("isa = PBXNativeTarget;")
app_head = ""
for part in parts[1:]:
    head = part.split("isa = ", 1)[0]
    if 'productType = "com.apple.product-type.application";' in head:
        app_head = head
        break
if not app_head:
    raise SystemExit("application target not found")
list_id = re.search(r"buildConfigurationList = ([A-F0-9]{24})", app_head)
if not list_id:
    raise SystemExit("application target has no configuration list")
list_body = re.search(
    rf"\t\t{list_id.group(1)} /\* Build configuration list for PBXNativeTarget .*? \*/ = \{{\n"
    rf"\t\t\tisa = XCConfigurationList;\n"
    rf"\t\t\tbuildConfigurations = \((.*?)\);",
    text,
    re.S,
)
if not list_body:
    raise SystemExit("application configuration list not found")
config_ids = re.findall(r"([A-F0-9]{24})", list_body.group(1))
if not config_ids:
    raise SystemExit("application target has no build configurations")

text = re.sub(
    r"DEVELOPMENT_TEAM = [^;]+;",
    f"DEVELOPMENT_TEAM = {team};",
    text,
)

def signing_settings(body: str) -> str:
    if "CODE_SIGN_STYLE = " in body:
        body = re.sub(r"CODE_SIGN_STYLE = [^;]+;", "CODE_SIGN_STYLE = Manual;", body, count=1)
    else:
        body = "\t\t\t\tCODE_SIGN_STYLE = Manual;\n" + body
    body = re.sub(r'\t*"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = [^;]+;\n', "", body)
    body = re.sub(r"\t*CODE_SIGN_IDENTITY = [^;]+;\n", "", body)
    body = re.sub(r'\t*PROVISIONING_PROFILE_SPECIFIER = "[^"]*";\n', "", body)

    found = {}

    def bundle_line(match: re.Match) -> str:
        indent = match.group(1)
        current = match.group(2).strip().strip('"')
        if current.startswith("$(") and current.endswith(")"):
            key = current[2:-1]
            cfg = Path("Config/Signing.xcconfig").read_text()
            resolved = re.search(rf"^{re.escape(key)}\s*=\s*(\S+)\s*$", cfg, re.M)
            if not resolved:
                raise SystemExit(f"{key} missing from Signing.xcconfig")
            current = resolved.group(1)
        found["id"] = current
        return (
            f'{indent}CODE_SIGN_IDENTITY = "Apple Distribution";\n'
            f'{indent}"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";\n'
            f'{indent}PROVISIONING_PROFILE_SPECIFIER = "{profile}";\n'
            f"{indent}PRODUCT_BUNDLE_IDENTIFIER = {match.group(2)};"
        )

    updated, count = re.subn(
        r"^(\s*)PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);",
        bundle_line,
        body,
        count=1,
        flags=re.M,
    )
    if count != 1 or "id" not in found:
        raise SystemExit("application configuration has no bundle id")
    bundle_ids.append(found["id"])
    return updated

bundle_ids = []
patched = 0
for config_id in config_ids:
    match = re.search(
        rf"(\t\t{config_id} /\* .*? \*/ = \{{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = \{{\n)(.*?)(\n\t\t\t\}};\n)",
        text,
        re.S,
    )
    if not match:
        raise SystemExit(f"build configuration {config_id} not found")
    text = text[: match.start()] + match.group(1) + signing_settings(match.group(2)) + match.group(3) + text[match.end() :]
    patched += 1

if len(set(bundle_ids)) != 1:
    raise SystemExit(f"application bundle ids differ: {bundle_ids}")
path.write_text(text)
print(bundle_ids[0])
PY
)"
[[ -n "$BUNDLE_ID" ]] || { echo "Bundle ID not found"; exit 1; }

EXPORT_PLIST="ios/ExportOptions.ci.plist"
mkdir -p ios
cat >"$EXPORT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>teamID</key>
  <string>${IOS_TEAM_ID}</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>${BUNDLE_ID}</key>
    <string>${PROFILE_NAME}</string>
  </dict>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
EOF

printf '%s' "$KEYCHAIN_PASSWORD" >"${RUNNER_TEMP}/ios_keychain_password"
printf '%s' "$KEYCHAIN_PATH" >"${RUNNER_TEMP}/ios_keychain_path"
chmod 600 "${RUNNER_TEMP}/ios_keychain_password" "${RUNNER_TEMP}/ios_keychain_path"

echo "Keychain: $KEYCHAIN_NAME"
echo "Profile: $PROFILE_NAME (UUID $PROFILE_UUID)"
echo "Bundle ID: $BUNDLE_ID"
security find-identity -v -p codesigning "$KEYCHAIN_PATH" || true
