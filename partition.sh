#!/usr/bin/env bash
set -euo pipefail

# partition.sh: Partition and mount a drive using disko and flake-based config
# This script is meant to be run before install.sh. It will partition and mount the selected drive, then exit.

# If disko is not available, start a nix shell with disko and re-exec the script
if ! command -v disko &>/dev/null; then
  if command -v nix-shell &>/dev/null; then
    echo "disko not found. Re-executing in a nix-shell with disko..."
    exec nix-shell -p disko --run "bash $0 $@"
  else
    echo "Error: disko is required but not found, and nix-shell is not available. Aborting." >&2
    exit 1
  fi
fi

# Show available drives
lsblk -dpno NAME,SIZE,MODEL | grep -v "/loop" || true

echo "\nWARNING: This will ERASE ALL DATA on the selected drive!"
read -rp "Enter the device path to partition (e.g. /dev/sda): " DRIVE

# Confirm selection
read -rp "Are you sure you want to partition $DRIVE? This will destroy all data on it! (yes/NO): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborted."
  exit 1
fi

# Run disko to partition and mount using flake output (parameterized by drive)
echo "Partitioning $DRIVE using flake disko config..."
disko --flake ".#disko-config" --argstr drive "$DRIVE"

echo "Partitioning and mounting complete. You may now run install.sh."
