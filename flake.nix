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
              pkgs.kdePackages.yakuake
              pkgs.orca-slicer

            ];
            services.xserver.enable = false;
            services.displayManager = {
              sddm.enable = true;
              sddm.wayland.enable = true;
              autoLogin = {
                enable = true;
                user = "adam";
              };
            };
            programs.steam = {
              enable = true;
              remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
              dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
              localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
            };
            services.sunshine.enable = true;
            systemd.services.my-auto-upgrade = {
              description = "Custom NixOS auto-upgrade (host-specific)";
              serviceConfig.Type = "oneshot";
              script = ''
                set -euxo pipefail
                ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --upgrade --flake github:adfitzhu/nix#desktop --no-write-lock-file --impure
              '';
            };
            systemd.timers.my-auto-upgrade = {
              description = "Run custom NixOS auto-upgrade weekly (host-specific)";
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnCalendar = "weekly";
                Persistent = true;
              };
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
              pkgs.kdePackages.yakuake
              pkgs.git
              pkgs.vscode
 
            ];
            services.xserver.enable = false;
            services.displayManager = {
              sddm.enable = true;
              sddm.wayland.enable = true;
              autoLogin = {
                enable = true;
                user = "adam";
              };
            };
            systemd.services.my-auto-upgrade = {
              description = "Custom NixOS auto-upgrade (host-specific)";
              serviceConfig.Type = "oneshot";
              script = ''
                set -euxo pipefail
                ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --upgrade --flake github:adfitzhu/nix#laptop --no-write-lock-file --impure
              '';
            };
            systemd.timers.my-auto-upgrade = {
              description = "Run custom NixOS auto-upgrade weekly (host-specific)";
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnCalendar = "weekly";
                Persistent = true;
              };
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
              pkgs.wcalc
            ];
            services.xserver.enable = false;
            services.displayManager = {
              sddm.enable = true;
              sddm.wayland.enable = true;
              autoLogin = {
                enable = true;
                user = "adam";
              };
            };
            systemd.services.my-auto-upgrade = {
              description = "Custom NixOS auto-upgrade (host-specific)";
              serviceConfig.Type = "oneshot";
              script = ''
                set -euxo pipefail
                ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --upgrade --flake github:adfitzhu/nix#generic --no-write-lock-file --impure
              '';
            };
            systemd.timers.my-auto-upgrade = {
              description = "Run custom NixOS auto-upgrade weekly (host-specific)";
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnCalendar = "weekly";
                Persistent = true;
              };
            };
          })
        ];
      };
    };
  };
}
