{
  description = "NixOS install with Btrfs subvolumes and disko";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, disko, flake-utils, ... }:
    let
      hostConfig = import ./host-config.nix;
      diskoConfig = import ./disko-config.nix;
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        nixosConfigurations = {
          gamer-desktop = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              (hostConfig {
                hostname = "gamer-desktop";
                user = "gamer";
                swapSize = "8GiB";
                autoUpgradeFlake = "github:adfitzhu/nix#gamer-desktop";
                extraPackages = with pkgs; [
                  libreoffice
                  vlc
                ];
                initialFlatpaks = [
                  "com.obsproject.Studio"
                  "org.audacityteam.Audacity"
                  "org.kde.audiotube"
                  "org.kde.kdenlive"
                  "org.clementine_player.Clementine"
                  "fr.handbrake.ghb"
                  "com.makemkv.MakeMKV"
                  "io.github.JaGoli.ytdl_gui"
                  "io.freetubeapp.FreeTube"
                  "org.kde.audiotube"
                  "com.usebottles.bottles"
                  "com.nextcloud.desktopclient"
                  "org.kde.skanpage"
                  "net.supertuxkart.SuperTuxKart"
                ];
                extraServices = {
                  services.sunshine.enable = true;
                };
              })
              disko.nixosModules.disko
              { disko.devices = diskoConfig { swapSize = "8GiB"; device = "/dev/sda"; }; }
            ];
          };
          user-desktop = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              (hostConfig {
                hostname = "user-desktop";
                user = "user";
                swapSize = "4GiB";
                autoUpgradeFlake = "github:adfitzhu/nix#user-desktop";
                extraPackages = with pkgs; [
                  libreoffice
                  vlc
                ];
                initialFlatpaks = [
                  "com.obsproject.Studio"
                  "org.audacityteam.Audacity"
                  "org.kde.audiotube"
                ];
                extraServices = {
                  services.sunshine.enable = true;
                };
              })
              disko.nixosModules.disko
              { disko.devices = diskoConfig { swapSize = "4GiB"; device = "/dev/sda"; }; }
            ];
          };
          user-laptop = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              (hostConfig {
                hostname = "user-laptop";
                user = "user";
                swapSize = "17GiB";
                autoUpgradeFlake = "github:adfitzhu/nix#user-laptop";
                extraPackages = with pkgs; [
                  libreoffice
                  vlc
                ];
                initialFlatpaks = [
                  "com.obsproject.Studio"
                  "org.audacityteam.Audacity"
                  "org.kde.audiotube"
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