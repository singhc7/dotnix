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

# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, pkgs, ... }:

{
  # ============================================================
  # NIX (the package manager itself)
  # ============================================================

  # --- Lix (macOS Specific) -------------------------------------------
  # Specify Lix as the underlying package manager instead of standard C++ Nix.
  nix.package = pkgs.lix;

  # Enable the nix-daemon for macOS. Commented out because it is
  # handled automatically in nix-darwin.
  # services.nix-daemon.enable = true;

  # Enable flakes and the modern `nix` CLI. Required by nix-direnv,
  # `nh`, and almost every modern NixOS/darwin guide. Safe to leave on.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Hard-link identical files in /nix/store to save disk space. Tiny
  # build-time cost, big space savings over months of system updates.
  nix.settings.auto-optimise-store = true;

  # Automatic garbage collection. Without this, /nix/store grows
  # forever. Runs weekly, removes profile generations older than 14
  # days that aren't referenced by your active system. If you want a
  # bigger rollback window, change "14d" → "30d" or "90d".
  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 0; Minute = 0; }; # darwin equivalent to "weekly"
    options = "--delete-older-than 14d";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # ============================================================
  # USERS
  # ============================================================
  # Define a user account.
  users.users.chahat = {
    name = "chahat";
    home = "/Users/chahat";
    description = "Chahatpreet Singh";

    # Make zsh the login shell. The dotfiles in ~/dotfiles/zsh expect
    # this. `programs.zsh.enable` below registers zsh as a valid login
    # shell so chsh / this option won't fail validation.
    shell = pkgs.zsh;

    # Per-user packages go here. Because this is a shared macOS
    # machine, we intentionally install everything here instead of
    # environment.systemPackages so any future user account on this
    # box does not get polluted with your toolkit.
    packages = with pkgs; [
      nh # Modern wrapper for `darwin-rebuild` with diff/preview

      # --- Downloads & media ---
      aria2 # multi-connection downloader
      yt-dlp # YouTube / video downloader
      mpv # media player
      ffmpeg

      # --- File search & navigation ---
      bat # cat-replacement with syntax highlighting
      eza # ls-replacement, used heavily in your aliases
      fd # find-replacement
      fzf # fuzzy finder
      ripgrep # grep-replacement (rg)
      zoxide # smart cd (z / zi)
      tealdeer # `tldr` man-page summaries

      # --- Cloud & backup ---
      borgbackup # Encrypted, deduplicating backups
      rclone # Cloud-storage sync (your aliases lean on this)

      # --- Dev tooling ---
      direnv # per-directory env loading
      stow # symlink-based dotfiles manager
      gh # GitHub CLI — auth, PR review, issue triage from terminal
      delta # Better git diff
      pre-commit # Pre-commit hooks

      # --- Toolchains ---
      # Installed here for Mason to compile-from-source language
      # servers, formatters, and linters. Pre-installing them here means
      # `:Mason` "just works" without surprise build failures.
      go # gopls, golangci-lint, delve
      jdk # OpenJDK
      nodejs_22 # typescript-language-server, prettier, eslint_d, vscode-* servers
      python3 # pyright, ruff, debugpy, etc.

      # --- Editor & Terminal ---
      neovim # Your editor; kickstart config in ~/.config/nvim
      tmux # Terminal multiplexer
    ];
  };

  # Enable zsh system-wide. We don't turn on zsh-autosuggestions /
  # syntax-highlighting via NixOS modules because your dotfiles already
  # manage these via antidote — turning both on would double-load them.
  programs.zsh.enable = true;

  # ============================================================
  # APPS / TOOLS (HOMEBREW)
  # ============================================================
  # This block replaces your custom ~/.homebrew setup, integrating
  # cleanly with nix-darwin to solve the shared user pollution problem.
  homebrew = {
    enable = true;

    # "zap" uninstalls any casks/formulas you didn't explicitly list below
    onActivation.cleanup = "zap";

    # Force casks to install to YOUR user's Applications folder
    # completely isolating GUI apps from other profiles on this Mac.
    caskArgs.appdir = "~/Applications";

    casks = [
      "antigravity"
      "antigravity-cli"
      "karabiner-elements"
      "keepassxc"
      "kitty"
      "libreoffice"
      "thunderbird"
    ];

    # Add syncthing to your brews, but use an attribute set
    # instead of a plain string.
    brews = [
      {
        name = "syncthing";
        # Ensures that the daemon is kept alive and will only
        # be actively restarted if a darwin-rebuild command pulls
        # down a newer version of Syncthing.
        restart_service = "changed";
      }
    ];
  };

  # ============================================================
  # FONTS
  # ============================================================
  # Your kitty + Powerlevel10k config rely on Nerd Font glyphs (the
  # icons you see in eza, p10k segments, devicons in nvim). Without
  # these you get tofu/squares. JetBrainsMono is the "main" font; the
  # rest cover Unicode coverage gaps (CJK, emoji).
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # Primary terminal font
    nerd-fonts.fira-code # Backup, in case you switch
    noto-fonts # Broad Unicode coverage
    noto-fonts-cjk-sans # Chinese / Japanese / Korean
    noto-fonts-color-emoji # Color emoji
  ];

  # ============================================================
  # SYSTEM SETTINGS
  # ============================================================
  # This value determines the nix-darwin release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = 5; # equivalent to NixOS stateVersion

  # Define a primary user to handle Homebrew's ownership
  system.primaryUser = "chahat";
}
