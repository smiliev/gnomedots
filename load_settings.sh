#!/bin/bash

# Load the saved settings back into dconf
dconf load /org/gnome/desktop/wm/keybindings/ < ./dconf-backups/wm-scripts.dconf
dconf load /org/gnome/settings-daemon/plugins/media-keys/ < ./dconf-backups/custom-keys.dconf
dconf load /org/gnome/shell/extensions/forge/ < ./dconf-backups/forge-settings.dconf

echo "Settings have been successfully restored!"
