# dotnix

A flake-based NixOS configuration for my Linux laptop targeting **NixOS 25.11 stable**, designed to mirror the macOS environment in [singhc7/.mac](https://github.com/singhc7/.mac) so the shell, terminal, editor, and tooling feel identical on either side.

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
├── configuration.nix           # Main system configuration (every option commented)
├── flake.lock                  # Lockfile for the flake dependencies
├── flake.nix                   # Flake configuration pinning nixpkgs and system setup
├── hardware-configuration.nix  # Hardware-specific scan results (tracked locally)
├── LICENSE                     # GNU AGPL-3.0
└── README.md
```

`hardware-configuration.nix` is now tracked locally inside the repository and imported by [flake.nix](flake.nix).

## Deployment

On the target NixOS machine, rebuild the system directly using the flake:

```sh
sudo nixos-rebuild switch --flake .#nixos
```

After the rebuild, set zsh as the active shell with `chsh -s $(which zsh)` (the user already has `shell = pkgs.zsh` declared, but interactive `chsh` finalises it on existing sessions).

## Companion dotfiles

Pairs with [singhc7/.mac](https://github.com/singhc7/.mac), stowed
into `$HOME` exactly as on macOS. Two source paths in
`~/.config/zsh/.zshrc` need adjusting on NixOS — see the comment
block next to `zsh-powerlevel10k` in `configuration.nix` for the
exact replacements (Antidote and Powerlevel10k live under the
nix store, not `~/.antidote` or `$(brew --prefix)`).

## Release upgrades

The configuration inputs are pinned via [flake.lock](flake.lock). To update the pinned channel packages:

```sh
nix flake update
```

To move to a newer release channel (e.g., `nixos-26.05`), update the `url` under `inputs.nixpkgs` in [flake.nix](flake.nix), run `nix flake update`, and rebuild the system.

## License

Copyright (C) 2026 Chahatpreet Singh.
Licensed under the [GNU Affero General Public License v3.0](LICENSE)
or, at your option, any later version.
