# glasshouse-custom

LG G6 Home custom layout for [Glasshouse](https://github.com/rorygallagher2024/glasshouse), kept as an update-safe patch behind a **Spotlight View** toggle in Home settings.

Built against Glasshouse 0.144.1 (upstream commit `306db88`).

## Use

Copy the `customizations/` folder into the root of a Glasshouse checkout, then run:

```sh
./customizations/apply-lg-g6-home.sh
```

See [customizations/README.md](customizations/README.md) for what the layout changes, how to deploy to the TV, and how to refresh the patch.

## Also here: Settings Restyle

[lg-settings-restyle/](lg-settings-restyle/) is a separate Homebrew Channel app that gives LG's own Settings the same look, applied again by a boot hook at every start. See its [README](lg-settings-restyle/README.md).

## Also here: Picture Panel and HDMI Sources

Two overlay apps for Glasshouse on the same TV, both in the Spotlight View look, and both closing themselves after 60 seconds untouched. Each installs as a Homebrew Channel package that puts its own page on Glasshouse's server, so nothing needs copying by hand:

- [picture-panel/](picture-panel/) shows the signal the TV is receiving and the picture settings (picture mode, OLED pixel brightness, colour temperature, TruMotion, and the rest under "See more"), and changes them. See its [README](picture-panel/README.md).
- [hdmi-sources/](hdmi-sources/) is a small switcher: a square Home tile and all four HDMI inputs, most recently used first, with a dot on the one on screen and "Inactive" on empty ports. See its [README](hdmi-sources/README.md).
