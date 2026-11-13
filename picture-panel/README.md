# Picture Panel

A picture settings panel shown as an **overlay window** over whatever is playing, in the Spotlight View look (square, black, subtle outlines, 95% opaque). It reads and sets the TV's real values, and shows the signal the TV is receiving.

Needs [Glasshouse](https://github.com/rorygallagher2024/glasshouse) running on the TV, and the Homebrew Channel.

## What it shows

**Signal** (top, three lines of four, refreshed every 3 seconds, for what is on screen):

| Resolution | Refresh rate | Frame rate | VRR |
|---|---|---|---|
| **Dynamic range** | **Low latency** | **Color** | **Bit depth** |
| **Link speed** | **Video data** | **Audio** | **Audio output** |

- What is on screen is the TV's own foreground app, not Glasshouse's "last input". On an app or Home the picture is read the same way (Home gives 1080p SDR, for example).
- Refresh rate and Frame rate are given to two decimals (23.976 Hz, 59.94 Hz, 24 FPS). The TV's HDMI receiver cuts the refresh rate to a whole number (23.976 reads 23), so the standard NTSC-style rates (23, 29, 47, 59, 119) are shown as their fractional values; other readings stand.
- Frame rate is what Glasshouse's game reading reports, and shows only on an HDMI input in game content. Under VRR the refresh rate stays at the link's rate (120 Hz) while the frame rate moves.
- VRR is the kind in use as the TV names it (G-SYNC, FreeSync, HDMI VRR) or Off; a plain On only when the TV says VRR is active without saying which.
- Dynamic range is SDR, HDR10, HDR10+, HLG or Dolby Vision. It comes from the TV's video output service, the same source as Glasshouse's dashboard, so it names Dolby Vision whichever way the source announces it (the Apple TV's home screen and its playback use different signalling). Home's HDMI reading is only a fallback.
- Link speed is the HDMI mode agreed with the device on that input: "HDMI 2.1" when it uses FRL, "HDMI 2.0" or "HDMI 1.4" for the older TMDS modes, from the TV's stats. It is a dash off an HDMI input.
- Video data is not the link's own top speed: it is what the picture itself needs, worked out from its resolution, refresh rate, colour format and bit depth. It is normally well under the link's ceiling.
- Audio is what the TV is receiving on its HDMI inputs: PCM, Dolby Digital, Dolby Digital+, Dolby TrueHD, DTS, DTS-HD, and Dolby Atmos or DTS:X when flagged. It is None for silence on an HDMI input and a dash elsewhere, where the sound is made inside the TV. Glasshouse has no channel count or sample rate.
- Audio output is the TV's output setting (TV Speaker, Optical, Bluetooth...); over ARC it is the soundbar's name when Glasshouse has found one.
- The last values the TV gave for the Signal block are shown at once when the panel opens and replaced when the TV answers. The settings are not kept: they show a dash until the TV answers, and no change is sent before then.

**Settings**, in three pages of up to five rows, titled "Picture Settings 1/3" to "3/3", in the order of LG's own Picture menu. Beside the title are up and down arrows; going Down past the last row of a page turns to the next, and past the first row of a page back to the one before, wrapping at both ends. It always opens on the first page.

| 1/3 | 2/3 | 3/3 |
|---|---|---|
| Picture Mode | Auto Dynamic Contrast | Color Temperature |
| Brightness (LG's OLED Pixel Brightness) | Expression Enhancer | Sharpness |
| Contrast | Gamma | TruMotion |
| Black Level | Dynamic Tone Mapping (HDR only) | Game Genre (game picture modes only) |
| Peak Brightness | Filmmaker Ambient Light | All Settings, which opens LG's full Settings and closes the panel |

The choices are the ones the TV itself offers (this G6 has no "Clear" TruMotion, for example). Brightness, Contrast, Black Level and Sharpness are plain numbers. Color Temperature runs from Warm 50 through Neutral to Cool 50, and its arrows follow the number shown: Left lowers it (Warm 10 to Warm 9), Right raises it. Gamma shows BT.1886 or 2.2. A setting the TV does not offer here is shown as a dash, with the reason where there is one ("HDR only", "Game modes only"). The panel keeps the height of five rows on every page.

Selecting a row for a second shows a box beside the panel: the setting's name, Glasshouse's own description of it (read from the TV's reply, not kept in the page), and a short recommendation line from this panel where there is one (for example "Use High for HDR and Off for SDR." for Peak Brightness). The box goes away as soon as you move.

Filmmaker Ambient Light is not one of Glasshouse's settings, so the panel reads and sets it through the Homebrew Channel's exec service (the TV's own `luna-send`), the way the launcher installs the page. It needs nothing from Glasshouse. LG hides and greys it outside Filmmaker Mode, so the panel asks the TV whether it applies and shows it greyed when it does not.

Settings are per picture mode and per input, so the panel shows and changes those of the input on screen. Changing the picture mode re-reads everything.

## Using it

- Up and Down move between rows and pages; Left and Right (or OK) change the value, or open Settings on that row; Back closes. A Magic Remote pointer can click rows and arrows, and its scroll wheel and the channel up and down keys act as Up and Down.
- Picture Mode waits half a second after the last press before it is sent, so flicking through modes only applies the one you stop on. Until the TV has been read again for that mode, every other setting shows a dash and is greyed.
- Settings the TV has switched off for the current mode or input (TruMotion, Peak Brightness and Auto Dynamic Contrast in Game mode, for example) are shown greyed and are not changed. Their box says "Not available in HDR Game mode." under the description. This is read from the `active` flag the TV gives each setting, so a change is never sent only to be refused. Errors use the same box, with an amber outline.
- It closes itself after 60 seconds without a key or pointer.

## Install

Install the package (`release/io.github.kharboush.picture-panel_1.7.2_all.ipk`, or the manifest in the same folder, with the Homebrew Channel, or the TV's `dev/install`). That is all: the app puts what it needs on Glasshouse's server itself the first time it is opened, and again if that is ever missing or out of date.

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
| `app/index.html` | The installed app, with an **overlay** window (`defaultWindowType: overlay`, `transparent: true` in `appinfo.json`) | The launcher. Checks that Glasshouse is up and that the page there is this app's version (a marker in the page); if not, asks the Homebrew Channel's exec service to run `payload/install.sh` as root, which copies the page in (and restarts Glasshouse, which keeps served assets in memory, only when replacing an older copy). Then opens the page, keeping the overlay window. Once a version's page has been confirmed, the launcher remembers that and later opens go straight to the panel. |

Glasshouse updates leave files they do not ship alone, so the page survives them; the launcher puts it back anyway if it ever goes missing. `payload/uninstall.sh` removes the page; uninstalling the app from the Homebrew Channel does not run it, and the page is a few KB.

## Building

```sh
./picture-panel/build-ipk.py      # needs ares-package (npm i -g @webos-tools/cli)
```

writes `dist/<id>_<version>_all.ipk` and its manifest (also kept in `release/`, where older versions stay beside the current one). The version comes from `app/appinfo.json` and is filled in for `@VERSION@` in the launcher and the page.

## Tested

On the TV (G6, webOS 11.2.0): installing the package, a clean first open with the page removed (the app put it back and opened the panel as an overlay), an update from one version to the next (1.1.0 to 1.1.1: the app replaced the page, restarted Glasshouse, waited for it and reopened by itself), reading values through the API, a write and read-back of a setting, and that the bundled page is identical to the one on Glasshouse. The layout was checked in a browser. Not tried: a Glasshouse update with the panel installed, opening the panel from a remapped remote button, and changing Game Genre or Dynamic Tone Mapping from the panel.
