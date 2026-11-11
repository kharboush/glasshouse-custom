#!/bin/sh
# Installs or updates Spotlight View on the TV over SSH (asks for the root
# password once). Glasshouse itself is not modified from here; the service on
# the TV adds the one line Home needs, now and after every Glasshouse update.
#
# Usage: ./customizations/install-tv.sh [tv-address]
set -eu

TV=${1:-192.168.0.42}
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

cd "$HERE/g6-spotlight"
tar -cf - service.js settings.html 60-g6-spotlight overlay fonts | ssh "root@$TV" '
set -e
D=/var/lib/g6-spotlight
HOOK=/var/lib/webosbrew/init.d/60-g6-spotlight
mkdir -p "$D"
tar -xf - -C "$D"
# First install: on, with the TV system font. Later installs keep the settings.
[ -f "$D/settings.json" ] || echo "{\"on\":true,\"font\":\"system\"}" > "$D/settings.json"
cp "$D/60-g6-spotlight" "$HOOK"
chmod 755 "$HOOK"
# Stop the running copy (its restart loop first), then start the new one.
[ -f "$D/loop.pid" ] && kill "$(cat "$D/loop.pid")" 2>/dev/null || true
pkill -f "node /var/lib/g6-spotlight/service[.]js" 2>/dev/null || true
rm -f "$D/loop.pid"
# Left by an earlier version of the overlay; settings now come from the service.
rm -f /var/lib/tvweb/assets/g6/settings.json
sleep 1
nohup "$HOOK" >/dev/null 2>&1
echo "Spotlight View installed. Settings: http://'"$TV"':8090/"
'
