#!/bin/sh
# Removes the Picture Panel's page from Glasshouse's server. Uninstalling the app
# from the Homebrew Channel does not run this; the page is a few KB and harmless.
rm -f /var/lib/tvweb/assets/picture-panel.html
[ -x /var/lib/tvweb/tvwebctl ] && /var/lib/tvweb/tvwebctl restart >/dev/null 2>&1
printf '{"ok":true,"action":"removed"}\n'
