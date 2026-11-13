# Input Badge

A Homebrew Channel app that restyles the banner LG shows when you switch to an HDMI input (the input's name, in a dark shape on the left). It becomes an [HDMI Sources](../hdmi-sources/) tile, 32px from the side:

- 320×112, square, black at 90%, a 1px outline at 20% white (2px white on `#141310` when the banner is selected with OK);
- the input's name at 26px over its port ("HDMI 1") at 20px in grey, with the same space at the sides as above and below the text;
- where LG's own banner position setting puts it, left or right, 32px from that side (LG put it against the edge). At the top it is 32px down; LG's "bottom" is really the middle of the screen, and there the tile is centred on where LG's taller banner was.

The size, colours, wording and timing of everything else are LG's. The name is the TV's own label for the input, so renaming an input in LG's input list changes it. The channel banner for the TV tuner, the detail view (OK, then the info button) and Live Pick are left as LG has them.

Built for a rooted LG G6 on webOS 11.2.0 with frozen firmware.

## What it does

The banner is drawn by LG's input app (`com.webos.app.inputcommon`) from QML files on the read-only system partition, so nothing is edited in place. At every start a boot hook:

1. copies LG's `InputBanner.qml` and `BannerListView.qml` from the TV and changes them with exact replacements (`app/payload/patch.js`, run with the TV's own `node`): the banner's height, its 32px from the side and from the top, and a black box in place of LG's two background pictures;
2. takes this package's own `SimpleBanner.qml`, the tile's contents, which stands in for LG's;
3. bind-mounts the three files over LG's, and restarts LG's input app so it reads them, reopening the input on screen.

The files are rebuilt only when LG's files or this package's change. Every replacement has to match exactly once, and LG's `SimpleBanner.qml` has to still have what this package's stands in for, or nothing is mounted: a firmware that changes these files keeps LG's own banner. **LG's files are never in this package**; the patched copies are made on the TV, in `/var/lib/input-badge/files/`.

## Install

```sh
./input-badge/build-ipk.py      # needs ares-package (npm i -g @webos-tools/cli)
```

writes `dist/io.github.kharboush.input-badge_1.0.2_all.ipk` and its manifest (both also in `release/`). Install it with the Homebrew Channel or `dev/install`, then open **Input Badge** once: its page has the Homebrew Channel run `payload/install.sh` as root, which links the boot hook and applies the banner straight away. From then on the hook does it at every start; it logs to `/var/lib/input-badge/restyle.log`.

The page also has a **Remove the restyle** button (`payload/uninstall.sh`): it unmounts the files, removes the hook and deletes `/var/lib/input-badge`, which brings back LG's own banner. Uninstalling the app from the Homebrew Channel leaves the hook pointing at nothing, so nothing runs after the next restart.

## Files

| File | Purpose |
|---|---|
| `app/appinfo.json`, `app/index.html`, icons | The launch page: installs, and offers removal |
| `app/payload/SimpleBanner.qml` | The tile: this package's own, in place of LG's file of that name |
| `app/payload/patch.js` | Builds the three files from LG's (exact replacements, all or nothing) |
| `app/payload/restyle.sh` | Builds if needed, mounts, restarts LG's input app |
| `app/payload/boot.sh` | The boot hook, linked as `/var/lib/webosbrew/init.d/70-input-badge` |
| `app/payload/install.sh`, `uninstall.sh` | Run as root by the page |
| `build-ipk.py` | Builds the `.ipk` and manifest with ares-package |

## Tested

On the TV (G6, webOS 11.2.0): the look and place, switching between HDMI inputs, installing the package and running `install.sh`, and a simulated boot (unmount, run the hook, the three files mounted again). **Not tried:** a real restart of the TV, the banner when selected with OK, the input icon (the TV's QML did not draw the SVG icons HDMI Sources uses, so the tile has none), and the launch page's buttons pressed on the TV.
