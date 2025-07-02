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
            system.autoUpgrade = {
              enable = true;
              dates = "weekly";
              flake = "github:adfitzhu/nix#desktop";
              allowReboot = false;
            };
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
            system.autoUpgrade = {
              enable = true;
              dates = "weekly";
              flake = "github:adfitzhu/nix#laptop";
              allowReboot = false;
            };
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
            };
          })
          ./base-config.nix
          ({ pkgs, ... }: {
            users.users.adam = {
              isNormalUser = true;
              extraGroups = [ "networkmanager" "wheel" ];
            };
            environment.systemPackages = [
              pkgs.git
              pkgs.vscode
              pkgs.wcalc
            ];
            system.autoUpgrade = {
              enable = true;
              dates = "weekly";
              flake = "github:adfitzhu/nix#generic";
              allowReboot = false;
            };
          })
        ];
      };
    };
  };
}
