#!/bin/bash
# Builds ~/.claude/peon/Peon.app from peon.applescript + an image.
# Uses only built-in macOS tools: osacompile, sips, codesign, lsregister.
# Re-run whenever you change the image. Bundle id / signing / Launch Services
# registration are baked in so notifications keep working after a rebuild.
set -euo pipefail

DIR="$HOME/.claude/peon"
SRC="$DIR/peon.applescript"
APP="$DIR/Peon.app"
BUNDLE_ID="com.claudepeon.notify"

# Accept any peon.* image (png/jpg/jpeg) — sips converts it.
IMG="$(/bin/ls "$DIR"/peon.png "$DIR"/peon.jpg "$DIR"/peon.jpeg 2>/dev/null | /usr/bin/head -1 || true)"
if [[ -z "${IMG:-}" ]]; then
  echo "No image found at $DIR/peon.png (or .jpg) — skipping icon build." >&2
  echo "The notifier still works text-only until you add one and re-run this." >&2
  exit 0
fi
echo "Using image: $IMG"

echo "Compiling applet -> $APP"
rm -rf "$APP"
osacompile -o "$APP" "$SRC"

echo "Building icon (normalize -> sRGB 512 square -> icns)"
# sips direct conversion is more reliable than iconutil, which often fails
# with "Failed to generate ICNS" on certain JPEGs.
sips -z 512 512 "$IMG" --out "$DIR/_icon512.png" >/dev/null
sips -s format icns "$DIR/_icon512.png" --out "$DIR/peon.icns" >/dev/null
rm -f "$DIR/_icon512.png"
cp "$DIR/peon.icns" "$APP/Contents/Resources/applet.icns"

echo "Setting bundle identifier -> $BUNDLE_ID"
# osacompile applets ship WITHOUT a bundle id; without one the notification
# system silently drops every notification. This is the #1 gotcha.
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$APP/Contents/Info.plist" \
  || /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APP/Contents/Info.plist"

echo "Re-signing (ad-hoc) and registering with Launch Services"
codesign --force --deep -s - "$APP"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
"$LSREGISTER" -f "$APP"

# Refresh the notification icon cache.
touch "$APP"
killall usernoted 2>/dev/null || true
echo "Done. Built $APP"
