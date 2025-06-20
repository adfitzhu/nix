#!/bin/sh
# update.sh - manually trigger system update

echo "Triggering system update..."
sudo systemctl start nixos-upgrade.service

echo "Update triggered. You will be notified when the new configuration is ready."
