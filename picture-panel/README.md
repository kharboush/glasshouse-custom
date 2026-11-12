# Picture Panel

A picture settings panel shown as an **overlay window** over whatever is playing, in the Spotlight View look (square, black, subtle outlines). It reads and sets the TV's real values for Picture Mode, OLED Pixel Brightness, Black Level, Auto Dynamic Contrast, Peak Brightness, Color Temperature and TruMotion.

- Up and Down move between rows; Left and Right (or OK) change the value; Back closes. A Magic Remote pointer can click rows and the arrows. There is no on-screen help text.
- Settings the TV has switched off for the current picture mode or input (TruMotion, Peak Brightness and Auto Dynamic Contrast in Game mode, for example) are shown greyed and are not changed; focusing one says "Not available in <mode> mode." This is read from the `active` flag the TV gives each setting, so a change is never sent only to be refused.
- The last row, **All Settings**, opens LG's full Settings app (`com.palm.app.settings`) and closes the panel.
- The choices are the ones the TV itself offers (this G6 has no "Clear" TruMotion, for example). Colour temperature runs from Warm 50 to Cool 50. Black Level shows "Not on this input" unless the input on screen is an HDMI input, because LG keeps it per input and, for apps and the tuner, per colour system.
- Settings are per picture mode and per input, so the panel shows and changes those of the input on screen. Changing the picture mode re-reads everything.
- It closes itself after two minutes without a key or pointer.

Needs [Glasshouse](https://github.com/rorygallagher2024/glasshouse) running on the TV, and the Homebrew Channel.

## Install and use

Install the package (`release/io.github.kharboush.picture-panel_1.0.1_all.ipk`, or the manifest in the same folder, with the Homebrew Channel, or the TV's `dev/install`). That is all: the app puts what it needs on Glasshouse's server itself the first time it is opened, and again if that is ever missing or out of date.

Open **Picture Panel** from the app list, or assign it to a remote button in Glasshouse's remote keys (it is listed there like any app). To open it from a command:

```sh
luna-send -n 1 luna://com.webos.applicationManager/launch '{"id":"io.github.kharboush.picture-panel"}'
```

If you open it just as Glasshouse is restarting (it takes about 20 seconds), it says so and closes; open it again.

## How it works

Two parts, because Glasshouse only accepts changes from pages it serves (`POST /api/control` refuses other origins):

| Part | Where | What |
|---|---|---|
| `app/payload/picture-panel.html` | Copied to `/var/lib/tvweb/assets/picture-panel.html` | The panel. Reads `GET /api/lgsettings?section=picture`, sets with `POST /api/control` `{action:'lgSetting', value:{id, value}}`, the same calls Glasshouse's dashboard makes. |
| `app/index.html` | The installed app, with an **overlay** window (`defaultWindowType: overlay`, `transparent: true` in `appinfo.json`) | The launcher. Checks that Glasshouse is up and that the page there is this app's version (a marker in the page); if not, asks the Homebrew Channel's exec service to run `payload/install.sh` as root, which copies the page in (and restarts Glasshouse, which keeps served assets in memory, only when replacing an older copy). Then opens the page, keeping the overlay window. |

Glasshouse updates leave files they do not ship alone, so the page survives them; the launcher puts it back anyway if it ever goes missing. `payload/uninstall.sh` removes the page; uninstalling the app from the Homebrew Channel does not run it, and the page is a few KB.

## Building

```sh
./picture-panel/build-ipk.py      # needs ares-package (npm i -g @webos-tools/cli)
```

writes `dist/<id>_<version>_all.ipk` and its manifest (also kept in `release/`). The version comes from `app/appinfo.json` and is filled in for `@VERSION@` in the launcher and the page.

## Tested

On the TV (G6, webOS 11.2.0): installing the package, a clean first open with the page removed (the app put it back and opened the panel as an overlay), reading and setting values through the same API, and that Glasshouse lists the app for remapping. Not tried: a Glasshouse update with the panel installed, and opening the panel from a remapped remote button.
