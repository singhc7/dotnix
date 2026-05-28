# dotnix — Multi-OS System Flake
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

{
  description = "Chahat's Multi-OS System Flake";

  inputs = {
    # Pins my system package inputs to the 26.05 stable branch
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    # My macOS system management tool (pinned to match 26.05 stable)
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      # I want to force nix-darwin to use my nixpkgs input instead of downloading its own
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # I'll add the Home Manager input for my user environments (standalone on OCI VM)
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }@inputs: {

    # ============================================================
    # LINUX (NixOS)
    # ============================================================
    # I build this config with: nh os switch
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # I updated these paths to reflect my new host-based directory structure
        ./hosts/nixos/hardware-configuration.nix
        ./hosts/nixos/configuration.nix
      ];
    };

    # ============================================================
    # UBUNTU (Standalone Home Manager on OCI)
    # ============================================================
    # I build this config with: home-manager switch --flake .#ubuntu
    homeConfigurations."ubuntu" = home-manager.lib.homeManagerConfiguration {
      # I need to specify the architecture of my OCI VM instance (ARM is aarch64-linux)
      pkgs = nixpkgs.legacyPackages."aarch64-linux";
      # I can pass inputs down to the modules if I ever need to reference them in home.nix
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ./hosts/oci/home.nix
      ];
    };

    # ============================================================
    # macOS (nix-darwin)
    # ============================================================
    # I build this config with: nh darwin switch
    # The key "macbook" here needs to match my target hostname or my build command target
    darwinConfigurations."macbook" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        # This points directly to my isolated macOS user-level configuration
        ./hosts/macbook/configuration.nix
      ];
    };

  };
}
