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
sudo apt-get install -y -qq xvfb scrot xdotool x11-utils imagemagick >/dev/null

Xvfb :99 -screen 0 1920x1080x24 &
XVFB_PID=$!
export DISPLAY=:99

cleanup() { kill "$XVFB_PID" 2>/dev/null || true; }
trap cleanup EXIT

# A backgrounded Xvfb is not necessarily listening on :99 when the shell
# returns -- a fixed sleep is either flaky (too short, races real hardware
# variance) or wasteful (too long, padding every run for a race that usually
# resolves in well under a second). Poll instead.
for _ in $(seq 1 20); do
  xdpyinfo >/dev/null 2>&1 && break
  sleep 0.5
done
xdpyinfo >/dev/null 2>&1 || { echo "Xvfb never came up on :99" >&2; exit 1; }

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

# A window that maps but paints nothing (a failed GL context, a crash after
# the initial frame, a silently-broken theme) looks identical to a working
# app in a pass/fail bit -- unless something checks what actually rendered.
# Non-fatal by design: this is a probe, and a genuinely blank first frame on
# some apps (a splash screen fading in) is real information worth an
# artifact, not a reason to abort the whole run.
colors=$(identify -format '%k' probe-before.png 2>/dev/null || echo 0)
echo "probe-before.png: $colors unique colours"
[ "$colors" -ge 4 ] || echo "::warning::probe-before.png looks blank ($colors unique colours) -- the app may not have rendered"

if [ -n "$INTERACT_SCRIPT" ]; then
  set +e
  eval "$INTERACT_SCRIPT"
  echo "Interact script exit status: $?"
  set -e
fi

sleep 2
scrot probe-after.png
colors=$(identify -format '%k' probe-after.png 2>/dev/null || echo 0)
echo "probe-after.png: $colors unique colours"
[ "$colors" -ge 4 ] || echo "::warning::probe-after.png looks blank ($colors unique colours) -- the app may not have rendered"
