#!/bin/sh
# webosbrew boot hook, linked as /var/lib/webosbrew/init.d/70-lg-settings-restyle by
# install.sh. Mounts the restyled Settings over LG's, in the background so boot is
# not held up. If this package is removed the link leads nowhere and nothing runs.
HERE=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
W=/var/lib/lg-settings-restyle
mkdir -p "$W"
LOG="$W/restyle.log"
[ "$(wc -c < "$LOG" 2>/dev/null || echo 0)" -gt 32768 ] && mv -f "$LOG" "$LOG.old"
( echo "$(date): boot"; sh "$HERE/restyle.sh" ) >>"$LOG" 2>&1 </dev/null &
exit 0
