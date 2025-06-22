#!/bin/sh
set -eu

# Enable experimental Nix features for flakes and nix-command
export NIX_CONFIG="experimental-features = nix-command flakes"

# If jq is not available, and nix-shell is present, enter a shell with jq and git and re-exec the script
if ! command -v jq >/dev/null 2>&1; then
  if command -v nix-shell >/dev/null 2>&1; then
    echo "jq not found. Re-executing in a nix-shell with jq and git..."
    exec nix-shell -p git jq --run "sh $0 $@"
  else
    echo "Error: jq is required but not found, and nix-shell is not available. Aborting." >&2
    exit 1
  fi
fi

# NixOS Flake Automated Installer (partitioning must be done first!)
# This script assumes /mnt is already partitioned and mounted by partition.sh
# It will:
# 1. Prompt for system config, user, password, hostname
# 2. Generate hardware config
# 3. Write host-args.nix
# 4. Run nixos-install with flake
# 5. Set user/root password
# 6. Copy utils and symlink Setup.desktop
# 7. Reboot

REPO_URL="github:adfitzhu/nix"
REPO_DIR="/mnt/etc/nixos"

# 0. Mount all partitions and subvolumes
if [ -f "./mount.sh" ]; then
  if [ ! -x "./mount.sh" ]; then
    echo "mount.sh found but not executable. Setting executable bit..."
    chmod +x ./mount.sh
  fi
  echo "Mounting partitions and subvolumes using mount.sh..."
  ./mount.sh
else
  echo "Error: mount.sh not found in the current directory. Please ensure it exists." >&2
  exit 1
fi

# 1. Prompt for system config, user, password, hostname

echo ""
echo "Step 1: Available system configurations in flake:"
USER_CONFIGS=(
  "Gaming|gaming"
  "Desktop|desktop"
  "Laptop|laptop"
)
for i in "${!USER_CONFIGS[@]}"; do
  NAME="${USER_CONFIGS[$i]%%|*}"
  echo "$((i+1)). $NAME"
done
read -rp "Step 1: Enter the number of the system config to use: " NIXSYSTEM_NUM
NIXSYSTEM_PATH="${USER_CONFIGS[$((NIXSYSTEM_NUM-1))]}"
NIXSYSTEM="${NIXSYSTEM_PATH#*|}"

echo ""
read -rp "Step 2: Enter desired username: " NIXUSER
echo ""
read -rp "Step 3: Enter desired hostname: " NIXHOST
echo ""

echo "Assuming /mnt is already partitioned and mounted. (If not, run partition.sh first!)"

# 2. Generate hardware config
nixos-generate-config --root /mnt

# 3. Write host-config.nix args
cat > /mnt/etc/nixos/host-args.nix <<EOF
{
  hostname = "$NIXHOST";
  user = "$NIXUSER";
  autoUpgradeFlake = "$REPO_URL";
}
EOF

# 4. Install NixOS with flake
nixos-install --flake "$REPO_DIR#$NIXSYSTEM"

# 5. Copy utils folder to /usr/local/share/utils after install
mkdir -p "/mnt/usr/local/share"
cp -r "$REPO_DIR/utils" "/mnt/usr/local/share/utils"
# Symlink Setup.desktop to user's Desktop for convenience
mkdir -p "/mnt/home/$NIXUSER/Desktop"
ln -sf "/usr/local/share/utils/Setup.desktop" "/mnt/home/$NIXUSER/Desktop/Setup.desktop"
chown -h $NIXUSER:users "/mnt/home/$NIXUSER/Desktop/Setup.desktop"

# 6. Prompt to remove install media before reboot
echo "Installation complete! Please remove the install media before rebooting."
read -p "Press Enter to reboot..."
reboot
