---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "wezterm"
local application_launcher = "rofi -modes drun -show drun"

-------------------
---- AUTOSTART ----
-------------------

-- exec
hl.on("config.reloaded", function ()
  hl.exec_cmd("kanshictl reload")
end)

-- exec-once
hl.on("hyprland.start", function ()
  hl.exec_cmd(terminal)
  hl.exec_cmd("hypridle")
  hl.exec_cmd("nm-applet")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("mako")
  hl.exec_cmd("waybar")
  hl.exec_cmd("vesktop")
  hl.exec_cmd("kanshi")
end)

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-----------------------
---- LOOK AND FEEL ----
-----------------------


