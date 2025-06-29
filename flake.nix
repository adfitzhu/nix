{
  description = "NixOS flake for laptop and desktop hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        nixosConfigurations = {
          desktop = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              /etc/nixos/hardware-configuration.nix
              ./base-config.nix
              ({ pkgs, config, ... }: {
                autoUpgradeFlake = "github:adfitzhu/nix#desktop";
                myRepoPath = "/etc/nixos";
                users.users.adam = {
                  isNormalUser = true;
                  extraGroups = [ "networkmanager" "wheel" "vboxsf" "dialout" "audio" "video" "input" "docker" ];
                };
                environment.systemPackages = (config.environment.systemPackages or []) ++ [
                  pkgs.git
                  pkgs.vscode
                  pkgs.clonehero
                ];
                services.sunshine.enable = true;
              })
            ];
          };
          laptop = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              /etc/nixos/hardware-configuration.nix
              ./base-config.nix
              ({ pkgs, config, ... }: {
                autoUpgradeFlake = "github:adfitzhu/nix#laptop";
                myRepoPath = "/etc/nixos";
                users.users.adam = {
                  isNormalUser = true;
                  extraGroups = [ "networkmanager" "wheel" "vboxsf" "dialout" "audio" "video" "input" "docker" ];
                };
                # No extra packages/services for laptop
              })
            ];
          };
        };
      }
    );
}
