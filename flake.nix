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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # macOS system management (pinned to match 25.11 stable)
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      # Forces nix-darwin to use your nixpkgs input instead of downloading its own
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, ... }@inputs: {

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
    # LINUX (oci)
    # ============================================================
    # Build with: nh os switch
    nixosConfigurations."oci" = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        # Updated to reflect the new host-based directory structure
        ./hosts/oci/configuration.nix
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
