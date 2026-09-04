# nix-dotfiles

NixOS (flake) + [caelestia shell](https://github.com/caelestia-dots/shell) +
Hyprland.

A full graphical system in one `nixos-rebuild`: Hyprland (Lua config), the
caelestia bar/launcher/lock, a themed terminal stack (fish + foot + tmux +
starship + fastfetch), yazi, LazyVim, fcitx5 (Vietnamese), PipeWire, Bluetooth,
and a text-mode greeter.

---

## What hardware this is tuned for

Some of `configuration.nix` is specific to **this** box. On identical hardware it
applies verbatim; on anything else, review the [machine-specific knobs](#3-review-the-machine-specific-knobs)
before the first build.

| | |
|---|---|
| GPU | NVIDIA GeForce GT 730 (GK208B, Kepler) on **nouveau** — no reclocking, kernel too new for `nvidia-470` |
| Display | HDMI monitor with **no EDID** → console mode is pinned in `boot.kernelParams` |
| Disk | dual-boot with Windows; **96 MiB ESP shared** with the Windows bootloader |
| CPU | Intel (`kvm-intel`) |
| Keyboard | Apple-clone wireless (`hid_apple`, `fnmode=2` so F1–F12 are plain function keys) |
| Boot | GRUB (EFI), `systemd-boot` disabled, scripted initrd (systemd initrd is too big for the ESP) |

---

## Fresh install

Assumes a machine that already has (or will get) a minimal NixOS install and an
EFI System Partition. If you're dual-booting Windows, install Windows **first**
so it owns the ESP, then shrink a partition for Linux.

### 1. Boot the NixOS installer, partition, mount

Reproduce this layout (adjust device names; UUIDs will differ and are captured
in step 4):

| Mount | FS | Notes |
|---|---|---|
| `/boot` | vfat | the EFI System Partition — **reuse Windows' ESP** when dual-booting, else make one ≥512 MiB (this repo squeezes into 96 MiB, which needs the initrd tuning already in `configuration.nix`) |
| `/` | ext4 | root |
| `/home` | ext4 | separate partition (optional but this config assumes it) |
| `/data` | ext4 | extra data disk, label `nixos-data` (optional — remove the mount from `hardware-configuration.nix` and the `/mnt/data` tmpfiles rule if absent) |
| swap | — | 16 GiB **swapfile** at `/swapfile`, created automatically by `swapDevices` |

```sh
# example — YOUR device names will differ
mkfs.ext4 -L nixos /dev/sdaX
mkfs.ext4 -L home  /dev/sdaY
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot /mnt/home
mount /dev/disk/by-label/home /mnt/home
mount /dev/disk/by-uuid/<ESP-UUID> /mnt/boot      # existing Windows ESP, or a fresh one
```

### 2. Enable flakes in the installer and clone

```sh
nix-shell -p git nixVersions.stable

git clone <this-repo-url> /mnt/etc/nixos-dotfiles
# (final home is ~/nix-dotfiles after first boot — see step 6)
```

### 3. Review the machine-specific knobs

Open `configuration.nix` and check these against the new machine:

| Setting | Line(s) | Change if… |
|---|---|---|
| `networking.hostName = "nixos"` | ~98 | you want a different hostname (**also rename `nixosConfigurations.nixos`** in `flake.nix`) |
| `networking.hosts` in **`local.nix`** | — | internal `/etc/hosts` entries (placeholder in the repo) — set yours or blank the attrs; then `git update-index --skip-worktree local.nix` |
| `boot.loader.grub` + 96 MiB ESP tuning (`initrd.systemd.enable = mkForce false`, `configurationLimit`, locale strip) | ~40–96 | your ESP is roomy → you can drop all of it and use `boot.loader.systemd-boot.enable = true` instead |
| `video=HDMI-A-1:1920x1080@60` | ~149 | your monitor gives EDID, or a different output name (`nvidia`/`amdgpu` users: usually remove) |
| `nouveau.config=NvClkMode=0xf` | ~132 | not an nvidia/nouveau GPU → remove |
| `boot.extraModprobeConfig` — `hid_apple fnmode=2` | ~192 | not an Apple-style keyboard → remove |
| `boot.kernelModules = [ "kvm-intel" ]` | in `hardware-configuration.nix` | AMD CPU → `kvm-amd` (regenerated in step 4 anyway) |
| `time.timeZone`, `i18n` | ~109 | different locale / timezone |
| `i18n.inputMethod` (fcitx5 + Unikey) | ~116 | don't need Vietnamese input → remove the block |
| GPU stack | `hardware.graphics`, no `services.xserver.videoDrivers` | nvidia proprietary / amdgpu → add the relevant driver + `hardware.nvidia` options |

`system.stateVersion` / `home.stateVersion` are **`26.05`** — leave them, even on
a newer NixOS. They pin defaults, not the package set.

### 4. Regenerate `hardware-configuration.nix`

The committed one has **this machine's disk UUIDs** — you must replace it:

```sh
nixos-generate-config --root /mnt --show-hardware-config > /mnt/etc/nixos-dotfiles/hardware-configuration.nix
```

Then re-add anything you want to keep from the old one (the `/data` mount is the
only non-generated part here — drop it if you have no data disk).

### 5. First build — install the whole system

```sh
cd /mnt/etc/nixos-dotfiles
git add -A                          # the flake only sees tracked/staged files
nixos-install --flake .#nixos       # use your hostname if you renamed it
# set the root password when prompted
```

Reboot into the new system.

### 6. Put the repo where the flake expects it

`home.nix` hard-codes `repo = "${config.home.homeDirectory}/nix-dotfiles"` for
the out-of-store symlinks. After first boot, as your user:

```sh
sudo passwd campbells               # your login password (users are mutable; not in the config)
mv /etc/nixos-dotfiles ~/nix-dotfiles && sudo chown -R campbells:users ~/nix-dotfiles
# from now on:
sudo nixos-rebuild switch --flake ~/nix-dotfiles#nixos
```

Log out; the greeter offers Hyprland automatically.

---

## Post-install manual steps

Not expressible in the flake:

### SSH keys (not in the repo — set up per machine)

`~/.ssh/config` and the private keys live **outside** this repo. Recreate:

```sh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/github_personal -C "personal"
ssh-keygen -t ed25519 -f ~/.ssh/gitlab_work    -C "work"
```

`~/.ssh/config` — one host block per remote, each pinned to its own key
(`IdentitiesOnly yes` stops ssh from offering the wrong one):

```sshconfig
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_personal
    IdentitiesOnly yes

Host git.example.internal          # your work git server
    HostName git.example.internal
    User git
    IdentityFile ~/.ssh/gitlab_work
    IdentitiesOnly yes
```

Add the `.pub` keys to GitHub / the work server. Switch each repo's remote to
SSH so pushes use the right key.

### Git identity

`git/config` (personal, default) and `git/config-work` are symlinked to
`~/.config/git/` by `home.nix`. Repos under `~/Workspaces/finepro/` pick up the
work email via `includeIf`. **In the published repo the emails are placeholders**
— set your real ones locally after cloning, or keep them out of a public repo by
adding `git/config-work` to `.gitignore`.

### Machine-local Hyprland tweaks (optional)

`hypr/caelestia/hypr-user.lua` does `pcall(require, "hypr-user-local")`. For
per-machine binds/monitor quirks that shouldn't be committed, create
`~/.config/caelestia/hypr-user-local.lua`:

```lua
-- example: launch a game only present on this machine
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd([[...]]))
```

### tmux plugins

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

then open tmux and press `prefix + I` (`prefix` = `Ctrl+s`). (Plugins also come
from nixpkgs via `home.nix` and are `run` directly, so this is only for TPM-only
extras.)

### neovim / LazyVim

First `nvim` launch clones `lazy.nvim` and all plugins (needs network).
`lazy-lock.json` is committed, so `:Lazy restore` reproduces exact versions.

**Mason binaries mostly don't run on NixOS.** `programs.nix-ld` is enabled, which
makes many of them work; still, LSP servers are provided from nixpkgs via
`home.packages` (`lua-language-server`, `prettier`, `nodejs`, `tree-sitter`,
`gcc`, …). Add more there rather than via `:Mason`. `blink.cmp` is pinned to a v1
tag in `lazy-lock.json` (v2 needs a `blink.lib` plugin LazyVim doesn't ship yet).

### yazi plugins / flavor

```sh
ya pkg install        # reads yazi/package.toml
```

### Bluetooth

`bluetoothctl` — no GUI manager is installed; the caelestia bar toggles/connects
over DBus. Pair devices once with `bluetoothctl` (`scan on`, `pair`, `trust`,
`connect`).

### fcitx5 (Vietnamese input)

Toggle with `Ctrl+Space`. `fcitx5-configtool` to remap. It's launched from
`hypr/hyprland/execs.lua` (Hyprland-from-TTY ignores XDG autostart).

---

## Layout

| Path | What |
|---|---|
| `flake.nix` / `flake.lock` | inputs: nixpkgs (unstable), home-manager, caelestia-shell |
| `configuration.nix` | system: boot/grub, network, audio (pipewire), bluetooth, fonts, fcitx5, thunar, hyprland, nix-ld, greetd + tuigreet |
| `hardware-configuration.nix` | generated by the installer — **machine specific**, regenerate on a new box |
| `local.nix` | machine-local system config (internal `networking.hosts`, per-box tweaks) — imported by `configuration.nix`, committed with placeholders |
| `home.nix` | Home Manager: caelestia, hyprland wiring, cursor, term-scheme sync, out-of-store symlinks, user packages |
| `hypr/bootstrap.lua` | appended to the HM-generated `hyprland.lua`; `require`s the modules below |
| `hypr/hyprland/*.lua` | env, general, input, misc, animations, decoration, group, execs, rules, gestures, keybinds |
| `hypr/variables.lua` | apps + keybind definitions (edit this to rebind things) |
| `hypr/hyprtoolkit.conf` | hyprtoolkit palette |
| `hypr/scheme/default.lua` | fallback Material palette (caelestia writes `scheme/current.lua` at runtime) |
| `hypr/caelestia/hypr-{vars,user}.lua` | user overrides loaded from `~/.config/caelestia/` |
| `caelestia/` | shell/CLI settings (`shell.json`, `cli.json`) + `apply-term-scheme.py` |
| `git/` | `config` (personal identity) + `config-work` (`includeIf` for `~/Workspaces/finepro/`) |
| `fish/`, `foot/`, `tmux/`, `starship.toml`, `fastfetch/` | terminal stack (verbatim from arch-dotfiles) |
| `catppuccin/` | palette source (`mocha.conf`) + starship/tmux generators |
| `yazi/`, `swappy/`, `nvim/` | file manager, screenshot editor, LazyVim config |
| `images/` | wallpapers + avatar + session gif |

### Out-of-store symlinks

`hypr/hyprland/`, `hypr/variables.lua`, `hypr/hyprtoolkit.conf`, the
`caelestia/*` files, `git/*`, and the whole terminal stack (`fish/ foot/ tmux/
starship.toml fastfetch/ catppuccin/ yazi/ swappy/ nvim/`) plus `images/` are
symlinked **out of the nix store** into `~/.config`. Editing them here takes
effect immediately (`hyprctl reload` for Hyprland; new shell for fish/foot;
`prefix r` for tmux) — no rebuild needed. `bootstrap.lua`, all `*.nix`, and
package changes need a rebuild.

Files the flake deliberately does **not** track (they're runtime state or
machine-local): `hypr/scheme/current.lua`, `fish/fish_variables`,
`fish/fish_history`, `tmux/plugins/`, `yazi/{flavors,plugins}/`,
`nvim/.luarc.json`, `~/.config/caelestia/hypr-user-local.lua`, `~/.ssh/*`.

---

## Daily use

```sh
git add -A                                     # the flake only sees tracked/staged files
sudo nixos-rebuild switch --flake ~/nix-dotfiles#nixos
hyprctl reload                                 # pick up hypr config changes
```

Update inputs (nixpkgs, home-manager, caelestia):

```sh
nix flake update --flake ~/nix-dotfiles
sudo nixos-rebuild switch --flake ~/nix-dotfiles#nixos
```

### Roll back

```sh
sudo nixos-rebuild switch --rollback     # previous generation
sudo nix-env -p /nix/var/nix/profiles/system --list-generations
```

The 96 MiB ESP only fits **one** GRUB generation (`configurationLimit = 1`), so
`--rollback` is the recovery path, not the boot menu. If the ESP wedges at 100%:
`sudo rm -f /boot/kernels/*.tmp`, remove the orphaned old initrd, then
`sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot`.

### Housekeeping

```sh
sudo nix-collect-garbage -d
nix-collect-garbage -d
```

---

## Login

`services.greetd` + `tuigreet` — a text-mode console greeter, no compositor of
its own. It launches Hyprland via a small wrapper (`start-hyprland`, Hyprland's
official watchdog launcher) that also redirects startup output to
`~/.local/share/hyprland/session.log`.

SDDM + the vendored SilentSDDM theme were tried but abandoned: SDDM's greeter
needs its own Wayland compositor, and on this nouveau card (no reclocking, no
EDID on the HDMI monitor) both weston (needs atomic modesetting) and kwin
glitched the display. Hyprland itself drives the GPU fine, so a greeter that
doesn't touch the GPU is the reliable choice.

- Boot is a **silent black screen** until the greeter: kernel/initrd/systemd
  output is routed to VT 2 (`console=tty2`), VT 1 stays black. Something hung?
  `Ctrl+Alt+F2` to read it.
- nouveau mode is pinned via `boot.kernelParams` (`video=HDMI-A-1:1920x1080@60`)
  because the monitor exposes no EDID. Change it there if the monitor differs.
