{ config, pkgs, lib, inputs, ... }:

let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  # This repo must live here for the out-of-store symlinks below to resolve.
  repo = "${config.home.homeDirectory}/nix-dotfiles";
  # ~/.config/<path>  ->  ~/nix-dotfiles/<path>  (edit in place, no rebuild)
  link = p: mkOutOfStoreSymlink "${repo}/${p}";
in
{
  home.username = "campbells";
  home.homeDirectory = "/home/campbells";
  home.stateVersion = "26.05";

  imports = [ inputs.caelestia-shell.homeManagerModules.default ];

  programs.caelestia = {
    enable = true;
    cli.enable = true;
    # arch-dotfiles starts the shell from hypr/hyprland/execs.lua
    # (`caelestia shell -d`), and the shell-restart / lock keybinds assume they
    # own the lifecycle. Disable the HM systemd service so there's one owner.
    systemd.enable = false;

    # Patches ported from the arch-dotfiles quickshell/caelestia fork (which
    # tracks caelestia-shell 2.1.0 and has diverged ~120 files from the flake's
    # HEAD, so we can't vendor it wholesale). Applied against the current source
    # as `--replace-fail` edits (fail the build loudly if upstream moves the
    # lines) plus one vendored file for the interaction rework.
    package = inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli.overrideAttrs (o: {
      postPatch = (o.postPatch or "") + ''
        # --- click-to-open everything, nothing on hover (vendored file) ---
        # modules/drawers/Interactions.qml: every panel / popout (dashboard,
        # OSD, utilities, launcher, sidebar, bar popouts) opens on CLICK in its
        # screen-edge zone, never on hover. Session stays keybind-only. If
        # upstream changes Interactions.qml the sha check fails — re-merge
        # caelestia/shell-patches/ against it and bump this hash.
        _want=88ea719b1d0ab48c3e48ce7dc798220635f967261cd8fb5156d97b949063265d
        _have=$(sha256sum modules/drawers/Interactions.qml | cut -d' ' -f1)
        if [ "$_have" != "$_want" ]; then
          echo "caelestia: upstream modules/drawers/Interactions.qml changed ($_have)." >&2
          echo "Re-merge caelestia/shell-patches/ against it and bump the hash in home.nix." >&2
          exit 1
        fi
        cp -r ${./caelestia/shell-patches}/. .

        # Bar clock: click it to toggle the dashboard (checkPopout only runs on
        # click here — the vendored Interactions.qml disables hover popouts).
        # Also expose entryIdAt() so Interactions.qml can scope the pointing-hand
        # cursor to just the clock / tray / status-icon entries.
        substituteInPlace modules/bar/Bar.qml \
          --replace-fail '} else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.activeWindow.showOnHover) {' '} else if (id === "clock") { screenState.dashboard = !screenState.dashboard; } else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.activeWindow.showOnHover) {' \
          --replace-fail 'function checkPopout(y: real): void {' 'function entryIdAt(y: real): string { return (childAt(width / 2, y) as EntryWrapper)?.entryId ?? ""; }

    function checkPopout(y: real): void {'
        substituteInPlace modules/bar/BarWrapper.qml \
          --replace-fail 'function checkPopout(y: real): void {' 'function entryIdAt(y: real): string { return (content.item as Bar)?.entryIdAt(y) ?? ""; }

    function checkPopout(y: real): void {'

        # Bar workspaces: pointing-hand cursor (its MouseArea has none, so the
        # default arrow was overriding the Interactions overlay).
        substituteInPlace modules/bar/components/workspaces/Workspaces.qml \
          --replace-fail $'        MouseArea {\n            anchors.fill: layout\n            onClicked: event => {' $'        MouseArea {\n            anchors.fill: layout\n            cursorShape: Qt.PointingHandCursor\n            onClicked: event => {'

        # Dashboard user card: drop the "up " prefix, the window-manager icon,
        # and show "B-baka..." instead of the WM name.
        substituteInPlace modules/dashboard/dash/User.qml \
          --replace-fail 'text: "up " + SysInfo.uptime' 'text: SysInfo.uptime' \
          --replace-fail 'text: "select_window"' 'text: ""' \
          --replace-fail 'text: SysInfo.wm + "..."' 'text: "B-baka..."'

        # Lock screen avatar: smaller, plain circle instead of the clam shell.
        substituteInPlace modules/lock/center/ProfilePic.qml \
          --replace-fail 'centerWidth * 0.7' 'centerWidth * 0.5' \
          --replace-fail 'shape: MaterialShape.ClamShell' 'shape: MaterialShape.Circle'

        # Lock screen cards: extraLarge corner radius (the leftover
        # bottomRightRadius in Content.qml is then a harmless no-op).
        substituteInPlace modules/lock/Content.qml \
          --replace-fail 'radius: Tokens.rounding.medium' 'radius: Tokens.rounding.extraLarge'
        substituteInPlace modules/lock/NotifDock.qml \
          --replace-fail 'radius: Tokens.rounding.medium' 'radius: Tokens.rounding.extraLarge'

        # Lock screen fetch: extraLarge radius on the outer card only, title
        # "caelestia", no uptime line (BATT already only shows on laptops).
        substituteInPlace modules/lock/Fetch.qml \
          --replace-fail $'anchors.margins\n    radius: Tokens.rounding.medium' $'anchors.margins\n    radius: Tokens.rounding.extraLarge' \
          --replace-fail '"caelestiafetch.sh"' '"caelestia"' \
          --replace-fail 'items.push(`UP  : ''${SysInfo.uptime}`);' '// uptime line hidden'

        # Lock screen weather: upstream uses extraExtraLarge, every other lock
        # card is extraLarge -- match them.
        substituteInPlace modules/lock/WeatherInfo.qml \
          --replace-fail 'radius: Tokens.rounding.extraExtraLarge' 'radius: Tokens.rounding.extraLarge'

        # Session (power) panel GIF: clip it to a rounded rect so it matches the
        # session buttons above/below it.
        substituteInPlace modules/session/Content.qml \
          --replace-fail $'    AnimatedImage {\n        width: Tokens.sizes.session.button\n        height: Tokens.sizes.session.button\n        sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)\n\n        playing: visible\n        asynchronous: true\n        speed: Config.general.sessionGifSpeed\n        source: Paths.absolutePath(Config.paths.sessionGif)\n        fillMode: AnimatedImage.PreserveAspectFit\n    }' $'    StyledClippingRect {\n        width: Tokens.sizes.session.button\n        height: Tokens.sizes.session.button\n        radius: Tokens.rounding.largeIncreased\n\n        AnimatedImage {\n            anchors.fill: parent\n            sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)\n\n            playing: visible\n            asynchronous: true\n            speed: Config.general.sessionGifSpeed\n            source: Paths.absolutePath(Config.paths.sessionGif)\n            fillMode: AnimatedImage.PreserveAspectFit\n        }\n    }'

        # --- click-outside / Esc to close popouts, utilities, click-opened OSD ---
        # Stock HyprlandFocusGrab only covers dashboard / launcher / sidebar /
        # session. Extend it so the click-to-open surfaces from the vendored
        # Interactions.qml close the same way (click outside the shell, or Esc),
        # matching the dashboard. A key-triggered OSD (interactions.osdClicked
        # false) stays a non-modal transient.
        substituteInPlace modules/drawers/ContentWindow.qml \
          --replace-fail $'                return true;\n            return false;\n        }' $'                return true;\n            if (panels.popouts.hasCurrent || (s.utilities && conf.utilities.enabled) || (interactions.osdClicked && s.osd && conf.osd.enabled))\n                return true;\n            return false;\n        }' \
          --replace-fail $'            root.screenState.dashboard = false;\n            panels.popouts.hasCurrent = false;' $'            root.screenState.dashboard = false;\n            root.screenState.utilities = false;\n            root.screenState.osd = false;\n            panels.popouts.hasCurrent = false;'

      '';
    });
  };

  wayland.windowManager.hyprland = {
    enable = true;
    # Bootstrap is baked into the generation (it rarely changes). The topic
    # modules it require()s are out-of-store symlinks (see xdg.configFile), so
    # editing keybinds/variables/rules in ~/nix-dotfiles + `hyprctl reload` is
    # instant.
    extraConfig = builtins.readFile ./hypr/bootstrap.lua;
  };

  xdg.configFile = {
    # --- Hyprland (Lua, split by topic) ---
    "hypr/variables.lua".source        = link "hypr/variables.lua";
    "hypr/hyprland".source             = link "hypr/hyprland";
    "hypr/scheme/default.lua".source    = link "hypr/scheme/default.lua";
    "hypr/hyprtoolkit.conf".source      = link "hypr/hyprtoolkit.conf";

    # --- caelestia (shell/CLI settings + hypr override hooks + term sync) ---
    "caelestia/hypr-user.lua".source        = link "hypr/caelestia/hypr-user.lua";
    "caelestia/hypr-vars.lua".source        = link "hypr/caelestia/hypr-vars.lua";
    "caelestia/shell.json".source           = link "caelestia/shell.json";
    "caelestia/cli.json".source             = link "caelestia/cli.json";
    "caelestia/user-config.fish".source     = link "caelestia/user-config.fish";
    "caelestia/apply-term-scheme.py".source = link "caelestia/apply-term-scheme.py";

    # --- terminal stack (verbatim from arch-dotfiles) ---
    "fish".source         = link "fish";
    "foot".source         = link "foot";
    # tmux.conf is COPIED into the store (not an out-of-store symlink like the
    # rest). An out-of-store link here self-references: ~/.config/tmux/tmux.conf
    # -> ~/nix-dotfiles/tmux/tmux.conf, and since every entry under ~/.config/tmux
    # is HM-managed, HM collapses the dir to a single symlink back into the repo,
    # so the file ends up pointing at itself ("Too many levels of symbolic
    # links"). Copying breaks the cycle; edit + `nixos-rebuild switch` + prefix-r.
    "tmux/tmux.conf".source = ./tmux/tmux.conf;
    "starship.toml".source = link "starship.toml";
    "fastfetch".source    = link "fastfetch";
    "catppuccin".source   = link "catppuccin";

    # tmux plugins (arch installs these via TPM into ~/.config/tmux/plugins/;
    # here they come from nixpkgs and tmux.conf `run`s them directly, no TPM).
    # The catppuccin path matches the run line in tmux.conf: plugins/catppuccin/tmux/.
    "tmux/plugins/catppuccin/tmux".source = "${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin";
    "tmux/plugins/tmux-sensible".source   = "${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible";
    "tmux/plugins/tmux-yank".source       = "${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank";
    "tmux/plugins/tmux-resurrect".source  = "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect";
    "tmux/plugins/tmux-continuum".source  = "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum";

    # --- git (personal identity + per-dir work override) ---
    "git/config".source      = link "git/config";
    "git/config-work".source = link "git/config-work";

    # --- other tools ---
    "yazi".source   = link "yazi";
    "swappy".source = link "swappy";
    "nvim".source   = link "nvim";

    # Wallpapers / avatar / session gif. All the configs (shell.json,
    # CAELESTIA_WALLPAPERS_DIR, fastfetch logo) hardcode ~/.config/images/*.
    "images".source = link "images";
  };

  # "Terminals follow the color scheme" — ported from arch-dotfiles
  # systemd/user/caelestia-term-scheme.{path,service}. Dark-mode only, tmux-safe.
  systemd.user.services.caelestia-term-scheme = {
    Unit.Description = "Apply caelestia scheme to terminals (dark-only, tmux-safe)";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 %h/.config/caelestia/apply-term-scheme.py";
      Environment = [ "PATH=${lib.makeBinPath [ pkgs.tmux pkgs.coreutils ]}" ];
    };
  };
  systemd.user.paths.caelestia-term-scheme = {
    Unit.Description = "Watch caelestia scheme.json for theme changes";
    Path.PathChanged = "%h/.local/state/caelestia/scheme.json";
    Install.WantedBy = [ "default.target" ];
  };

  # GUI polkit authentication prompts (pkexec, mounting, etc.)
  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland Polkit authentication agent";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # Cursor theme referenced by hypr/variables.lua (cursorTheme / cursorSize).
  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
  };

  # Icon theme. caelestia's dconf default is "Papirus-Dark" but the package was
  # never installed, so themed tray icons (e.g. fcitx5's "input-keyboard-symbolic")
  # fell back to bare hicolor and rendered as the missing-image checkerboard.
  # gtk.iconTheme.package is added to home.packages and the name is pushed to
  # dconf (org.gnome.desktop.interface icon-theme), which quickshell reads.
  #
  # GTK theme. arch-dotfiles packages/pacman.txt pulls in `adw-gtk-theme`
  # (= adw-gtk3): caelestia's generated ~/.config/gtk-3.0/gtk.css only sets
  # libadwaita colour tokens (@define-color window_bg_color ...), which the
  # GTK3 built-in Adwaita theme ignores — you get half-styled "classic" widgets
  # (fat non-symbolic toolbar, light chrome). adw-gtk3 is the GTK3 port that
  # actually reads those tokens, so Thunar etc. match the shell.
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # Tell GTK4/libadwaita apps to use the dark variant too (caelestia is
  # dark-only). The gtk module already pushes gtk-theme / icon-theme to
  # org/gnome/desktop/interface via dconf; color-scheme isn't covered.
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  # arch-dotfiles user-dirs.dirs defined only these three.
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    download = "${config.home.homeDirectory}/Downloads";
    pictures = "${config.home.homeDirectory}/Pictures";
    videos = "${config.home.homeDirectory}/Videos";
  };

  # Minimal default-app wiring (arch-dotfiles mimeapps.list, trimmed to apps we
  # actually install here).
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "thunar.desktop";
      "text/plain" = "nvim.desktop";
      "application/json" = "nvim.desktop";
      "application/x-shellscript" = "nvim.desktop";
      "text/html" = "chromium-browser.desktop";
      "x-scheme-handler/http" = "chromium-browser.desktop";
      "x-scheme-handler/https" = "chromium-browser.desktop";
      "x-scheme-handler/about" = "chromium-browser.desktop";
      "x-scheme-handler/unknown" = "chromium-browser.desktop";
    };
  };

  # Hide the per-component LibreOffice launchers from the app launcher; keep
  # only the "LibreOffice" Start Center (startcenter.desktop). Same-named files
  # in $XDG_DATA_HOME/applications shadow the package's entries. (Done as raw
  # dataFile rather than xdg.desktopEntries: the latter also injects the entry
  # into home.packages, which collides with libreoffice's own math.desktop etc.
  # in the profile buildEnv.)
  xdg.dataFile = lib.genAttrs
    (map (id: "applications/${id}.desktop")
      [ "base" "calc" "draw" "impress" "math" "writer" ])
    (name: {
      text = ''
        [Desktop Entry]
        Type=Application
        NoDisplay=true
        Name=${lib.removeSuffix ".desktop" (baseNameOf name)}
      '';
    });

  home.packages = with pkgs; [
    # browsers / terminals / file managers (referenced by hypr keybinds)
    chromium          # vars.browser
    foot              # vars.terminal + yazi bind
    yazi              # ALT+E
    ffmpegthumbnailer poppler-utils imagemagick ueberzugpp  # yazi previews
    tmux
    p7zip            # 7z / 7za / 7zr (archives; yazi extract + general use)

    # office suite
    libreoffice      # Writer / Calc / Impress etc.

    # chat
    # Discord client with bundled Vencord. caelestia themes it automatically: on
    # every scheme change the shell runs `caelestia wallpaper` / `caelestia
    # scheme set`, whose apply_colours() step compiles the "Midnight" Vencord
    # theme (keyed to the current scheme colours) and writes it to
    # ~/.config/vesktop/themes/caelestia.theme.css. The caelestia CLI already
    # bundles dart-sass for that, so nothing else is needed here. Enable it once
    # in Vesktop: Settings -> Vencord -> Themes -> tick "caelestia.theme.css".
    vesktop

    # shell stack (fish/config.fish + starship.toml + fastfetch + catppuccin)
    fish
    starship
    fastfetch
    eza bat fd ripgrep fzf zoxide direnv fnm
    btop              # `caelestia toggle sysmon` / rules.lua special:sysmon
    tuxedo            # keyboard-driven TUI/CLI for todo.txt (`tuxedo`)
    qt6Packages.fcitx5-configtool # launcher / hidden-apps entry

    # Icon theme: Papirus-Dark (set in gtk.iconTheme above) + breeze-icons for
    # the -symbolic names Papirus inherits but doesn't ship (Papirus-Dark
    # Inherits=breeze-dark,hicolor; papirus-icon-theme only propagates breeze's
    # -dev output, which has no icons). Without this, fcitx5's tray icon
    # "input-keyboard-symbolic" doesn't resolve and renders as a broken image.
    kdePackages.breeze-icons

    # hypr keybinds + execs.lua helpers
    hyprpicker        # SUPER+SHIFT+P
    fuzzel            # caelestia clipboard/emoji pickers
    cliphist          # clipboard history backend
    wl-clipboard      # wl-copy / wl-paste
    libnotify         # notify-send (test-notification bind)
    brightnessctl     # brightness keys
    pavucontrol       # audio settings
    trash-cli         # `trash-empty 30` in execs.lua
    bluez             # bluetoothctl + mpris-proxy in execs.lua
    grim slurp swappy # screenshots + swappy editor

    # neovim / LazyVim runtime deps. LSP servers are kept here (Mason's
    # downloaded binaries often don't run against the Nix loader); formatters /
    # linters are left to Mason, so it gets its build deps: go + unzip.
    gcc gnumake nodejs_22 tree-sitter lazygit
    lua-language-server
    prettier
    go unzip

    # JS package managers
    pnpm
    yarn              # classic 1.x; `yarn set version berry` per-project for v2+
  ];
}
