mkdir -p /mnt/usr/local
git clone http://github.com/adfitzhu/nix /mnt/usr/local/nixos
for userdir in /home/*; do
    desktop_dir="$userdir/Desktop"
    if [ -d "$userdir" ]; then
        mkdir -p "$desktop_dir"
        cp /mnt/usr/local/nixos/utils/Setup.desktop "$desktop_dir/"
        chown "$(basename "$userdir")":"$(basename "$userdir")" "$desktop_dir/Setup.desktop"
        chmod 755 "$desktop_dir/Setup.desktop"
    fi
done