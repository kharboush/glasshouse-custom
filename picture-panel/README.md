# Picture Panel

A picture settings panel shown as an **overlay window** over whatever is playing, in the Spotlight View look (square, black, subtle outlines). It reads and sets the TV's real values for Picture Mode, OLED Pixel Brightness, Black Level, Auto Dynamic Contrast, Peak Brightness, Color Temperature and TruMotion.

- Up and Down move between rows; Left and Right (or OK) change the value; Back closes. A Magic Remote pointer can click rows and the arrows.
- The choices are the ones the TV itself offers (this G6 has no "Clear" TruMotion, for example). Colour temperature runs from Warm 50 to Cool 50. Black Level shows "Not on this input" unless the input on screen is an HDMI input, because LG keeps it per input and, for apps and the tuner, per colour system.
- Settings are per picture mode and per input, so the panel shows and changes those of the input on screen. Changing the picture mode re-reads everything.
- It closes itself after two minutes without a key or pointer.

## How it is built

Two parts, because Glasshouse only accepts changes from pages it serves (`POST /api/control` refuses other origins):

| Part | Where | What |
|---|---|---|
| `server/picture-panel.html` | `/var/lib/tvweb/assets/picture-panel.html` on the TV | The panel. Reads `GET /api/lgsettings?section=picture`, sets with `POST /api/control` `{action:'lgSetting', value:{id, value}}`, the same calls Glasshouse's dashboard makes. |
| `app/` | Installed as an app, `io.github.kharboush.picture-panel` | A thin launcher with an **overlay** window (`defaultWindowType: overlay`, `transparent: true` in `appinfo.json`). It checks Glasshouse is up, then opens the panel from its server, keeping the overlay window. |

## Deploying

Copy the panel to the TV and restart Glasshouse, which keeps assets in memory (repeat after editing the page):

```sh
scp picture-panel/server/picture-panel.html root@<tv>:/var/lib/tvweb/assets/picture-panel.html
ssh root@<tv> /var/lib/tvweb/tvwebctl restart
```

Build and install the app (`ares-package --no-minify --outdir dist app`, then the TV's `dev/install`), and launch it with `luna-send -n 1 luna://com.webos.applicationManager/launch '{"id":"io.github.kharboush.picture-panel"}'`. Glasshouse updates leave files it does not ship alone, so the panel page survives them.
