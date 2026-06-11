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

# My main NixOS configuration file where I define my laptop setup.
# I can check the configuration.nix(5) man page or run `nixos-help` if I get stuck.

{ config, pkgs, ... }:

{
  imports = [
    # I need to import the hardware configuration generated for this laptop.
    ./hardware-configuration.nix
  ];

  # ============================================================
  # BOOTLOADER
  # ============================================================
  # I'm using systemd-boot as my bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # I'll keep at most 10 generations in the systemd-boot menu so it stays
  # readable. My older generations will still exist on disk for rollbacks
  # until I run the garbage collector. I can bump this if I want more entries,
  # or lower it to tidy up the boot menu.
  boot.loader.systemd-boot.configurationLimit = 10;

  # --- Latest mainline kernel (OPTIONAL) -------------------------------
  # I can uncomment this if I need the absolute newest mainline Linux kernel
  # for fresher hardware support (like newer Wi-Fi chips, GPUs, or laptop sensors).
  # The default is the LTS kernel, which is usually fine for me. I should only
  # enable this if I have a specific hardware reason, since newer kernels can break.
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  # ============================================================
  # NIX (the package manager itself)
  # ============================================================
  # I'm enabling flakes and the modern `nix` CLI. I need this for nix-direnv,
  # `nh`, and pretty much every modern NixOS guide I follow. Definitely safe to leave on.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # I want to hard-link identical files in my /nix/store to save precious disk space.
  # It has a tiny build-time overhead, but the space savings over months of updates are huge.
  nix.settings.auto-optimise-store = true;

  # I need automatic garbage collection, otherwise my /nix/store will grow
  # forever. I'll configure it to run weekly and wipe out profile generations
  # older than 14 days that my active system isn't referencing. If I need a
  # bigger rollback safety net, I can change "14d" to "30d" or "90d".
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # --- Channel / package source (STABLE) -------------------------------
  # My `pkgs` here resolves to whatever my local `nixos` channel is tracking.
  # Since I've upgraded my flake inputs to 26.05, my packages now pull from the
  # stable 26.05 branch, matching my inputs. If I were still using legacy channels,
  # I'd expect my channel to point to https://nixos.org/channels/nixos-26.05.
  #
  # I can verify channels any time with:
  #     sudo nix-channel --list
  # Expected:
  #     nixos https://nixos.org/channels/nixos-26.05
  #
  # If it gets messed up (like if I accidentally tracked unstable), I can fix it with:
  #     sudo nix-channel --remove nixos
  #     sudo nix-channel --add https://nixos.org/channels/nixos-26.05 nixos
  #     sudo nix-channel --update
  #     sudo nixos-rebuild switch
  #
  # Now that 26.05 is active, I've updated my flake to point to the 26.05 release.
  # I'm keeping my system.stateVersion at "25.11" (since that's what it was when
  # I first installed), but my packages are happily on 26.05.

  # ============================================================
  # NETWORKING
  # ============================================================
  networking.hostName = "nixos"; # I'll set my hostname to "nixos".
  # networking.wireless.enable = true;  # I can uncomment this if I need wireless support via wpa_supplicant.

  # I can configure a network proxy here if I ever find myself behind one:
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # I need NetworkManager enabled for easy Wi-Fi and ethernet management.
  networking.networkmanager.enable = true;

  # --- Tailscale (OPTIONAL) --------------------------------------------
  # I can uncomment this to enable Tailscale: a drop-in mesh VPN that lets me
  # reach this laptop from my other devices without fiddling with port forwarding.
  # Once enabled and rebuilt, I'll need to run `sudo tailscale up` to log in.
  # services.tailscale.enable = true;

  # --- Avahi / mDNS (OPTIONAL) -----------------------------------------
  # I can enable this to let `.local` hostnames resolve on my LAN (for example,
  # so I can run `ssh laptop.local`). Handy since I have other Linux/macOS boxes.
  # It's totally harmless on my home network, though some corporate networks block it.
  # services.avahi = {
  #   enable = true;
  #   nssmdns4 = true;
  #   openFirewall = true;
  # };

  # I'll set my time zone to Winnipeg.
  time.timeZone = "America/Winnipeg";

  # I'll stick with Canadian English for my default locale settings.
  i18n.defaultLocale = "en_CA.UTF-8";

  # ============================================================
  # DESKTOP — X11 / GNOME
  # ============================================================
  # I need to enable the X11 windowing system so GNOME can start.
  services.xserver.enable = true;

  # I want to use GNOME as my desktop environment.
  # Note to self: ever since NixOS 25.11, display- and desktop-manager options
  # moved out from under `services.xserver.*` to the top-level
  # `services.displayManager.*` and `services.desktopManager.*` since they're
  # no longer strictly X11-specific (Wayland uses them too). The old paths
  # would still work but they spit out deprecation warnings that I want to avoid.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # --- Strip GNOME bloat -----------------------------------------------
  # GNOME ships with a bunch of default apps I'm never going to use. I'm excluding
  # them here so they don't clutter my app grid or bloat my nix store closure.
  # If I ever need one of these back, I can just delete it from this list.
  environment.gnome.excludePackages = (
    with pkgs;
    [
      gnome-tour # I don't need a first-run tutorial slideshow
      gnome-connections # I don't use this RDP/VNC client
      epiphany # I use Firefox instead of this GNOME Web browser
      geary # I don't need this email client
      totem # I use mpv for video playing
      yelp # I don't need the GNOME help viewer
      gnome-music # I don't use the GNOME music player
      gnome-contacts # I don't need a contacts manager here
      gnome-maps # I don't need GNOME Maps on my laptop
      gnome-weather # I don't need this weather widget
      gnome-clocks # I don't need this clock/timer app
      simple-scan # I don't have a scanner hooked up
      cheese # I don't need the webcam toy
    ]
  );

  # GNOME ships its own power daemon, but I'm disabling it because I use TLP
  # below to get much better control over my laptop's battery life. The two
  # daemons conflict, so I have to pick one. If I ever decide to go back to
  # GNOME's built-in power-profiles-daemon, I'll turn off my TLP config below
  # and flip this to true.
  services.power-profiles-daemon.enable = false;

  # I'll stick to a standard US keyboard layout for X11.
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # I want to enable CUPS so I can print documents when I need to.
  services.printing.enable = true;

  # ============================================================
  # AUDIO — PipeWire
  # ============================================================
  # I'm setting up my audio using PipeWire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # I can uncomment this if I ever need to run JACK audio applications
    #jack.enable = true;

    # I don't need to specify a session manager since WirePlumber is standard now and
    # handles everything out of the box.
    #media-session.enable = true;
  };

  # I don't need to explicitly enable touchpad support since GNOME enables it by default.
  # services.xserver.libinput.enable = true;

  # ============================================================
  # BLUETOOTH
  # ============================================================
  # Stock NixOS leaves Bluetooth disabled, but I'm turning it on because this is a
  # laptop. I'll use `powerOnBoot` to bring the radio up automatically on boot so
  # my devices reconnect without me having to manually click anything. GNOME's settings
  # panel will show it automatically.
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # --- Blueman tray applet (OPTIONAL) ----------------------------------
  # I can uncomment this to get the Blueman tray applet, but it's only really
  # useful if I ever switch away from GNOME to a tiling window manager (like Sway/Hyprland)
  # since GNOME already has a great Bluetooth UI built right into its panel.
  # services.blueman.enable = true;

  # ============================================================
  # LAPTOP POWER MANAGEMENT — TLP
  # ============================================================
  # I'm using TLP to manage my laptop's power settings (spinning down disks, CPU scaling governors,
  # battery charge thresholds, etc.). It gives me great defaults right out of the box.
  # The configuration below is relatively conservative — I'd tweak the start/stop charge thresholds
  # if my battery hardware supported it (mostly a ThinkPad/Dell thing).
  services.tlp = {
    enable = true;
    settings = {
      # I want maximum performance when I'm plugged in, and powersave mode when on battery.
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Energy-performance preference for my AMD CPU.
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Battery charge thresholds (only works on ThinkPad-style hardware; others ignore it).
      # I can uncomment these if I want to limit charging to extend battery lifespan.
      # START_CHARGE_THRESH_BAT0 = 75;
      # STOP_CHARGE_THRESH_BAT0  = 80;
    };
  };

  # --- auto-cpufreq alternative (OPTIONAL) -----------------------------
  # I can uncomment this if I want to try auto-cpufreq instead of TLP. It's
  # more reactive and focuses on CPU scaling. If I use it, I'll need to disable TLP.
  # services.auto-cpufreq.enable = true;

  # ============================================================
  # SYSTEM RELIABILITY / PERFORMANCE
  # ============================================================
  # I'll set up compressed in-RAM swap using zram. It treats a chunk of my RAM as
  # compressed swap before hitting my SSD. This is a huge win for my dev workflow
  # because heavy browser tabs and LSP servers can swap without grinding my SSD.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # I'm explicitly enabling systemd-oomd to kill runaway processes when my memory
  # pressure spikes, rather than letting the entire system lock up. NixOS turns it
  # on by default anyway, but I like having it explicitly written down here.
  systemd.oomd.enable = true;

  # I'll enable fstrim to run weekly via a systemd timer. This tells my SSD
  # which blocks are free so it can run its internal garbage collection and stay fast.
  services.fstrim.enable = true;

  # ============================================================
  # USERS
  # ============================================================
  # Setting up my main user account. I need to make sure I run `passwd` to set my password.
  users.users.chahat = {
    isNormalUser = true;
    description = "Chahatpreet Singh";
    # Adding my user to `video` so I can adjust screen brightness without needing sudo.
    # I'll need to add "docker" or "libvirtd" here later if I enable those services.
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
    ];

    # I want zsh to be my default login shell since my dotfiles in ~/dotfiles/zsh expect it.
    # Enabling `programs.zsh.enable` below registers it so this setting is validated.
    shell = pkgs.zsh;

    # I'll keep this per-user packages list empty on purpose. I prefer installing
    # packages system-wide in `environment.systemPackages` below so that any other user
    # account I create gets the exact same tools. I'd only put things here if they were
    # private or license-restricted to my user alone.
    packages = with pkgs; [
    ];
  };

  # I'm enabling zsh system-wide. I'm deliberately NOT using the NixOS modules for
  # zsh-autosuggestions or syntax-highlighting because my dotfiles manage these via
  # antidote — double-loading them would just slow down my shell startup.
  programs.zsh.enable = true;

  # ============================================================
  # APPS / TOOLS
  # ============================================================
  # Firefox is my primary web browser, so I'll enable it here.
  programs.firefox.enable = true;

  # I'm setting up direnv with nix-direnv. Since my dotfiles already source the direnv hook
  # in my zsh configuration (`eval "$(direnv hook zsh)"`), I just need this nix-direnv glue
  # to cache environments so `use flake` and `use nix` are blazing fast when I cd into projects.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # I'm enabling nix-index to quickly find which package provides a given command.
  # This gives me the comma (`,`) helper (e.g. I can run `, cowsay hi` to run it instantly).
  # It also hooks into my shell to suggest packages when I type a command that isn't installed.
  # I'll disable the legacy command-not-found service below so they don't fight.
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.command-not-found.enable = false;

  # My git config signs commits using my SSH key (signingkey = ~/.ssh/id_ed25519),
  # so I need an SSH agent running to manage my passphrase-protected keys.
  #
  # On GNOME I DO NOT want to enable `programs.ssh.startAgent`. GNOME 47+ ships
  # `services.gnome.gcr-ssh-agent` (enabled automatically with GNOME), which is a
  # keyring-backed SSH agent. If I enable both, NixOS will throw an evaluation error
  # because they conflict. Let's let the GNOME default win. I'll just run `ssh-add`
  # once and the GNOME keyring will remember my passphrase and unlock it when I log in.
  #
  # If I ever move off GNOME, I'll need to uncomment the plain OpenSSH agent:
  # programs.ssh.startAgent = true;
  #
  # Note to self: my dotfiles contain `ssh-add --apple-load-keychain`, which is macOS-only.
  # Here on NixOS, I just run `ssh-add` once and the keyring handles the rest.

  # ============================================================
  # NEOVIM / MASON SUPPORT
  # ============================================================
  # Mason (the LSP/DAP/linter installer for my kickstart Neovim setup) has two major
  # pain points on NixOS that I don't have to deal with on macOS:
  #
  # 1. Mason downloads prebuilt binaries that expect a standard FHS glibc. They fail
  #    with "no such file or directory" on NixOS because the loader path is different.
  #    I use `programs.nix-ld` to provide a shim at /lib64/ld-linux-* so these binaries
  #    can run. If a server complains about a missing library, I'll add it to the list here.
  #
  # 2. Mason also builds some servers from source, meaning I need node/python/go/cargo on
  #    my $PATH. I've installed these globally in my `systemPackages` below.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib # libstdc++ — I need this for a lot of Mason language servers
      zlib # Compression library — required by almost everything
      openssl # TLS support — needed by servers that talk to online registries
      curl # I need libcurl for networking tools
      icu # Unicode libraries — used by some language servers
      libxml2
      libsecret # Required for my Antigravity keyring auth fallback
      glib
    ];
  };

  # --- GnuPG agent (OPTIONAL) ------------------------------------------
  # I can enable this if I ever start using GPG keys for encrypted emails or
  # package signing. Since I sign all my git commits with SSH instead, I can leave this off.
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # I can enable SUID wrappers or start user agents here if needed:
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

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
    noto-fonts-color-emoji # Color emojis (NixOS renamed this in 25.11)
  ];

  # I need to allow unfree packages so I can install proprietary software.
  nixpkgs.config.allowUnfree = true;

  # ============================================================
  # SYSTEM PACKAGES
  # ============================================================
  # These are my system-wide packages. To find new ones, I can run `nix search wget`.
  # This block acts as the NixOS equivalent of my macOS Brewfile, along with some
  # handy NixOS-specific utility programs.
  environment.systemPackages = with pkgs; [
    # I should ensure I have an editor installed so I don't lock myself out of configuration edits.
    #  wget

    # --- Editor ---
    neovim # My main editor, configured via kickstart in ~/.config/nvim

    # --- Terminal & multiplexer ---
    kitty # My primary terminal emulator
    tmux # Terminal multiplexer for managing sessions

    # --- Shell prompt + plugin manager ---
    # Note to self: Nix paths differ from macOS. In my ~/.zshrc, I must handle:
    #   - antidote path: `/run/current-system/sw/share/antidote/antidote.zsh`
    #     (my macOS source line won't work here on Linux)
    #   - powerlevel10k is handled by antidote, so I don't need it built here
    antidote

    # --- File search & navigation (mirrors my macOS Brewfile) ---
    fd # Fast search replacement for `find`
    fzf # Fuzzy finder for history and files
    ripgrep # High-speed search tool (`rg`)
    zoxide # Smart cd helper (`z`)
    bat # Better cat with syntax highlighting
    eza # Modern replacement for `ls` that my aliases depend on
    tealdeer # Rust-based client for tldr man page summaries
    # Rebuilding `nnn` with nerd icons. Using the Nix `.override` function is how I customize
    # compile-time flags like `withNerdIcons = true` to make it render icons properly.
    (nnn.override { withNerdIcons = true; })

    # --- Git tools (mirrors Brewfile) ---
    git
    pre-commit
    gh # GitHub CLI for managing PRs and issues from my terminal

    # --- Downloads & media (mirrors Brewfile) ---
    aria2 # multi-connection downloader
    yt-dlp # YouTube / video downloader
    mpv # media player

    # --- Cloud & backup (mirrors Brewfile) ---
    rclone # Rclone sync tool for cloud storage (my aliases depend on it)
    borgbackup # Encrypted, deduplicating backups

    # --- Dev tooling (mirrors Brewfile) ---
    yamlfmt # YAML linter by google
    direnv # per-directory env loading (also enabled as program above)
    stow # Dotfiles manager (I also use this on macOS)

    # --- Build essentials (I'll need these the first time I try to run `make`) ---
    clang-tools # Installs the clang toolkit, provides clang, clang-format etc.
    gcc
    gnumake
    pkg-config

    # --- Mason / Neovim toolchain ------------------------------------
    # I need these toolchains on my global $PATH so that Mason in Neovim can download
    # and build LSP/linter servers. Putting them here makes my editor setup "just work"
    # without surprise build failures. I can swap to per-project devshells later.
    nodejs_22 # typescript-language-server, prettier, eslint_d, vscode-* servers
    python3 # pyright, ruff, debugpy, etc.
    go # gopls, golangci-lint, delve
    cargo # rust-analyzer (when built from source) + many Mason tools
    rustc # paired with cargo
    tree-sitter # tree-sitter CLI — nvim-treesitter `:TSUpdate` calls this

    # --- Java toolchain ----------------------------------------------
    # Using the default OpenJDK from nixpkgs. I'll get the LTS version (JDK 21 on 25.11/26.05).
    # If I need to pin a specific version, I can use `jdk17`, `jdk21`, etc.
    #
    # My environment wrapper sets $JAVA_HOME automatically, meaning `java`, `javac`, and
    # `jshell` will be on my $PATH. I can use direnv flakes for per-project JDK versions later.
    jdk # OpenJDK (latest LTS in this channel)
    maven # Maven build tool — `mvn`
    gradle # Gradle build tool — `gradle`
    # jdt-language-server     # Eclipse JDT LSP — uncomment if you'd rather not let Mason manage it
    # google-java-format      # Java formatter
    # checkstyle              # Java linter

    # --- NixOS-specific helpers ---
    nh # My modern CLI wrapper for rebuilds so I can see diffs easily
    nix-output-monitor # Prettier terminal output when building nix packages
    nvd # Package diff tool so I can see exactly what changed between system updates
    pkgs.nixfmt # Official nix repo formatter

    # --- nixpkgs contributor toolkit ---------------------------------
    # My toolkit for contributing to the nixpkgs repository. These match what's in the
    # nixpkgs CONTRIBUTING.md guidelines. They help me write, lint, format, and test
    # new package definitions.
    #
    # My typical development workflow:
    #   1. `nixpkgs-review pr 12345`    → review and build a PR in a sandbox
    #   2. `nix-update <attr>`          → bump package version and update its hash
    #   3. `nurl <url>`                 → get the fetcher setup for a URL
    #   4. `nix-init <url>`             → bootstrap a brand new derivation
    #   5. `nixfmt-rfc-style file.nix`  → format my Nix code according to RFC 166
    #   6. `statix check .`             → run the style linter
    #   7. `deadnix .`                  → scan for any unused nix variables
    nixpkgs-review # Build + test PRs locally in a sandbox
    nix-update # Auto-bump version + sha256 of a package
    nurl # Generate fetchFrom* expressions from URLs
    nix-init # Boilerplate generator for new packages
    nixfmt-rfc-style # Official nixpkgs formatter (RFC 166)
    statix # Lints / suggests idiomatic Nix
    deadnix # Finds dead code in .nix files
    nix-tree # Interactive TUI for /nix/store closures
    nix-diff # Diff two derivations attribute-by-attribute
    nil # Nix LSP — pair with nvim's lspconfig
    # nixd                    # Alternative Nix LSP (richer, heavier). Pick one.
    # vulnix                  # Scans your closure for known CVEs
    # editorconfig-checker    # nixpkgs CI uses this; nice for local checks

    # Note to self: when I `cd` into my local nixpkgs clone, I should drop a `.envrc`
    # with `use nix` or `use flake` so direnv automatically loads the tree's dev shell.

    # --- GNOME tweakability ---
    gnome-tweaks # To change hidden GNOME settings like fonts and animations
    dconf-editor # Registry editor for GNOME settings — I should use this carefully

    # --- General system utilities ---
    htop # Classic process monitor
    btop # Modern, pretty terminal process monitor
    unzip # For extracting zip archives
    zip
    p7zip # 7z format support (my `extract` shell function depends on it)
    unrar # RAR support (my `extract` function calls this)
    curl
    wget
    file # Identify file types
    tree # ASCII directory tree

    # --- OPTIONAL: extra git tooling --------------------------------
    # I can uncomment these if I want additional git CLI helpers.
    # lazygit                 # TUI git client
    delta # Better git diff pager, matching my gitconfig setup

    # --- OPTIONAL: extra language toolchains -------------------------
    # I've already installed Node, Python, Go, Rust, and Java above.
    # For other languages, I prefer using per-project devshells instead of global installs.
    # rustup                  # rustc/cargo toolchain manager (replaces the cargo+rustc above if you prefer multiple toolchains)
    # zig
    # ghc                     # Haskell
    # ruby
    # kotlin                  # JVM, pairs nicely with the jdk above
    # scala                   # JVM, ditto

    # --- Password manager ---
    keepassxc # My local KeePass password database reader

    # --- Security and Keychain injection handling ---
    libsecret

    # --- Mail ---
    thunderbird # My preferred desktop email client

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
    # Rebuilding isn't enough to activate these — I must also turn them on in gnome-tweaks.
    # gnomeExtensions.appindicator      # Legacy tray-icon support
    # gnomeExtensions.user-themes       # Custom shell themes
    # gnomeExtensions.dash-to-dock      # macOS-style permanent dock
    # gnomeExtensions.blur-my-shell     # Cosmetic blur
  ];

  # ============================================================
  # SERVICES (commented, opt-in)
  # ============================================================

  # I can enable these background services if I ever need them:

  # Enable the OpenSSH daemon for remote SSH access.
  # services.openssh.enable = true;

  # --- Flatpak (OPTIONAL) ----------------------------------------------
  # I can uncomment this to enable Flatpaks, which is useful for proprietary GUI apps
  # that aren't in nixpkgs or are outdated. It requires setting up xdg-desktop-portal.
  # services.flatpak.enable = true;
  # xdg.portal.enable = true;
  # xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

  # --- Podman / containers (OPTIONAL) ----------------------------------
  # I can enable Podman here for a rootless container environment. It's drop-in compatible
  # with the Docker CLI. I prefer this on NixOS since it doesn't run a system-wide daemon.
  # I should add myself to the "podman" group if I want socket access without sudo.
  # virtualisation.podman = {
  #   enable = true;
  #   dockerCompat = true;
  #   defaultNetwork.settings.dns_enabled = true;
  # };

  # --- Docker alternative (OPTIONAL) -----------------------------------
  # Alternative to Podman. I must only pick one of the two. If I use Docker, I need
  # to add myself to the "docker" group under users.users.chahat.extraGroups.
  # virtualisation.docker.enable = true;

  # --- Libvirt / VMs (OPTIONAL) ----------------------------------------
  # I can enable virtualisation here to run local VMs (like other distros or Windows)
  # via KVM/QEMU and virt-manager. I'll need to add my user to "libvirtd" as well.
  # virtualisation.libvirtd.enable = true;
  # programs.virt-manager.enable = true;

  # --- Borg automated backup (OPTIONAL) --------------------------------
  # I can enable nightly automated Borg backups of my home directory here.
  # I'll need to run `borg init` on the target repository first before the schedule works.
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
  # I'm using Syncthing for peer-to-peer directory syncing across my devices.
  # I can access the UI at http://localhost:8384 to link devices and folders.
  # On first launch, it will show my Device ID which I can share to pair my devices.
  #
  # Syncthing defaults to my home directory as the data base path.
  services.syncthing = {
    enable = true;
    user = "chahat";
    dataDir = "/home/chahat";
    configDir = "/home/chahat/.config/syncthing";

    # I want these set to false so any directories or devices I link in the web UI
    # persist across my system rebuilds. If I turned this to true, I'd have to define
    # every single device/folder in this Nix file, or else it would wipe them out.
    overrideDevices = false;
    overrideFolders = false;
  };

  # ============================================================
  # FIREWALL
  # ============================================================
  # Since NixOS turns on the firewall by default, I need to open the ports
  # that my background services use to communicate with my local network.
  #
  # Ports I need open for Syncthing:
  #   22000 TCP/UDP — for the encrypted syncing traffic
  #   21027 UDP     — for local network discovery protocol
  #   8384  TCP     — my admin UI (I intentionally keep this closed to external networks)
  networking.firewall.allowedTCPPorts = [ 22000 ];
  networking.firewall.allowedUDPPorts = [
    22000
    21027
  ];

  # If I ever want to disable the firewall entirely, I'd uncomment this:
  # networking.firewall.enable = false;

  # This value sets the initial NixOS release version of this system's install to determine
  # legacy default behaviors for databases and state files. I should leave this alone
  # even when I upgrade my package channels/flakes so I don't break existing databases.
  system.stateVersion = "25.11"; # Yes, I read the comment. I'm keeping it at my original install version.

}
