# Input Badge

A Homebrew Channel app that restyles the banner LG shows when you switch to an HDMI input (the input's name, in a dark shape on the left). It becomes an [HDMI Sources](../hdmi-sources/) tile, 32px from the side:

- 320×112, square, black at 90%, a 1px outline at 20% white (2px white on `#141310` when the banner is selected with OK);
- the input's name at 26px over its port ("HDMI 1") at 20px in grey, with the same space at the sides as above and below the text;
- where LG's own banner position setting puts it, left or right, 32px from that side (LG put it against the edge). At the top it is 32px down; LG's "bottom" is really the middle of the screen, and there the tile is centred on where LG's taller banner was.

It also shows its own **signal toast** in place of LG's Dolby and HDR ones: a box in the Picture Panel's signal style (small grey labels over values), top right, 32px from the edges, black at 90% with the 1px outline. It comes a second after the picture's dynamic range changes, or Dolby Atmos starts, and stays 5 seconds. Two rows of two: Dynamic range and Audio, then Resolution and Refresh rate ("120 Hz VRR" when VRR is on). Everything in it is read from the TV itself, not from Glasshouse: the picture from the video output service, the sound from the audio service (Audio is left out when there is none, or a format it does not know). It shows on HDMI inputs only: in the TV's own apps, LG's input app is not running. It runs only in the input app on screen; LG keeps one preloaded for each input, and the ones in the background watch nothing.

LG's toasts are switched off at every start so the signal toast replaces theirs. The notification service has no way to switch off only some, so **every ordinary toast is hidden** (alerts still show); removing the app switches them back on.

It also turns the grey screen LG shows while an HDMI input opens (a flat grey with LG's HDMI plug icon) plain black, on all four inputs.

The size, colours, wording and timing of everything else are LG's. The name is the TV's own label for the input, so renaming an input in LG's input list changes it. The channel banner for the TV tuner, the detail view (OK, then the info button) and Live Pick are left as LG has them.

Built for a rooted LG G6 on webOS 11.2.0 with frozen firmware.

## What it does

The banner is drawn by LG's input app (`com.webos.app.inputcommon`) from QML files on the read-only system partition, so nothing is edited in place. At every start a boot hook:

1. copies LG's `InputBanner.qml` and `BannerListView.qml` from the TV and changes them with exact replacements (`app/payload/patch.js`, run with the TV's own `node`): the banner's height, its 32px from the side and from the top, and a black box in place of LG's two background pictures;
2. takes this package's own `SimpleBanner.qml`, the tile's contents, which stands in for LG's;
3. bind-mounts the three files over LG's, and restarts LG's input app so it reads them, reopening the input on screen;
4. adds the signal toast inside LG's `RootWindow.qml` (the input app's root): this package's own `app/payload/signal-toast.qml.part`, put in just before its last brace, with the import its watchers need;
5. switches LG's toasts off (`com.webos.notification/disable`) once the notification service answers;
6. makes a plain black splash the size of LG's (`app/payload/splash.js`: a compressed `.astc` texture of solid black blocks under LG's own header, and a black `.png`) and bind-mounts it over each HDMI input's two splash files (`com.webos.app.hdmiN/assets/HDMI-N_splash.astc` and `.png`). This is done on its own: if it fails, the inputs keep LG's grey splash and the banner is not affected.

The files are rebuilt only when LG's files or this package's change. Every replacement has to match exactly once, and LG's `SimpleBanner.qml` and `RootWindow.qml` have to still have what this package's relies on, or nothing is mounted: a firmware that changes these files keeps LG's own banner. **LG's files are never in this package**; the patched copies are made on the TV, in `/var/lib/input-badge/files/`.

## Install

```sh
./input-badge/build-ipk.py      # needs ares-package (npm i -g @webos-tools/cli)
```

writes `dist/io.github.kharboush.input-badge_1.2.3_all.ipk` and its manifest (both also in `release/`). Install it with the Homebrew Channel or `dev/install`, then open **Input Badge** once: its page has the Homebrew Channel run `payload/install.sh` as root, which links the boot hook and applies the banner straight away. From then on the hook does it at every start; it logs to `/var/lib/input-badge/restyle.log`.

The page also has a **Remove the restyle** button (`payload/uninstall.sh`): it unmounts the files, removes the hook, deletes `/var/lib/input-badge` and switches LG's toasts back on, which brings back LG's own banner, splash and toasts. Uninstalling the app from the Homebrew Channel leaves the hook pointing at nothing, so nothing runs after the next restart.

## Files

| File | Purpose |
|---|---|
| `app/appinfo.json`, `app/index.html`, icons | The launch page: installs, and offers removal |
| `app/payload/SimpleBanner.qml` | The tile: this package's own, in place of LG's file of that name |
| `app/payload/signal-toast.qml.part` | The signal toast: this package's own, added inside LG's `RootWindow.qml` |
| `app/payload/patch.js` | Builds the three files from LG's (exact replacements, all or nothing) |
| `app/payload/splash.js` | Makes the black launch splash in LG's sizes |
| `app/payload/restyle.sh` | Builds if needed, mounts, restarts LG's input app |
| `app/payload/boot.sh` | The boot hook, linked as `/var/lib/webosbrew/init.d/70-input-badge` |
| `app/payload/install.sh`, `uninstall.sh` | Run as root by the page |
| `build-ipk.py` | Builds the `.ipk` and manifest with ares-package |

## Tested

On the TV (G6, webOS 11.2.0): the look and place, the black launch splash, the signal toast on dynamic range and Atmos changes, switching between HDMI inputs, installing the package and running `install.sh`, and a simulated boot (unmount, run the hook, the three files mounted again). The TV's log shows the boot hook running by itself after a restart. **Not tried:** the banner when selected with OK, the input icon (the TV's QML did not draw the SVG icons HDMI Sources uses, so the tile has none), and the launch page's buttons pressed on the TV.
