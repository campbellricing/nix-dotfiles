local scheme = require("scheme.current")

return {
	------------------
	---- HYPRLAND ----
	------------------

	-- Apps
	terminal = "foot",
	browser = "chromium",
	editor = "codium",
	fileExplorer = "thunar",
	audioSettings = "pavucontrol",

	-- Touchpad
	touchpadDisableTyping = true,
	touchpadScrollFactor = 0.3,
	-- gestureFingers = 3,
	workspaceSwipeFingers = 3,
	-- gestureFingersMore = 4,

	-- Blur
	blurEnabled = true,
	blurSpecialWs = false,
	blurPopups = true,
	blurInputMethods = true,
	blurSize = 8,
	blurPasses = 2,
	blurXray = false,

	-- Shadow
	shadowEnabled = false,
	shadowRange = 15,
	shadowRenderPower = 4,
	shadowColour = "rgba(" .. scheme.inversePrimary .. "10)",

	-- Gaps
	workspaceGaps = 8,
	windowGapsIn = 4,
	windowGapsOut = 16,
	singleWindowGapsOut = 16,

	-- Window styling
	windowOpacity = 0.95,
	windowRounding = 20,
	windowBorderSize = 2,
	activeWindowBorderColour = "rgba(" .. scheme.primary .. "e6)",
	inactiveWindowBorderColour = "rgba(" .. scheme.onSurfaceVariant .. "11)",

	-- Misc
	volumeStep = 2,
	volumeMax = 100,
	cursorTheme = "Bibata-Modern-Ice",
	cursorSize = 24,
	sleepGestureCmd = "systemctl suspend-then-hibernate",

	------------------
	---- KEYBINDS ----
	------------------

	-- Launcher
	kbLauncher = "SUPER + SPACE", -- open the app launcher

	-- Workspaces
	kbMoveWinToWs = "SUPER + SHIFT", -- + [1-9, 0]: move active window to workspace N
	-- kbMoveWinToWsGroup = "CTRL + SUPER + ALT", -- + [1-9, 0]: move active window to workspace N in current group
	kbGoToWs = "SUPER", -- + [1-9, 0]: focus workspace N
	-- kbGoToWsGroup = "CTRL + SUPER", -- + [1-9, 0]: focus workspace N in current group
	kbNextWs = "CTRL + SUPER + J", -- focus next workspace
	kbPrevWs = "CTRL + SUPER + K", -- focus previous workspace

	-- Window Group
	kbWindowGroupCycleNext = "SUPER + TAB", -- cycle to next window in group
	kbWindowGroupCyclePrev = "SHIFT + SUPER + TAB", -- cycle to previous window in group
	-- kbUngroup = "SUPER + U", -- move active window out of its group
	-- kbToggleGroup = "SUPER + Comma", -- toggle grouping for active window

	-- Window focus (vim keys)
	kbFocusLeft = "SUPER + H", -- focus window to the left
	kbFocusDown = "SUPER + J", -- focus window below
	kbFocusUp = "SUPER + K", -- focus window above
	kbFocusRight = "SUPER + L", -- focus window to the right

	-- Window focus (arrow keys)
	kbFocusLeftArrow = "SUPER + left", -- focus window to the left
	kbFocusDownArrow = "SUPER + down", -- focus window below
	kbFocusUpArrow = "SUPER + up", -- focus window above
	kbFocusRightArrow = "SUPER + right", -- focus window to the right

	-- Window move (vim keys)
	kbMoveWinLeft = "SUPER + SHIFT + H", -- move active window left
	kbMoveWinDown = "SUPER + SHIFT + J", -- move active window down
	kbMoveWinUp = "SUPER + SHIFT + K", -- move active window up
	kbMoveWinRight = "SUPER + SHIFT + L", -- move active window right

	-- Window move (arrow keys)
	kbMoveWinLeftArrow = "SUPER + SHIFT + left", -- move active window left
	kbMoveWinDownArrow = "SUPER + SHIFT + down", -- move active window down
	kbMoveWinUpArrow = "SUPER + SHIFT + up", -- move active window up
	kbMoveWinRightArrow = "SUPER + SHIFT + right", -- move active window right

	-- Window resize
	kbShrinkWinX = "SUPER + Minus", -- shrink active window horizontally
	kbGrowWinX = "SUPER + Equal", -- grow active window horizontally
	kbShrinkWinY = "SUPER + SHIFT + Minus", -- shrink active window vertically
	kbGrowWinY = "SUPER + SHIFT + Equal", -- grow active window vertically
	kbShrinkWinXArrow = "SUPER + ALT + left", -- shrink active window horizontally
	kbGrowWinXArrow = "SUPER + ALT + right", -- grow active window horizontally
	kbShrinkWinYArrow = "SUPER + ALT + up", -- shrink active window vertically
	kbGrowWinYArrow = "SUPER + ALT + down", -- grow active window vertically

	-- Window Action
	kbMoveWindow = "SUPER + Z", -- drag window with keyboard bind
	kbResizeWindow = "SUPER + X", -- resize window with keyboard bind
	kbDragWindowMouse = "SUPER + mouse:272", -- drag window with left mouse button
	kbResizeWindowMouse = "SUPER + mouse:273", -- resize window with right mouse button
	kbCenterWindow = "SUPER + SHIFT + C", -- center the active (floating) window
	-- kbWindowPip = "SUPER + ALT + backslash", -- float, pin and shrink window (picture-in-picture)
	-- kbPinWindow = "SUPER + P", -- pin the active window (show on all workspaces)
	kbWindowFullscreen = "SUPER + SHIFT + ALT + F", -- true fullscreen (no bar/borders)
	kbWindowBorderedFullscreen = "SUPER + SHIFT + F", -- maximise (keep bar/borders)
	kbToggleWindowFloating = "SUPER + SHIFT + T", -- toggle floating for active window
	kbCloseWindow = "SUPER + Q", -- close the active window
	kbToggleSplit = "SUPER + SHIFT + S", -- toggle split orientation (dwindle layout)

	-- Special workspaces toggles
	-- kbSpecialWs = "SUPER + S", -- toggle scratchpad special workspace
	kbSystemMonitorWs = "CTRL + SHIFT + Escape", -- toggle system monitor special workspace
	-- kbMusicWs = "SUPER + M", -- toggle music special workspace
	-- kbCommunicationWs = "SUPER + D", -- toggle communication special workspace
	-- kbTodoWs = "SUPER + R", -- toggle todo special workspace

	-- Apps
	kbTerminal = "SUPER + RETURN", -- open terminal
	kbBrowser = "SUPER + SHIFT + RETURN", -- open browser
	-- kbEditor = "SUPER + C", -- open code editor
	kbFileExplorer = "ALT + SHIFT + E", -- open file explorer
	kbYazi = "ALT + E", -- open yazi (terminal file manager)
	kbNotes = "SUPER + SHIFT + Z", -- open zennotes

	-- Utilities
	kbScreenshotFreeze = "ALT + SHIFT + S", -- take a screenshot (frozen screen)
	kbColourPicker = "SUPER + SHIFT + P", -- pick a colour from the screen (hyprpicker)
	kbClipboard = "SUPER + SHIFT + V", -- open clipboard history picker
	kbEmojiPicker = "SUPER + SHIFT + E", -- open emoji picker
	kbTestNotif = "SUPER + ALT + F12", -- send a test notification

	-- Brightness
	kbBrightnessUp = "XF86MonBrightnessUp", -- increase screen brightness
	kbBrightnessDown = "XF86MonBrightnessDown", -- decrease screen brightness

	-- Media
	kbMediaToggle = "CTRL + SUPER + Space", -- play/pause media
	kbMediaNext = "CTRL + SUPER + Equal", -- next track
	kbMediaPrev = "CTRL + SUPER + Minus", -- previous track
	kbMediaPlayKey = "XF86AudioPlay", -- play/pause media (hardware key)
	kbMediaPauseKey = "XF86AudioPause", -- play/pause media (hardware key)
	kbMediaNextKey = "XF86AudioNext", -- next track (hardware key)
	kbMediaPrevKey = "XF86AudioPrev", -- previous track (hardware key)
	kbMediaStopKey = "XF86AudioStop", -- stop media (hardware key)

	-- Volume
	kbVolumeUp = "XF86AudioRaiseVolume", -- raise volume (unmutes first)
	kbVolumeDown = "XF86AudioLowerVolume", -- lower volume
	kbVolumeMute = "XF86AudioMute", -- toggle speaker mute (hardware key)
	kbVolumeMuteAlt = "SUPER + SHIFT + M", -- toggle speaker mute
	kbMicMute = "XF86AudioMicMute", -- toggle microphone mute

	-- Shell
	-- kbShellKill = "CTRL + SUPER + SHIFT + R", -- kill the caelestia shell
	kbShellRestart = "CTRL + SUPER + ALT + R", -- restart the caelestia shell

	-- Misc
	kbSession = "CTRL + SUPER + Delete", -- open session (power) menu
	kbShowSidebar = "SUPER + SHIFT + N", -- toggle sidebar
	kbClearNotifs = "CTRL + ALT + C", -- clear all notifications
	kbShowPanels = "SUPER + SHIFT + D", -- toggle dashboard panels
	-- kbLock = "SUPER + CTRL + L", -- lock the screen
	kbRestoreLock = "SUPER + ALT + L", -- restart shell daemon and lock screen
	kbSleep = "CTRL + ALT + SUPER + L", -- suspend (sleep) the system
}
