# dotnix

A flake-based multi-OS system configuration targeting **NixOS 25.11 stable** (Linux) and **nix-darwin** (macOS), designed to mirror environment setups between platforms so that the shell, terminal, editor, and tooling feel identical.

## Overview

| | |
|---|---|
| **Channel** | `nixos-25.11` (stable) |
| **Desktop / Window Manager** | GNOME on Wayland (Linux), macOS (Darwin) |
| **Shell** | zsh + Powerlevel10k + Antidote |
| **Terminal** | Kitty |
| **Editor** | Neovim (kickstart-based) |
| **Multiplexer** | tmux |
| **File manager** | nnn (built with `O_NERD` on NixOS) |

**What's enabled out of the box:** flakes, weekly garbage collection, auto-optimise-store, Nerd Fonts, Syncthing, Zsh configured system-wide, and shared toolchains (Node, Python, Go, Java JDK).
* **NixOS Specific:** zram swap, systemd-oomd, fstrim, TLP for laptop power, Bluetooth, GNOME bloat trimming, `nix-ld` + Mason toolchain, and the nixpkgs contributor toolkit (`nixpkgs-review`, `nix-update`, `nurl`, etc.).
* **macOS Specific:** Lix package manager, Homebrew integration (cleaning up unlisted casks/formulae, user-isolated applications, Karabiner-Elements, KeePassXC, Kitty, Thunderbird, LibreOffice), and system preference overrides.

**What's wired up but commented:** Tailscale, Avahi/mDNS, Blueman, auto-cpufreq, latest mainline kernel, GnuPG agent, Flatpak, Podman, Docker, libvirt, Borg backups, GNOME extensions, extra GUI apps, extra language toolchains. Each block has a one-paragraph note describing what it does and the tradeoff before flipping it on.

## Layout

```
.
├── flake.lock                  # Lockfile for the flake dependencies
├── flake.nix                   # Flake configuration pinning inputs and systems
├── hosts/                      # Host configurations
│   ├── macbook/
│   │   └── configuration.nix   # macOS nix-darwin system configuration
│   └── nixos/
│       ├── configuration.nix   # NixOS system configuration
│       └── hardware-configuration.nix # Hardware scan results (tracked locally)
├── LICENSE                     # GNU AGPL-3.0
└── README.md
```

## Deployment

Deploy or update configurations based on the host platform:

### Using Nix Helper (`nh`) - Recommended

```sh
# On NixOS (Linux)
nh os switch

# On macOS (Darwin)
nh darwin switch
```

### Using standard Nix tools

```sh
# On NixOS (Linux)
sudo nixos-rebuild switch --flake .#nixos

# On macOS (Darwin)
darwin-rebuild switch --flake .#macbook
```

After the rebuild, if you haven't already, set zsh as the active shell with `chsh -s $(which zsh)`.

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
