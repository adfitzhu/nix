{ config, pkgs, ... }:
let
  dolphinVersionsBin = pkgs.writeScriptBin "dolphin-versions.py" (builtins.readFile ./dolphin-versions.py);
in
{
  # Install the service menu system-wide for Plasma 6
  environment.etc."kio/servicemenus/Versions.desktop".source = ./Versions.desktop;
  environment.etc."kio/servicemenus/TestAction.desktop".source = ./TestAction.desktop;

  # Install the script as an executable in PATH
  environment.systemPackages = [ dolphinVersionsBin ];
}
