{ config, pkgs, ... }:
{
  # Install the service menu system-wide for Plasma 6
  environment.etc."xdg/kservices6/ServiceMenus/Versions.desktop".source = ./Versions.desktop;
  environment.etc."xdg/kservices6/ServiceMenus/TestAction.desktop".source = ./TestAction.desktop;

  # Install the script system-wide
  environment.etc."dolphin-versions.py".source = ./dolphin-versions.py;

  # Symlink the script to /run/current-system/sw/bin for all users
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "dolphin-versions.py" ''
      exec ${pkgs.python3.interpreter} /etc/dolphin-versions.py "$@"
    '')
  ];
}
