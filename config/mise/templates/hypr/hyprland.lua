-- Hyprland configuration in Lua.
-- Refer to https://wiki.hypr.land/Configuring/Start/ for the full API.

------------------
---- MONITORS ----
------------------

hl.monitor({
  output = "DP-1",
  mode = "2560x1440@144",
  position = "0x0",
  scale = "auto",
  vrr = 2,
})

hl.monitor({
  output = "DP-2",
  mode = "1920x1080@60",
  position = "2560x-240",
  scale = "auto",
  transform = 3,
})

hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1,
})

for _, workspace in ipairs({ 1, 2, 9 }) do
  hl.workspace_rule({ workspace = tostring(workspace), monitor = "DP-1" })
end

for _, workspace in ipairs({ 3, 4 }) do
  hl.workspace_rule({ workspace = tostring(workspace), monitor = "DP-2" })
end

---------------------
---- MY PROGRAMS ----
---------------------

local home = os.getenv("HOME")
local terminal = home .. "/.local/kitty.app/bin/kitty"
local file_manager = "dolphin"
local apps = "rofi -show drun -config ~/.config/rofi/drun.rasi"
local windows = "rofi -show window -config ~/.config/rofi/drun.rasi"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
  hl.exec_cmd("dunst & hyprpaper & waybar")
  hl.exec_cmd("systemctl --user start plasma-polkit-agent")
  hl.exec_cmd("firefox", { workspace = "3 silent" })
  hl.exec_cmd("steam", { workspace = "4 silent" })
  hl.exec_cmd("flatpak run dev.vencord.Vesktop", { workspace = "4 silent" })
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "RosePineDawn")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("XDG_MENU_PREFIX", "plasma-")

hl.env("PATH", home .. "/.local/bin:" .. (os.getenv("PATH") or ""))

-----------------------
---- LOOK AND FEEL ----
-----------------------

local subtle = 0xff{{ vars.theme_subtle | trim_start(pat="#") }}
local color1 = 0xff{{ vars.theme_love | trim_start(pat="#") }}
local color3 = 0xff{{ vars.theme_rose | trim_start(pat="#") }}

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 20,
    border_size = 3,
    col = {
      active_border = { colors = { color3, color1 }, angle = 45 },
      inactive_border = subtle,
    },
    resize_on_border = true,
    extend_border_grab_area = 15,
    hover_icon_on_border = true,
    allow_tearing = false,
    layout = "dwindle",
  },

  decoration = {
    rounding = 10,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = 0xee1a1a1a,
    },
    blur = {
      enabled = true,
      size = 3,
      passes = 1,
      vibrancy = 0.1696,
    },
  },

  animations = {
    enabled = true,
  },

  dwindle = {
    preserve_split = true,
  },

  master = {
    new_status = "master",
  },

  misc = {
    force_default_wallpaper = -1,
    disable_hyprland_logo = false,
    initial_workspace_tracking = 0,
  },

  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    kb_rules = "",
    follow_mouse = 1,
    sensitivity = 0,
  },
})

hl.curve("myBezier", {
  type = "bezier",
  points = { { 0.05, 0.9 }, { 0.1, 1.05 } },
})

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

---------------------
---- KEYBINDINGS ----
---------------------

local main_mod = "SUPER"

hl.bind(main_mod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(main_mod .. " + C", hl.dsp.window.close())
hl.bind(main_mod .. " + M", hl.dsp.exit())
hl.bind(main_mod .. " + E", hl.dsp.exec_cmd(file_manager))
hl.bind(main_mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(main_mod .. " + R", hl.dsp.exec_cmd(apps))
hl.bind(main_mod .. " + W", hl.dsp.exec_cmd(windows))
hl.bind(main_mod .. " + P", hl.dsp.window.pseudo())

hl.bind(main_mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(main_mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(main_mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(main_mod .. " + down", hl.dsp.focus({ direction = "down" }))

for workspace = 1, 10 do
  local key = workspace % 10
  hl.bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
  hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind(main_mod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(main_mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
  name = "windowrule-1",
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  name = "windowrule-2",
  match = { class = "^steam$" },
  workspace = "4",
})

hl.window_rule({
  name = "windowrule-3",
  match = { class = "^vesktop$" },
  workspace = "4",
})

hl.window_rule({
  name = "windowrule-4",
  match = { class = "^steam_app_\\d+$" },
  monitor = "DP-1",
})

hl.window_rule({
  name = "windowrule-5",
  match = { class = "^steam_app_\\d+$" },
  workspace = "9",
})

hl.workspace_rule({
  workspace = "9",
  no_border = true,
  no_rounding = true,
})
