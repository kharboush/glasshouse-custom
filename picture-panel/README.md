# Picture Panel

A picture settings panel shown as an **overlay window** over whatever is playing, in the Spotlight View look (square, black, subtle outlines, 95% opaque). It reads and sets the TV's real values, and shows the signal the TV is receiving.

Needs [Glasshouse](https://github.com/rorygallagher2024/glasshouse) running on the TV, and the Homebrew Channel.

## What it shows

**Signal** (top, two lines, refreshed every 3 seconds, for the input on screen):

| Resolution | Refresh rate | VRR | Dynamic range |
|---|---|---|---|
| **Low latency** | **Color** | **Bit depth** | **Audio** |

- VRR is the kind in use as the TV names it (G-SYNC, FreeSync, HDMI VRR) or Off; a plain On only when the TV says VRR is active without saying which.
- Dynamic range is SDR, HDR10, HDR10+, HLG or Dolby Vision.
- Audio is what the TV is receiving: PCM, Dolby Digital, Dolby Digital+, Dolby TrueHD, DTS, DTS-HD, and Dolby Atmos or DTS:X when the TV flags the content as such. Glasshouse has no channel count or sample rate to show.

**Settings**, a short list to start with and **See more** for the rest:

| Short list | See more adds |
|---|---|
| Picture Mode | Game Genre (only in a game picture mode) |
| OLED Pixel Brightness | Black Level |
| Color Temperature | Auto Dynamic Contrast |
| TruMotion | Peak Brightness |
| | Dynamic Tone Mapping |
| | All Settings, which opens LG's full Settings and closes the panel |

The choices are the ones the TV itself offers (this G6 has no "Clear" TruMotion, for example). OLED Pixel Brightness is a plain number. Color Temperature runs from Warm 50 to Cool 50, and its arrows follow the number shown: Left lowers it (Warm 10 to Warm 9), Right raises it. Black Level shows "Not on this input" unless an HDMI input is on screen, because LG keeps it per input and, for apps and the tuner, per colour system. Rows the TV does not offer here (Dynamic Tone Mapping outside HDR) are left out.

Settings are per picture mode and per input, so the panel shows and changes those of the input on screen. Changing the picture mode re-reads everything.

## Using it

- Up and Down move between rows and wrap at both ends; Left and Right (or OK) change the value, or open Settings / See more on those rows; Back closes. A Magic Remote pointer can click rows and arrows.
- Settings the TV has switched off for the current mode or input (TruMotion, Peak Brightness and Auto Dynamic Contrast in Game mode, for example) are shown greyed and are not changed. Focusing one shows a box beside the panel: the setting's name over "Not available in HDR Game mode." This is read from the `active` flag the TV gives each setting, so a change is never sent only to be refused. Errors use the same box, with an amber outline.
- It always opens on the short list, and closes itself after 60 seconds without a key or pointer.

## Install

Install the package (`release/io.github.kharboush.picture-panel_1.1.1_all.ipk`, or the manifest in the same folder, with the Homebrew Channel, or the TV's `dev/install`). That is all: the app puts what it needs on Glasshouse's server itself the first time it is opened, and again if that is ever missing or out of date.

Open **Picture Panel** from the app list, or assign it to a remote button in Glasshouse's remote keys (it is listed there like any app). To open it from a command:

```sh
luna-send -n 1 luna://com.webos.applicationManager/launch '{"id":"io.github.kharboush.picture-panel"}'
```

If you open it while Glasshouse is down for some other reason, it says so and closes; open it again once Glasshouse is back. After installing a new version the first open replaces the page itself and waits up to a minute for Glasshouse to come back.

## How it works

Two parts, because Glasshouse only accepts changes from pages it serves (`POST /api/control` refuses other origins):

| Part | Where | What |
|---|---|---|
| `app/payload/picture-panel.html` | Copied to `/var/lib/tvweb/assets/picture-panel.html` | The panel. Reads `GET /api/lgsettings?section=picture` and `section=game`, sets with `POST /api/control` `{action:'lgSetting', value:{id, value}}`, the same calls Glasshouse's dashboard makes. The signal comes from `/api/home/now`, `/api/home/picture`, `/api/game/fps` (for the VRR kind) and `/api/audio`. |
| `app/index.html` | The installed app, with an **overlay** window (`defaultWindowType: overlay`, `transparent: true` in `appinfo.json`) | The launcher. Checks that Glasshouse is up and that the page there is this app's version (a marker in the page); if not, asks the Homebrew Channel's exec service to run `payload/install.sh` as root, which copies the page in (and restarts Glasshouse, which keeps served assets in memory, only when replacing an older copy). Then opens the page, keeping the overlay window. |

Glasshouse updates leave files they do not ship alone, so the page survives them; the launcher puts it back anyway if it ever goes missing. `payload/uninstall.sh` removes the page; uninstalling the app from the Homebrew Channel does not run it, and the page is a few KB.

## Building

```sh
./picture-panel/build-ipk.py      # needs ares-package (npm i -g @webos-tools/cli)
```

writes `dist/<id>_<version>_all.ipk` and its manifest (also kept in `release/`, where older versions stay beside the current one). The version comes from `app/appinfo.json` and is filled in for `@VERSION@` in the launcher and the page.

## Tested

On the TV (G6, webOS 11.2.0): installing the package, a clean first open with the page removed (the app put it back and opened the panel as an overlay), an update from one version to the next (1.1.0 to 1.1.1: the app replaced the page, restarted Glasshouse, waited for it and reopened by itself), reading values through the API, a write and read-back of a setting, and that the bundled page is identical to the one on Glasshouse. The layout was checked in a browser. Not tried: a Glasshouse update with the panel installed, opening the panel from a remapped remote button, and changing Game Genre or Dynamic Tone Mapping from the panel.
