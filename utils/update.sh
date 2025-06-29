#!/bin/sh
# update.sh - manually trigger system update using the flake

set -eu

# Path to your flake repo (should match myRepoPath in host-config.nix)
REPO_PATH="/etc/nixos-flake"
REPO_URL="https://github.com/adfitzhu/nix"

# Clone or update the flake repo
if [ ! -d "$REPO_PATH/.git" ]; then
  echo "Cloning flake repo..."
  rm -rf "$REPO_PATH"
  git clone "$REPO_URL" "$REPO_PATH"
else
  echo "Updating flake repo..."
  git -C "$REPO_PATH" fetch --all
  git -C "$REPO_PATH" reset --hard origin/main
fi

# Rebuild the system using the flake
if [ -f /etc/nixos-flake/host-args.nix ]; then
  echo "Running: sudo nixos-rebuild switch --flake $REPO_PATH"
  sudo nixos-rebuild switch --flake "$REPO_PATH"
else
  echo "host-args.nix not found in $REPO_PATH. Skipping rebuild."
fi

echo "Update complete. If there was a new configuration, you may need to reboot."
