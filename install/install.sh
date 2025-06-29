#!/bin/sh
set -eu

# Enable experimental Nix features for flakes and nix-command
export NIX_CONFIG="experimental-features = nix-command flakes"

# NixOS Flake Automated Installer (partitioning must be done first!)
# This script assumes /mnt is already partitioned and mounted by partition.sh and mount.sh
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

echo "Assuming /mnt is already partitioned and mounted. (If not, run partition.sh and mount.sh first!)"

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
nixos-install --impure --flake "$REPO_DIR#$NIXSYSTEM"

# 5. Copy utils folder to /usr/local/share/utils after install
mkdir -p "/mnt/usr/local/share"
cp -r "$REPO_DIR/utils" "/mnt/usr/local/share/utils"
chmod -R a+rX "/mnt/usr/local/share/utils"

# 6. Prompt to remove install media before reboot
echo "Installation complete! Please remove the install media before rebooting."
read -p "Press Enter to reboot..."
reboot
