{ config, pkgs, ... }:
let
  myRepoPath = if config ? myRepoPath then config.myRepoPath else "/etc/nixos";
  autoUpgradeFlake = if config ? autoUpgradeFlake then config.autoUpgradeFlake else null;
in
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
    #rustdesk
    google-chrome
    btrfs-assistant
    wine
    digikam
    timeshift
    btrbk
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
  # services.snapper = {
  #   snapshotInterval = "hourly";
  #   cleanupInterval = "daily";
  #   configs = {
  #     home = {
  #       SUBVOLUME = "/home";
  #       TIMELINE_CREATE = true;
  #       TIMELINE_CLEANUP = true;
  #       TIMELINE_LIMIT_HOURLY = 6;
  #       TIMELINE_LIMIT_DAILY = 7;
  #       TIMELINE_LIMIT_WEEKLY = 4;
  #       TIMELINE_LIMIT_MONTHLY = 3;
  #     };
  #   };
  # };
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  system.stateVersion = "25.05";

  # Disable built-in autoUpgrade
  system.autoUpgrade.enable = false;

  # Custom auto-upgrade service and timer
  systemd.services.my-auto-upgrade = {
    description = "Custom NixOS and Flatpak auto-upgrade";
    serviceConfig.Type = "oneshot";
    path = [ pkgs.git pkgs.nixos-rebuild pkgs.flatpak pkgs.util-linux pkgs.coreutils-full pkgs.systemd pkgs.gawk pkgs.libnotify ];
    script = ''
      set -euxo pipefail
      # Use autoUpgradeFlake if set, otherwise default to github:adfitzhu/nix#generic
      FLAKE="${if autoUpgradeFlake != null then autoUpgradeFlake else "github:adfitzhu/nix#generic"}"
      nixos-rebuild switch --upgrade --flake "$FLAKE" --no-write-lock-file --impure 
      # Update all Flatpaks
      ${pkgs.flatpak}/bin/flatpak update -y || true
      # Notify users
      systemctl start notify-users.service 'System Updated' 'NixOS and Flatpak updates have been applied. Please reboot to use the new system.'
      # Update local utility repo
      if [ -d /usr/local/nixos/.git ]; then
        ${pkgs.git}/bin/git -C /usr/local/nixos pull --rebase || true
      else
        ${pkgs.git}/bin/git clone https://github.com/adfitzhu/nix.git /usr/local/nixos || true
      fi
    '';
  };
  systemd.timers.my-auto-upgrade = {
    description = "Run custom NixOS and Flatpak auto-upgrade weekly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
  # Use NixOS native btrbk service for hourly snapshots and retention
  services.btrbk.instances = {
    "home" = {
      onCalendar = "hourly";
      settings = {
        timestamp_format = "long";
        snapshot_preserve_min = "1d";
        snapshot_preserve = "6h 7d 4w 3m";
        volume = {
          "/home" = {
            snapshot_dir = ".snapshots";
            subvolume = ".";
          };
        };
      };
    };
  };
  # Ensure /home/.snapshots exists for btrbk
  systemd.tmpfiles.rules = [
    "d /home/.snapshots 0755 root root"
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Notify users systemd service for desktop notifications (Plasma 6/Wayland compatible)
  systemd.services.notify-users = {
    description = "Send desktop notification to all logged-in users";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        /bin/sh -c '
          title="${1:-$NOTIFY_TITLE}"; body="${2:-$NOTIFY_BODY}";
          for session in $(loginctl list-sessions --no-legend | awk "{print \$1}"); do
            user=$(loginctl show-session "$session" -p Name | cut -d= -f2)
            uid=$(id -u "$user")
            runtime_dir="/run/user/$uid"
            export XDG_RUNTIME_DIR="$runtime_dir"
            dbus_addr=$(grep -z DBUS_SESSION_BUS_ADDRESS "$runtime_dir/environment" | cut -d= -f2-)
            export DBUS_SESSION_BUS_ADDRESS="$dbus_addr"
            echo "[$(date)] Notifying $user (uid $uid) with XDG_RUNTIME_DIR=$runtime_dir DBUS_SESSION_BUS_ADDRESS=$dbus_addr" >> /tmp/notify-users.log
            # Use full path to sudo to avoid 'command not found' error
            /run/wrappers/bin/sudo -u "$user" XDG_RUNTIME_DIR="$runtime_dir" DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
              ${pkgs.libnotify}/bin/notify-send "$title" "$body" -u normal -a "System" -c "system" -t 10000 >> /tmp/notify-users.log 2>&1 || true
          done'
      '';
      Environment = [
        "NOTIFY_TITLE=SystemD Notification"
        "NOTIFY_BODY=Attempting a notification but no arguments were provided."
      ];
      PassEnvironment = [ "NOTIFY_TITLE" "NOTIFY_BODY" ];
      After = [ "graphical-session.target" "plasma-workspace.target" ];
    };
  };
}
