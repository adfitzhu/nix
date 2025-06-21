#!/usr/bin/env bash
set -euo pipefail

# partition.sh: Partition and mount a drive using disko and disko-config.nix
# This script is meant to be run before install.sh. It will partition and mount the selected drive, then exit.

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

# Run disko to partition and mount
if ! command -v disko &>/dev/null; then
  echo "Error: disko is not installed. Please install disko before running this script."
  exit 1
fi

echo "Partitioning $DRIVE using disko-config.nix..."
disko --mode disko --config ./disko-config.nix --arg drive "$DRIVE"

echo "Partitioning and mounting complete. You may now run install.sh."
