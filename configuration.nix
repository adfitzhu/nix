{ config, pkgs, ... }:
{
`  imports = [
    ./hardware-configuration.nix

  ];
  networking.hostName = "adam";
  users.users.adam = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
  environment.systemPackages = with pkgs; [
    kdePackages.kate
    kdePackages.discover
    timeshift
    kdePackages.kdesu
    clementine
    libreoffice
    vlc
    git
    vscode
    libnotify
    flatpak
  ];
  time.timeZone = "America/Los_Angeles";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };
  services.xserver.enable = false;
  services.displayManager = {
    sddm.enable = true;
    sddm.wayland.enable = true;
    autoLogin = {
      enable = true;
      user = "adam";
    };
  };
  services.desktopManager.plasma6.enable = true;
  services.printing = {
    enable = true;
    browsing = true;
    drivers = [ pkgs.epson-escpr2 ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };
  security.rtkit.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  services.openssh.enable = true;
  services.tailscale.enable = true;
  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };
  systemd.services.initial-flatpaks = {
    description = "Install initial Flatpaks";
    wantedBy = [ "multi-user.target" ];
    after = [ "flatpak-repo.service" ];
    path = [ pkgs.flatpak ];
    serviceConfig.Type = "oneshot";
    script = ''
      #!/bin/sh
      MARKER=/var/lib/initial-flatpaks.done
      if [ -e "$MARKER" ]; then
        exit 0
      fi
      for app in \
        com.obsproject.Studio \
        org.audacityteam.Audacity \
        org.kde.audiotube \
        org.kde.kdenlive \
        org.clementine_player.Clementine \
        fr.handbrake.ghb \
        com.makemkv.MakeMKV \
        io.github.JaGoli.ytdl_gui \
        io.freetubeapp.FreeTube \
        org.kde.audiotube \
        com.usebottles.bottles \
        com.nextcloud.desktopclient \
        org.kde.skanpage \
        net.supertuxkart.SuperTuxKart
      do
        flatpak install -y --noninteractive flathub "$app"
      done
      touch "$MARKER"
    '';
  };

  system.stateVersion = "25.05";
}
