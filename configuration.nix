# dotnix — NixOS configuration for a Linux laptop
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

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # ============================================================
  # BOOTLOADER
  # ============================================================
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Keep at most 10 generations in the systemd-boot menu so it stays
  # readable. Older generations still exist on disk for rollback until
  # the GC sweep below removes them. Bump this if you want more entries
  # visible at boot; lower it for a tidier menu.
  boot.loader.systemd-boot.configurationLimit = 10;

  # --- Latest mainline kernel (OPTIONAL) -------------------------------
  # Uncomment to enable: pulls the newest mainline Linux kernel for
  # fresher hardware support (recent Wi-Fi chips, GPUs, laptop sensors).
  # Default is the LTS kernel — usually fine. Only flip this on if you
  # have a hardware reason; newer kernels occasionally break drivers.
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  # ============================================================
  # NIX (the package manager itself)
  # ============================================================
  # Enable flakes and the modern `nix` CLI. Required by nix-direnv,
  # `nh`, and almost every modern NixOS guide. Safe to leave on.
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
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # --- Channel / package source (STABLE) -------------------------------
  # `pkgs` in this file resolves to whatever the `nixos` channel points
  # at. A fresh 25.11 install already pins it to the stable 25.11
  # branch — i.e. the same release line as `system.stateVersion` at the
  # bottom of this file — so packages are pulled from
  # https://nixos.org/channels/nixos-25.11 (stable), NOT nixos-unstable.
  #
  # Verify any time with:
  #     sudo nix-channel --list
  # Expected:
  #     nixos https://nixos.org/channels/nixos-25.11
  #
  # If something is wrong (e.g. someone added unstable), fix with:
  #     sudo nix-channel --remove nixos
  #     sudo nix-channel --add https://nixos.org/channels/nixos-25.11 nixos
  #     sudo nix-channel --update
  #     sudo nixos-rebuild switch
  #
  # When 26.05 ships and you're ready to upgrade, swap "25.11" for
  # "26.05" in the URL above AND in `system.stateVersion` at the bottom.
  # Stay one release behind unstable on purpose — it's the whole point
  # of running stable.

  # ============================================================
  # NETWORKING
  # ============================================================
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # --- Tailscale (OPTIONAL) --------------------------------------------
  # Uncomment to enable: drop-in mesh VPN, lets you reach this laptop
  # from any other device you own without dealing with port forwarding.
  # After enabling and rebuilding, run `sudo tailscale up` once to log in.
  # services.tailscale.enable = true;

  # --- Avahi / mDNS (OPTIONAL) -----------------------------------------
  # Uncomment to enable: lets `.local` hostnames resolve on your LAN
  # (e.g. `ssh laptop.local`). Useful if you have other Linux/macOS
  # boxes around. Harmless on home networks; some corp networks block it.
  # services.avahi = {
  #   enable = true;
  #   nssmdns4 = true;
  #   openFirewall = true;
  # };

  # Set your time zone.
  time.timeZone = "America/Winnipeg";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # ============================================================
  # DESKTOP — X11 / GNOME
  # ============================================================
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  # NOTE: as of nixos-25.11 the display- and desktop-manager options
  # moved out from under `services.xserver.*` to top-level
  # `services.displayManager.*` / `services.desktopManager.*` since
  # they're no longer X11-specific (Wayland uses them too). The old
  # paths still evaluate but emit a deprecation warning.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # --- Strip GNOME bloat -----------------------------------------------
  # GNOME ships a lot of default apps most people never use. We exclude
  # them so they don't clutter the app grid or the installation closure.
  # Re-add anything you actually want by deleting it from this list.
  environment.gnome.excludePackages = (with pkgs; [
    gnome-tour          # First-run tutorial slideshow
    gnome-connections   # RDP/VNC client
    epiphany            # GNOME Web browser (we use Firefox)
    geary               # Email client
    totem               # Video player (we use mpv)
    yelp                # GNOME help viewer
    gnome-music         # Music player
    gnome-contacts      # Contacts app
    gnome-maps          # Maps app
    gnome-weather       # Weather widget
    gnome-clocks        # Clocks app (timer/world clock)
    simple-scan         # Scanner front-end
    cheese              # Webcam toy
  ]);

  # GNOME ships its own power daemon. We disable it because we use TLP
  # below for finer laptop power control. The two daemons conflict; pick
  # one. If you'd rather use GNOME's built-in (less aggressive) one,
  # disable the TLP block below and flip this back to `true`.
  services.power-profiles-daemon.enable = false;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # ============================================================
  # AUDIO — PipeWire
  # ============================================================
  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # ============================================================
  # BLUETOOTH
  # ============================================================
  # Stock NixOS doesn't enable Bluetooth. We do, since this is a
  # laptop. powerOnBoot brings the radio up after a cold boot so
  # devices reconnect without manual steps. GNOME's Settings panel
  # picks this up automatically — no extra UI needed.
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # --- Blueman tray applet (OPTIONAL) ----------------------------------
  # Uncomment to enable: standalone Bluetooth tray. Only useful if you
  # ever leave GNOME for a tiling WM (Sway/Hyprland) — GNOME has its
  # own Bluetooth UI built in.
  # services.blueman.enable = true;

  # ============================================================
  # LAPTOP POWER MANAGEMENT — TLP
  # ============================================================
  # TLP is the de-facto laptop power tool: spins down disks, manages
  # CPU governors, sets battery charge thresholds, etc. Sensible
  # defaults out of the box. The settings below are conservative —
  # tweak `START_CHARGE_THRESH_BAT0` / `STOP_CHARGE_THRESH_BAT0` if
  # your laptop supports charge limits (mostly ThinkPads, some Dells).
  services.tlp = {
    enable = true;
    settings = {
      # CPU scaling governor — performance when plugged in, powersave on battery.
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Energy-performance preference (Intel/AMD modern CPUs).
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Battery charge thresholds (ThinkPad-style hardware only — others ignore these).
      # Uncomment if your laptop supports it; longevity > capacity if you're plugged in often.
      # START_CHARGE_THRESH_BAT0 = 75;
      # STOP_CHARGE_THRESH_BAT0  = 80;
    };
  };

  # --- auto-cpufreq alternative (OPTIONAL) -----------------------------
  # Uncomment to enable: a simpler, more reactive alternative to TLP
  # focused only on CPU scaling. If you flip this on, disable TLP above.
  # services.auto-cpufreq.enable = true;

  # ============================================================
  # SYSTEM RELIABILITY / PERFORMANCE
  # ============================================================
  # Compressed in-RAM swap. Treats a chunk of RAM as compressed swap
  # before falling back to disk. Big quality-of-life win for dev boxes:
  # browser tabs / language servers can swap without thrashing the SSD.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Out-of-memory daemon. Kills the worst-offending process when memory
  # pressure spikes, instead of letting the whole system freeze.
  # NixOS enables this by default with systemd ≥ 247, but we set it
  # explicitly so it's obvious what's going on.
  systemd.oomd.enable = true;

  # Periodic SSD trim. Tells the SSD which blocks are free so it can
  # garbage-collect internally. Runs weekly via systemd timer.
  services.fstrim.enable = true;

  # ============================================================
  # USERS
  # ============================================================
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.chahat = {
    isNormalUser = true;
    description = "Chahatpreet Singh";
    # `video` lets us control screen brightness without sudo.
    # Add "docker" / "libvirtd" here later if you enable those below.
    extraGroups = [ "networkmanager" "wheel" "video" ];

    # Make zsh the login shell. The dotfiles in ~/dotfiles/zsh expect
    # this. `programs.zsh.enable` below registers zsh as a valid login
    # shell so chsh / this option won't fail validation.
    shell = pkgs.zsh;

    # Per-user packages go here. This list is empty on purpose —
    # everything is installed in environment.systemPackages above so
    # any future user account on this box gets the same toolkit. Move
    # apps here if you ever want them visible only to chahat (e.g. a
    # personal license-bound app you don't want exposed to a guest
    # account).
    packages = with pkgs; [
    ];
  };

  # Enable zsh system-wide. We don't turn on zsh-autosuggestions /
  # syntax-highlighting via NixOS modules because your dotfiles already
  # manage these via antidote — turning both on would double-load them.
  programs.zsh.enable = true;

  # ============================================================
  # APPS / TOOLS
  # ============================================================
  # Install firefox.
  programs.firefox.enable = true;

  # Direnv with nix-direnv. Your dotfiles already hook direnv into zsh
  # (`eval "$(direnv hook zsh)"` in integrations.zsh), so the only thing
  # we add here is the nix-direnv glue, which makes `use flake` and
  # `use nix` blazing fast (cached) inside .envrc files.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # nix-index — fast lookup of "which package provides this binary?".
  # Includes the `comma` (`,`) helper: `, cowsay hi` runs cowsay
  # without installing it. Also drops in a command-not-found hook for
  # zsh that suggests the right `nix-shell` invocation when you type a
  # missing command. We disable the legacy command-not-found below so
  # they don't both run.
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.command-not-found.enable = false;

  # SSH agent. Your gitconfig signs commits with an SSH key
  # (gpg.format = ssh, signingkey = ~/.ssh/id_ed25519), so an agent
  # needs to be running for passphrase-protected keys.
  #
  # On GNOME we DO NOT enable `programs.ssh.startAgent` — GNOME 47+ ships
  # `services.gnome.gcr-ssh-agent` (enabled by default with the GNOME
  # module) which is a keyring-backed SSH agent. The two conflict at
  # eval time ("only one ssh agent can be installed at a time"), so we
  # let the GNOME default win. `gcr-ssh-agent` exports SSH_AUTH_SOCK
  # automatically; just run `ssh-add` once and the GNOME keyring will
  # remember the passphrase across sessions (unlocked by your login).
  #
  # If you ever switch off GNOME, flip this on and you're back to the
  # plain OpenSSH agent:
  # programs.ssh.startAgent = true;
  #
  # NOTE: your dotfiles' integrations.zsh contains
  # `ssh-add --apple-load-keychain`, which is macOS-only — on NixOS just
  # run `ssh-add` once and the keyring takes it from there.

  # ============================================================
  # NEOVIM / MASON SUPPORT
  # ============================================================
  # Mason (the LSP/DAP/linter installer your kickstart nvim uses) has
  # two failure modes on NixOS that don't exist on macOS:
  #
  # 1. Mason often downloads PREBUILT binaries (e.g. lua-language-server,
  #    rust-analyzer, eslint_d). These are linked against a normal FHS
  #    glibc that doesn't exist in NixOS, so they fail with
  #    "no such file or directory" even though the file is right there.
  #    `programs.nix-ld` provides a shim ld-linux at /lib64/ld-linux-*
  #    so those binaries can find their loader. The `libraries` list
  #    is what nix-ld preloads — add more if a Mason binary complains
  #    about a missing .so at runtime.
  #
  # 2. Mason ALSO compiles some servers from source. Those need the
  #    appropriate toolchain on $PATH (node/python/go/cargo). We
  #    install those globally further down, in systemPackages.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib   # libstdc++ — needed by lots of Mason binaries
      zlib               # compression — pulled in by nearly everything
      openssl            # TLS — needed by anything that talks to a registry
      curl               # libcurl
      icu                # Unicode — used by some language servers
      libxml2
      glib
    ];
  };

  # --- GnuPG agent (OPTIONAL) ------------------------------------------
  # Uncomment to enable: only useful if you actually use GPG (encrypted
  # email, package signing, etc). You sign git commits with SSH, not
  # GPG, so this is off by default.
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # ============================================================
  # FONTS
  # ============================================================
  # Your kitty + Powerlevel10k config rely on Nerd Font glyphs (the
  # icons you see in eza, p10k segments, devicons in nvim). Without
  # these you get tofu/squares. JetBrainsMono is the "main" font; the
  # rest cover Unicode coverage gaps (CJK, emoji).
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono   # Primary terminal font
    nerd-fonts.fira-code        # Backup, in case you switch
    noto-fonts                  # Broad Unicode coverage
    noto-fonts-cjk-sans         # Chinese / Japanese / Korean
    noto-fonts-color-emoji      # Color emoji (renamed from noto-fonts-emoji in 25.11)
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # ============================================================
  # SYSTEM PACKAGES
  # ============================================================
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  #
  # This block is the NixOS equivalent of your ~/dotfiles/Brewfile,
  # plus a handful of NixOS-specific quality-of-life additions.
  # Anything you DON'T want, just delete the line. Anything new you
  # want, add it under the relevant heading.
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget

    # --- Editor ---
    neovim                    # Your editor; kickstart config in ~/.config/nvim

    # --- Terminal & multiplexer ---
    kitty                     # Primary terminal emulator
    tmux                      # Terminal multiplexer

    # --- Shell prompt + plugin manager ---
    # NOTE: paths differ from macOS Homebrew. In your ~/.zshrc:
    #   - antidote lives at  ${pkgs.antidote}/share/antidote/antidote.zsh
    #     (your line `source ~/.antidote/antidote.zsh` won't work on NixOS)
    #   - p10k lives at ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    # Update those two source lines when you stow zsh on this box.
    zsh-powerlevel10k
    antidote

    # --- File search & navigation (mirrors Brewfile) ---
    fd                        # find-replacement
    fzf                       # fuzzy finder
    ripgrep                   # grep-replacement (rg)
    zoxide                    # smart cd (z / zi)
    bat                       # cat-replacement with syntax highlighting
    eza                       # ls-replacement, used heavily in your aliases
    tealdeer                  # `tldr` man-page summaries
    # nnn rebuilt with the O_NERD flag so it renders Nerd Font icons
    # in the file listing. This is the Nix way to flip a build-time
    # option: `.override { withNerdIcons = true; }` re-derives the
    # package with that flag set. Other available toggles include
    # `withIcons` (emoji icons) and `withPcre` (PCRE regex). Your
    # zsh integration (`n()` function, NNN_PLUG, NNN_FCOLORS, etc.)
    # all work the same with this build.
    (nnn.override { withNerdIcons = true; })

    # --- Git tools (mirrors Brewfile) ---
    git
    pre-commit
    gh                        # GitHub CLI — auth, PR review, issue triage from terminal

    # --- Downloads & media (mirrors Brewfile) ---
    aria2                     # multi-connection downloader
    yt-dlp                    # YouTube / video downloader
    mpv                       # media player

    # --- Cloud & backup (mirrors Brewfile) ---
    rclone                    # Cloud-storage sync (your aliases lean on this)
    borgbackup                # Encrypted, deduplicating backups

    # --- Dev tooling (mirrors Brewfile) ---
    yamllint                  # YAML linter
    direnv                    # per-directory env loading (also enabled as program above)
    stow                      # symlink-based dotfiles manager (you use this on macOS)

    # --- Build essentials (you'll want these the first time you `make` anything) ---
    gcc
    gnumake
    pkg-config

    # --- Mason / Neovim toolchain ------------------------------------
    # Mason needs these on $PATH to compile-from-source language
    # servers, formatters, and linters. Pre-installing them here means
    # `:Mason` "just works" without surprise build failures. They're
    # also useful generally — keep, comment, or swap to per-project
    # devshells later if you prefer the cleaner approach.
    nodejs_22                 # typescript-language-server, prettier, eslint_d, vscode-* servers
    python3                   # pyright, ruff, debugpy, etc.
    go                        # gopls, golangci-lint, delve
    cargo                     # rust-analyzer (when built from source) + many Mason tools
    rustc                     # paired with cargo
    tree-sitter               # tree-sitter CLI — nvim-treesitter `:TSUpdate` calls this

    # --- Java toolchain ----------------------------------------------
    # `jdk` is the default OpenJDK in nixpkgs (currently a recent LTS,
    # JDK 21 on the 25.11 channel). If you need a specific major version
    # use `jdk17`, `jdk21`, `jdk23`, etc. Maven and Gradle are the two
    # build tools you'll meet most often.
    #
    # JAVA_HOME is set automatically by the wrapper — `java`, `javac`,
    # and `jshell` will all be on $PATH after a rebuild. For per-project
    # JDK pinning later, consider an `.envrc` with
    # `use_flake` + a flake providing a specific `jdkXX`.
    jdk                       # OpenJDK (latest LTS in this channel)
    maven                     # Maven build tool — `mvn`
    gradle                    # Gradle build tool — `gradle`
    # jdt-language-server     # Eclipse JDT LSP — uncomment if you'd rather not let Mason manage it
    # google-java-format      # Java formatter
    # checkstyle              # Java linter

    # --- NixOS-specific helpers ---
    nh                        # Modern wrapper for `nixos-rebuild` with diff/preview
    nix-output-monitor        # Prettier `nix build` output (pipe with `|& nom`)
    nvd                       # Nix version diff — show what changed between generations

    # --- nixpkgs contributor toolkit ---------------------------------
    # The de-facto dev-env for working in the nixpkgs repo. Most of
    # these are referenced in nixpkgs's CONTRIBUTING.md and pkgs/README;
    # together they cover review, version-bumps, package authoring,
    # formatting, and linting. None of them are required to BUILD
    # nixpkgs (a checkout + `nix-build` works without them) — but every
    # one of them removes friction from the contributor loop.
    #
    # Typical workflow:
    #   1. `nixpkgs-review pr 12345`    → builds + sandbox-tests a PR
    #   2. `nix-update <attr>`          → bumps a package version + hash
    #   3. `nurl <url>`                 → emits a fetchFromGitHub block
    #   4. `nix-init <url>`             → bootstraps a new derivation
    #   5. `nixfmt-rfc-style file.nix`  → official formatter (RFC 166)
    #   6. `statix check .`             → lint
    #   7. `deadnix .`                  → find unused bindings
    nixpkgs-review            # Build + test PRs locally in a sandbox
    nix-update                # Auto-bump version + sha256 of a package
    nurl                      # Generate fetchFrom* expressions from URLs
    nix-init                  # Boilerplate generator for new packages
    nixfmt-rfc-style          # Official nixpkgs formatter (RFC 166)
    statix                    # Lints / suggests idiomatic Nix
    deadnix                   # Finds dead code in .nix files
    nix-tree                  # Interactive TUI for /nix/store closures
    nix-diff                  # Diff two derivations attribute-by-attribute
    nil                       # Nix LSP — pair with nvim's lspconfig
    # nixd                    # Alternative Nix LSP (richer, heavier). Pick one.
    # vulnix                  # Scans your closure for known CVEs
    # editorconfig-checker    # nixpkgs CI uses this; nice for local checks

    # Workflow note: when you `cd ~/path/to/nixpkgs`, drop a `.envrc`
    # containing `use nix` (or `use flake`) so direnv + nix-direnv (both
    # already enabled above) load the repo's own dev shell automatically.
    # That gives you anything specific the nixpkgs tree ships in its
    # `shell.nix` on top of the system-wide tools above.

    # --- GNOME tweakability ---
    gnome-tweaks              # Toggle hidden GNOME settings (fonts, animations, etc.)
    dconf-editor              # Raw GSettings registry editor — use with care

    # --- General system utilities ---
    htop                      # Process viewer
    btop                      # Prettier process viewer
    unzip                     # zip extraction
    zip
    p7zip                     # 7z / rar handling — your `extract` function uses these
    unrar                     # rar extraction (your `extract` function calls `unrar`)
    curl
    wget
    file                      # Identify file types
    tree                      # ASCII directory tree

    # --- OPTIONAL: extra git tooling --------------------------------
    # Uncomment whichever you want.
    # lazygit                 # TUI git client
    # delta                   # Better git diff (set as core.pager in gitconfig)

    # --- OPTIONAL: extra language toolchains -------------------------
    # node / python / go / cargo / jdk are already installed above.
    # Only the less-common ones are listed here. Per-project flakes or
    # devshells are usually a cleaner answer than going global.
    # rustup                  # rustc/cargo toolchain manager (replaces the cargo+rustc above if you prefer multiple toolchains)
    # zig
    # ghc                     # Haskell
    # ruby
    # kotlin                  # JVM, pairs nicely with the jdk above
    # scala                   # JVM, ditto

    # --- Password manager ---
    keepassxc                 # Local KeePass-format password vault

    # --- Mail ---
    thunderbird               # Mozilla email / calendar / news client

    # --- OPTIONAL: GUI apps ------------------------------------------
    # chromium
    # vscode
    # obsidian
    # bitwarden
    # signal-desktop
    # spotify
    # discord
    # zoom-us
    # slack

    # --- OPTIONAL: GNOME extensions ----------------------------------
    # Installing the package alone isn't enough — after a rebuild you
    # also have to enable each one in gnome-tweaks → Extensions.
    # gnomeExtensions.appindicator      # Legacy tray-icon support
    # gnomeExtensions.user-themes       # Custom shell themes
    # gnomeExtensions.dash-to-dock      # macOS-style permanent dock
    # gnomeExtensions.blur-my-shell     # Cosmetic blur
  ];

  # ============================================================
  # SERVICES (commented, opt-in)
  # ============================================================

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # --- Flatpak (OPTIONAL) ----------------------------------------------
  # Uncomment to enable: useful for GUI apps that aren't packaged in
  # nixpkgs or whose nix package lags behind upstream. Requires
  # xdg.portal so apps can talk to the file picker / screen sharer.
  # services.flatpak.enable = true;
  # xdg.portal.enable = true;
  # xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

  # --- Podman / containers (OPTIONAL) ----------------------------------
  # Uncomment to enable: rootless container runtime, drop-in compatible
  # with `docker` CLI (so `docker run ...` works). Preferable to Docker
  # on NixOS because it doesn't need a system daemon. Add "podman" to
  # users.users.chahat.extraGroups if you want non-sudo socket access.
  # virtualisation.podman = {
  #   enable = true;
  #   dockerCompat = true;
  #   defaultNetwork.settings.dns_enabled = true;
  # };

  # --- Docker alternative (OPTIONAL) -----------------------------------
  # Uncomment to enable: only pick one of (podman, docker). If you flip
  # this on, also add "docker" to chahat's extraGroups above.
  # virtualisation.docker.enable = true;

  # --- Libvirt / VMs (OPTIONAL) ----------------------------------------
  # Uncomment to enable: KVM + QEMU + virt-manager GUI for running
  # VMs (other Linux distros, Windows, etc). Add "libvirtd" to
  # extraGroups if you flip this on.
  # virtualisation.libvirtd.enable = true;
  # programs.virt-manager.enable = true;

  # --- Borg automated backup (OPTIONAL) --------------------------------
  # Uncomment and edit paths to enable: nightly encrypted backup of
  # your home dir. You'll need to `borg init` the repo once before
  # the timer can run successfully. Replace REPO and PASSCOMMAND.
  # services.borgbackup.jobs.home = {
  #   paths = [ "/home/chahat" ];
  #   exclude = [ "/home/chahat/.cache" "/home/chahat/Downloads" ];
  #   repo = "/mnt/backup/borg";          # or a remote: "user@host:/path"
  #   encryption = {
  #     mode = "repokey-blake2";
  #     passCommand = "cat /etc/nixos/borg-passphrase";
  #   };
  #   compression = "auto,zstd";
  #   startAt = "daily";
  # };

  # ============================================================
  # SYNCTHING — peer-to-peer file sync
  # ============================================================
  # Continuous, encrypted folder sync between your devices over LAN
  # or internet (no cloud middleman, no account). After a rebuild,
  # open http://localhost:8384 to add devices and folders via the
  # web UI. The first time you run it, syncthing prints a Device ID
  # — share that with your other devices to pair.
  #
  # Folder defaults to /home/chahat (`dataDir`); created folders
  # appear in there unless you pick another path in the UI.
  services.syncthing = {
    enable = true;
    user = "chahat";
    dataDir = "/home/chahat";
    configDir = "/home/chahat/.config/syncthing";

    # Keep these `false` so devices/folders you add through the web
    # UI persist across rebuilds. Flip to `true` only if you want to
    # manage every device and folder declaratively in this file
    # (in which case anything not declared here gets removed on
    # every `nixos-rebuild switch` — easy to lose data).
    overrideDevices = false;
    overrideFolders = false;
  };

  # ============================================================
  # FIREWALL
  # ============================================================
  # NixOS enables the firewall by default; we only need to poke
  # holes for the services that talk to other machines.
  #
  # Syncthing port reference:
  #   22000 TCP/UDP — actual sync traffic (encrypted)
  #   21027 UDP     — LAN device discovery (multicast)
  #   8384  TCP     — web UI; intentionally NOT exposed (localhost only)
  networking.firewall.allowedTCPPorts = [ 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];

  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
