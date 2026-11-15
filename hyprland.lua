-- Aether — compositor layer
--
-- Loaded by Omarchy's `require_optional.module("omarchy.current.theme.hyprland")`
-- after the stock defaults and before ~/.config/hypr/looknfeel.lua. Anything a
-- user puts in looknfeel.lua therefore still wins.
--
-- The theme bakes in glass rather than depending on the Appearance > Windows >
-- Window Opacity toggle: terminals carry their own opacity, and this file
-- enables the frosted compositor blur, the cyan/violet border gradient, the
-- violet halo, and blur behind every Omarchy layer-shell surface.

local cyan = "rgba(00f0ffee)"
local violet = "rgba(a855f7ee)"

local aether_active_border = { colors = { cyan, violet }, angle = 45 }
local aether_inactive_border = "rgba(2b3f5799)"

hl.config({
  general = {
    border_size = 2,
    gaps_in = 6,
    gaps_out = 14,

    col = {
      active_border = aether_active_border,
      inactive_border = aether_inactive_border,
    },
  },

  decoration = {
    rounding = 12,

    -- Soft violet/cyan halo rather than a neutral drop shadow.
    shadow = {
      enabled = true,
      range = 20,
      render_power = 3,
      color = "rgba(00f0ff2b)",
      color_inactive = "rgba(a855f71f)",
    },

    -- The glass engine. Sized and brightened so the luminous veil wallpaper
    -- reads as visible frost behind translucent windows while terminal text
    -- stays crisp.
    blur = {
      enabled = true,
      size = 10,
      passes = 3,
      ignore_opacity = true,
      new_optimizations = true,
      xray = false,
      noise = 0.012,
      contrast = 1.05,
      brightness = 0.9,
      vibrancy = 0.6,
      vibrancy_darkness = 0.28,
      popups = true,
      popups_ignorealpha = 0.2,
      special = true,
    },

    dim_inactive = true,
    dim_strength = 0.06,
  },

  group = {
    col = {
      border_active = aether_active_border,
      border_inactive = aether_inactive_border,
    },

    groupbar = {
      height = 24,
      font_size = 12,
      gaps_in = 6,
      gaps_out = 0,
      text_color = "rgb(e6f1ff)",
      text_color_inactive = "rgba(cfe3f780)",
      col = {
        active = "rgba(00f0ff2b)",
        inactive = "rgba(111a2b66)",
      },
      gradients = true,
      gradient_rounding = 8,
      gradient_round_only_edges = false,
    },
  },

  misc = {
    background_color = "rgb(03050a)",
  },
})

-- Blur the real Omarchy shell surfaces even when the optional Glassy bar /
-- Glassy windows modes are off. The shell alpha lives in shell.*.toml, so this
-- is what turns those translucent cards into frosted glass.
hl.layer_rule({
  match = {
    namespace = "^(omarchy-bar|omarchy-dock|omarchy-dock-apps|omarchy-menu|omarchy-notifications|omarchy-osd|omarchy-polkit|omarchy-reminders|omarchy-clipboard|omarchy-emojis|omarchy-image-selector|omarchy-keyboard-panel|omarchy-network-qr|omarchy-lock-preview)$",
  },
  blur = true,
  ignore_alpha = 0.2,
})

-- GTK apps paint a solid surface, so fade the whole window a little. This is
-- the same trade-off Omarchy's Glassy windows mode makes for Nautilus; the
-- shell's global Glassy mode, when enabled, tightens it to 0.75.
o.window("org\\.gnome\\.Nautilus", { opacity = "0.82 0.78" })

-- Glass extension pack — more apps on the frosted surface. Electron/CEF
-- windows fade their text along with the background, so the values stay
-- subtle, and blur comes from the compositor engine above. Obsidian is on
-- by default; uncomment a line to add that app, or change the pair to
-- "1.0" to leave it opaque.
o.window({ class = "(obsidian)" }, { opacity = "0.90 0.86" })
-- o.window({ class = "(spotify)" }, { opacity = "0.86 0.82" })
-- o.window({ class = "(discord)" }, { opacity = "0.86 0.82" })
-- o.window({ class = "(code-oss|Code|code)" }, { opacity = "0.88 0.84" })
-- o.window({ class = "(steam)" }, { opacity = "0.90 0.86" })
-- o.window({ class = "(Postman|postman)" }, { opacity = "0.90 0.86" })

-- The TTE screensaver runs inside the user's terminal, whose Aether theme is
-- deliberately translucent. Force the screensaver itself fully opaque so the
-- animated wordmark floats on black, not on the desktop.
o.window({ class = "^org\\.omarchy\\.screensaver$" }, { opacity = "1.0 override 1.0 override" })
