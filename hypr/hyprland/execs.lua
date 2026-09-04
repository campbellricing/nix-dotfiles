local vars = require("variables")
local fn = require("hyprland.functions")

hl.on("hyprland.start", function()
	-- Keyring (gnome-keyring is also started by PAM via services.gnome.gnome-keyring;
	-- this just makes sure the secrets component is up for early clients)
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")

	-- Polkit auth agent: NixOS uses hyprpolkitagent (systemd user service in
	-- home.nix), not polkit-gnome. Nothing to launch here.

	-- Clipboard history
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	-- Auto delete trash 30 days old
	hl.exec_cmd("trash-empty 30")

	-- Cursors (theme/size also set declaratively via home.pointerCursor)
	hl.exec_cmd("hyprctl setcursor " .. vars.cursorTheme .. " " .. vars.cursorSize)

	-- Forward bluetooth media commands to MPRIS (mpris-proxy ships with bluez)
	hl.exec_cmd("mpris-proxy")

	-- Input methods: the NixOS i18n.inputMethod module wires the env vars and
	-- drops an XDG autostart file, but Hyprland-from-TTY doesn't process XDG
	-- autostart, so launch fcitx5 here. -d daemonizes, --replace is harmless.
	hl.exec_cmd("fcitx5 -d --replace")

	-- Thunar daemon (consistent window class + faster window open)
	hl.exec_cmd("thunar --daemon")

	-- Default to the wallpaper-derived "dynamic" colour scheme on any machine
	-- reusing this config (caelestia's built-in default is catppuccin/mocha).
	-- Only acts when the scheme isn't already dynamic, so a manual switch to
	-- another scheme and the current light/dark toggle are both left alone.
	-- No-ops on a brand-new machine until the shell has set a wallpaper (the
	-- scheme then goes dynamic on the next login).
	hl.exec_cmd("caelestia scheme get -n | grep -qx dynamic || caelestia scheme set -n dynamic")

	-- Start shell (systemd caelestia.service is disabled in home.nix so this,
	-- and the shell-restart/lock keybinds, own the lifecycle like on arch)
	hl.exec_cmd("caelestia shell -d")
end)

-- Resizer listener
hl.on("window.title", function(win)
	local d = {
		hl.dsp.window.float({ action = "on", window = win }),
		hl.dsp.window.center({ window = win }),
	}
	local pip = fn.move_actions(win) or {}

	fn.resizer(win, "Bitwarden", 20, 54, d, true)
	fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip, false)
end)

hl.on("window.open", function(win)
	local d = {
		hl.dsp.window.float({ action = "on", window = win }),
		hl.dsp.window.center({ window = win }),
	}
	local pip = fn.move_actions(win) or {}

	fn.resizer(win, "Bitwarden", 20, 54, d, true)
	fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip, false)
end)
