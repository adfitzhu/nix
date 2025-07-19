{
  description = "NixOS flake for laptop and desktop hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-flatpak.url = "github:gmodena/nix-flatpak"; # Add this
  };

  outputs = { self, nixpkgs, home-manager, nix-flatpak, ... }: {
    nixosConfigurations = {
      alphanix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ({ ... }: {
            _module.args = {
              autoUpgradeFlake = "github:adfitzhu/nix#alphanix";
            };
          })
          ./base-config.nix
          nix-flatpak.nixosModules.nix-flatpak
          ({ pkgs, ... }: {
            users.users.adam = {
              isNormalUser = true;
              extraGroups = [ "networkmanager" "wheel" "vboxsf" "dialout" "audio" "video" "input" "docker" ];
            };
            environment.systemPackages = with pkgs; [
            orca-slicer
            ];
            
            # Flatpak packages for this host
            services.flatpak.packages = [
              "com.usebottles.bottles"
              "com.heroicgameslauncher.hgl"
              "com.discordapp.Discord"
              "com.obsproject.Studio"
              "com.github.tchx84.Flatseal"
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
              remotePlay.openFirewall = true;
              dedicatedServer.openFirewall = true;
              localNetworkGameTransfers.openFirewall = true;
            };
            services.sunshine.enable = true;
            systemd.services.my-auto-upgrade = {
              description = "Custom NixOS auto-upgrade (host-specific)";
              serviceConfig.Type = "oneshot";
              script = ''
                set -euxo pipefail
                ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --upgrade --flake github:adfitzhu/nix#alphanix --no-write-lock-file --impure
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
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.adam = import ./home/adam/home.nix;
          }
        ];
      };
      
      yactop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ({ ... }: {
            _module.args = {
              autoUpgradeFlake = "github:adfitzhu/nix#yactop";
            };
          })
          ./base-config.nix
          ({ pkgs, ... }: {
            networking.hostName = "yactop";
            users.users.beth = {
              isNormalUser = true;
              group = "beth";
              extraGroups = [ "networkmanager" "wheel" "vboxsf" "dialout" "audio" "video" "input" "docker" ];
            };
            users.groups.beth = {};
            environment.systemPackages = with pkgs; [
              obs-studio
              droidcam
              obs-studio-plugins.droidcam-obs
              kdePackages.skanpage
              audacity
              clementine
              superTuxKart
            ];
            
            # Flatpak packages for this host
            services.flatpak.packages = [
              "com.microsoft.Edge"

            ];
            
            services.xserver.enable = false;
            services.displayManager = {
              sddm.enable = true;
              sddm.wayland.enable = true;
              autoLogin = {
                enable = true;
                user = "beth";
              };
            };
            systemd.services.my-auto-upgrade = {
              description = "Custom NixOS auto-upgrade (host-specific)";
              serviceConfig.Type = "oneshot";
              script = ''
                set -euxo pipefail
                ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --upgrade --refresh --flake github:adfitzhu/nix#yactop --no-write-lock-file --impure
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
          home-manager.nixosModules.home-manager
          nix-flatpak.nixosModules.nix-flatpak
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.beth = import ./home/beth/home.nix;
          }
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
          nix-flatpak.nixosModules.nix-flatpak
          ({ pkgs, ... }: {
            users.users.nixos = {
              isNormalUser = true;
              extraGroups = [ "networkmanager" "wheel" ];
            };
            environment.systemPackages = [

            ];
            
            # Flatpak packages for this host
            services.flatpak.packages = [
              "com.github.tchx84.Flatseal"
              "org.mozilla.firefox"
              "org.libreoffice.LibreOffice"
            ];
            
            services.xserver.enable = false;
            services.displayManager = {
              sddm.enable = true;
              sddm.wayland.enable = true;
              autoLogin = {
                enable = true;
                user = "nixos";
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
          nix-flatpak.nixosModules.nix-flatpak
          ({ pkgs, ... }: {
            users.users.nixos = {
              isNormalUser = true;
              extraGroups = [ "networkmanager" "wheel" "vboxsf" "dialout" "audio" "video" "input" "docker" ];
            };
            environment.systemPackages = with pkgs; [

            ];
            
            # Flatpak packages for this host
            services.flatpak.packages = [
              "com.github.tchx84.Flatseal"
              "org.mozilla.firefox"
              "org.libreoffice.LibreOffice"
              "com.spotify.Client"
            ];
            
            services.xserver.enable = false;
            services.displayManager = {
              sddm.enable = true;
              sddm.wayland.enable = true;
              autoLogin = {
                enable = true;
                user = "nixos";
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



    };
  };
}
