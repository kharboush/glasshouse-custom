#!/bin/sh
# Puts LG's own Settings back and removes the boot hook and the restyled copy.
APP=com.palm.app.settings
SRC=/usr/palm/applications/$APP
luna-send -n 1 -w 8000 luna://com.webos.applicationManager/closeByAppId "{\"id\":\"$APP\"}" >/dev/null 2>&1
sleep 1
rm -f /var/lib/webosbrew/init.d/70-lg-settings-restyle
if mount | grep -q " $SRC "; then
  umount "$SRC" || { printf '{"ok":false,"error":"could not unmount; restart the TV"}\n'; exit 0; }
fi
rm -rf /var/lib/lg-settings-restyle
printf '{"ok":true,"action":"removed"}\n'
