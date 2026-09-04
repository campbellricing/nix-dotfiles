-- Hyprland (Lua) bootstrap for NixOS — ported from arch-dotfiles/hypr/hyprland.lua
--
-- Home Manager appends this to the generated ~/.config/hypr/hyprland.lua via
-- wayland.windowManager.hyprland.extraConfig. It require()s the topic modules
-- in ~/.config/hypr/hyprland/ which are out-of-store symlinks to this repo, so
-- editing them + `hyprctl reload` takes effect without a rebuild.
--
-- Full port: env / general / input / misc / animations / decoration / group /
-- execs (autostart) / rules (window rules) / gestures / keybinds.

local home = os.getenv("HOME")
local hypr = home .. "/.config/hypr"
package.path = package.path .. ";" .. home .. "/.config/caelestia/?.lua"

-- Create a file if it doesn't exist, optionally with initial content
local function maybe_create(file, content)
	local f = io.open(file)
	if f then
		f:close()
		return
	end
	f = io.open(file, "w")
	if f then
		if content then
			f:write(content)
		end
		f:close()
	end
end

-- Copy src to dst, but only if dst doesn't already exist
local function maybe_copy(src, dst)
	local out = io.open(dst)
	if out then
		out:close()
		return
	end
	local input = io.open(src, "r")
	if not input then
		return
	end
	out = io.open(dst, "w")
	if out then
		out:write(input:read("*a"))
		out:close()
	end
	input:close()
end

-- Seed the colour scheme if caelestia hasn't written one yet
maybe_copy(hypr .. "/scheme/default.lua", hypr .. "/scheme/current.lua")

-- User variable overrides: ~/.config/caelestia/hypr-vars.lua returns a table
maybe_create(home .. "/.config/caelestia/hypr-vars.lua", "return {}\n")
local overrides = require("hypr-vars")
if type(overrides) == "table" then
	local vars = require("variables")
	for k, v in pairs(overrides) do
		vars[k] = v
	end
end

-- Default monitor
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1,
})

-- Config modules
require("hyprland.env")
require("hyprland.general")
require("hyprland.input")
require("hyprland.misc")
require("hyprland.animations")
require("hyprland.decoration")
require("hyprland.group")
require("hyprland.execs")
require("hyprland.rules")
require("hyprland.gestures")
require("hyprland.keybinds")

-- Free-form user hook: ~/.config/caelestia/hypr-user.lua
maybe_create(home .. "/.config/caelestia/hypr-user.lua")
require("hypr-user")
