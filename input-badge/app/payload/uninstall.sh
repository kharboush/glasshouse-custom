#!/bin/sh
# Puts LG's own banner back and removes the boot hook and the built files.
APP=com.webos.app.inputcommon
Q=/usr/palm/applications/$APP/qml
rm -f /var/lib/webosbrew/init.d/70-input-badge
for f in UserInterfaceLayer/Containers/MainViewLayer/InputBanner/SimpleBanner.qml UserInterfaceLayer/Containers/MainViewLayer/InputBanner/InputBanner.qml UserInterfaceLayer/Containers/MainViewLayer/BannerItems/BannerListView.qml RootWindow.qml; do
  if grep -q " $Q/$f " /proc/mounts; then
    umount "$Q/$f" || { printf '{"ok":false,"error":"could not unmount; restart the TV"}\n'; exit 0; }
  fi
done
for n in 1 2 3 4; do
  for f in /usr/palm/applications/com.webos.app.hdmi$n/assets/HDMI-${n}_splash.astc /usr/palm/applications/com.webos.app.hdmi$n/assets/HDMI-${n}_splash.png; do
    grep -q " $f " /proc/mounts && umount "$f"
  done
done
P=$(pidof $APP)
if [ -n "$P" ]; then
  FG=$(luna-send -n 1 -w 8000 luna://com.webos.applicationManager/getForegroundAppInfo '{}' 2>/dev/null | grep -o '"appId":"[^"]*"' | cut -d'"' -f4)
  kill $P
  sleep 2
  case "$FG" in com.webos.app.hdmi*|com.webos.app.livetv) luna-send -n 1 -w 8000 luna://com.webos.applicationManager/launch "{\"id\":\"$FG\"}" >/dev/null 2>&1 ;; esac
fi
G=/usr/lib/weston/images/Spinner_large.gif
grep -q " $G " /proc/mounts && umount "$G"
rm -rf /var/lib/input-badge
# LG's own toasts back on.
luna-send -n 1 -w 8000 luna://com.webos.notification/enable '{}' >/dev/null 2>&1
printf '{"ok":true,"action":"removed"}\n'
