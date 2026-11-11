# LG G6 Home custom layout

Published at <https://github.com/kharboush/glasshouse-custom>. To restore it into a fresh Glasshouse checkout, copy that repo's `customizations/` folder into the checkout root and run the apply script below.

`lg-g6-home.patch` adds a saved **Spotlight View** toggle to Glasshouse Home settings (setting key `g6CustomLayout`, saved in the TV's Home layout). The stock layout remains the default; switching the toggle off restores stock styling, the stock long date and Guide-last ordering.

All styling is additive: every override is scoped under the `.g6-custom` class on `#stage`, so no stock CSS declaration is replaced.

## What the toggle changes (1920×1080)

Top strip (`#now`, 602px tall, 64px padding), left to right:

| Element | Custom | Stock |
|---|---|---|
| Preview (`#preview`) | 864×486, first in the strip, top-aligned, 56px gap to its right | 356×200, right of the source text |
| Source text (`#source`) | Title 32px, source ("via") line 24px; takes the remaining width | Title 70px, via 26px |
| Clock (`#when`) | 48px clock, 24px date, right-aligned in the top-right corner, shrinks to fit (frees width for the source text) | 176px clock, 28px date, fixed 520px on the left |
| Date | Short form, e.g. "Wed, Nov 11" (locale-aware) | Long form, e.g. "Wednesday 11 November" |
| Picture details on the preview (`#pvInfo`) | Directly under the source text (24px below the "via" line, e.g. HDMI), left-aligned with it; wraps onto further lines instead of truncating; the label and via lines get fixed 30px and 32px line heights so this position is exact | Left of the preview (which would fall off-screen here) |
| Weather (`#weather`) | Just left of the clock, matching it line for line: icon at the clock line height (38.4px), 48px temperature, 24px line 10px below | 112px icon, 176px temperature, 28px line |
| Picture details without preview (`#plate`) | Just left of the clock: 32px mode, 18px lines | 52px mode, 23px lines |

Below the strip:

- Rows (`#rows`) start at 696px, with 64px side offsets.
- The Guide (`#guide`) starts at 612px, with 64px side margins; it shows 4 channel rows and scrolls the rest.
- Input tiles and Internet TV tiles are 384×216. Broadcast channel tiles keep their stock size.
- Guide is the first Internet TV tile.

Alternative View keeps its own clock and input tiles.

## Files the patch touches

- `server/assets/home.html` – the `.g6-custom` CSS block, the short date in `dateText()`, the class toggle, and Guide-first ordering.
- `server/lib/home.js` – validates and saves `g6CustomLayout` (only a boolean changes it; resetting tiles keeps it).
- `server/assets/dashboard.html`, `server/assets/ui.html`, `server/assets/ui/home.js` – the toggle in the browser and TV-app Home settings.
- `docs/dashboard/home.md` – the setting's documentation.
- `test/test-home.js`, `scripts/check-dashboards.js` – the setting test and the layout geometry check.

## Reapplying after a Glasshouse update

After updating the Glasshouse checkout, run:

```sh
./customizations/apply-lg-g6-home.sh
```

The script applies the patch only if every file applies cleanly. Running it again is safe: it reports that the changes are already applied. If an upstream release changes a patched section, the script stops without modifying any file; review and refresh the patch rather than forcing it.

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
