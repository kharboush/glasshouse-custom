# Spotlight View for Glasshouse Home (LG G6)

Published at <https://github.com/kharboush/glasshouse-custom>.

Spotlight View is an alternative layout for Glasshouse Home: a big live preview up top, a compact clock in the corner and larger tiles below. It is an **overlay**: Glasshouse's own files stay stock, and a small service on the TV keeps the overlay applied, including after Glasshouse updates itself. Nothing needs redoing after an update.

## How it survives updates

Glasshouse's updater replaces every file a release ships and leaves everything else alone. So the overlay lives in files no release ships:

| On the TV | What it is |
|---|---|
| `/var/lib/g6-spotlight/` | The service, its settings (`settings.json`), the settings page, and master copies of the overlay and fonts |
| `/var/lib/tvweb/assets/g6/spotlight.css`, `spotlight.js` | The overlay itself, served by Glasshouse to Home |
| `/var/lib/tvweb/assets/fonts/Geist-*`, `Inter-*` | The optional fonts |
| `/var/lib/webosbrew/init.d/60-g6-spotlight` | Boot hook that starts the service (Glasshouse's updater only refreshes its own `50-tvweb` hook) |

Every 30 seconds the service checks and, when needed, puts back:

1. **One line in `home.html`** that loads `assets/g6/spotlight.css` and `spotlight.js` (marked `<!-- g6-spotlight -->`).
2. **Guide-first**: a one-line swap where Home adds the Guide tile, so it goes first while Spotlight View is on. If a release changes that line, the swap is skipped, the service logs it, and Guide simply stays last. Nothing breaks.
3. The overlay and font files, if they ever go missing.

Glasshouse keeps every asset in memory once served, so after changing any file the service restarts Glasshouse, then reloads Home, but only if Home is on screen; it never pulls the TV away from what is being watched. In testing, a stock `home.html` was back to Spotlight View about 20 seconds after Glasshouse restarted.

If a future release renames elements the CSS targets, the affected parts look stock until the CSS is updated; nothing breaks either way.

## Settings

Open **http://192.168.0.42:8090/** (the TV's address, port 8090) from any device on the network:

- **Spotlight View**: on or off. Off is stock Glasshouse.
- **Font**, used while Spotlight View is on:
  - **Glasshouse fonts**: no font change; Home keeps stock Outfit and Manrope.
  - **System font**: LG Smart UI, the font LG uses for the webOS menus, already installed on the TV (`/usr/share/fonts/LG_Smart_UI-*.ttf`). LG licenses it for the TV only, so it is referenced by name and never copied here. Plain `sans-serif` is not used because on the TV it resolves to LG Display, a narrow single-weight font.
  - **Geist**: Vercel, SIL Open Font License (`g6-spotlight/fonts/OFL-Geist.txt`).
  - **Inter**: Rasmus Andersson, v4.0, SIL Open Font License (`g6-spotlight/fonts/OFL-Inter.txt`).

  Geist and Inter are bundled in Light 300, Regular 400, Medium 500 and SemiBold 600; Home only downloads one when it is chosen.

Changes apply straight away: Home reads the settings from the service when it loads, and the service reloads Home if it is on screen. The settings are not in Glasshouse's own settings screens, and anyone on the network can change them (they only affect the layout).

If Alternative View is on too, Alternative View wins.

## What Spotlight View changes (1920×1080)

Every rule is scoped under `.g6-custom` on `#stage`, which the overlay script adds only while Spotlight View is on.

Top strip (`#now`, 602px tall, 64px padding), left to right:

| Element | Spotlight View | Stock |
|---|---|---|
| Preview (`#preview`) | 864×486, first in the strip, top-aligned, 56px gap to its right | 356×200, right of the source text |
| Source text (`#source`) | Title 32px, source ("via") line 24px; takes the remaining width | Title 70px, via 26px |
| Clock (`#when`) | 48px clock, 24px date, right-aligned in the top-right corner, shrinks to fit (frees width for the source text) | 176px clock, 28px date, fixed 520px on the left |
| Date | Short form, e.g. "Wed, Nov 11" (locale-aware; set by the overlay script) | Long form, e.g. "Wednesday 11 November" |
| Picture details on the preview (`#pvInfo`) | One line 12px under the preview, left-aligned: 18px in the dim grey `#6b665e`, picture mode SemiBold, every item separated by a dot (e.g. "Filmmaker · OLED light 50 · 4K · HDR10 · 60Hz") | Three formatted lines left of the preview (which would fall off-screen here) |
| Weather (`#weather`) | Just left of the clock, matching it line for line: icon at the clock line height (38.4px), 48px temperature, 24px line 10px below | 112px icon, 176px temperature, 28px line |
| No-picture panel (`#pvNote`) | Solid black; label reads "NO SIGNAL" (swapped in with CSS), 18px SemiBold in capitals, slightly spaced | Near-black `#14120f`; label "No picture", 23px regular |
| Preview outline | The same 1px, 16% white line, drawn just outside the preview (`outline` on `#preview`) so the TV's video layer cannot cover it; the stock inner border (`#preview:after`) is removed because it flickered as the preview switched between "No picture" and video | 1px, 16% white, inside the preview |
| Full-colour channel logos (`.glyph img.plate`), on tiles and in the Guide | Square corners | 6px rounded corners |
| Picture details without preview (`#plate`) | Just left of the clock: 32px mode, 18px lines | 52px mode, 23px lines |

Below the strip:

- Rows (`#rows`) start at 696px, with 64px side offsets.
- The Guide (`#guide`) starts at 612px, with 64px side margins; it shows 4 channel rows and scrolls the rest.
- Input tiles and Internet TV tiles are 384×216. Broadcast channel tiles keep their stock size.
- Guide is the first Internet TV tile.

## Files here

| File | Purpose |
|---|---|
| `install-tv.sh` | Installs or updates everything on the TV over SSH (asks for the root password once). Keeps existing settings; a first install starts on, with the system font. |
| `g6-spotlight/overlay/spotlight.css` | All Spotlight View styling |
| `g6-spotlight/overlay/spotlight.js` | Adds the classes to `#stage`, the short date, and the Guide-first switch |
| `g6-spotlight/service.js` | The service (Node, port 8090) |
| `g6-spotlight/settings.html` | The settings page |
| `g6-spotlight/60-g6-spotlight` | The boot hook |
| `g6-spotlight/fonts/` | Geist and Inter, with their licences |

## Installing and editing

To install, or to send changes to the TV after editing any file here:

```sh
./customizations/install-tv.sh
```

The script restarts the service, which applies the changes and restarts Glasshouse if a served file changed. The service's log is `/var/lib/g6-spotlight/service.log` on the TV.

Then copy the `customizations/` folder into a clone of <https://github.com/kharboush/glasshouse-custom>, commit and push, so the published copy stays current.

## Uninstalling

On the TV, remove `/var/lib/webosbrew/init.d/60-g6-spotlight`, stop the service (kill the pid in `/var/lib/g6-spotlight/loop.pid`, then `pkill -f "node /var/lib/g6-spotlight/service[.]js"`), delete `/var/lib/g6-spotlight` and `/var/lib/tvweb/assets/g6`, remove the `<!-- g6-spotlight -->` line and the `/* g6-spotlight */` Guide line from `/var/lib/tvweb/assets/home.html` (or let the next Glasshouse update replace it), and run `/var/lib/tvweb/tvwebctl restart`.
