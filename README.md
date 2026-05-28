# dotnix

A flake-based multi-OS system configuration targeting **NixOS 26.05 stable** (Linux), **nix-darwin** (macOS), and **standalone Home Manager** (Ubuntu/OCI). It is designed to mirror environment setups between platforms so that the shell, terminal, editor, and tooling feel identical.

## Overview

| Feature | Target / Implementation |
| :--- | :--- |
| **Channel / Release** | `nixos-26.05` / `release-26.05` (stable) |
| **Desktop / WM** | GNOME on Wayland (Linux), macOS Native (Darwin), Headless / CLI-only (Ubuntu/OCI) |
| **Shell** | Zsh + Powerlevel10k + Antidote |
| **Terminal** | Kitty (Linux, macOS) |
| **Editor** | Neovim (kickstart-based) |
| **Multiplexer** | tmux |
| **File Manager** | `nnn` (built with Nerd Font icons on NixOS) |

---

## Enabled Out of the Box

### Shared Features (Across All Platforms)
- **Flakes & modern CLI**: Fully enabled by default.
- **Weekly Garbage Collection**: Prevents `/nix/store` from growing indefinitely.
- **Store Optimization**: Automatically hard-links identical store paths to save space.
- **Shared Zsh Environment**: Caches environment loading via Direnv + `nix-direnv` inside `.envrc`.
- **Fast Lookups**: `nix-index` for "which package provides this binary?" queries, featuring the `,` (comma) runner.
- **Developer Toolchains**: NodeJS 22, Python 3, Go, Cargo + Rustc, Tree-sitter CLI, Java JDK + Maven + Gradle.
- **Common CLI Suite**: `fd`, `fzf`, `ripgrep`, `zoxide`, `bat`, `eza`, `tealdeer`, `htop`, `btop`, `stow`, etc.

### NixOS Specific ([hosts/nixos](file:///Users/chahat/nixos/hosts/nixos))
- **Kernel & Boot**: `systemd-boot` loader capped at 10 generations to keep the menu tidy.
- **Performance**: `zram` swap (using 50% RAM with `zstd` compression) and `systemd-oomd` memory watchdog.
- **Storage**: Weekly SSD trim (`fstrim`).
- **Laptop Power**: `tlp` daemon configuration tuning CPU scaling governors & policies.
- **Connectivity**: Bluetooth enabled and set to power on by default.
- **Clean GNOME**: Excludes bloated default apps (epiphany, geary, yelp, etc.) to keep the installation slim.
- **Neovim/Mason Integration**: Preconfigured `nix-ld` library paths (e.g. `libstdc++`, `zlib`, `openssl`, etc.) so that Mason-downloaded language servers execute natively without dynamic linking errors.
- **Nixpkgs Contributor Toolkit**: Built-in contribution tools including `nixpkgs-review`, `nix-update`, `nurl`, `nix-init`, `nixfmt-rfc-style`, `statix`, `deadnix`, and interactive store inspectors like `nix-tree` / `nix-diff`.
- **File Sync**: Peer-to-peer background folder synchronization via the Syncthing daemon.

### macOS Specific ([hosts/macbook](file:///Users/chahat/nixos/hosts/macbook))
- **Lix Package Manager**: Replaces standard C++ Nix for enhanced performance and modern tooling.
- **Homebrew Integration**: Synchronized via Nix-darwin (`homebrew.enable = true` with `onActivation.cleanup = "zap"`).
- **Application Isolation**: Enforces GUI app isolation by installing casks to `~/Applications` only.
- **Casks**: Karabiner-Elements, KeePassXC, Kitty, Thunderbird, LibreOffice, and Antigravity.
- **Syncthing Service**: Deployed via Homebrew and managed as a launch daemon, automatically restarting on rebuilds only if updated.
- **Fonts**: Preinstalled JetBrains Mono Nerd Font, Fira Code Nerd Font, Noto Fonts (Unicode, CJK, and Color Emoji).

### Ubuntu Specific ([hosts/oci](file:///Users/chahat/nixos/hosts/oci))
- **Standalone Home Manager**: Headless CLI environment targeted for OCI Virtual Machines running Ubuntu.
- **User Space Isolation**: Safely installs developer tools, toolchains, and shell configurations in `/home/ubuntu` without interfering with system-wide APT packages.

---

## Directory Layout

```
.
├── flake.lock                  # Lockfile pinning flake input dependencies
├── flake.nix                   # Root system flake defining configurations & systems
├── hosts/                      # Host configurations
│   ├── macbook/
│   │   └── configuration.nix   # macOS nix-darwin configuration
│   ├── nixos/
│   │   ├── configuration.nix   # NixOS laptop configuration
│   │   └── hardware-configuration.nix # Hardware scan properties
│   └── oci/
│       └── home.nix            # Standalone Home Manager configuration (Ubuntu)
├── LICENSE                     # GNU AGPL-3.0
└── README.md                   # This document
```

---

## Target Deployments & Commands

Deploy, switch, or build configurations depending on your platform target.

### 1. NixOS (Linux Laptop)
- **Target Configuration**: `nixosConfigurations."nixos"`
- **Module Entrypoint**: [hosts/nixos/configuration.nix](file:///Users/chahat/nixos/hosts/nixos/configuration.nix)
- **Commands**:
  - **Build & Activate (Recommended)**:
    ```sh
    nh os switch .
    ```
    *(Or simply `nh os switch` which auto-resolves your host).*
  - **Build & Activate (Standard)**:
    ```sh
    sudo nixos-rebuild switch --flake .#nixos
    ```
  - **Build & Set as Boot Default**:
    ```sh
    nh os boot .
    # Or: sudo nixos-rebuild boot --flake .#nixos
    ```
  - **Build & Test (Temporarily Apply)**:
    ```sh
    nh os test .
    # Or: sudo nixos-rebuild test --flake .#nixos
    ```
  - **Dry-run / Build Only**:
    ```sh
    nix build .#nixosConfigurations.nixos.config.system.build.toplevel
    ```

### 2. macOS (nix-darwin)
- **Target Configuration**: `darwinConfigurations."macbook"`
- **Module Entrypoint**: [hosts/macbook/configuration.nix](file:///Users/chahat/nixos/hosts/macbook/configuration.nix)
- **Commands**:
  - **Build & Switch (Recommended)**:
    ```sh
    nh darwin switch .
    ```
    *(Or simply `nh darwin switch`).*
  - **Build & Switch (Standard)**:
    ```sh
    darwin-rebuild switch --flake .#macbook
    ```
  - **Dry-run / Build Only**:
    ```sh
    nix build .#darwinConfigurations.macbook.system
    ```

### 3. Ubuntu / OCI VM (Standalone Home Manager)
- **Target Configuration**: `homeConfigurations."ubuntu"`
- **Module Entrypoint**: [hosts/oci/home.nix](file:///Users/chahat/nixos/hosts/oci/home.nix)
- **Commands**:
  - **Build & Switch (Recommended)**:
    ```sh
    nh home switch .
    ```
  - **Build & Switch (Standard)**:
    ```sh
    home-manager switch --flake .#ubuntu
    ```
  - **Dry-run / Build Only**:
    ```sh
    nix build .#homeConfigurations.ubuntu.activationPackage
    ```

---

## Maintenance & Upgrades

### Updating Flake Inputs
To fetch and lock the latest packages from the pinned `26.05` release branches:

```sh
# Update all dependencies
nix flake update

# Update a specific dependency (e.g., nixpkgs only)
nix flake lock --update-input nixpkgs
```

After updating the lockfile, re-run the corresponding **switch** command for your target host.

### Garbage Collection & Cleanup
Nix maintains past configurations so you can roll back at any time. When you are ready to free up disk space:

- **Using Nix Helper (Recommended)**:
  ```sh
  nh clean all
  ```
- **Using Standard Tools**:
  ```sh
  # Clean user profiles
  nix-collect-garbage -d
  
  # Clean system profiles (requires sudo, NixOS only)
  sudo nix-collect-garbage -d
  
  # Optimize store (hardlink duplicates post-cleanup)
  nix-store --optimise
  ```

### Release Upgrades
To transition system derivations to a new release channel (e.g., `26.05` → `26.11`):
1. Open [flake.nix](file:///Users/chahat/nixos/flake.nix).
2. Edit the channel tags in the input URLs:
   - `nixpkgs.url`: change `nixos-26.05` to `nixos-26.11`.
   - `darwin.url`: change `nix-darwin-26.05` to `nix-darwin-26.11`.
   - `home-manager.url`: change `release-26.05` to `release-26.11`.
3. Run `nix flake update` to lock the new revisions.
4. Execute the switch commands to perform the upgrade.

---

## Companion Dotfiles

This system flake works in tandem with companion dotfiles (e.g. managed via [singhc7/.mac](https://github.com/singhc7/.mac) or similar), stowed directly into `$HOME`. On NixOS, adjust the path variables for shell tools such as `antidote` and `powerlevel10k` to reference their Nix store paths under `/run/current-system/sw/share/` rather than the traditional Homebrew paths.

---

## License

Copyright (C) 2026 Chahatpreet Singh.  
Licensed under the [GNU Affero General Public License v3.0](LICENSE) or, at your option, any later version.
