# dotnix — nix-darwin configuration for an Apple Silicon Mac
# Copyright (C) 2026  Chahatpreet Singh <c@chahat.dev>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with this program. If not, see
# <https://www.gnu.org/licenses/>.

# My nix-darwin configuration file where I define my Apple Silicon Mac setup.
# I can refer to the nix-darwin documentation or run man pages if I need help.
{ config, pkgs, ... }:

{
  # ============================================================
  # NIX (the package manager itself)
  # ============================================================

  # --- Lix (macOS Specific) -------------------------------------------
  # I'm specifying Lix as my underlying package manager here instead of using the standard C++ Nix.
  nix.package = pkgs.lix;

  # I'll enable flakes and the modern `nix` CLI. I need this for nix-direnv, `nh`,
  # and basically every modern NixOS/darwin guide I follow. Definitely safe to leave on.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # I want to hard-link identical files in my /nix/store to save disk space.
  # The build-time cost is tiny, but the space savings over months of updates are huge.
  nix.settings.auto-optimise-store = true;

  # I need automatic garbage collection so my /nix/store doesn't grow forever.
  # I'll run it weekly to wipe out profile generations older than 14 days that my
  # active system isn't using. If I want a bigger rollback window, I can change "14d" to "30d".
  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 0; Minute = 0; }; # My darwin equivalent to running this "weekly"
    options = "--delete-older-than 14d";
  };

  # I need to allow unfree packages so I can install proprietary software on my Mac.
  nixpkgs.config.allowUnfree = true;

  # ============================================================
  # USERS
  # ============================================================
  # Defining my user account.
  users.users.chahat = {
    name = "chahat";
    home = "/Users/chahat";
    description = "Chahatpreet Singh";

    # I want zsh as my login shell since my dotfiles in ~/dotfiles/zsh expect it.
    # Enabling `programs.zsh.enable` below registers it so nix-darwin doesn't complain.
    shell = pkgs.zsh;

    # I'll list my per-user packages here. Since this is a shared macOS machine,
    # I'm deliberately installing my tools here instead of environment.systemPackages
    # so that I don't pollute other user profiles with my personal dev toolkit.
    packages = with pkgs; [
      # --- Editor ---
      neovim # My text editor of choice; kickstart config lives in ~/.config/nvim

      # --- Terminal & multiplexer ---
      tmux # Terminal multiplexer for terminal sessions

      # --- File search & navigation (matching my NixOS setup) ---
      fd # Fast alternative to `find`
      fzf # Command-line fuzzy finder
      ripgrep # Faster grep tool (`rg`)
      zoxide # Smart directory jumper (`z`)
      bat # Syntactically highlighted cat
      eza # Modern ls replacement that I use heavily in my aliases
      tealdeer # Fast tldr client for quick man page lookups

      # --- Git tools ---
      # git is preinstalled via Xcode CLI tools, so I don't need to put it here
      pre-commit # For managing my git commit hooks
      gh # GitHub CLI for triaging PRs and issues
      delta # My preferred git diff pager

      # --- Downloads & media (matching my NixOS setup) ---
      aria2 # High-speed download utility
      yt-dlp # For downloading videos from YouTube and elsewhere
      # mpv is replaced on my Mac by the native IINA player, so I don't install it here
      ffmpeg

      # --- Cloud & backup ---
      rclone # Cloud sync utility that my shell aliases depend on
      borgbackup # Encryption-ready backups

      # --- Dev tooling ---
      stow # GNU Stow for managing my symlinked dotfiles
      yamllint # Linter for YAML files

      # --- Build essentials (for compiling local tools) ---
      gnumake
      pkg-config

      # --- Mason / Neovim toolchain (matching my NixOS setup) ---
      nodejs_22 # typescript server, prettier, and eslint_d
      python3 # pyright, ruff, and debugpy
      go # gopls and delve debugger
      cargo # Rust build tool
      rustc # Rust compiler
      tree-sitter # CLI tool for tree-sitter updates in Neovim

      # --- Java toolchain (matching my NixOS setup) ---
      jdk # The default OpenJDK package (tracks latest LTS)
      maven # Build tool for Java projects
      gradle # Another Java build tool

      # --- Nix-specific helpers (matching my NixOS setup) ---
      nh # My CLI helper for darwin-rebuild switches
      nix-output-monitor # Cleaner formatting during nix builds
      nvd # Let's me see the package version diffs between my system updates

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
  };

  # ============================================================
  # ZSH & INTEGRATIONS
  # ============================================================

  # I'm enabling zsh system-wide here. I shouldn't enable zsh-autosuggestions or
  # syntax-highlighting modules here because my dotfiles manage them using antidote.
  # Doing it in both places would load them twice and slow down my shell startup.
  programs.zsh.enable = true;

  # I'm setting up direnv and nix-direnv. Since my dotfiles already load direnv in my
  # shell configuration (`eval "$(direnv hook zsh)"`), I just need this nix-direnv glue
  # to cache environments so `use flake` and `use nix` are fast inside my .envrc files.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # I'm enabling nix-index so I can quickly figure out which package provides a given command.
  # This makes the comma (`,`) helper work so I can run temporary commands on the fly.
  programs.nix-index = {
    enable = true;
  };

  # ============================================================
  # APPS / TOOLS (HOMEBREW)
  # ============================================================
  # This block manages my Homebrew setups. By letting nix-darwin control it, I avoid manual
  # ~/.homebrew setups and ensure my Mac is cleanly configured.
  homebrew = {
    enable = true;

    # "zap" will uninstall any casks/formulae that I don't explicitly list below
    onActivation.cleanup = "zap";

    # I want to force casks to install to my user's ~/Applications directory,
    # keeping my GUI applications isolated from other user accounts on this Mac.
    caskArgs.appdir = "~/Applications";

    casks = [
      "antigravity"
      "karabiner-elements"
      "keepassxc"
      "kitty"
      "libreoffice"
      "thunderbird"
    ];

    # Adding Syncthing here to my brews. I'll configure it via an attribute set.
    brews = [
      {
        name = "syncthing";
        # I want to make sure the daemon is kept alive and only restarted when a
        # darwin-rebuild command pulls down a newer version of Syncthing.
        restart_service = "changed";
      }
    ];
  };

  # ============================================================
  # FONTS
  # ============================================================
  # My Kitty and Powerlevel10k configs rely heavily on Nerd Font icons (used by eza, p10k,
  # and devicons in Neovim). Without these, I'll get broken tofu boxes. JetBrainsMono is
  # my main font, and I'll add Noto fonts to cover CJK and emojis.
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # My primary terminal font
    nerd-fonts.fira-code # My backup font, in case I want to swap
    noto-fonts # Broad Unicode coverage
    noto-fonts-cjk-sans # Support for CJK characters
    noto-fonts-color-emoji # Color emojis
  ];

  # ============================================================
  # SYSTEM SETTINGS
  # ============================================================
  # This value sets the initial nix-darwin release version of this system's install to determine
  # legacy default behaviors for database paths and files. I should leave this alone
  # even when I upgrade my package channels/flakes so I don't break existing databases.
  system.stateVersion = 5; # This is my original install state version, equivalent to NixOS stateVersion.

  # Defining myself as the primary user to manage Homebrew's permissions.
  system.primaryUser = "chahat";
}
