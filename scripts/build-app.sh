#!/usr/bin/env bash
# Assembles WindowKit.app from a release SwiftPM build.
# Unsigned — macOS will treat each rebuild as a new app identity, so
# Accessibility permission must be re-granted after every build.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP="$ROOT/build/WindowKit.app"
CONTENTS="$APP/Contents"

echo "==> swift build -c release"
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)"
EXEC="$BIN_PATH/WindowKit"
if [[ ! -x "$EXEC" ]]; then
  echo "error: $EXEC not found" >&2
  exit 1
fi

echo "==> assembling $APP"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$EXEC" "$CONTENTS/MacOS/WindowKit"
cp "$ROOT/App/Info.plist" "$CONTENTS/Info.plist"

if [[ -d "$ROOT/App/Assets.xcassets" ]]; then
  cp -R "$ROOT/App/Assets.xcassets" "$CONTENTS/Resources/"
fi

if [[ -f "$ROOT/App/AppIcon.icns" ]]; then
  cp "$ROOT/App/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"
fi

# Ad-hoc sign so Gatekeeper and the AX subsystem get a stable code identity
# (still unsigned in the distribution sense; re-granting AX per rebuild still applies).
codesign --force --sign - "$APP" >/dev/null 2>&1 || true

echo "==> done: $APP"
