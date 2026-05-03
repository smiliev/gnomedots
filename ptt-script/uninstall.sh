#!/bin/bash

# Uninstall Push-to-Talk service

echo "Stopping and disabling service..."
systemctl --user stop push-to-talk.service 2>/dev/null
systemctl --user disable push-to-talk.service 2>/dev/null

echo "Removing files..."
rm -f ~/.local/bin/push-to-talk.py
rm -rf ~/.local/share/push-to-talk
rm -f ~/.config/systemd/user/push-to-talk.service

systemctl --user daemon-reload

echo ""
echo "Uninstall complete!"
echo ""
echo "Note: User was not removed from 'input' group (may be needed by other apps)."
echo "To remove manually: sudo gpasswd -d $USER input"
