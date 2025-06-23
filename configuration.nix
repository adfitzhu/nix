# configuration.nix for flake-based NixOS system
# This file makes plain nixos-rebuild work by importing the flake config
{
  imports = [
    (import ./flake.nix).nixosConfigurations.laptop.config
  ];
}
