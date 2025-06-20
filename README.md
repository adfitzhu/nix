> **Inspiration:** This project was inspired by [nixbook](https://github.com/mkellyxp/nixbook). I liked the idea of the nixbook but wanted to make my own version using KDE and some specific apps for my users' needs.

# nix

> **Note:** You must run `install.sh` as root. On the NixOS live ISO, you are already root by default, so you do not need to use `sudo` or enter a password.

## Automated Install Procedure

This guide will help you install NixOS using this flake-based configuration, fully automated with `install.sh`.

### Step 1: Prepare the Live Environment
- Boot the target machine with the latest NixOS installer ISO (graphical or minimal).
- **If using the minimal (command-line) ISO:**
  - Open a shell with git and jq available:
    ```sh
    nix-shell -p git jq
    ```
  - Connect to WiFi using:
    ```sh
    nmtui
    ```
- **If using the graphical ISO:**
  - Connect to WiFi using the network applet in the system tray.
  - Open a terminal (git and jq are already installed).

### Step 2: Clone this repository to the correct location
```sh
git clone https://github.com/adfitzhu/nix /mnt/etc/nixos
cd /mnt/etc/nixos
```
> **Note:** The installer expects the repo to be at `/mnt/etc/nixos` so it can find `install.sh` and all config files.

### Step 3: Run the installer
```sh
sh install.sh
```

### Step 4: Follow the prompts
- Select the system configuration you want to use (e.g., `gaming`, `laptop`) from a numbered menu.
- Enter your desired username, password, and hostname.
- Select the target drive from a numbered menu (e.g., `/dev/sda`).
- Confirm that you want to erase the selected drive.

### Step 5: Wait for the script to finish
- The script will partition and format the drive, generate hardware config, set up user and hostname, install NixOS, set your user and root password, and reboot.

### Step 6: Run the Setup script on your Desktop
- After rebooting and logging in, double-click the **Setup** icon on your Desktop to complete extra configuration (such as Tailscale setup and more).

### Notes
- **All data on the selected drive will be erased.**
- The script expects a valid `disko-config.nix` in the repo root for partitioning.
- If you want to customize packages or services, edit the flake files before running the installer.
- After reboot, log in with the username and password you set during installation. The root password will be the same as the user password (you can change it later).

---

Enjoy your reproducible, flake-powered NixOS system!