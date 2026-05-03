#!/bin/bash

# Install Push-to-Talk service

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check dependency
if ! python3 -c "import evdev" 2>/dev/null; then
    echo "Installing python3-evdev..."
    sudo apt-get install -y python3-evdev
fi

# Install script
mkdir -p ~/.local/bin
cp "$SCRIPT_DIR/push-to-talk.py" ~/.local/bin/
chmod +x ~/.local/bin/push-to-talk.py

# Install systemd service
mkdir -p ~/.config/systemd/user
cp "$SCRIPT_DIR/push-to-talk.service" ~/.config/systemd/user/

# Add user to input group (needed to read /dev/input devices)
echo "Adding user to 'input' group (requires sudo)..."
sudo usermod -aG input "$USER"

# Reload and enable service
systemctl --user daemon-reload
systemctl --user enable push-to-talk.service

echo ""
echo "Installation complete!"
echo ""
echo "IMPORTANT: You need to log out and log back in for the 'input' group to take effect."
echo ""
echo "After logging back in, start the service with:"
echo "  systemctl --user start push-to-talk.service"
echo ""
echo "Check status with:"
echo "  systemctl --user status push-to-talk.service"
echo ""
echo "View logs with:"
echo "  journalctl --user -u push-to-talk.service -f"
