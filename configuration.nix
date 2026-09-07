# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  # greetd session launcher: redirect Hyprland's startup output to a log file
  # instead of the VT (so login is just a black screen until the caelestia shell
  # paints), and start it via start-hyprland — Hyprland's official watchdog
  # launcher, which sets the session up properly (no "launched improperly" warnings).
  hyprSession = pkgs.writeShellScript "hypr-session" ''
    mkdir -p "$HOME/.local/share/hyprland"
    exec >>"$HOME/.local/share/hyprland/session.log" 2>&1
    exec ${config.programs.hyprland.package}/bin/start-hyprland
  '';

  # GRUB background: the avatar centred on a 1080p black canvas, replacing the
  # stock NixOS gradient+logo that GRUB paints for the split second it runs
  # (timeout = 0). Built from the source PNG so only that one image lives in the
  # repo. `null` here instead would give a plain black GRUB screen.
  grubSplash = pkgs.runCommand "grub-splash.png" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    # 8-bit, stripped: GRUB's png module rejects 16-bit depth and chokes on
    # oversized files.
    magick -size 1920x1080 xc:black \
      \( ${./images/avatar/avatar.png} -resize 512x512 \) -gravity center -composite \
      -depth 8 -strip $out
  '';
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Machine-local config (internal /etc/hosts, per-box tweaks). Tracked with
      # placeholders; real values are kept via `git update-index --skip-worktree`.
      ./local.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.timeout = 0;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    # arch-dotfiles etc/default/grub had GRUB_DISABLE_OS_PROBER=false, but
    # os-prober during bootloader install is a common switch failure. There *is*
    # a Windows install on sdb3, but it's booted from the firmware menu, not
    # GRUB — leave this off unless you want it in the GRUB menu (and have ESP
    # room for the probe).
    useOSProber = false;

    # The ESP is only 96 MiB and shared with the Windows bootloader. Drop GRUB's
    # menu translations (~5 MiB) on every install — the menu just shows in
    # English, which is what it does here anyway. Absolute path: this string is
    # appended to install-grub.sh, which runs under systemd-run with a bare PATH.
    extraInstallCommands = "${pkgs.coreutils}/bin/rm -rf /boot/grub/locale";

    # Replace the stock NixOS gradient/logo GRUB paints on its way through.
    splashImage = grubSplash;
  };
  boot.loader.efi = {
    efiSysMountPoint = "/boot";
    canTouchEfiVariables = true;
  };

  # nixos-unstable now defaults boot.initrd.systemd.enable to true, which drags
  # systemd + openssl (libcrypto ~8.6M) + tpm2-tss + lvm2/cryptsetup tooling into
  # the initrd — ~44 MiB compressed, 82 MiB unpacked, of which only ~3 MiB is the
  # kernel modules this box actually needs. This machine is plain ext4 with no
  # LUKS / LVM / RAID / TPM, so the classic scripted stage-1 initrd does the
  # identical job at ~25 MiB (~32 MiB once Plymouth is folded in, below). That
  # difference is what keeps the 96 MiB ESP (shared with the Windows bootloader +
  # GRUB) usable: a switch briefly holds the old initrd + the new one, and
  # 2x44 MiB + kernel + GRUB overflows it — so *every* initrd-changing
  # `nixos-rebuild` was dying with "No space left on device" / "Failed to install
  # bootloader".
  #   NOTE: the scripted initrd is deprecated (warned since 26.05, slated for
  #   removal "in 26.11"). When it finally goes: trim the systemd initrd
  #   (boot.initrd.systemd.tpm2.enable = false + compressor = "xz" got it to
  #   ~35 MiB in testing) or enlarge the ESP.
  boot.initrd.systemd.enable = lib.mkForce false;

  # Silent black boot. No Plymouth — it can't grab the framebuffer on this
  # nouveau card early enough to actually paint (the avatar never showed), so it
  # was pure initrd weight. Instead:
  #   - boot.initrd.verbose = false      → no "<<< NixOS Stage 1 >>>" / "starting
  #                                         device mapper and LVM" from stage-1
  #   - console=tty2 (kernelParams below) → the kernel, the scripted initrd's
  #     systemd-udevd, and systemd's own status all write to VT 2. VT 1 — the one
  #     the monitor shows, and where greetd/tuigreet then paints — never receives
  #     any of it, so it stays black from power-on until the greeter.
  #   - rd.udev.log_level=3 / udev.log_level=3 → belt-and-braces, in case tty1 is
  #     ever the console again.
  # Trade-off: a boot that hangs or panics shows nothing on the main screen;
  # switch to VT 2 with Ctrl+Alt+F2 to read it.
  boot.initrd.verbose = false;

  networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Static /etc/hosts entries for internal services live in ./local.nix
  # (networking.hosts) so the real addresses stay out of the published repo.

  # Set your time zone.
  time.timeZone = "Asia/Ho_Chi_Minh";
  i18n.defaultLocale = "en_US.UTF-8";

  # Vietnamese input method (fcitx5 + Unikey). Toggle with Ctrl+Space by default;
  # run `fcitx5-configtool` to remap. GTK/Qt/Wayland frontends are wired in.
  # The module sets env vars + an XDG autostart file; Hyprland-from-TTY ignores
  # XDG autostart, so fcitx5 is actually launched from hypr/hyprland/execs.lua.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        qt6Packages.fcitx5-unikey
        fcitx5-gtk
      ];
    };
  };

  # Kernel cmdline. First entry keeps nouveau on a sane clock; the rest are
  # ported from arch-dotfiles etc/default/grub (GRUB_CMDLINE_LINUX_DEFAULT):
  # quiet boot + no hardware watchdog + no console cursor on the TTYs.
  boot.kernelParams = [
    "nouveau.config=NvClkMode=0xf"
    "loglevel=3"
    "quiet"
    "systemd.show_status=false"
    "nowatchdog"
    "nmi_watchdog=0"
    "vt.global_cursor_default=0"
    # Silent black boot (see the boot.initrd.verbose comment above): send every
    # console writer — kernel, scripted-initrd udevd, systemd status — to VT 2,
    # so VT 1 (shown on the monitor, then painted by greetd) stays black the
    # whole way. Ctrl+Alt+F2 to see boot output if something goes wrong.
    "console=tty2"
    "rd.udev.log_level=3"
    "udev.log_level=3"
    # The HDMI monitor exposes no EDID, so nouveau (no reclocking on this card)
    # guesses modes and can pick one the monitor rejects ("input not supported").
    # Pin a known-good progressive mode for the console + Wayland compositors.
    "video=HDMI-A-1:1920x1080@60"
  ];
  # Keep the boot screen quiet: NixOS appends loglevel=4 (shows err+warning), so
  # harmless noise like dbus "Ignoring duplicate name" and "SGX disabled by BIOS"
  # ends up on the console. 3 = only crit/alert/emerg on screen (full log stays
  # in journalctl).
  boot.consoleLogLevel = 3;
  # `nowatchdog` + `nmi_watchdog=0` above only kill the soft-lockup / NMI
  # detector — the hardware watchdog drivers (iTCO_wdt, and on this kernel the
  # newer intel_oc_wdt) still load and register /dev/watchdog0. On reboot
  # systemd-shutdown arms that device as a "reset the box if the reboot hangs"
  # net, then closes it just before rebooting; intel_oc_wdt has no working
  # stop / magic-close, so the kernel prints
  #   watchdog: watchdog0: watchdog did not stop!
  # at KERN_CRIT — loud enough to get past loglevel=3 — right as the screen
  # should be going black. poweroff is unaffected: systemd only arms the
  # watchdog for reboot/kexec, never for power-off. Tell it not to:
  systemd.watchdog.rebootTime = "0";
  # (arch-dotfiles blacklisted the iTCO_wdt modules instead; that works too —
  # boot.blacklistedKernelModules = [ "intel_oc_wdt" "iTCO_wdt"
  # "iTCO_vendor_support" ] — but this is the smaller change and leaves the
  # initrd / the 96 MiB ESP untouched.)

  # The ESP is tiny (96 MiB, shared with Windows). A generation is ~46 MiB
  # (13.6 MiB kernel + ~32 MiB initrd-with-Plymouth); GRUB + fonts + the Windows
  # bootloader are ~14 MiB. A switch transiently holds the outgoing generation's
  # initrd + the incoming one (the kernel is one shared file while the version
  # matches), so the peak is ~2x32 + 13.6 + 14 ≈ 92 MiB — it fits, but barely.
  # limit=2 would need a third initrd on disk and overflows ("No space left on
  # device" / "Failed to install bootloader"). So: one generation only, and a
  # rebuild that ALSO bumps the kernel version can still tip over — if it does,
  # `rm /boot/kernels/*.tmp` + the old initrd, then
  # `sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot`.
  # Rollback is still possible with `nixos-rebuild switch --rollback`.
  boot.loader.grub.configurationLimit = 1;

  # The wireless keyboard ("USB Dongle", VID 05AC / Apple clone, PID 024F) binds
  # to hid_apple, whose default fnmode=auto makes the top row send media / XF86
  # keys (F1/F2 = brightness, F7-F12 = playback/volume, etc.) and requires Fn for
  # real F1-F12. fnmode=2 ("fkeysfirst") flips that: F1-F12 are plain function
  # keys, hold Fn for the media actions. hid_apple can load in the initrd, so
  # this goes in modprobe.d (picked up there too); a live change without a
  # rebuild is `echo 2 | sudo tee /sys/module/hid_apple/parameters/fnmode`.
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';

  swapDevices = [{
    device = "/swapfile";
    size = 16384;
  }];

  # NOTE: the ext4 data disk (partition 23193f60-…, label "nixos-data") is
  # already mounted at /data by hardware-configuration.nix. There used to be a
  # second fileSystems."/mnt/data" entry here pointing at the SAME partition, so
  # systemd tried to mount it twice and intermittently failed local-fs.target →
  # emergency mode on boot. Removed. /mnt/data is kept as a symlink to /data for
  # anything that still references that path.
  systemd.tmpfiles.rules = [
    "d /mnt 0755 root root -"
    "L+ /mnt/data - - - - /data"
  ];

  # Audio: full PipeWire stack (replaces the arch pipewire/pipewire-pulse/-jack/
  # -alsa packages). The caelestia bar's volume widget + pavucontrol need this.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Bluetooth (arch: bluez + bluez-utils). The caelestia bar's status icon talks
  # to BlueZ over DBus directly for toggle / connect; no GUI manager (blueman) is
  # installed. mpris-proxy (started from hypr execs.lua) ships with bluez.
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # 32-bit graphics libraries, needed by many Wine apps/games.
  hardware.graphics.enable32Bit = true;

  # Secret storage (arch: gnome-keyring). Unlocked at login via the greetd PAM stack.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.campbells = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.fish;
  };

  # fish is the login shell (arch-dotfiles: chsh -s /usr/bin/fish). Enabling it
  # here registers it in /etc/shells and installs system-wide completions.
  # The actual config is an out-of-store symlink from home.nix (xdg.configFile).
  programs.fish.enable = true;

  # nix-ld: run unpatched, dynamically-linked "generic Linux" executables
  # (Mason LSP/formatter downloads, pnpm's @biomejs/cli-linux-x64, etc.) that
  # would otherwise fail with "cannot run dynamically linked executable".
  programs.nix-ld.enable = true;

  programs.hyprland.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  # Thunar file manager (bound to a Hyprland keybind) + thumbnails / trash / mounts.
  programs.thunar.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Login: greetd + tuigreet — a console greeter that renders as text in the VT,
  # with no Wayland/X compositor of its own. SDDM's greeter needs a compositor
  # (weston needs atomic modesetting; kwin still glitched on this nouveau card),
  # so it's dropped entirely. Hyprland itself drives nouveau fine.
  #   --user campbells : pre-fill the username, so only the password is typed
  #   --cmd ${hyprSession} : see the hyprSession launcher in the `let` above
  # No --time: the config below strips everything except the prompt box.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${lib.getExe pkgs.tuigreet} --asterisks --user campbells --cmd ${hyprSession}";
      user = "greeter";
    };
  };

  # tuigreet (0.11 fork) reads /etc/tuigreet/config.toml before the CLI flags.
  # Strip the greeter down to just the username + password box: no clock, no
  # form title, no bottom status bar (F-key hint legend, session / caps-lock
  # indicators). The F2 (command) / F3 (sessions) / F12 (power) menus still
  # work — they're only hidden from view.
  environment.etc."tuigreet/config.toml".text = ''
    [display]
    show_time = false
    show_title = false

    [layout.widgets]
    time_position = "hidden"
    status_position = "hidden"
  '';

  # Fonts referenced by the caelestia shell, the Hyprland config and foot.ini
  # (FiraCode Nerd Font).
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    figtree            # UI font the caelestia Vesktop/Midnight theme asks for
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs; [
    neovim git wget
    claude-code
    wineWowPackages.stable  # Wine with both 32-bit and 64-bit support
    winetricks
  ];
  environment.variables.EDITOR = "nvim";
  environment.variables.VISUAL = "nvim";

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
