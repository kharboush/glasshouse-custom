# LG G6 Home custom layout

Published at <https://github.com/kharboush/glasshouse-custom>. To restore it into a fresh Glasshouse checkout, copy that repo's `customizations/` folder into the checkout root and run the apply script below.

`lg-g6-home.patch` adds a saved **Spotlight View** toggle to Glasshouse Home settings (setting key `g6CustomLayout`, saved in the TV's Home layout). The stock layout remains the default; switching the toggle off restores stock styling, the stock long date and Guide-last ordering.

All styling is additive: every override is scoped under the `.g6-custom` class on `#stage`, so no stock CSS declaration is replaced.

## What the toggle changes (1920×1080)

Top strip (`#now`, 602px tall, 64px padding), left to right:

| Element | Custom | Stock |
|---|---|---|
| Preview (`#preview`) | 864×486, first in the strip, top-aligned, 56px gap to its right | 356×200, right of the source text |
| Source text (`#source`) | Title 32px with 6px below it, source ("via") line 24px; takes the remaining width | Title 70px, via 26px |
| Clock (`#when`) | 48px clock, 24px date, right-aligned in the top-right corner, shrinks to fit (frees width for the source text) | 176px clock, 28px date, fixed 520px on the left |
| Date | Short form, e.g. "Wed, Nov 11" (locale-aware) | Long form, e.g. "Wednesday 11 November" |
| Picture details on the preview (`#pvInfo`) | One line 12px under the preview, left-aligned: 18px Manrope in the dim grey `#6b665e`, picture mode SemiBold, every item separated by a dot (e.g. "Filmmaker · OLED light 50 · 4K · HDR10 · 60Hz") | Three formatted lines left of the preview (which would fall off-screen here) |
| Weather (`#weather`) | Just left of the clock, matching it line for line: icon at the clock line height (38.4px), 48px temperature, 24px line 10px below | 112px icon, 176px temperature, 28px line |
| No-picture panel (`#pvNote`) | Solid black; label reads "NO SIGNAL" (swapped in with CSS), 18px SemiBold in capitals, slightly spaced | Near-black `#14120f`; label "No picture", 23px regular |
| Preview outline | The same 1px, 16% white line, drawn just outside the preview (`outline` on `#preview`) so the TV's video layer cannot cover it; the stock inner border (`#preview:after`) is removed because it flickered as the preview switched between "No picture" and video | 1px, 16% white, inside the preview |
| Full-colour channel logos (`.glyph img.plate`), on tiles and in the Guide | Square corners | 6px rounded corners |
| Tiles (`.tile`) | Square corners; 16px apart; every tile has the preview's outline (1px, 16% white); the selected tile keeps its 2px white outline | 8px apart; 6px rounded corners; no outline until selected |
| Picture details without preview (`#plate`), shown with no source or while switching | Hidden (the panel says "No signal" then; the line under the preview shows details while a picture plays) | Beside the clock: 52px mode, 23px lines |

Below the strip:

- Rows (`#rows`) start at 720px, with 64px side offsets.
- The Guide (`#guide`) starts at 612px, with 64px side margins; it shows 4 channel rows and scrolls the rest.
- Input tiles and Internet TV tiles are 384×216. App tiles are 216×216 (stock 168 wide, about 181 tall), with the same padding as the other tiles and the icon and name centred. Broadcast channel tiles keep their stock size.
- More apps: the same app tiles, 16px apart across and down, seven to a line (stock: nine, 8px across and 14px down); `FOLDER_COLS` is read through `folderCols()` so the arrow keys follow the seven columns.
- Guide is the first Internet TV tile.

Alternative View keeps its own clock and input tiles.

## Font

A **Spotlight View font** dropdown, next to the Spotlight View toggle in both settings screens (setting key `g6Font`), picks the typeface Home uses while Spotlight View is on:

- **Glasshouse fonts**: no font change at all; Home keeps stock Outfit and Manrope.
- **System font** (the default when nothing is chosen): LG Smart UI, the font LG uses for the webOS menus, already installed on the TV (`/usr/share/fonts/LG_Smart_UI-*.ttf`). LG licenses it for the TV only, so it is referenced by name and never copied into this repo. Plain `sans-serif` is not used because on the TV it resolves to LG Display, a narrow single-weight font.
- **Geist**: Vercel, SIL Open Font License (`fonts/OFL-Geist.txt`).
- **Inter**: Rasmus Andersson, v4.0, SIL Open Font License (`fonts/OFL-Inter.txt`).

Geist and Inter are bundled in Light 300, Regular 400, Medium 500 and SemiBold 600. A text patch cannot carry font files, so they live in `customizations/fonts/`, and the apply script copies them into `server/assets/fonts/`. When deploying, copy them to `/var/lib/tvweb/assets/fonts/` on the TV. Browsers only download a bundled font when it is chosen.

## Files the patch touches

- `server/assets/home.html` – the `.g6-custom` CSS block, the short date in `dateText()`, the class toggle, Guide-first ordering, and the More apps column count (`folderCols()`).
- `server/lib/home.js` – validates and saves `g6CustomLayout` (only a boolean changes it; resetting tiles keeps it).
- `server/assets/dashboard.html`, `server/assets/ui.html`, `server/assets/ui/home.js` – the toggle in the browser and TV-app Home settings.
- `docs/dashboard/home.md` – the setting's documentation.
- `test/test-home.js`, `scripts/check-dashboards.js` – the setting test and the layout geometry check.

## Reapplying after a Glasshouse update

After updating the Glasshouse checkout, run:

```sh
./customizations/apply-lg-g6-home.sh
```

The script applies the patch only if every file applies cleanly. It then copies the bundled fonts from `customizations/fonts/` into `server/assets/fonts/`. Running it again is safe: it reports that the changes are already applied. If an upstream release changes a patched section, the script stops without modifying any file; review and refresh the patch rather than forcing it.

The script does not touch the TV. Deploy as below, then turn on **Spotlight View** in Home settings (it stays on across deploys once saved).

## Deploying `home.html` to the TV

Copy `server/assets/home.html` to the TV's `/tmp`, back up the live file, move the new one into `/var/lib/tvweb/assets/home.html`, run `/var/lib/tvweb/tvwebctl restart`, then relaunch Home:

```sh
luna-send -n 1 luna://com.webos.applicationManager/launch '{"id":"com.webos.app.home"}'
```

Changes to the server or settings UI files need those files deployed too.

## Editing the customisation

Change the checkout directly, then regenerate the patch from the repository root:

```sh
git diff --output=customizations/lg-g6-home.patch -- \
  docs/dashboard/home.md \
  scripts/check-dashboards.js \
  server/assets/dashboard.html \
  server/assets/home.html \
  server/assets/ui.html \
  server/assets/ui/home.js \
  server/lib/home.js \
  test/test-home.js
```

Then copy the updated `customizations/` folder into a clone of <https://github.com/kharboush/glasshouse-custom>, commit and push, so the published copy stays current.
