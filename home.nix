{ config, pkgs, lib, inputs, ... }:

let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  # This repo must live here for the out-of-store symlinks below to resolve.
  repo = "${config.home.homeDirectory}/nix-dotfiles";
in
{
  home.username = "campbells";
  home.homeDirectory = "/home/campbells";
  home.stateVersion = "26.05";

  imports = [ inputs.caelestia-shell.homeManagerModules.default ];

  programs.caelestia = {
    enable = true;
    cli.enable = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    # Bootstrap is baked into the generation (it rarely changes). The topic
    # modules it require()s are out-of-store symlinks (see xdg.configFile), so
    # editing keybinds/variables in ~/nix-dotfiles + `hyprctl reload` is instant.
    extraConfig = builtins.readFile ./hypr/bootstrap.lua;
  };

  xdg.configFile = {
    "hypr/variables.lua".source      = mkOutOfStoreSymlink "${repo}/hypr/variables.lua";
    "hypr/hyprland".source           = mkOutOfStoreSymlink "${repo}/hypr/hyprland";
    "hypr/scheme/default.lua".source = mkOutOfStoreSymlink "${repo}/hypr/scheme/default.lua";
    "caelestia/hypr-user.lua".source = mkOutOfStoreSymlink "${repo}/hypr/caelestia/hypr-user.lua";
    "caelestia/hypr-vars.lua".source = mkOutOfStoreSymlink "${repo}/hypr/caelestia/hypr-vars.lua";
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
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
  };

  home.packages = with pkgs; [
    kitty
    google-chrome

    # Apps and helpers referenced by the ported Hyprland keybinds
    foot          # terminal (vars.terminal, yazi bind)
    chromium      # browser (vars.browser)
    yazi          # terminal file manager (ALT+E)
    hyprpicker    # colour picker (SUPER+SHIFT+P)
    fuzzel        # used by caelestia clipboard/emoji pickers
    cliphist      # clipboard history backend
    wl-clipboard  # wl-copy / wl-paste
    libnotify     # notify-send (test-notification bind)
    brightnessctl # brightness keys
    pavucontrol   # audio settings
  ];
}
