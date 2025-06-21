#!/bin/sh
set -eu

# partition.sh: Interactive partitioning and subvolume setup (no disko, pure shell)
# This script will:
# 1. Show available disks
# 2. Let user pick a disk
# 3. Partition, format, and set up btrfs subvolumes as in disko-config.nix
# 4. Do NOT mount anything (for use with graphical installer)

# 1. Show available disks
lsblk -dpno NAME,SIZE,MODEL | grep -v "/loop" || true

echo "\nWARNING: This will ERASE ALL DATA on the selected drive!"
DISKS=($(lsblk -dpno NAME | grep -v loop))
for i in "${!DISKS[@]}"; do
  echo "$((i+1)). ${DISKS[$i]}"
done
read -rp "Enter the number of the disk to partition: " DISKNUM
DRIVE="${DISKS[$((DISKNUM-1))]}"

echo "You selected $DRIVE"
read -rp "Are you sure you want to partition $DRIVE? This will destroy all data on it! (yes/NO): " CONFIRM
[ "$CONFIRM" = "yes" ] || { echo "Aborted."; exit 1; }

# 2. Unmount and wipe
umount ${DRIVE}?* 2>/dev/null || true
swapoff ${DRIVE}?* 2>/dev/null || true
wipefs -a "$DRIVE"

# 3. Partition (GPT: bios, boot, swap, root)
parted --script "$DRIVE" \
  mklabel gpt \
  mkpart primary 1MiB 2MiB \
  set 1 bios_grub on \
  name 1 bios \
  mkpart primary fat32 2MiB 514MiB \
  set 2 esp on \
  name 2 boot \
  mkpart primary linux-swap 514MiB 17538MiB \
  name 3 swap \
  mkpart primary 17538MiB 100% \
  name 4 root

# 4. Format partitions
mkfs.vfat -F32 "${DRIVE}2"
mkswap "${DRIVE}3"
mkfs.btrfs -f "${DRIVE}4"

# 5. Create btrfs subvolumes (but do not mount for install)
mount "${DRIVE}4" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt

# 6. Do NOT mount anything (for graphical installer compatibility)
echo "Partitioning, formatting, and subvolume setup complete. You may now use the graphical installer and assign mount points as needed."
