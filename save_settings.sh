#!/bin/bash

# Create a folder for the config dumps if it doesn't exist
mkdir -p ./dconf-backups

# Export Keybindings and Forge settings
dconf dump /org/gnome/desktop/wm/keybindings/ > ./dconf-backups/wm-scripts.dconf
dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > ./dconf-backups/custom-keys.dconf
dconf dump /org/gnome/shell/extensions/forge/ > ./dconf-backups/forge-settings.dconf

echo "GNOME and Forge settings exported to ./dconf-backups/"
