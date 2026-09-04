local vars = require("variables")

-- Themes
-- qtengine (the arch AUR Qt theme engine) isn't packaged for NixOS. GTK/Qt
-- theming isn't tracked in arch-dotfiles either, so leave PLATFORMTHEME unset
-- and let caelestia / the defaults handle it. Set it here if you add qt6ct etc.
-- hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
-- quickshell can't detect the icon theme without a Qt platform-theme plugin
-- (QIcon::themeName() is empty -> hicolor only), so themed tray icons like
-- fcitx5's "input-keyboard-symbolic" render as a broken image. Point quickshell
-- at the theme explicitly (matches home.nix gtk.iconTheme / dconf).
hl.env("QS_ICON_THEME", "Papirus-Dark")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("XCURSOR_THEME", vars.cursorTheme)
hl.env("XCURSOR_SIZE", vars.cursorSize)

-- Toolkit backends
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland,x11,windows")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- XDG specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Default editor
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")

-- Others
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
-- Suppress quickshell's "Configuration Loaded" popup on every shell start.
-- caelestia sets this via `pragma DefaultEnv`, but that only applies when the
-- var is unset — force it here so it also covers the initial load.
hl.env("QS_NO_RELOAD_POPUP", "1")
-- ~/.config/images is an out-of-store symlink to nix-dotfiles/images
hl.env("CAELESTIA_WALLPAPERS_DIR", "/home/campbells/.config/images/wallpapers")
