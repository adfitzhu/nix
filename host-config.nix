{ hostname, user, swapSize, autoUpgradeFlake, extraPackages ? [], initialFlatpaks ? [
  "com.obsproject.Studio"
  "org.audacityteam.Audacity"
  "org.kde.audiotube"
], staticIP ? null, extraServices ? {} }:
{ config, pkgs, ... }:
let
  myRepoPath = "/etc/nixos-flake";
  myRepoUrl = "https://github.com/adfitzhu/nix";
  nixChannel = "https://nixos.org/channels/nixos-25.05";
  basePackages = with pkgs; [
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
  allPackages = basePackages ++ extraPackages;
  baseServices = {
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
    # sunshine intentionally omitted from base
  };
  mergedServices = baseServices // extraServices;
in
{
  # Only set hostname if provided (for adam and server)
  networking.hostName = if hostname != null then hostname else null;
  networking.interfaces = if staticIP != null then {
    "${staticIP.interface}".ipv4.addresses = [{
      address = staticIP.address;
      prefixLength = staticIP.prefixLength;
    }];
  } else {};
  networking.defaultGateway = if staticIP != null then staticIP.gateway else null;
  networking.nameservers = if staticIP != null then [ "192.168.1.60" staticIP.gateway ] else null;
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    # No packages here; all packages are in environment.systemPackages
  };
  environment.systemPackages = allPackages;
  system.autoUpgrade = {
    enable = true;
    flake = autoUpgradeFlake;
    allowReboot = false;
    dates = "weekly";
  };
  # Locale, time, and i18n
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
  # Wayland and desktop environment (Plasma6, SDDM)
  services.xserver.enable = false;
  services.displayManager = {
    sddm.enable = true;
    sddm.wayland.enable = true;
    autoLogin = {
      enable = true;
      user = user;
    };
  };
  services.desktopManager.plasma6.enable = true;
  # Flatpak and Flathub
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
      for app in ${builtins.concatStringsSep " " initialFlatpaks}; do
        flatpak install -y --noninteractive flathub "$app"
      done
      touch "$MARKER"
    '';
  };
  # Merge in base and extra services
  # (Nix will merge attrsets, so extraServices can override baseServices)
  # This must be at the top level
} // mergedServices // {
  notifyUsersScript = pkgs.writeScript "notify-users.sh" ''
    set -eu
    title="$1"
    body="$2"
    users=$(${pkgs.systemd}/bin/loginctl list-sessions --no-legend | ${pkgs.gawk}/bin/awk '{print $1}' | while read session; do
      loginctl show-session "$session" -p Name | cut -d'=' -f2
    done | sort -u)
    for user in $users; do
      [ -n "$user" ] || continue
      uid=$(id -u "$user") || continue
      [ -S "/run/user/$uid/bus" ] || continue
      ${pkgs.sudo}/bin/sudo -u "$user" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
        ${pkgs.libnotify}/bin/notify-send "$title" "$body" || true
    done
  '';

  updateFlakeScript = pkgs.writeScript "update-flake.sh" ''
    set -eu
    # Clone or update your flake repo
    if [ ! -d "${myRepoPath}/.git" ]; then
      rm -rf "${myRepoPath}"
      git clone "${myRepoUrl}" "${myRepoPath}"
    else
      git -C "${myRepoPath}" fetch --all
      git -C "${myRepoPath}" reset --hard origin/main
    fi
    # Update Nix channel if needed
    currentChannel=$(${pkgs.nix}/bin/nix-channel --list | ${pkgs.gnugrep}/bin/grep '^nixos' | ${pkgs.gawk}/bin/awk '{print $2}')
    targetChannel="${nixChannel}";
    if [ "$currentChannel" != "$targetChannel" ]; then
      ${pkgs.nix}/bin/nix-channel --add "$targetChannel" nixos
      ${pkgs.nix}/bin/nix-channel --update
    fi
  '';
  system.stateVersion = "25.05";
}
