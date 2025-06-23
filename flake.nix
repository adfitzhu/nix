{
  description = "NixOS install for non-tech users with auto updating and initial set of software";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      gaming = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (import /mnt/etc/nixos/hardware-configuration.nix)
          (import /mnt/etc/nixos/host-config.nix (
            (import /mnt/etc/nixos/host-args.nix)
            // {
              swapSize = "8GiB";
              autoUpgradeFlake = "github:adfitzhu/nix#gaming";
              extraPackages = with import nixpkgs { system = "x86_64-linux"; }; [
                git vscode clonehero
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
            }
          ))
        ];
      };
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (import /mnt/etc/nixos/hardware-configuration.nix)
          (import /mnt/etc/nixos/host-config.nix (
            (import /mnt/etc/nixos/host-args.nix)
            // {
              swapSize = "4GiB";
              autoUpgradeFlake = "github:adfitzhu/nix#desktop";
              extraPackages = with import nixpkgs { system = "x86_64-linux"; }; [
                libreoffice vlc
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
            }
          ))
        ];
      };
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (import /mnt/etc/nixos/hardware-configuration.nix)
          (import /mnt/etc/nixos/host-config.nix (
            (import /mnt/etc/nixos/host-args.nix)
            // {
              swapSize = "17GiB";
              autoUpgradeFlake = "github:adfitzhu/nix#laptop";
              extraPackages = with import nixpkgs { system = "x86_64-linux"; }; [
                libreoffice vlc
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
            }
          ))
          {
            boot.loader.systemd-boot.enable = true;
            boot.loader.systemd-boot.configurationLimit = 10;
            boot.loader.systemd-boot.configurationName = "laptop";
            boot.loader.efi.canTouchEfiVariables = true;
          }
        ];
      };
    };
    apps = {};
    packages = {};
  };
}