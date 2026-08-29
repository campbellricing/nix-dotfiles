local vars = require("variables")

hl.config({
	input = {
		kb_layout = "us",
		kb_options = "ctrl:nocaps,altwin:swap_alt_win",
		numlock_by_default = false,
		repeat_delay = 250,
		repeat_rate = 35,
		focus_on_close = 1,

		touchpad = {
			natural_scroll = true,
			disable_while_typing = vars.touchpadDisableTyping,
			scroll_factor = vars.touchpadScrollFactor,
		},
	},

	binds = {
		scroll_event_delay = 0,
	},

	cursor = {
		-- nouveau falls back to legacy DRM (no atomic modesetting), where the
		-- hardware cursor plane flickers on every move frame. Render in software.
		no_hardware_cursors = 1,

		hotspot_padding = 1,
		inactive_timeout = 0.4,
	},
})

hl.device({
	name = "tpps/2-ibm-trackpoint",
	sensitivity = -0.4,
})
