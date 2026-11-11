# glasshouse-custom

**Spotlight View** for [Glasshouse](https://github.com/rorygallagher2024/glasshouse) Home on an LG G6: a big live preview up top, a compact clock in the corner and larger tiles below.

It is an update-proof overlay. Glasshouse's own files stay stock, and a small service on the TV keeps the overlay applied, including after Glasshouse updates itself. Tested with Glasshouse 0.144.1.

## Install

From this repo, with the TV's address:

```sh
./customizations/install-tv.sh 192.168.0.42
```

Then open `http://<tv-address>:8090/` to switch it on or off and choose the font.

See [customizations/README.md](customizations/README.md) for how it works, everything it changes, and how to uninstall.
