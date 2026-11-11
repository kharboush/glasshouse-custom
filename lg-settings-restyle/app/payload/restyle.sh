#!/bin/sh
# Builds the restyled copy of LG's Settings app and mounts it over the original.
#   restyle.sh            at boot: build if needed, mount
#   restyle.sh --reopen   at install: also close Settings first and open it again
# The copy is LG's own app (copied from this TV, never shipped in the package)
# plus custom.css appended to its stylesheet. Rebuilt only when LG's files or
# custom.css change. Nothing is mounted unless the copy was built whole, so a
# failure leaves LG's original in place.
HERE=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
APP=com.palm.app.settings
SRC=/usr/palm/applications/$APP
W=/var/lib/lg-settings-restyle
mounted() { mount | grep -q " $SRC "; }
luna() { luna-send -n 1 -w 8000 "$1" "$2" >/dev/null 2>&1; }

[ "$1" = "--reopen" ] && { luna luna://com.webos.applicationManager/closeByAppId "{\"id\":\"$APP\"}"; sleep 1; }

# LG's files are only readable with nothing mounted over them.
if mounted; then umount "$SRC" || { echo "could not unmount $SRC (is Settings open?)"; exit 1; }; fi
[ -f "$SRC/main.css" ] || { echo "LG's Settings app is not at $SRC"; exit 1; }

mkdir -p "$W" || exit 1
sums=$( { md5sum "$SRC/main.css" "$SRC/main.js" "$SRC/index.html"; md5sum < "$HERE/custom.css"; } | md5sum | cut -d' ' -f1 )
if [ ! -s "$W/$APP/main.css" ] || [ "$(cat "$W/stamp" 2>/dev/null)" != "$sums" ]; then
  rm -rf "$W/$APP.new"
  cp -a "$SRC" "$W/$APP.new" \
    && cat "$SRC/main.css" "$HERE/custom.css" > "$W/$APP.new/main.css.tmp" \
    && mv -f "$W/$APP.new/main.css.tmp" "$W/$APP.new/main.css" \
    || { rm -rf "$W/$APP.new"; echo "could not build the restyled copy"; exit 1; }
  rm -rf "$W/$APP" && mv "$W/$APP.new" "$W/$APP" && echo "$sums" > "$W/stamp" \
    || { echo "could not put the restyled copy in place"; exit 1; }
fi
[ -s "$W/$APP/main.css" ] || { echo "restyled copy is empty"; exit 1; }
mount --bind "$W/$APP" "$SRC" || { echo "could not mount the restyled copy"; exit 1; }

[ "$1" = "--reopen" ] && luna luna://com.webos.applicationManager/launch "{\"id\":\"$APP\"}"
exit 0
