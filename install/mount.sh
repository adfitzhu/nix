#!/bin/sh
# mount.sh - Mount all partitions and subvolumes for NixOS install
# Run after partition.sh and before nixos-install
set -euo pipefail

# Devices and labels (must match your partition.sh and host-config.nix)
ROOT_DEV="/dev/disk/by-label/root"
BOOT_DEV="/dev/disk/by-label/boot"

# Mount points
MNT="/mnt"

# Unmount and remove any existing mounts or directories for a clean start
for dir in "$MNT/home" "$MNT/.snapshots" "$MNT/boot"; do
  if mountpoint -q "$dir"; then
    umount -l "$dir"
  fi
  if [ -d "$dir" ]; then
    rmdir "$dir" 2>/dev/null || true
  fi
  mkdir -p "$dir"
done

# Mount root subvolume
mount -o subvol=@ "$ROOT_DEV" "$MNT"

# Ensure /mnt/home, /mnt/.snapshots, /mnt/boot exist after root mount
mkdir -p "$MNT/home" "$MNT/.snapshots" "$MNT/boot"

# Mount home subvolume
mount -o subvol=@home "$ROOT_DEV" "$MNT/home"

# Mount snapshots subvolume
mount -o subvol=@snapshots "$ROOT_DEV" "$MNT/.snapshots"

# Mount boot partition
mount "$BOOT_DEV" "$MNT/boot"

echo "All partitions and subvolumes mounted successfully."
