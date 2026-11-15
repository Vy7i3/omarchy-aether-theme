#!/usr/bin/env bash
# Aether — regenerate wallpapers, wordmark and previews.
#
# The theme ships finished assets. Run this only when you want to rebuild them
# after changing the palette, pane sources or the preview mock-up.
#
# Requires: ImageMagick 7 (`magick`) and, for preview.png, rsvg-convert.
# The glass pane sources live in extras/src/ and are part of the package.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/extras/src"
BG="$ROOT/backgrounds"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/aether-assets.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

W=2560
H=1440

say() { printf '  %s\n' "$*"; }

if ! command -v magick >/dev/null 2>&1; then
  echo "generate-assets: ImageMagick 7 is required (the 'magick' command)." >&2
  exit 1
fi

for pane in pane1.png pane2.png pane3.png; do
  if [[ ! -f "$SRC/$pane" ]]; then
    echo "generate-assets: missing extras/src/$pane — the package is incomplete." >&2
    exit 1
  fi
done

FONT="Adwaita-Sans-Bold"
FONT_LIST="$(magick -list font 2>/dev/null || true)"
if ! grep -qF "Font: $FONT" <<<"$FONT_LIST"; then
  FONT="Liberation-Sans-Bold"
fi
if ! grep -qF "Font: $FONT" <<<"$FONT_LIST"; then
  FONT="JetBrainsMono-NF-Bold"
fi
if ! grep -qF "Font: $FONT" <<<"$FONT_LIST"; then
  echo "generate-assets: no usable bold font found (install Adwaita Sans or Liberation Sans)." >&2
  exit 1
fi

cd "$WORK"

# ── Shared fields ────────────────────────────────────────────────────────────
make_stars() {
  magick -size ${W}x${H} xc:black -seed "$1" +noise Random \
    -colorspace gray -threshold 99.93% -blur 0x0.4 stars.png
}

make_grid() {
  { for x in $(seq 64 256 $W); do echo "line $x,0 $x,$H"; done
    for y in $(seq 64 256 $H); do echo "line 0,$y $W,$y"; done; } > grid.mvg
}

make_ribbon() {
  magick -size ${W}x${H} xc:none -stroke 'rgba(110,244,255,0.9)' -strokewidth 2 -fill none \
    -draw "path 'M -150,1010 C 420,1050 900,860 1400,580 C 1740,390 2140,300 2700,295'" ribbon.png
}

vignette() {
  magick -size ${W}x${H} radial-gradient:'rgba(0,0,0,0)-rgba(0,0,0,0.60)' "$1"
}

finish_wallpaper() {
  local png="$1" out="$2"
  magick "$png" -resize 5120x2880 -filter Lanczos -quality 92 "$out"
}

# ── Wallpaper 1: Aether Veil ─────────────────────────────────────────────────
# Glass-friendly: the aurora band and glows run bright enough that Hyprland's
# blur has real luminance to refract behind the theme's translucent terminal
# windows. Keep the mean luminance roughly 40–65 or the frosted glass reads as
# plain black again.
compose_veil() {
  say "composing 1-aether-veil"
  make_stars 17
  make_grid
  make_ribbon
  vignette vig.png

  # The veil itself — a thin diagonal sheet of pale cyan light. Built larger
  # than the frame and composited with a centered negative offset: `-extent`
  # flattens alpha onto the background colour, which would wash the whole
  # frame opaque, so the oversized canvas is clipped by the composite instead.
  magick -size 640x640 radial-gradient:'rgba(196,247,255,0.55)-rgba(196,247,255,0)' \
    -resize 3300x300\! -background none -rotate 26 -blur 0x26 veil-band.png
  read -r BAND_W BAND_H <<< "$(magick identify -format '%w %h' veil-band.png)"
  BAND_X=$(( (W - BAND_W) / 2 ))
  BAND_Y=$(( (H - BAND_H) / 2 ))

  magick -size ${W}x${H} xc:'#0a1120' \
    \( -size 2400x2400 radial-gradient:'rgba(0,205,235,0.42)-rgba(0,205,235,0)' \) -geometry -600-760 -compose over -composite \
    \( -size 2100x2100 radial-gradient:'rgba(168,85,247,0.38)-rgba(168,85,247,0)' \) -geometry +1150+60 -compose over -composite \
    \( -size 1700x1700 radial-gradient:'rgba(0,150,190,0.26)-rgba(0,150,190,0)' \) -geometry +1500-520 -compose over -composite \
    \( -size 2300x2300 radial-gradient:'rgba(24,64,120,0.24)-rgba(24,64,120,0)' \) -geometry -300+520 -compose over -composite \
    veil-band.png -geometry ${BAND_X}${BAND_Y} -compose screen -composite \
    \( stars.png -fill '#e2f7ff' -opaque white \) -compose screen -composite \
    -stroke 'rgba(120,220,240,0.07)' -strokewidth 1 -fill none -draw @grid.mvg \
    "$SRC/pane3.png" -geometry +1710+1055 -compose over -composite \
    "$SRC/pane2.png" -geometry +1410+780 -compose over -composite \
    "$SRC/pane1.png" -geometry +1490+110 -compose over -composite \
    \( ribbon.png -blur 0x22 -channel A -evaluate multiply 0.72 \) -compose screen -composite \
    \( ribbon.png -blur 0x6 -channel A -evaluate multiply 0.86 \) -compose screen -composite \
    ribbon.png -compose screen -composite \
    \( vig.png -channel A -evaluate multiply 0.55 \) -compose over -composite \
    veil.png

  finish_wallpaper veil.png "$BG/1-aether-veil.webp"
}

# ── Wallpaper 2: Aether Obsidian ─────────────────────────────────────────────
compose_obsidian() {
  say "composing 2-aether-obsidian"
  make_stars 23
  make_grid

  magick -size ${W}x${H} xc:none -stroke 'rgba(120,240,255,0.85)' -strokewidth 2 -fill none \
    -draw "path 'M -100,1180 C 500,1150 1300,1200 2660,1130'" horizon.png
  magick -size 2200x2200 radial-gradient:'rgba(0,190,210,0.16)-rgba(0,190,210,0)' \
    -resize 2400x420\! horizon-soft.png
  magick "$SRC/pane1.png" -resize 150% obsidian-pane1.png
  magick "$SRC/pane2.png" -resize 95% obsidian-pane2.png
  vignette vig.png

  magick -size ${W}x${H} xc:'#03050a' \
    \( -size 2300x2300 radial-gradient:'rgba(92,42,195,0.30)-rgba(92,42,195,0)' \) -geometry +700-150 -compose over -composite \
    \( -size 1600x1600 radial-gradient:'rgba(0,170,190,0.20)-rgba(0,170,190,0)' \) -geometry -500+800 -compose over -composite \
    \( stars.png -fill '#cfefff' -opaque white -evaluate multiply 0.85 \) -compose screen -composite \
    -stroke 'rgba(120,220,240,0.045)' -strokewidth 1 -fill none -draw @grid.mvg \
    obsidian-pane1.png -geometry +980+170 -compose over -composite \
    obsidian-pane2.png -geometry +250+800 -compose over -composite \
    horizon-soft.png -geometry +80+970 -compose screen -composite \
    \( horizon.png -blur 0x14 -channel A -evaluate multiply 0.45 \) -compose screen -composite \
    \( horizon.png -blur 0x4 -channel A -evaluate multiply 0.65 \) -compose screen -composite \
    horizon.png -compose screen -composite \
    vig.png -compose over -composite \
    obsidian.png

  finish_wallpaper obsidian.png "$BG/2-aether-obsidian.webp"
}

# ── Wallpaper 3: Aether Horizon ──────────────────────────────────────────────
compose_horizon() {
  say "composing 3-aether-horizon"
  make_stars 31

  magick -size 2560x2 gradient:'#00f0ff-#a855f7' -rotate 270 horizon-line.png
  magick -size 2560x800 xc:none \
    \( -size 2400x2400 radial-gradient:'rgba(0,200,220,0.30)-rgba(0,200,220,0)' -resize 2400x620\! \) -geometry -100+90 -compose over -composite \
    \( -size 1600x1600 radial-gradient:'rgba(120,60,230,0.26)-rgba(120,60,230,0)' -resize 1600x560\! \) -geometry +1200+120 -compose over -composite \
    horizon-glow.png
  magick -size 340x340 radial-gradient:'rgba(180,250,255,0.28)-rgba(180,250,255,0)' sun.png
  vignette vig.png

  { echo "stroke rgba(120,220,240,0.10)"; echo "stroke-width 1"; echo "fill none"
    for x in -1800 -1100 -600 -200 200 600 1100 1800 2800 3800; do echo "line 1280,980 $x,1440"; done
    for y in 1000 1030 1070 1120 1185 1265 1360 1440; do echo "line 0,$y 2560,$y"; done
    echo "stroke rgba(120,220,240,0.045)"
    for x in $(seq 64 256 2560); do echo "line $x,0 $x,960"; done; } > floor.mvg

  magick -size ${W}x${H} xc:'#04060b' \
    \( -size 2500x2500 radial-gradient:'rgba(0,120,150,0.16)-rgba(0,120,150,0)' \) -geometry -400-700 -compose over -composite \
    \( stars.png -fill '#cfefff' -opaque white -evaluate multiply 0.9 \) -compose screen -composite \
    -draw @floor.mvg \
    horizon-glow.png -geometry +0+580 -compose screen -composite \
    sun.png -geometry +1110+810 -compose screen -composite \
    horizon-line.png -geometry +0+979 -compose over -composite \
    \( horizon-glow.png -resize 100%x50%\! -channel A -evaluate multiply 0.30 \) -geometry +0+981 -compose screen -composite \
    vig.png -compose over -composite \
    horizon.png

  finish_wallpaper horizon.png "$BG/3-aether-horizon.webp"
}

# ── Wordmark used by Plymouth and the Omarchy wallpaper ─────────────────────
make_wordmark() {
  say "drawing unlock.png wordmark"
  magick -size 800x188 xc:none -font "$FONT" -pointsize 106 -fill white \
    -gravity center -kerning 16 -annotate +0-2 'AETHER' mask.png

  magick -size 800x188 gradient:'#00f0ff-#a855f7' -rotate 270 -resize 800x188\! grad.png
  magick grad.png \( mask.png -alpha extract \) -compose CopyOpacity -composite text.png
  magick grad.png \( mask.png -alpha extract -threshold 12% -blur 0x26 -level 0%,38% \) \
    -compose CopyOpacity -composite glow.png
  magick glow.png text.png -compose over -composite "$ROOT/unlock.png"
}

# ── Omarchy wallpaper ───────────────────────────────────────────────────────
compose_omarchy() {
  say "composing omarchy.webp"
  magick "$BG/1-aether-veil.webp" -resize 3840x2160\! -blur 0x28 \
    -modulate 62,92,100 -fill '#050810' -colorize 18% omarchy-bg.png
  magick omarchy-bg.png \( "$ROOT/unlock.png" -resize 1500x \) \
    -gravity center -geometry +0-30 -compose over -composite \
    -quality 92 "$BG/omarchy.webp"
}

# ── Plymouth preview ────────────────────────────────────────────────────────
make_preview_unlock() {
  say "composing preview-unlock.png"
  local plymouth="${OMARCHY_PATH:-/usr/share/omarchy}/default/plymouth"
  if [[ -d "$plymouth" ]] && [[ -f "$plymouth/entry.png" ]]; then
    local p="$WORK/plymouth"
    mkdir -p "$p"
    find "$plymouth" -maxdepth 1 -type f -exec cp -t "$p" {} +
    cp "$ROOT/unlock.png" "$p/logo.png"
    for asset in bullet.png entry.png lock.png; do
      magick "$p/$asset" -channel RGB +level-colors '#e6f1ff','#e6f1ff' "$p/$asset"
    done

    local logo_w logo_h entry_w entry_h lock_w lock_h logo_x logo_y entry_x entry_y lock_x lock_y bullet_y bx
    logo_w=$(magick identify -format '%w' "$p/logo.png")
    logo_h=$(magick identify -format '%h' "$p/logo.png")
    entry_w=$(magick identify -format '%w' "$p/entry.png")
    entry_h=$(magick identify -format '%h' "$p/entry.png")
    lock_h=$((entry_h * 8 / 10))
    lock_w=$((84 * lock_h / 96))
    logo_x=$(((1920 - logo_w) / 2))
    logo_y=$(((1080 - logo_h) / 2))
    entry_x=$(((1920 - entry_w) / 2))
    entry_y=$((logo_y + logo_h + 40))
    lock_x=$((entry_x - lock_w - 15))
    lock_y=$((entry_y + entry_h / 2 - lock_h / 2))
    bullet_y=$((entry_y + entry_h / 2 - 4))

    local -a args=()
    for i in 0 1 2 3; do
      bx=$((entry_x + 20 + i * 12))
      args+=( '(' "$p/bullet.png" -resize 7x7 ')' -geometry "+${bx}+${bullet_y}" -composite )
    done

    magick -size 1920x1080 'xc:#070b14' \
      "$p/logo.png" -geometry "+${logo_x}+${logo_y}" -composite \
      "$p/entry.png" -geometry "+${entry_x}+${entry_y}" -composite \
      \( "$p/lock.png" -resize "${lock_w}x${lock_h}" \) -geometry "+${lock_x}+${lock_y}" -composite \
      "${args[@]}" "$ROOT/preview-unlock.png"
  else
    # Minimal fallback so the generator still works on a non-Omarchy host.
    magick -size 1920x1080 'xc:#070b14' \
      "$ROOT/unlock.png" -gravity center -geometry +0-90 -composite \
      -fill none -stroke '#e6f1ff' -strokewidth 3 \
      -draw "roundrectangle 817,664 1103,712 3,3" \
      -fill '#e6f1ff' -stroke none \
      -draw "circle 837,688 837,692" -draw "circle 851,688 851,692" \
      -draw "circle 865,688 865,692" -draw "circle 879,688 879,692" \
      "$ROOT/preview-unlock.png"
  fi
}

# ── Desktop preview ─────────────────────────────────────────────────────────
make_preview() {
  say "composing preview.png"
  if ! command -v rsvg-convert >/dev/null 2>&1; then
    say "skipping preview.png: rsvg-convert is not installed"
    return 0
  fi
  mkdir -p preview
  cp "$ROOT/extras/preview.svg" preview/preview.svg
  magick "$BG/1-aether-veil.webp" -resize 2560x1440\! preview/preview-bg.png
  (
    cd preview
    rsvg-convert -w 2560 -h 1440 preview.svg -o "$ROOT/preview.png"
  )
}

mkdir -p "$BG"

while (( $# > 0 )); do
  case "$1" in
    --wallpapers-only) WALLPAPERS_ONLY=1 ;;
    --veil-only) VEIL_ONLY=1 ;;
    --help | -h)
      cat <<'USAGE'
Usage: extras/generate-assets.sh [--wallpapers-only] [--veil-only]

Regenerates backgrounds/*.webp, unlock.png, preview-unlock.png, preview.png
and backgrounds/omarchy.webp in place. Use --wallpapers-only to leave the
previews and wordmark untouched, or --veil-only to rebuild just the glass
hero wallpaper and the omarchy.webp derived from it.
USAGE
      exit 0
      ;;
    *) echo "generate-assets: unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

if [[ -n ${VEIL_ONLY:-} ]]; then
  mkdir -p "$BG"
  compose_veil
  compose_omarchy
  echo "Aether veil assets regenerated in $ROOT"
  exit 0
fi

compose_veil
compose_obsidian
compose_horizon

if [[ -z ${WALLPAPERS_ONLY:-} ]]; then
  make_wordmark
  compose_omarchy
  make_preview_unlock
  make_preview
fi

echo "Aether assets regenerated in $ROOT"
