# Settings Restyle

A Homebrew Channel app that gives LG's Settings (the full "All settings" app) the Spotlight View look: solid black, square corners, Home's cream and grey text, smaller text and icons, tighter padding. It is applied again at every start of the TV.

Built for a rooted LG G6 on webOS 11.2.0 with frozen firmware. The CSS targets this firmware's class names (read from the Settings app's own `main.js`), so a different firmware may look partly stock.

## What it does

LG's apps sit on a read-only system partition, so nothing is edited in place. At every start a boot hook:

1. copies LG's Settings app from the TV to `/var/lib/lg-settings-restyle/`;
2. appends `app/payload/custom.css` to the copy's `main.css`;
3. bind-mounts the copy over `/usr/palm/applications/com.palm.app.settings`.

It rebuilds the copy only when LG's files or `custom.css` change, and mounts nothing unless the copy was built whole, so a failure leaves LG's own Settings in place. **LG's files are never in this package**; the copy is made on the TV.

The quick settings and quick control panels are compiled Flutter apps and cannot be restyled this way.

## Install

Build the package, then install it on the TV with the Homebrew Channel (or `dev/install` as Glasshouse does):

```sh
./lg-settings-restyle/build-ipk.py      # needs ares-package (npm i -g @webos-tools/cli)
```

This writes `dist/io.github.kharboush.lg-settings-restyle_1.0.1_all.ipk` and its `.manifest.json`. After installing, open **Settings Restyle** once: its page has the Homebrew Channel run `payload/install.sh` as root, which links the boot hook into the app's folder and applies the restyle straight away. From then on the hook does it at every start.

The built package and manifest of the current version are also in `release/`, so the manifest can be added to the Homebrew Channel by its raw GitHub URL.

The page also has a **Remove the restyle** button (`payload/uninstall.sh`): it unmounts the copy, removes the hook and deletes `/var/lib/lg-settings-restyle`, which brings back LG's own Settings. Uninstalling the app from the Homebrew Channel leaves the hook pointing at nothing, so nothing runs after the next restart.

## Files

| File | Purpose |
|---|---|
| `app/appinfo.json`, `app/index.html`, icons | The launch page: installs, and offers removal |
| `app/payload/custom.css` | All the styling. Edit this, rebuild, reinstall |
| `app/payload/restyle.sh` | Builds the copy and mounts it (`--reopen` also closes and reopens Settings) |
| `app/payload/boot.sh` | The boot hook, linked as `/var/lib/webosbrew/init.d/70-lg-settings-restyle`; runs `restyle.sh` in the background and logs to `/var/lib/lg-settings-restyle/restyle.log` |
| `app/payload/install.sh`, `uninstall.sh` | Run as root by the page |
| `build-ipk.py` | Builds the `.ipk` and manifest with ares-package |

## Tested

On the TV: installing the package, running `install.sh`, a simulated boot (unmount, run the hook, the restyle comes back), removing, and installing again. The launch page's own button presses, and a real restart of the TV, were not tried.

## Notes on `custom.css`

- Menu greys: the main menu's selected item uses `--semantic-color-surface-default-translucent`, and a focused disabled option uses `--semantic-color-surface-default-disabled-focused`. Darkening the first to black makes the selected item invisible, so it is left as LG has it.
- The light-grey wash over the menus is LG's white at 10% on five elements; they are set to a see-through warm grey instead.
- Toggle knobs are squared to sit in the square track.
