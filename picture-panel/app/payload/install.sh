#!/bin/sh
# Puts the Picture Panel's page on Glasshouse's server, or brings it up to date.
# Run as root by the launcher, through the Homebrew Channel's exec service, when
# the page is missing or is not this app's version. Safe to run any number of times.
# Prints one JSON line last, which the launcher reads.
HERE=$(cd "$(dirname "$0")" && pwd)
D=/var/lib/tvweb
A=$D/assets
fail() { printf '{"ok":false,"error":"%s"}\n' "$1"; exit 0; }

[ -x "$D/tvwebctl" ] && [ -d "$A" ] || fail "Glasshouse is not installed on this TV"
[ -f "$HERE/picture-panel.html" ] || fail "the app is missing its page"
# ares-package stores plain files as 0666 and as another user; this runs as root.
chown -R root:root "$(dirname "$HERE")" 2>/dev/null
chmod -R go-w "$(dirname "$HERE")" 2>/dev/null

if [ -f "$A/picture-panel.html" ] && cmp -s "$HERE/picture-panel.html" "$A/picture-panel.html"; then
  printf '{"ok":true,"action":"current"}\n'
  exit 0
fi
had=0; [ -f "$A/picture-panel.html" ] && had=1
cp "$HERE/picture-panel.html" "$A/picture-panel.html.new" && chmod 644 "$A/picture-panel.html.new" \
  && mv -f "$A/picture-panel.html.new" "$A/picture-panel.html" || fail "could not copy the page"
# Glasshouse keeps every asset it has served in memory, so an older copy of the
# page is only replaced by restarting it. A first install needs no restart.
[ "$had" = 1 ] && "$D/tvwebctl" restart >/dev/null 2>&1
printf '{"ok":true,"action":"%s"}\n' "$([ "$had" = 1 ] && echo updated || echo installed)"
