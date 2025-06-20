> **Inspiration:** This project was inspired by [nixbook](https://github.com/mkellyxp/nixbook). I liked the idea of the nixbook but wanted to make my own version using KDE and some specific apps for my users' needs.

# nix

> **Note:** You must run `install.sh` as root. On the NixOS live ISO, you are already root by default, so you do not need to use `sudo` or enter a password.

## Automated Install Procedure

This guide will help you install NixOS using this flake-based configuration, fully automated with `install.sh`.

### Prerequisites
- Boot the target machine with the latest NixOS installer ISO (graphical or minimal).
- Connect to WiFi using the graphical network applet, or if on the command line, use `nmtui`:
  ```sh
  nmtui
  ```
- Open a terminal and install git:
  ```sh
  nix-shell -p git
  ```

### Installation Steps

1. **Clone this repository to the correct location:**
   ```sh
   git clone https://github.com/adfitzhu/nix /mnt/etc/nixos
   cd /mnt/etc/nixos
   ```
   > **Note:** The installer expects the repo to be at `/mnt/etc/nixos` so it can find `install.sh` and all config files.

2. **Run the installer:**
   ```sh
   sh install.sh
   ```

3. **Follow the prompts:**
   - Select the system configuration you want to use (e.g., `gaming`, `server`) from a numbered menu.
   - Enter your desired username, password, and hostname.
   - Select the target drive from a numbered menu (e.g., `/dev/sda`).
   - Confirm that you want to erase the selected drive.

4. **Wait for the script to finish:**
   - The script will partition and format the drive, generate hardware config, set up user and hostname, install NixOS, set your user and root password, and reboot.

### Notes
- **All data on the selected drive will be erased.**
- The script expects a valid `disko-config.nix` in the repo root for partitioning.
- If you want to customize packages or services, edit the flake files before running the installer.
- After reboot, log in with the username and password you set during installation. The root password will be the same as the user password (you can change it later).

### Troubleshooting
- If the script fails, check the output for errors and ensure your network connection is working.
- You can re-run the script after fixing any issues.

---

Enjoy your reproducible, flake-powered NixOS system!