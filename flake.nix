{
  description = "NixOS flake for laptop and desktop hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ({ ... }: {
            _module.args = {
              autoUpgradeFlake = "github:adfitzhu/nix#desktop";
              myRepoPath = "/usr/local/nixos";
            };
          })
          ./base-config.nix
          ({ pkgs, ... }: {
            users.users.adam = {
              isNormalUser = true;
              extraGroups = [ "networkmanager" "wheel" "vboxsf" "dialout" "audio" "video" "input" "docker" ];
            };
            environment.systemPackages = [
              pkgs.git
              pkgs.vscode

            ];
            services.sunshine.enable = true;
          })
        ];
      };
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ({ ... }: {
            _module.args = {
              autoUpgradeFlake = "github:adfitzhu/nix#laptop";
              myRepoPath = "/usr/local/nixos";
            };
          })
          ./base-config.nix
          ({ pkgs, ... }: {
            users.users.adam = {
              isNormalUser = true;
              extraGroups = [ "networkmanager" "wheel" "vboxsf" "dialout" "audio" "video" "input" "docker" ];
            };
            environment.systemPackages = [
              pkgs.git
              pkgs.vscode
              pkgs.clonehero
              pkgs.kdePackages.yakuake
              pkgs.firefox
            ];
          })
        ];
      };
      generic = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ({ ... }: {
            _module.args = {
              autoUpgradeFlake = "github:adfitzhu/nix#generic";
              myRepoPath = "/usr/local/nixos";
            };
          })
          ./base-config.nix
          ({ pkgs, ... }: {
            users.users.adam = {
              isNormalUser = true;
              extraGroups = [ "networkmanager" "wheel" ];
            };
            # No extra packages or services for generic
          })
        ];
      };
    };
  };
}
