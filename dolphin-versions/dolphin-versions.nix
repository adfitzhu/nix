{ config, pkgs, ... }:
{
  home.packages = with pkgs; [ python3 kdialog ];
  home.file.".local/share/kservices5/ServiceMenus/Versions.desktop".source = ./Versions.desktop;
  home.file.".local/bin/dolphin-versions.py".source = ./dolphin-versions.py;
}
