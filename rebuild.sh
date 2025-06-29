#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/configuration.nix"
TARGET_DIR="/etc/nixos"
TARGET_FILE="$TARGET_DIR/configuration.nix"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found."
    exit 1
fi

sudo cp "$CONFIG_FILE" "$TARGET_FILE"
sudo nixos-rebuild switch
sudo reboot