# dotnix

NixOS configuration for my Linux laptop. A single, heavily commented
`configuration.nix` targeting **NixOS 25.11 stable**, designed to mirror
the macOS environment in [singhc7/.mac](https://github.com/singhc7/.mac)
so the shell, terminal, editor, and tooling feel identical on either
side.

## Overview

| | |
|---|---|
| **Channel** | `nixos-25.11` (stable) |
| **Desktop** | GNOME on Wayland (GDM) |
| **Shell** | zsh + Powerlevel10k + Antidote |
| **Terminal** | Kitty |
| **Editor** | Neovim (kickstart-based) |
| **Multiplexer** | tmux |
| **File manager** | nnn (built with `O_NERD`) |

**What's enabled out of the box:** flakes, weekly garbage collection,
auto-optimise-store, zram swap, systemd-oomd, fstrim, TLP for laptop
power, Bluetooth, Nerd Fonts, GNOME bloat trimming, Syncthing,
`nix-ld` + Mason toolchain (Node, Python, Go, Cargo, JDK), and the
nixpkgs contributor toolkit (`nixpkgs-review`, `nix-update`, `nurl`,
`nix-init`, `nixfmt-rfc-style`, `statix`, `deadnix`, `nil`, …).

**What's wired up but commented:** Tailscale, Avahi/mDNS, Blueman,
auto-cpufreq, latest mainline kernel, GnuPG agent, Flatpak, Podman,
Docker, libvirt, Borg backups, GNOME extensions, extra GUI apps,
extra language toolchains. Each block has a one-paragraph note
describing what it does and the tradeoff before flipping it on.

## Layout

```
.
├── configuration.nix    # Single source of truth — every option commented
├── LICENSE              # GNU AGPL-3.0
└── README.md
```

`hardware-configuration.nix` is **not** tracked. It is generated on
each target machine by `nixos-generate-config` and is hardware-specific
(disk UUIDs, CPU microcode module, kernel modules for the boot
process). It lives alongside `configuration.nix` in `/etc/nixos/`
on the target box.

## Deployment

On the target NixOS machine:

```sh
# Plain copy
sudo cp configuration.nix /etc/nixos/configuration.nix
sudo nixos-rebuild switch

# Or symlink so `git pull` updates the active config
sudo ln -sf "$PWD/configuration.nix" /etc/nixos/configuration.nix
sudo nixos-rebuild switch
```

After the rebuild, set zsh as the active shell with `chsh -s $(which zsh)`
(the user already has `shell = pkgs.zsh` declared, but interactive
`chsh` finalises it on existing sessions).

## Companion dotfiles

Pairs with [singhc7/.mac](https://github.com/singhc7/.mac), stowed
into `$HOME` exactly as on macOS. Two source paths in
`~/.config/zsh/.zshrc` need adjusting on NixOS — see the comment
block next to `zsh-powerlevel10k` in `configuration.nix` for the
exact replacements (Antidote and Powerlevel10k live under the
nix store, not `~/.antidote` or `$(brew --prefix)`).

## Release upgrades

The config is pinned to `nixos-25.11`. To move to a newer release,
update the channel URL and bump `system.stateVersion`. Both steps
are documented inline in `configuration.nix` next to the GC block.

## License

Copyright (C) 2026 Chahatpreet Singh.
Licensed under the [GNU Affero General Public License v3.0](LICENSE)
or, at your option, any later version.
