# 1. Generate hardware config
nixos-generate-config --root /mnt
echo "nixos-install --impure --no-write-lock-file --flake github:adfitzhu/nix#desktop"