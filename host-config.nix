{ hostname, user, swapSize, autoUpgradeFlake, extraPackages ? [], initialFlatpaks ? [
  "org.audacityteam.Audacity"
  "org.kde.audiotube"
  "org.clementine_player.Clementine"
  "io.freetubeapp.FreeTube"
], staticIP ? null, extraServices ? {} }:
{ config, pkgs, ... }:
let
  myRepoPath = "/etc/nixos-flake";
  myRepoUrl = "https://github.com/adfitzhu/nix";
  basePackages = with pkgs; [
    kdePackages.kate
    kdePackages.discover
    kdePackages.kdesu
    libreoffice
    vlc
    p7zip
    corefonts
    vista-fonts
    btrfs-progs
    libnotify
    flatpak
    rustdesk
    google-chrome
    microsoft-edge
    btrfs-assistant
    wine

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
    services.openssh = {
      enable = true;
      openFirewall = false;
    };
    services.tailscale.enable = true;
    services.syncthing = {
      enable = true;
      user = user;
      dataDir = "/home/${user}/Sync";
      configDir = "/home/${user}/.config/syncthing";
      openDefaultPorts = true;
    };

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
    postUpgrade = ''
      ${notifyUsersScript} "System Updated" "A new system configuration is ready. Please reboot to apply the update."
      if [ -d "${myRepoPath}/utils" ]; then
        cp -rT "${myRepoPath}/utils" "/usr/local/share/utils"
        chmod -R a+rX "/usr/local/share/utils"
      fi
    '';
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
  # Enable automatic garbage collection to free disk space from old generations and unused packages
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  # Merge in base and extra services
  # (Nix will merge attrsets, so extraServices can override baseServices)
  # This must be at the top level
} // mergedServices // {
  # Application modules
  programs.firefox.enable = true;
  programs.thunderbird.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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
    # Channel management removed; flakes handle Nixpkgs versioning.
  '';
  system.stateVersion = "25.05";

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/x-ms-dos-executable" = [ "wine.desktop" ];
      "application/x-msdownload" = [ "wine.desktop" ];
      "application/x-exe" = [ "wine.desktop" ];
      "application/x-winexe" = [ "wine.desktop" ];
      "application/x-msi" = [ "wine.desktop" ];
      ".exe" = [ "wine.desktop" ];
      ".msi" = [ "wine.desktop" ];
    };
  };

  # Create a desktop entry for setup.sh in the user's Desktop
  homeDir = "/home/${user}";
  desktopEntryDir = "${homeDir}/Desktop";
  desktopEntryPath = "${desktopEntryDir}/Setup.desktop";
  systemd.tmpfiles.rules = [
    "d ${desktopEntryDir} 0755 ${user} users - -"
    "f ${desktopEntryPath} 0755 ${user} users - -"
  ];
  environment.etc."setup-desktop-entry".text = ''
    [Desktop Entry]
    Name=Initial Setup
    Comment=Run post-install setup tasks (Tailscale, etc)
    Exec=${homeDir}/utils/setup.sh
    Icon=utilities-terminal
    Terminal=true
    Type=Application
    Categories=Utility;
  '';
  system.activationScripts.setupDesktopEntry.text = ''
    cp /etc/setup-desktop-entry ${desktopEntryPath}
    chmod +x ${desktopEntryPath}
    chown ${user}:users ${desktopEntryPath}
  '';
}
