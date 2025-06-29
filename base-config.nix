{ config, pkgs, ... }:
{
  # Shared config for all hosts
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    kdePackages.discover
    kdePackages.kdesu
    libreoffice
    libnotify
    flatpak
    vlc
    p7zip
    corefonts
    vista-fonts
    btrfs-progs
    rustdesk
    google-chrome
    btrfs-assistant
    wine
    digikam
  ];
  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };
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
    extraConf = ''
      FileDevice No
      DefaultPrinter None
    '';
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
  services.fail2ban.enable = true;
  services.tailscale.enable = true;
  virtualisation.waydroid.enable = true;
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "daily";
    configs = {
      home = {
        SUBVOLUME = "/home";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 6;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 3;
      };
    };
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  system.stateVersion = "25.05";
  notifyUsersScript = pkgs.writeShellScript "notify-users.sh" ''
    set -eu
    title="$1"
    body="$2"
    users=$(${pkgs.systemd}/bin/loginctl list-sessions --no-legend | ${pkgs.gawk}/bin/awk '{print $1}' | while read session; do
      loginctl show-session "$session" -p Name | cut -d'=' -f2
    done | sort -u)
    for user in $users; do
      export XDG_RUNTIME_DIR="/run/user/$(id -u $user)"
      sudo -u $user DISPLAY=:0 ${pkgs.libnotify}/bin/notify-send "$title" "$body" -u normal -a "System" -c "system" -t 10000 || true
    done
  '';

  system.autoUpgrade = {
    enable = true;
    flake = config.autoUpgradeFlake;
    allowReboot = false;
    dates = "weekly";
    postUpgrade = ''
      # Update all Flatpaks after system upgrade
      ${pkgs.flatpak}/bin/flatpak update -y || true
      ${config.notifyUsersScript} "System Updated" "A new system configuration is ready. Please reboot to apply the update."
      if [ -d "${config.myRepoPath}/utils" ]; then
        cp -rT "${config.myRepoPath}/utils" "/usr/local/share/utils"
        chmod -R a+rX "/usr/local/share/utils"
      fi
    '';
  };
}
