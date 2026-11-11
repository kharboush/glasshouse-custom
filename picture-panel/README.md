# Picture Panel

A picture settings panel shown as an **overlay window** over whatever is playing, in the Spotlight View look (square, black, subtle outlines). Version 0.1 is **display only**: it shows Picture Mode, OLED Pixel Brightness, Black Level, Auto Dynamic Contrast, Peak Brightness, Color Temperature and TruMotion with sample values that change in the panel but are not sent to the TV.

- Up and Down move between rows; Left and Right (or OK) change the value; Back closes. A Magic Remote pointer can click rows and the arrows.
- The footer shows the last key code received, to check that the remote reaches the overlay.
- It closes itself after two minutes without a key or pointer.

Build with `ares-package --no-minify --outdir dist app` and install with the TV's `dev/install` (or the Homebrew Channel). The window is an overlay because `app/appinfo.json` sets `defaultWindowType: overlay` and `transparent: true`; on the G6 (webOS 11.2.0) an installed app was confirmed to get an `_WEBOS_WINDOW_TYPE_OVERLAY` window.
