# HDMI Sources

The connected HDMI sources, shown as an **overlay window** over whatever is playing, drawn the way Glasshouse Home draws its input tiles, in the Spotlight View form (384×216 square tiles, 16px apart, the subtle 1px outline, black at 95%).

Needs [Glasshouse](https://github.com/rorygallagher2024/glasshouse) running on the TV, and the Homebrew Channel.

## What it shows

One tile per connected source, as Home's input tile:

- the device icon, chosen from its name by Glasshouse's own `devicons.js` (a streamer, a soundbar, a PC, a console...);
- the name, and below it `HDMI 3` (or `HDMI 3, through <device>` for a device behind another);
- at the bottom, **Currently active** in amber with its dot for the input on screen, otherwise **Connected**, and the CEC address on the right (`CEC 1.0.0.0`), where the device has one.

The selected tile has the 2px white outline and `#141310` fill, the others the subtle outline. Unselected tiles are dimmed, but only their contents, so the outline keeps its strength.

**Which sources count as connected.** The G6 reports all four ports as plugged in, so that alone cannot tell them apart. A source is shown when something answers on its port: a CEC device, a live signal, or it is the input on screen. A device with no CEC that is switched off is therefore left out until it has a signal. With nothing connected the app says so.

## Using it

- Left and Right move between the sources and wrap; OK opens the selected one (through `POST /api/home/open`, the call Home makes) and the panel closes; Back closes without changing anything.
- A Magic Remote pointer selects a tile by moving onto it, and opens it with a click.
- It opens with the active source selected, re-reads the TV every 5 seconds, and closes itself after 60 seconds without a key or pointer.

## Install

Install the package (`release/io.github.kharboush.hdmi-sources_0.1.1_all.ipk`, or the manifest in the same folder, with the Homebrew Channel, or the TV's `dev/install`). That is all: the app puts what it needs on Glasshouse's server itself the first time it is opened, and again if that is ever missing or out of date.

Open **HDMI Sources** from the app list, or assign it to a remote button in Glasshouse's remote keys. To open it from a command:

```sh
luna-send -n 1 luna://com.webos.applicationManager/launch '{"id":"io.github.kharboush.hdmi-sources"}'
```

## How it works

The same two parts as the [Picture Panel](../picture-panel/README.md):

| Part | Where | What |
|---|---|---|
| `app/payload/hdmi-sources.html` | Copied to `/var/lib/tvweb/assets/hdmi-sources.html` | The tiles. Reads `GET /api/home/catalogue` (the inputs), `/api/home/now` (what was last on) and `/api/home/signal?port=N`, loads `/assets/devicons.js` for the icons, and opens an input with `POST /api/home/open {kind:'dev', id}`. Glasshouse only accepts that from pages it serves. |
| `app/index.html` | The installed app, with an **overlay** window (`defaultWindowType: overlay`, `transparent: true`) | The launcher. Checks that Glasshouse is up and that the page there is this app's version (a marker in the page); if not, asks the Homebrew Channel's exec service to run `payload/install.sh` as root, which copies the page in (restarting Glasshouse, which keeps served assets in memory, only when replacing an older copy), and waits up to a minute for it to come back. Then opens the page, keeping the overlay window. |

`payload/uninstall.sh` removes the page; uninstalling the app does not run it, and the page is a few KB.

## Building

```sh
./hdmi-sources/build-ipk.py      # needs ares-package (npm i -g @webos-tools/cli)
```

writes `dist/<id>_<version>_all.ipk` and its manifest (also kept in `release/`). The version comes from `app/appinfo.json` and is filled in for `@VERSION@` in the launcher and the page.

## Tested

On the TV (G6, webOS 11.2.0): a clean first open (the app put its page on Glasshouse and opened as an overlay), an update from 0.1.0 to 0.1.1 (the app replaced the page and reopened by itself), the bundled page identical to the one on Glasshouse, and the tiles' data and layout in a browser. **Not tried:** pressing OK to switch an input, the remote's keys on the TV, a Glasshouse update with the app installed, and opening it from a remapped remote button.
