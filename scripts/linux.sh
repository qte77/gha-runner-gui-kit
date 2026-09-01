#!/usr/bin/env bash
# UNVERIFIED -- designed to mirror macos.sh's shape, not tested against a
# real target this session. There is no confirmed Linux consumer yet.
# Treat this as a starting point, not a proven path -- run it against a
# real app and fix what breaks before depending on it.
set -euo pipefail

: "${DOWNLOAD_URL:?required}"
INSTALL_TYPE="${INSTALL_TYPE:-appimage}"
LAUNCH_TARGET="${LAUNCH_TARGET:-}"
SETTLE_SECONDS="${SETTLE_SECONDS:-5}"
INTERACT_SCRIPT="${INTERACT_SCRIPT:-}"

sudo apt-get update -qq
sudo apt-get install -y -qq xvfb scrot xdotool >/dev/null

Xvfb :99 -screen 0 1920x1080x24 &
XVFB_PID=$!
export DISPLAY=:99
sleep 2

cleanup() { kill "$XVFB_PID" 2>/dev/null || true; }
trap cleanup EXIT

case "$INSTALL_TYPE" in
  appimage)
    curl -fsSL -o app.AppImage "$DOWNLOAD_URL"
    chmod +x app.AppImage
    launch_cmd="./app.AppImage"
    ;;
  deb)
    curl -fsSL -o app.deb "$DOWNLOAD_URL"
    sudo apt-get install -y -qq ./app.deb
    [ -n "$LAUNCH_TARGET" ] || { echo "launch-target is required for install-type=deb" >&2; exit 1; }
    launch_cmd="$LAUNCH_TARGET"
    ;;
  tar)
    curl -fsSL -o app.tar.gz "$DOWNLOAD_URL"
    mkdir -p app_extracted
    tar -xzf app.tar.gz -C app_extracted
    [ -n "$LAUNCH_TARGET" ] || { echo "launch-target is required for install-type=tar" >&2; exit 1; }
    launch_cmd="app_extracted/$LAUNCH_TARGET"
    ;;
  *)
    echo "Unknown install-type: $INSTALL_TYPE (expected appimage|deb|tar)" >&2
    exit 1
    ;;
esac

echo "Launching: $launch_cmd"
$launch_cmd &
sleep "$SETTLE_SECONDS"
scrot probe-before.png

if [ -n "$INTERACT_SCRIPT" ]; then
  set +e
  eval "$INTERACT_SCRIPT"
  echo "Interact script exit status: $?"
  set -e
fi

sleep 2
scrot probe-after.png
