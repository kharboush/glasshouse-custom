# HDMI Sources

A switcher for the connected HDMI sources, shown as an **overlay window** over whatever is playing, in the Spotlight View look: small square tiles (320×112, 16px apart), the subtle 1px outline, black at 95%, and Glasshouse Home's input icons.

Needs [Glasshouse](https://github.com/rorygallagher2024/glasshouse) running on the TV, and the Homebrew Channel.

## What it shows

- **Home** first: a tile with a house icon and "Home screen", which opens the TV's Home screen (Glasshouse Home).
- Then **one tile per connected source**: the device icon, chosen from its name by Glasshouse's own `devicons.js` (a streamer, a soundbar, a PC, a console...), the name, and below it `HDMI 3` (or `HDMI 3, through <device>` for a device behind another).
- The source on screen has a single **amber dot**, centred at the right edge of its tile. There is no status text and no CEC address.

The selected tile has the 2px white outline and `#141310` fill, the others the subtle outline. Unselected tiles are dimmed, but only their contents, so the outline keeps its strength.

**Which sources count as connected.** The G6 reports all four ports as plugged in, so that alone cannot tell them apart. A source is shown when something answers on its port: a CEC device, a live signal, or it is the input on screen. A device with no CEC that is switched off is therefore left out until it has a signal.

## Using it

- Left and Right move between the tiles and wrap; OK opens the selected one and the panel closes; Back closes without changing anything.
- A Magic Remote pointer selects a tile by moving onto it, and opens it with a click.
- It opens with the active source selected (Home if none is), re-reads the TV every 5 seconds, and closes itself after 60 seconds without a key or pointer.

## Install

Install the package (`release/io.github.kharboush.hdmi-sources_0.2.0_all.ipk`, or the manifest in the same folder, with the Homebrew Channel, or the TV's `dev/install`). That is all: the app puts what it needs on Glasshouse's server itself the first time it is opened, and again if that is ever missing or out of date.

Open **HDMI Sources** from the app list, or assign it to a remote button in Glasshouse's remote keys. To open it from a command:

```sh
luna-send -n 1 luna://com.webos.applicationManager/launch '{"id":"io.github.kharboush.hdmi-sources"}'
```

## How it works

The same two parts as the [Picture Panel](../picture-panel/README.md):

| Part | Where | What |
|---|---|---|
| `app/payload/hdmi-sources.html` | Copied to `/var/lib/tvweb/assets/hdmi-sources.html` | The tiles. Reads `GET /api/home/catalogue` (the inputs), `/api/home/now` (what is on screen) and `/api/home/signal?port=N`, loads `/assets/devicons.js` for the icons, opens an input with `POST /api/home/open {kind:'dev', id}` (the call Home makes) and Home with `POST /api/control {action:'launchApp', value:'com.webos.app.home'}`. Glasshouse only accepts those from pages it serves. |
| `app/index.html` | The installed app, with an **overlay** window (`defaultWindowType: overlay`, `transparent: true`) | The launcher. Checks that Glasshouse is up and that the page there is this app's version (a marker in the page); if not, asks the Homebrew Channel's exec service to run `payload/install.sh` as root, which copies the page in (restarting Glasshouse, which keeps served assets in memory, only when replacing an older copy), and waits up to a minute for it to come back. Then opens the page, keeping the overlay window. |

`payload/uninstall.sh` removes the page; uninstalling the app does not run it, and the page is a few KB.

## Building

```sh
./hdmi-sources/build-ipk.py      # needs ares-package (npm i -g @webos-tools/cli)
```

writes `dist/<id>_<version>_all.ipk` and its manifest (also kept in `release/`, where older versions stay beside the current one). The version comes from `app/appinfo.json` and is filled in for `@VERSION@` in the launcher and the page.

## Tested

On the TV (G6, webOS 11.2.0): a clean first open (the app put its page on Glasshouse and opened as an overlay), updates from one version to the next (the app replaced the page and reopened by itself, most recently 0.1.1 to 0.2.0), the bundled page identical to the one on Glasshouse, and the tiles' data and layout in a browser. **Not tried:** pressing OK to switch an input or to open Home, the remote's keys on the TV, a Glasshouse update with the app installed, and opening it from a remapped remote button.
