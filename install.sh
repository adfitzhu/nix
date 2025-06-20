#!/bin/sh
set -eu

# NixOS Flake Automated Installer
# This script will:
# 1. Prompt for system config, user, password, hostname, and drive
# 2. Show lsblk and confirm drive
# 3. Partition and format using disko
# 4. Generate hardware config
# 5. Run nixos-install with flake
# 6. Set user password
# 7. Reboot

REPO_URL="https://github.com/adfitzhu/nix"
REPO_DIR="/mnt/etc/nixos"
DISKO_CONFIG="/tmp/disko-config.nix"

# 1. Prompt for system config, user, password, hostname, and drive
FLAKE_REF="$REPO_URL"
echo "\nStep 1: Available system configurations in flake:"
FLAKE_SYSTEMS=($(nix flake show --json "$FLAKE_REF" | jq -r '.nixosConfigurations | keys[]'))
for i in "${!FLAKE_SYSTEMS[@]}"; do
  echo "$((i+1)). ${FLAKE_SYSTEMS[$i]}"
done
read -rp "Step 1: Enter the number of the system config to use: " NIXSYSTEM_NUM
NIXSYSTEM="${FLAKE_SYSTEMS[$((NIXSYSTEM_NUM-1))]}"

read -rp "\nStep 2: Enter desired username: " NIXUSER
read -rsp "Step 3: Enter password for $NIXUSER: " NIXPASS; echo
read -rp "Step 4: Enter desired hostname: " NIXHOST

# Numbered menu for drive selection
DEVICES=($(lsblk -dpno NAME | grep -v loop))
echo "\nStep 5: Available devices:"
for i in "${!DEVICES[@]}"; do
  echo "$((i+1)). ${DEVICES[$i]}"
done
read -rp "Step 5: Enter the number of the device to use: " DEVNUM
DRIVE="${DEVICES[$((DEVNUM-1))]}"

# Confirm drive erase
read -rp "\nStep 6: WARNING: All data on $DRIVE will be erased. Continue? (yes/no): " CONFIRM
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
