{
  description = "NixOS install for non-tech users with auto updating and initial set of software";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    disko.url = "github:nix-community/disko";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, disko, flake-utils, ... }:
    let
      hostConfig = import ./host-config.nix;
      diskoConfig = import ./disko-config.nix;
    in
    {
      diskoConfigurations = {
        default = disko.lib.makeConfig {
          modules = [ ./disko-config.nix ];
          device = "/dev/sda";
          swapSize = "17GiB";
        };
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        nixosConfigurations = {
          gaming = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              (hostConfig {
                swapSize = "8GiB";
                autoUpgradeFlake = "github:adfitzhu/nix#gaming";
                extraPackages = with pkgs; [
                  git
                  vscode
                  clonehero
                ];
                initialFlatpaks = [
                  "com.obsproject.Studio"
                  "org.kde.kdenlive"
                  "fr.handbrake.ghb"
                  "com.makemkv.MakeMKV"
                  "io.github.JaGoli.ytdl_gui"
                  "com.usebottles.bottles"
                  "com.heroicgameslauncher.hgl"
                  "com.nextcloud.desktopclient"
                  "org.kde.skanpage"
                  "net.supertuxkart.SuperTuxKart"
                ];
                extraServices = {
                  services.sunshine.enable = true;
                };
                virtualisation.waydroid.enable = true;
              })
              disko.nixosModules.disko
              { disko.devices = diskoConfig { swapSize = "8GiB"; device = "/dev/sda"; }; }
            ];
          };
          desktop = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              (hostConfig {
                swapSize = "4GiB";
                autoUpgradeFlake = "github:adfitzhu/nix#desktop";
                extraPackages = with pkgs; [
                  libreoffice
                  vlc
                ];
                initialFlatpaks = [
                  "com.obsproject.Studio"
                ];
                extraServices = {
                  services.sunshine.enable = true;
                };
              })
              disko.nixosModules.disko
              { disko.devices = diskoConfig { swapSize = "4GiB"; device = "/dev/sda"; }; }
            ];
          };
          laptop = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              (hostConfig {
                swapSize = "17GiB";
                autoUpgradeFlake = "github:adfitzhu/nix#laptop";
                extraPackages = with pkgs; [
                  libreoffice
                  vlc
                ];
                initialFlatpaks = [
                  "com.obsproject.Studio"
                  "com.dev47apps.droidcam"
                  "com.obsproject.Studio.Plugin.OBSVirtualCam"
                  "jp.co.epson.EpsonScan2"
                ];
                extraServices = {
                  services.sunshine.enable = true;
                };
              })
              disko.nixosModules.disko
              { disko.devices = diskoConfig { swapSize = "17GiB"; device = "/dev/sda"; }; }
            ];
          };
        };
      });
}