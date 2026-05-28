# dotnix — Standalone Home Manager configuration for my OCI VM
# Copyright (C) 2026  Chahatpreet Singh <c@chahat.dev>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with this program.  If not, see
# <https://www.gnu.org/licenses/>.

# My standalone Home Manager configuration file where I define my environment
# on my Oracle Cloud Infrastructure (OCI) server instance. Since this is running
# on top of Ubuntu, I manage packages and dotfiles via Home Manager rather than
# system-wide NixOS configurations.

{ config, pkgs, ... }:

{
  # I need to explicitly set my username and home directory paths since this is
  # a standalone Home Manager installation running on an Ubuntu host.
  home.username = "ubuntu";
  home.homeDirectory = "/home/ubuntu";

  # I'll allow unfree packages here as well so I can pull proprietary tools if needed.
  nixpkgs.config.allowUnfree = true;

  # These are my user-level packages. On this OCI instance, Home Manager will manage
  # these and symlink them into my user's profile. I've mirrored most of my standard
  # NixOS and macOS terminal utility toolkit here so my cloud shell feels like home.
  home.packages = with pkgs; [
    # --- Editor & Multiplexer ---
    neovim # My main editor, kickstart config synced via dotfiles
    tmux # Terminal multiplexer so I can keep sessions alive when SSH disconnects

    # --- File search & navigation ---
    fd # A fast replacement for `find`
    fzf # Command-line fuzzy finder
    ripgrep # High-speed search tool (`rg`)
    zoxide # Smart cd helper (`z`)
    bat # Better cat with syntax highlighting
    eza # Modern ls replacement that my aliases depend on
    tealdeer # Fast tldr client for quick man page lookups
    # Rebuilding `nnn` with nerd icons. Using the Nix `.override` function is how I customize
    # compile-time flags like `withNerdIcons = true` to make it render icons properly.
    (nnn.override { withNerdIcons = true; })

    # --- Git tools ---
    pre-commit # For managing my git commit hooks
    gh # GitHub CLI for managing PRs and issues
    delta # My preferred git diff pager

    # --- Cloud & backup ---
    rclone # Cloud sync utility that my shell aliases depend on
    borgbackup # Encryption-ready backups
    syncthing # For syncing files between this VM and my other devices

    # --- Dev tooling & build essentials ---
    stow # GNU Stow for managing my symlinked dotfiles
    yamllint # Linter for YAML files
    gnumake # Standard make build tool
    pkg-config # Package compiler helper

    # --- Toolchains ---
    nodejs_22 # typescript server, prettier, and eslint_d
    python3 # pyright, ruff, and debugpy
    go # gopls and delve debugger
    cargo # Rust build tool
    rustc # Rust compiler
    tree-sitter # CLI tool for tree-sitter updates in Neovim
    jdk # The default OpenJDK package (tracks latest LTS)
    maven # Build tool for Java projects
    gradle # Another Java build tool

    # --- Nix-specific helpers ---
    nh # My CLI helper for home-manager rebuild switches
    nix-output-monitor # Cleaner formatting during nix builds
    nvd # Let's me see the package version diffs between my rebuilds

    # --- General system utilities ---
    htop # Interactive process monitor
    btop # Eye-candy process monitor
    unzip # Zip archive extractor
    zip
    p7zip # 7-zip support for my custom `extract` shell function
    curl
    wget
    file # Utility to determine file types
    tree # Displays directory structure as a tree
  ];

  # ============================================================
  # ZSH & INTEGRATIONS
  # ============================================================
  # I'm enabling Zsh here. Since this is standalone Home Manager,
  # I want to register it so Home Manager handles its initialization.
  programs.zsh.enable = true;

  # I'm setting up direnv and nix-direnv. Since my dotfiles already load direnv in my
  # shell configuration (`eval "$(direnv hook zsh)"`), I just need this nix-direnv glue
  # to cache environments so `use flake` and `use nix` are fast inside my .envrc files.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # I'm enabling nix-index so I can quickly figure out which package provides a given command.
  programs.nix-index = {
    enable = true;
  };

  # ============================================================
  # SYSTEM SETTINGS
  # ============================================================
  # This option defines the Home Manager release version to use for default settings.
  # Since I'm on 26.05 stable branch now, I've set this to 26.05 to match.
  home.stateVersion = "26.05";
}
