#!/usr/bin/env bash
# Verified working this session (proved out in qte77/__2026-09-01-yappy-explore
# against a real notarized DMG on macos-14). This is the reference
# implementation the Windows/Linux scripts mirror structurally.
set -euo pipefail

: "${DOWNLOAD_URL:?required}"
INSTALL_TYPE="${INSTALL_TYPE:-dmg}"
LAUNCH_TARGET="${LAUNCH_TARGET:-}"
SETTLE_SECONDS="${SETTLE_SECONDS:-5}"
INTERACT_SCRIPT="${INTERACT_SCRIPT:-}"

case "$INSTALL_TYPE" in
  dmg)
    curl -fsSL -o installer.dmg "$DOWNLOAD_URL"
    hdiutil attach installer.dmg -nobrowse -mountpoint /Volumes/GuiKitMount
    app_path=$(find /Volumes/GuiKitMount -maxdepth 1 -name "*.app" -print -quit)
    if [ -z "$app_path" ]; then
      echo "No .app bundle found at the top level of the mounted DMG" >&2
      hdiutil detach /Volumes/GuiKitMount || true
      exit 1
    fi
    echo "Found app bundle: $app_path"
    cp -R "$app_path" /Applications/
    app_name=$(basename "$app_path")
    hdiutil detach /Volumes/GuiKitMount
    # Launch by full path, never by Launch-Services name lookup -- a
    # freshly-cp'd app is not registered there yet and `open -a NAME` fails.
    launch_path="/Applications/$app_name"
    ;;
  zip)
    curl -fsSL -o installer.zip "$DOWNLOAD_URL"
    unzip -q installer.zip -d /Applications/
    [ -n "$LAUNCH_TARGET" ] || { echo "launch-target is required for install-type=zip" >&2; exit 1; }
    launch_path="/Applications/$LAUNCH_TARGET"
    ;;
  pkg)
    curl -fsSL -o installer.pkg "$DOWNLOAD_URL"
    sudo installer -pkg installer.pkg -target /
    [ -n "$LAUNCH_TARGET" ] || { echo "launch-target is required for install-type=pkg" >&2; exit 1; }
    launch_path="/Applications/$LAUNCH_TARGET"
    ;;
  *)
    echo "Unknown install-type: $INSTALL_TYPE (expected dmg|zip|pkg)" >&2
    exit 1
    ;;
esac

echo "Launching: $launch_path"
open "$launch_path"
sleep "$SETTLE_SECONDS"
screencapture -x probe-before.png

if [ -n "$INTERACT_SCRIPT" ]; then
  set +e
  osascript <<APPLESCRIPT_EOF
$INTERACT_SCRIPT
APPLESCRIPT_EOF
  echo "Interact script exit status: $?"
  set -e
fi

sleep 2
screencapture -x probe-after.png
