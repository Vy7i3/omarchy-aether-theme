#!/usr/bin/env bash
# Aether — install the optional extras.
#
# Nothing here is required for the theme itself. The installer only touches
# user configuration under ~/.config and ~/.claude/~/.pi, records every
# change, and can undo its own work again with --remove.
#
# Optional pieces:
#   gtk4/gtk3    libadwaita + GTK3 colour tokens in gtk.css
#   screensaver  TTE wordmark at ~/.config/omarchy/branding/screensaver.txt
#   fastfetch    the emblem config as the user fastfetch config (backed up)
#   cava         selects themes/omarchy-current, which the theme hook renders
#                from the active palette on every theme switch
#   lazygit      seeds the (empty) lazygit config with themed colours
#   claude/pi    activates the synced "omarchy" theme inside Claude Code / Pi
#   hermes       activates the synced "omarchy" skin (needs a bootstrapped Hermes)
#   fcitx5       activates the synced "omarchy" candidate-window theme
#   hook         the CLI retint hook itself, wired into Omarchy's theme-set hook
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
GTK4="$HOME/.config/gtk-4.0/gtk.css"
GTK3="$HOME/.config/gtk-3.0/gtk.css"
BRAND_DIR="$HOME/.config/omarchy/branding"
SAVER="$BRAND_DIR/screensaver.txt"
SAVER_STATE="$BRAND_DIR/.aether-screensaver-backup"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/aether-cli"
CAVA_CONF="$HOME/.config/cava/config"
CAVA_THEMES="$HOME/.config/cava/themes"
LG_CONF="$HOME/.config/lazygit/config.yml"
FF_CONF="$HOME/.config/fastfetch/config.jsonc"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CLAUDE_SETTINGS="$CLAUDE_DIR/settings.json"
PI_SETTINGS="$HOME/.pi/agent/settings.json"
HERMES_BOOTSTRAP="$HOME/.hermes/hermes-agent/.hermes-bootstrap-complete"
FCITX5_CLASSICUI="$HOME/.config/fcitx5/conf/classicui.conf"
HOOK_SRC="$ROOT/extras/omarchy-cli-retints"
HOOK_DST="$HOME/.config/omarchy/hooks/theme-set.d/50-aether-cli-retints"
MARK_BEGIN='/* >>> aether-theme begin >>> */'
MARK_END='/* <<< aether-theme end <<< */'

say() { printf '  %s\n' "$*"; }

# ── shared record bookkeeping ────────────────────────────────────────────────
# One state file per key in STATE_DIR; its single line is the backup path, or
# empty when the file did not exist before us.
record_backup() {
  local key="$1" file="$2" backup
  [[ -f $STATE_DIR/$key ]] && return 0
  mkdir -p "$STATE_DIR"
  if [[ -f $file ]]; then
    backup="$STATE_DIR/$key.orig"
    cp -p "$file" "$backup"
    printf '%s\n' "$backup" >"$STATE_DIR/$key"
    say "backed up ${file/#$HOME/~} → ${backup/#$HOME/~}"
  else
    : >"$STATE_DIR/$key"
    say "noted ${file/#$HOME/~} (new file)"
  fi
}

restore_key() {
  local key="$1" file="$2" backup
  [[ -f $STATE_DIR/$key ]] || return 0
  backup="$(<"$STATE_DIR/$key")"
  if [[ -n $backup && -f $backup ]]; then
    cp -p "$backup" "$file"
    say "restored ${file/#$HOME/~}"
  else
    rm -f "$file"
    say "removed ${file/#$HOME/~}"
  fi
  rm -f "$STATE_DIR/$key" "$STATE_DIR/$key.orig"
}

# ── GTK + screensaver (unchanged behaviour) ──────────────────────────────────
strip_block() {
  local file="$1"
  [[ -f $file ]] || return 0
  awk -v begin="$MARK_BEGIN" -v end="$MARK_END" '
    $0 == begin { skip = 1; next }
    $0 == end   { skip = 0; next }
    !skip
  ' "$file" >"$file.aether-tmp"
  mv "$file.aether-tmp" "$file"
}

install_css() {
  local css="$1" target="$2" label="$3"
  [[ -f $css ]] || { echo "install-extras: missing $css" >&2; exit 1; }

  mkdir -p "${target%/*}"
  if [[ -f $target ]] && ! grep -qF "$MARK_BEGIN" "$target"; then
    cp -p "$target" "$target.aether-backup-$STAMP"
    say "backed up ${target/#$HOME/~} → ${target/#$HOME/~}.aether-backup-$STAMP"
  fi

  if [[ -f $target ]]; then
    strip_block "$target"
    if [[ -s $target && -n $(tail -c 1 "$target") ]]; then
      printf '\n' >>"$target"
    fi
  fi

  {
    printf '%s\n' "$MARK_BEGIN"
    printf '/* Aether — managed block. Remove with: %s --remove */\n' "extras/install-extras.sh"
    cat "$css"
    printf '%s\n' "$MARK_END"
  } >>"$target"

  say "installed $label → ${target/#$HOME/~}"
}

remove_css() {
  local target="$1" label="$2"
  [[ -f $target ]] || { say "$label: nothing to remove"; return 0; }
  if ! grep -qF "$MARK_BEGIN" "$target"; then
    say "$label: no Aether block present"
    return 0
  fi
  cp -p "$target" "$target.aether-removed-$STAMP"
  strip_block "$target"
  say "removed Aether block from ${target/#$HOME/~}"
}

install_screensaver() {
  [[ -f "$ROOT/extras/screensaver.txt" ]] || {
    echo "install-extras: missing extras/screensaver.txt" >&2
    exit 1
  }
  mkdir -p "$BRAND_DIR"

  if [[ -f $SAVER ]]; then
    if [[ ! -f $SAVER_STATE ]]; then
      cp -p "$SAVER" "$SAVER.aether-backup-$STAMP"
      printf '%s\n' "$SAVER.aether-backup-$STAMP" >"$SAVER_STATE"
      say "backed up ${SAVER/#$HOME/~} → ${SAVER/#$HOME/~}.aether-backup-$STAMP"
    fi
  else
    : >"$SAVER_STATE"
  fi

  cp "$ROOT/extras/screensaver.txt" "$SAVER"
  say "installed screensaver wordmark → ${SAVER/#$HOME/~}"
  say "preview it with: omarchy screensaver"
}

remove_screensaver() {
  if [[ ! -f $SAVER_STATE ]]; then
    say "screensaver: nothing to remove"
    return 0
  fi
  local backup
  backup="$(<"$SAVER_STATE")"
  if [[ -n $backup && -f $backup ]]; then
    cp -p "$backup" "$SAVER"
    say "restored ${SAVER/#$HOME/~} from ${backup/#$HOME/~}"
  else
    rm -f "$SAVER"
    say "removed ${SAVER/#$HOME/~}"
  fi
  rm -f "$SAVER_STATE"
}

# ── CLI retints ──────────────────────────────────────────────────────────────
install_hook() {
  [[ -f $HOOK_SRC ]] || { echo "install-extras: missing $HOOK_SRC" >&2; exit 1; }
  mkdir -p "${HOOK_DST%/*}"
  cp "$HOOK_SRC" "$HOOK_DST"
  chmod +x "$HOOK_DST"
  say "installed theme hook → ${HOOK_DST/#$HOME/~}"
}

remove_hook() {
  if [[ -f $HOOK_DST ]]; then
    rm -f "$HOOK_DST"
    say "removed theme hook"
  else
    say "hook: nothing to remove"
  fi
}

run_retints() {
  [[ -x $HOOK_DST ]] || { say "retints: hook not installed, skipping"; return 0; }
  "$HOOK_DST"
  say "retinted fastfetch, cava palette and lazygit for the current theme"
}

install_cava_select() {
  [[ -f $CAVA_CONF ]] || { say "cava: no config at ${CAVA_CONF/#$HOME/~}, skipping"; return 0; }
  if grep -qE "^[[:space:]]*theme[[:space:]]*=[[:space:]]*'omarchy-current'" "$CAVA_CONF"; then
    say "cava: already selecting omarchy-current"
  elif grep -qE "^[[:space:]]*;[[:space:]]*theme[[:space:]]*=[[:space:]]*'none'|^[[:space:]]*theme[[:space:]]*=[[:space:]]*'none'" "$CAVA_CONF"; then
    record_backup cava "$CAVA_CONF"
    sed -i "s/^\([[:space:]]*\)\(;\)\?[[:space:]]*theme[[:space:]]*=[[:space:]]*'none'[[:space:]]*/\1theme = 'omarchy-current'/" "$CAVA_CONF"
    say "cava: now selecting themes/omarchy-current"
  else
    say "cava: a custom theme is already selected, leaving it"
  fi
  say "cava: restart cava (or open it) to pick up the palette"
}

remove_cava_select() {
  restore_key cava "$CAVA_CONF"
  if [[ -f $CAVA_THEMES/omarchy-current ]]; then
    rm -f "$CAVA_THEMES/omarchy-current"
    say "removed ${CAVA_THEMES/#$HOME/~}/omarchy-current"
  fi
  rmdir "$CAVA_THEMES" 2>/dev/null || true
}

# ── agent + input-method activations (Omarchy's own --activate paths) ───────
run_activate() {
  local label="$1" script="$2"
  shift 2
  if ! command -v "$script" >/dev/null 2>&1; then
    say "$label: $script not on PATH, skipping"
    return 0
  fi
  "$script" "$@" || { say "$label: $script failed (see its output)"; return 0; }
  say "$label: activated"
}

install_claude() {
  [[ -d $CLAUDE_DIR ]] || { say "claude: no $CLAUDE_DIR, skipping"; return 0; }
  record_backup claude "$CLAUDE_SETTINGS"
  run_activate "claude" omarchy-theme-set-claude --activate
}

install_pi() {
  [[ -d $HOME/.pi/agent ]] || { say "pi: no ~/.pi/agent, skipping"; return 0; }
  record_backup pi "$PI_SETTINGS"
  run_activate "pi" omarchy-theme-set-pi --activate
}

install_hermes() {
  [[ -f $HERMES_BOOTSTRAP ]] || { say "hermes: not bootstrapped, skipping"; return 0; }
  record_backup hermes "$HOME/.hermes/config.yaml"
  run_activate "hermes" omarchy-theme-set-hermes --activate
}

install_fcitx5() {
  [[ -d $HOME/.config/fcitx5 ]] || { say "fcitx5: not configured, skipping"; return 0; }
  record_backup fcitx5 "$FCITX5_CLASSICUI"
  run_activate "fcitx5" omarchy-theme-set-fcitx5 --activate
}

remove_activation() {
  restore_key claude "$CLAUDE_SETTINGS"
  restore_key pi "$PI_SETTINGS"
  restore_key hermes "$HOME/.hermes/config.yaml"
  restore_key fcitx5 "$FCITX5_CLASSICUI"
}

remove_cli_files() {
  restore_key fastfetch "$FF_CONF"
  restore_key lazygit "$LG_CONF"
  remove_cava_select
}

usage() {
  cat <<'USAGE'
Usage: extras/install-extras.sh [target ...|all|--remove]

With no arguments, installs every optional extra. Each file is backed up
before the first change; --remove undoes everything this installer records.

  gtk4          libadwaita colour tokens in ~/.config/gtk-4.0/gtk.css
  gtk3          GTK3 fallback tokens in ~/.config/gtk-3.0/gtk.css
  screensaver   extras/screensaver.txt as the TTE screensaver wordmark
  fastfetch     the theme emblem as your fastfetch config
  cava          point cava at the hook-rendered themes/omarchy-current
  lazygit       seed the empty lazygit config with themed colours
  claude        activate the synced "omarchy" theme in Claude Code
  pi            activate the synced "omarchy-system" theme in Pi
  hermes        activate the synced "omarchy" skin (bootstrapped Hermes only)
  fcitx5        activate the synced "omarchy" candidate-window theme
  hook          install the CLI retint hook (runs on every theme switch)
  all           all of the above (default)
  --remove      undo the changes this installer made
USAGE
}

DO_GTK4=0
DO_GTK3=0
DO_SAVER=0
DO_CLI=0
DO_ACTIVATE=0
DO_HOOK=0
REMOVE=0

if (( $# == 0 )); then
  DO_GTK4=1
  DO_GTK3=1
  DO_SAVER=1
  DO_CLI=1
  DO_ACTIVATE=1
  DO_HOOK=1
fi

while (( $# > 0 )); do
  case "$1" in
    gtk | gtk4) DO_GTK4=1 ;;
    gtk3) DO_GTK3=1 ;;
    screensaver) DO_SAVER=1 ;;
    fastfetch | cava | lazygit) DO_CLI=1; DO_HOOK=1 ;;
    claude | pi | hermes | fcitx5) DO_ACTIVATE=1; DO_HOOK=1 ;;
    hook) DO_HOOK=1; DO_CLI=1 ;;
    all)
      DO_GTK4=1; DO_GTK3=1; DO_SAVER=1; DO_CLI=1; DO_ACTIVATE=1; DO_HOOK=1
      ;;
    --remove | remove) REMOVE=1 ;;
    -h | --help) usage; exit 0 ;;
    *) echo "install-extras: unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if (( REMOVE )); then
  remove_css "$GTK4" "gtk4"
  remove_css "$GTK3" "gtk3"
  remove_screensaver
  remove_hook
  remove_cli_files
  remove_activation
  rmdir "$STATE_DIR" 2>/dev/null || true
  say "done — every recorded change is reverted"
  exit 0
fi

(( DO_HOOK )) && install_hook
(( DO_CLI )) && run_retints
(( DO_ACTIVATE )) && { install_claude; install_pi; install_hermes; install_fcitx5; }
(( DO_CLI )) && install_cava_select
(( DO_GTK4 )) && install_css "$ROOT/extras/gtk.aether.css" "$GTK4" "GTK4 palette"
(( DO_GTK3 )) && install_css "$ROOT/extras/gtk3.aether.css" "$GTK3" "GTK3 palette"
(( DO_SAVER )) && install_screensaver

cat <<'EOF'

Done. The theme itself was not applied or modified.
  Apply Aether:      omarchy theme set aether
  Enable GTK blur:   omarchy hyprland window transparency glassy
  See the emblem:    fastfetch  (or the Omarchy menu → About)
EOF
