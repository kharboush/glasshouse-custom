#!/bin/sh
# Run as root by the app's launch page, through the Homebrew Channel's exec service.
# Safe to run any number of times. Prints one JSON line last, which the page reads.
HERE=$(cd "$(dirname "$0")" && pwd)
HOOKDIR=/var/lib/webosbrew/init.d
fail() { printf '{"ok":false,"error":"%s"}\n' "$1"; exit 0; }

for f in SimpleBanner.qml signal-toast.qml.part patch.js splash.js restyle.sh boot.sh; do [ -f "$HERE/$f" ] || fail "the app is missing its files"; done
command -v node >/dev/null 2>&1 || fail "this TV has no node to build the files with"
# ares-package stores plain files as 0666 and the installer owns them as another user; root runs
# them at every boot, so they are made root-owned and not writable by anyone else.
chown -R root:root "$(dirname "$HERE")" 2>/dev/null
chmod -R go-w "$(dirname "$HERE")" 2>/dev/null
chmod +x "$HERE/boot.sh" "$HERE/restyle.sh" "$HERE/uninstall.sh" 2>/dev/null
mkdir -p "$HOOKDIR" || fail "could not create $HOOKDIR"
ln -sf "$HERE/boot.sh" "$HOOKDIR/70-input-badge" || fail "could not add the boot hook"

# A hand-made trial from before this package.
Q=/usr/palm/applications/com.webos.app.inputcommon/qml/UserInterfaceLayer/Containers/MainViewLayer
for f in InputBanner/SimpleBanner.qml InputBanner/InputBanner.qml BannerItems/BannerListView.qml; do
  grep -q " $Q/$f " /proc/mounts && umount "$Q/$f"
done
rm -rf /var/lib/glasshouse-custom/input-banner
# A hand-made trial of the signal toast.
R=/usr/palm/applications/com.webos.app.inputcommon/qml/RootWindow.qml
grep -q " $R " /proc/mounts && umount "$R"
rm -rf /var/lib/input-badge/test
rm -f /var/lib/input-badge/spinner-test.gif
rmdir /var/lib/glasshouse-custom 2>/dev/null

out=$(sh "$HERE/restyle.sh" 2>&1) || fail "$(printf '%s' "$out" | tr '\n"' ' ')"
printf '{"ok":true,"action":"installed"}\n'
