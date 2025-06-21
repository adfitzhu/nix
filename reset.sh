#!/bin/sh
# reset.sh - Reset test environment for NixOS flake install
set -eu

# 1. Unmount everything mounted by mount.sh
umount -R /mnt/boot 2>/dev/null || true
umount -R /mnt/home 2>/dev/null || true
umount -R /mnt/.snapshots 2>/dev/null || true
umount -R /mnt 2>/dev/null || true

# 2. Remove /mnt/etc/nixos if it exists (to ensure a clean clone)
if [ -d /mnt/etc/nixos ]; then
  rm -rf /mnt/etc/nixos
fi

# 3. Clone the latest version of the repo
mkdir -p /mnt/etc
cd /mnt/etc

git clone --depth 1 https://github.com/adfitzhu/nix.git nixos
cd nixos

# 4. Make partition.sh and install.sh executable
chmod +x partition.sh install.sh

# 5. Run partition.sh (interactive)
./partition.sh

# 6. Run install.sh (interactive)
./install.sh
