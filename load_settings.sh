#!/bin/bash
# This loads everything back to the root of /org/gnome/
dconf load /org/gnome/ < ./dconf-backups/gnome_all.dconf
echo "Settings restored."
