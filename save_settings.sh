#!/bin/bash
mkdir -p ./dconf-backups
# This dumps everything under /org/gnome/ into one file with correct headers
dconf dump /org/gnome/ > ./dconf-backups/gnome_all.dconf
echo "Full backup created."
