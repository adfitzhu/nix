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

# NixOS Flake Automated Installer
# This script will:
# 1. Prompt for system config, user, password, hostname, and drive
# 2. Show lsblk and confirm drive
# 3. Partition and format using disko
# 4. Generate hardware config
# 5. Run nixos-install with flake
# 6. Set user password
# 7. Reboot

REPO_URL="github:adfitzhu/nix"
REPO_DIR="/mnt/etc/nixos"
DISKO_CONFIG="/tmp/disko-config.nix"

# 1. Prompt for system config, user, password, hostname, and drive
echo ""
echo "Step 1: Available system configurations in flake:"
# Hardcoded list of user-facing system configs and their flake paths
USER_CONFIGS=(
  "Gaming|x86_64-linux#gaming"
  "Desktop|x86_64-linux#desktop"
  "Laptop|x86_64-linux#laptop"
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
read -rsp "Step 3: Enter password for $NIXUSER: " NIXPASS; echo
read -rp "Step 4: Enter desired hostname: " NIXHOST
echo ""

# Numbered menu for drive selection
echo "Step 5: Block devices (detailed):"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,MODEL,SERIAL,UUID,PATH
DEVICES=($(lsblk -dpno NAME | grep -v loop))

echo ""
echo "Step 5: Available devices:"
for i in "${!DEVICES[@]}"; do
  DEVINFO=$(lsblk -d -o NAME,SIZE,MODEL,SERIAL,PATH --noheadings "${DEVICES[$i]}")
  echo "$((i+1)). $DEVINFO"
done
read -rp "Step 5: Enter the number of the device to use: " DEVNUM
DRIVE="${DEVICES[$((DEVNUM-1))]}"

echo ""
# Confirm drive erase
read -rp "Step 6: WARNING: All data on $DRIVE will be erased. Continue? (yes/no): " CONFIRM
[ "$CONFIRM" = "yes" ] || { echo "Aborted."; exit 1; }

# 3. Partition and format using disko
if [ -f disko-config.nix ]; then
  cp disko-config.nix "$DISKO_CONFIG"
else
  echo "disko-config.nix not found in repo. Aborting."; exit 1
fi
nix run github:nix-community/disko -- --mode disko /mnt "$DISKO_CONFIG" --arg drive '"$DRIVE"'

# 4. Generate hardware config
nixos-generate-config --root /mnt

# 5. Write host-config.nix args
cat > /mnt/etc/nixos/host-args.nix <<EOF
{
  hostname = "$NIXHOST";
  user = "$NIXUSER";
  autoUpgradeFlake = "$REPO_URL";
}
EOF

# 6. Install NixOS with flake
nixos-install --flake "$REPO_DIR#$NIXSYSTEM"

# 7. Set user and root password
echo "$NIXUSER:$NIXPASS" | chroot /mnt chpasswd
echo "root:$NIXPASS" | chroot /mnt chpasswd

# Copy utils folder to /usr/local/share/utils after install
cp -r "$REPO_DIR/utils" "/mnt/usr/local/share/utils"
# Symlink Setup.desktop to user's Desktop for convenience
mkdir -p "/mnt/home/$NIXUSER/Desktop"
ln -sf "/usr/local/share/utils/Setup.desktop" "/mnt/home/$NIXUSER/Desktop/Setup.desktop"
chown -h $NIXUSER:users "/mnt/home/$NIXUSER/Desktop/Setup.desktop"

# Prompt to remove install media before reboot
echo "Installation complete! Please remove the install media before rebooting."
read -p "Press Enter to reboot..."
reboot
