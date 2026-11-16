# Aether extras

Optional pieces that Aether's core theme deliberately does not install by
itself. The theme works without any of them; these add a GTK palette, an
Aether-branded TTE screensaver, the fastfetch emblem, cava and lazygit retints
wired to every theme switch, and one-command activation of the synced agent
themes (Claude Code, Pi, Hermes, fcitx5).

## Install

```bash
# Everything optional
./install-extras.sh

# One piece at a time
./install-extras.sh gtk         # GTK4 / libadwaita palette
./install-extras.sh gtk3        # GTK3 fallback palette
./install-extras.sh screensaver
./install-extras.sh fastfetch   # emblem config as your fastfetch config
./install-extras.sh cava        # select the hook-rendered palette
./install-extras.sh lazygit     # seed the empty lazygit config
./install-extras.sh claude      # activate "custom:omarchy" in Claude Code
./install-extras.sh pi          # activate "omarchy-system" in Pi
./install-extras.sh hermes      # activate the "omarchy" skin (bootstrapped only)
./install-extras.sh fcitx5      # activate the "omarchy" candidate window theme
./install-extras.sh hook        # the CLI retint hook on every theme switch
```

Every file is backed up before the first change. GTK changes are wrapped in
`/* >>> aether-theme begin >>> */` markers so they can be removed cleanly, and
the fastfetch/cava/lazygit takeovers are recorded in
`~/.local/state/omarchy/aether-cli/`:

```bash
./install-extras.sh --remove
```

`--remove` strips the GTK blocks, restores the screensaver file, restores the
original fastfetch and cava configs, un-seeds lazygit, restores the agent
settings backed up at activation, removes the hook, and forgets its records.
Backup copies are left on disk next to the originals; delete them once you are
happy.

## The CLI retint hook

`omarchy-cli-retints` is installed to
`~/.config/omarchy/hooks/theme-set.d/50-aether-cli-retints`, so Omarchy runs it
on **every** theme switch (not only Aether). It renders whatever theme is
current:

- **fastfetch** — copies the theme's `fastfetch.jsonc` to
  `~/.config/fastfetch/config.jsonc`. A foreign config is backed up once, then
  replaced. Themes without an emblem hand the original back.
- **cava** — renders the active palette to `~/.config/cava/themes/omarchy-current`
  (gradient from the theme's accent to its magenta, transparent background so
  the bars sit on the terminal glass). Point cava at it once with
  `theme = 'omarchy-current'` in `~/.config/cava/config` — the installer does
  this if cava still has the stock `; theme = 'none'` line.
- **lazygit** — renders `~/.config/lazygit/config.yml` with themed colours when
  the file is empty or hook-managed; a real user config is never touched.

Run any part on demand: `.../omarchy-cli-retints [fastfetch|cava|lazygit]`.

The agent themes need no hook of their own: Omarchy syncs `claude.json`,
`pi.json`, `hermes.yaml` and `fcitx5-theme.conf` from the current theme on every
switch. The installer only performs the one-time activation that points each
tool at the synced file.

## GTK

`gtk.aether.css` defines libadwaita's named colours: accent, window/view
surfaces, header bar, cards, dialogs, popovers, sidebars and semantic states. It
does not restyle widgets or replace Adwaita's layout. `gtk3.aether.css` does the
same for the older `theme_*` tokens used by GTK3 applications.

Backdrop blur is not part of these files. Omarchy owns that through its Glassy
windows mode, which adds the `backdrop-filter` rule to `gtk.css` itself:

```bash
omarchy hyprland window transparency glassy
```

The installer appends its block after whatever is already in `gtk.css`, so an
Omarchy Glassy block and Aether's colour tokens can coexist. Re-running the
installer replaces the Aether block instead of duplicating it.

## Screensaver

`screensaver.txt` is the Aether ASCII wordmark used by the TTE screensaver. The
installer copies it to:

```text
~/.config/omarchy/branding/screensaver.txt
```

Preview it with `omarchy screensaver`. To edit or reset it later:

```bash
omarchy branding screensaver text
omarchy branding screensaver reset
```

## Fastfetch emblem

The theme ships `../fastfetch.jsonc`: a cyan → violet ANSI-shadow **AETHER**
wordmark with letter-spaced taglines, over module keys that fade cyan → violet
down the list. Once the hook (or `install-extras.sh fastfetch`) has installed
it, both plain `fastfetch` and the Omarchy menu's About window render it,
because About detects a user config and runs it as-is.

To return to Omarchy's stock About window (the glint-sheen animation over its
own block logo), delete the user config:

```bash
rm ~/.config/fastfetch/config.jsonc
```

The hook will reinstall the emblem the next time a theme that ships one is
applied.

## Regenerate the artwork

`generate-assets.sh` rebuilds everything under `backgrounds/`, plus
`unlock.png`, `preview.png` and `preview-unlock.png`:

```bash
./generate-assets.sh
./generate-assets.sh --wallpapers-only
```

Requirements: ImageMagick 7 (`magick`) and, for `preview.png`,
`rsvg-convert`. The script composes at 2560×1440, upscales wallpapers to
5120×2880 with Lanczos, and writes WebP at quality 92. It uses the glass pane
sources in `src/`, so keep those files with the package.

`preview.svg` is the 2560×1440 desktop mock. It references `preview-bg.png`,
which the generator creates from the veil wallpaper. Edit the SVG to change the
mock's window layout, then re-run the generator.

`unlock.png` is generated from the system's Adwaita Sans Bold (falling back to
Liberation Sans Bold, then JetBrainsMono Nerd Font Bold). It is a transparent
800×188 PNG with a cyan → violet gradient and a soft glow.

## Preview notes

- `preview.png` is a designed desktop mock, not a captured screenshot. It shows
  the real palette, bar, terminal, btop and file manager at 2560×1440.
- `preview-unlock.png` is generated with Omarchy's own Plymouth layout and stock
  bullet/entry/lock assets, so it matches the actual boot screen proportions.
- `unlock.png` is the boot logo only. The lock-screen card is styled by
  `../shell.lock.toml`; the lock background is the current wallpaper.
