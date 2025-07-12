{ config, pkgs, ... }:
let
  dolphinVersionsBin = pkgs.writeScriptBin "dolphin-versions.py" (builtins.readFile ./dolphin-versions.py);
in
{
  # Install the service menu system-wide for Plasma 6
  environment.etc."usr/share/kio/servicemenus/Versions.desktop".source = ./Versions.desktop;

  # Install the script as an executable in PATH
  environment.systemPackages = [ dolphinVersionsBin ];
}
