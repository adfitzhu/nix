#!/bin/sh
# setup.sh - initial post-install setup script

# Start Tailscale (will prompt for auth if not already up)
echo "Starting Tailscale..."
sudo tailscale up

echo "Tailscale command issued. Follow prompts in your browser if needed."
