#!/bin/sh
# Run as root by the app's launch page, through the Homebrew Channel's exec service.
# Safe to run any number of times. Prints one JSON line last, which the page reads.
HERE=$(cd "$(dirname "$0")" && pwd)
HOOKDIR=/var/lib/webosbrew/init.d
fail() { printf '{"ok":false,"error":"%s"}\n' "$1"; exit 0; }

[ -f "$HERE/custom.css" ] && [ -f "$HERE/restyle.sh" ] && [ -f "$HERE/boot.sh" ] || fail "the app is missing its files"
# ares-package stores plain files as 0666 and the installer owns them as another user; root runs
# them at every boot, so they are made root-owned and not writable by anyone else.
chown -R root:root "$(dirname "$HERE")" 2>/dev/null
chmod -R go-w "$(dirname "$HERE")" 2>/dev/null
chmod +x "$HERE/boot.sh" "$HERE/restyle.sh" "$HERE/uninstall.sh" 2>/dev/null
mkdir -p "$HOOKDIR" || fail "could not create $HOOKDIR"
ln -sf "$HERE/boot.sh" "$HOOKDIR/70-lg-settings-restyle" || fail "could not add the boot hook"

out=$(sh "$HERE/restyle.sh" --reopen 2>&1) || fail "$(printf '%s' "$out" | tr '\n"' ' ')"
# A hand-made copy from before this package; the mount has moved off it.
[ -d /var/lib/lg-settings-overlay ] && rm -rf /var/lib/lg-settings-overlay
printf '{"ok":true,"action":"installed"}\n'
