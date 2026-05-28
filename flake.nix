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
    # Pins the system to the 25.11 stable branch
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    # macOS system management (pinned to match 25.11 stable)
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      # Forces nix-darwin to use your nixpkgs input instead of downloading its own
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add Home Manager input
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }@inputs: {

    # ============================================================
    # LINUX (NixOS)
    # ============================================================
    # Build with: nh os switch
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Updated to reflect the new host-based directory structure
        ./hosts/nixos/hardware-configuration.nix
        ./hosts/nixos/configuration.nix
      ];
    };

    # ============================================================
    # UBUNTU (Standalone Home Manager on OCI)
    # ============================================================
    # Build with: home-manager switch --flake .#ubuntu
    homeConfigurations."ubuntu" = home-manager.lib.homeManagerConfiguration {
      # Pass the architecture of your OCI (aarch64 for ARM, x86_64 for AMD/Intel)
      pkgs = nixpkgs.legacyPackages."aarch64-linux";
      # Optional: Pass inputs to modules if you need them
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ./hosts/oci/home.nix
      ];
    };

    # ============================================================
    # macOS (nix-darwin)
    # ============================================================
    # Build with: nh darwin switch
    # The string "macbook" must match your hostname or your build command target
    darwinConfigurations."macbook" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        # Points directly to the isolated macOS user configuration
        ./hosts/macbook/configuration.nix
      ];
    };

  };
}
