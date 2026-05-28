{ config, pkgs, ... }:

{
  # Define the user and home directory directly
  home.username = "ubuntu";
  home.homeDirectory = "/home/ubuntu";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Move your packages from users.users.ubuntu.packages to home.packages
  home.packages = with pkgs; [
    # --- Editor ---
    neovim
    tmux

    # --- File search & navigation ---
    fd
    fzf
    ripgrep
    zoxide
    bat
    eza
    tealdeer
    # nnn rebuilt with the O_NERD flag so it renders Nerd Font icons
    # in the file listing. This is the Nix way to flip a build-time
    # option: `.override { withNerdIcons = true; }` re-derives the
    # package with that flag set. Other available toggles include
    # `withIcons` (emoji icons) and `withPcre` (PCRE regex). Your
    # zsh integration (`n()` function, NNN_PLUG, NNN_FCOLORS, etc.)
    # all work the same with this build.
    (nnn.override { withNerdIcons = true; })

    # --- Git tools ---
    pre-commit
    gh
    delta

    # --- Cloud & backup ---
    rclone
    borgbackup
    syncthing

    # --- Dev tooling ---
    stow
    yamllint
    gnumake
    pkg-config

    # --- Toolchains ---
    nodejs_22
    python3
    go
    cargo
    rustc
    tree-sitter
    jdk
    maven
    gradle

    # --- Nix-specific helpers ---
    nh
    nix-output-monitor
    nvd

    # --- General system utilities ---
    htop
    btop
    unzip
    zip
    p7zip
    curl
    wget
    file
    tree
  ];

  # ============================================================
  # ZSH & INTEGRATIONS
  # ============================================================
  programs.zsh.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.nix-index = {
    enable = true;
  };

  # ============================================================
  # SYSTEM SETTINGS
  # ============================================================
  # Change system.stateVersion to home.stateVersion
  home.stateVersion = "26.05";
}
