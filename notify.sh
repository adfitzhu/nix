#!/bin/bash

# KDE Plasma 6 persistent notification script using notify-send only

MESSAGE="A system update has been downloaded. Please reboot to apply the changes."
TITLE="Update Downloaded"
APP_NAME="System Update"

if command -v notify-send &> /dev/null; then
    notify-send -a "$APP_NAME" -t 0 "$TITLE" "$MESSAGE"
    echo "Persistent notification sent using notify-send (-t 0, -a $APP_NAME)."
    exit 0
fi

echo "No supported notification method found (notify-send)."
exit 1
