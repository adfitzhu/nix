mkdir -p /mnt/usr/local
git clone http://github.com/adfitzhu/nix /mnt/usr/local/nixos
for userdir in /mnt/home/*; do
    desktop_dir="/mnt/home/$userdir/Desktop"
    if [ -d "$userdir" ]; then
        username=$(basename "$userdir")
        mkdir -p "$desktop_dir"
        cp /mnt/usr/local/nixos/utils/Setup.desktop "$desktop_dir/"
        chown "$username:$username" "$desktop_dir/Setup.desktop"
        chmod 755 "$desktop_dir/Setup.desktop"
    fi
done
