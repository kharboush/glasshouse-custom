#!/bin/sh
# webosbrew boot hook, linked as /var/lib/webosbrew/init.d/70-input-badge by install.sh.
# Lays the restyled banner over LG's, in the background so boot is not held up. If this
# package is removed the link leads nowhere and nothing runs.
HERE=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
W=/var/lib/input-badge
mkdir -p "$W"
LOG="$W/restyle.log"
[ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 32768 ] && mv -f "$LOG" "$LOG.old"
( echo "$(date): boot"; sh "$HERE/restyle.sh" ) >>"$LOG" 2>&1 </dev/null &
exit 0
