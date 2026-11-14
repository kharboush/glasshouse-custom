#!/bin/sh
# Builds the restyled banner files and mounts them over LG's, then restarts LG's input app so it
# reads them (the input on screen is opened again). Run at boot by boot.sh and at install.
# LG's files are copied from this TV and patched here (patch.js), never shipped in the package.
# Rebuilt only when LG's files or this package's change; nothing is mounted unless all three
# were built, so a failure, or a firmware that changed them, leaves LG's banner in place.
HERE=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
APP=com.webos.app.inputcommon
Q=/usr/palm/applications/$APP/qml/UserInterfaceLayer/Containers/MainViewLayer
FILES="InputBanner/SimpleBanner.qml InputBanner/InputBanner.qml BannerItems/BannerListView.qml"
W=/var/lib/input-badge

# LG's files are only readable with nothing mounted over them.
for f in $FILES; do
  if grep -q " $Q/$f " /proc/mounts; then umount "$Q/$f" || { echo "could not unmount $f"; exit 1; }; fi
  [ -f "$Q/$f" ] || { echo "LG's $f is not there"; exit 1; }
done

mkdir -p "$W" || exit 1
sums=$( { for f in $FILES; do md5sum "$Q/$f"; done; md5sum < "$HERE/SimpleBanner.qml"; md5sum < "$HERE/patch.js"; } | md5sum | cut -d' ' -f1 )
if [ ! -s "$W/files/SimpleBanner.qml" ] || [ "$(cat "$W/stamp" 2>/dev/null)" != "$sums" ]; then
  rm -rf "$W/files.new" "$W/stamp"
  out=$(node "$HERE/patch.js" "$Q" "$HERE" "$W/files.new" 2>&1) || { rm -rf "$W/files.new"; echo "not applied: $out"; exit 1; }
  rm -rf "$W/files" && mv "$W/files.new" "$W/files" && echo "$sums" > "$W/stamp" || { echo "could not put the files in place"; exit 1; }
fi

for f in $FILES; do
  b=$(basename "$f")
  [ -s "$W/files/$b" ] || { echo "$b is missing"; exit 1; }
done
for f in $FILES; do
  mount --bind "$W/files/$(basename "$f")" "$Q/$f" || { echo "could not mount $f"; for g in $FILES; do grep -q " $Q/$g " /proc/mounts && umount "$Q/$g"; done; exit 1; }
done

# The grey launch splash of each HDMI input (shown while it opens) becomes plain black: made once
# from LG's file sizes (splash.js) and laid over both of each input's splash files. Done on its
# own, so a failure here leaves LG's splash and does not affect the banner.
SPLASH_SUMS=$(md5sum < "$HERE/splash.js" | cut -d' ' -f1)
for n in 1 2 3 4; do
  A=/usr/palm/applications/com.webos.app.hdmi$n/assets
  for f in "$A/HDMI-${n}_splash.astc" "$A/HDMI-${n}_splash.png"; do grep -q " $f " /proc/mounts && umount "$f"; done
  [ -f "$A/HDMI-${n}_splash.astc" ] && [ -f "$A/HDMI-${n}_splash.png" ] || { echo "HDMI $n has no splash files"; continue; }
  if [ ! -s "$W/splash/black.astc" ] || [ "$(cat "$W/splash/stamp" 2>/dev/null)" != "$SPLASH_SUMS" ]; then
    rm -rf "$W/splash"
    out=$(node "$HERE/splash.js" "$A/HDMI-${n}_splash.astc" "$A/HDMI-${n}_splash.png" "$W/splash" 2>&1) \
      && echo "$SPLASH_SUMS" > "$W/splash/stamp" || { rm -rf "$W/splash"; echo "splash not made: $out"; break; }
  fi
  mount --bind "$W/splash/black.astc" "$A/HDMI-${n}_splash.astc" && mount --bind "$W/splash/black.png" "$A/HDMI-${n}_splash.png" \
    || echo "could not mount the splash for HDMI $n"
done

# LG's input app keeps its pages loaded, so it is restarted, and the input on screen reopened.
P=$(pidof $APP)
if [ -n "$P" ]; then
  FG=$(luna-send -n 1 -w 8000 luna://com.webos.applicationManager/getForegroundAppInfo '{}' 2>/dev/null | grep -o '"appId":"[^"]*"' | cut -d'"' -f4)
  kill $P
  sleep 2
  case "$FG" in com.webos.app.hdmi*|com.webos.app.livetv) luna-send -n 1 -w 8000 luna://com.webos.applicationManager/launch "{\"id\":\"$FG\"}" >/dev/null 2>&1 ;; esac
fi
exit 0
