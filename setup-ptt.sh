#!/bin/bash
# =============================================================================
# Push-to-Talk Setup Script for Debian Sid + GNOME Wayland
# =============================================================================
# Assumes the push2talk binary is in the same directory as this script.
#
# CONFIGURE THESE:
PTT_KEY="Alt_R"             # Key push2talk listens for.
                             # Must be an xkbcommon key name e.g. Alt_R,
                             # Caps_Lock, F13, etc.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="$SCRIPT_DIR/push2talk"

# =============================================================================
# 1. Check binary exists
# =============================================================================
if [ ! -f "$BINARY" ]; then
    echo "!!! push2talk binary not found at $BINARY"
    echo "    Copy it from another machine: cp ~/.cargo/bin/push2talk dotfiles/bin/"
    exit 1
fi

# =============================================================================
# 2. Install runtime dependencies (no cargo/build tools needed)
# =============================================================================
echo ">>> Installing runtime dependencies..."
sudo apt install -y \
    libxkbcommon0 \
    libinput10 \
    libpulse0 \
    libudev1 \
    input-remapper \
    evtest

# =============================================================================
# 3. Install binary
# =============================================================================
echo ">>> Installing push2talk binary..."
mkdir -p "$HOME/.local/bin"
cp "$BINARY" "$HOME/.local/bin/push2talk"
chmod +x "$HOME/.local/bin/push2talk"

# Add ~/.local/bin to PATH permanently if not already there
if ! grep -q '.local/bin' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

# =============================================================================
# 4. Add user to required groups
# =============================================================================
echo ">>> Adding user to input and plugdev groups..."
sudo usermod -aG input "$USER"
sudo usermod -aG plugdev "$USER"

# =============================================================================
# 5. Set up push2talk systemd user service
# =============================================================================
echo ">>> Setting up push2talk systemd user service..."
mkdir -p "$HOME/.config/systemd/user"

cat > "$HOME/.config/systemd/user/push2talk.service" << EOF
[Unit]
Description=Push2Talk - system-wide mic mute via PipeWire
After=pipewire.service

[Service]
ExecStart=$HOME/.local/bin/push2talk
Environment="PUSH2TALK_KEYBIND=$PTT_KEY"
Restart=on-failure

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now push2talk
echo ">>> push2talk service enabled and started"

# =============================================================================
# 6. Enable input-remapper daemon
# =============================================================================
echo ">>> Enabling input-remapper daemon..."

DAEMON_FILE=$(sudo systemctl cat input-remapper 2>/dev/null | head -1 | sed 's/# //')
if [ -f "$DAEMON_FILE" ]; then
    BASENAME=$(basename "$DAEMON_FILE")
    sudo cp "$DAEMON_FILE" "/etc/systemd/system/$BASENAME"
    sudo systemctl daemon-reload
    sudo systemctl enable "$BASENAME"
    echo ">>> input-remapper-daemon enabled"
else
    echo "!!! Could not find input-remapper service file. Enable manually:"
    echo "    sudo systemctl enable input-remapper-daemon"
fi

# =============================================================================
# Done
# =============================================================================
echo ""
echo "============================================================"
echo " Setup complete! Please reboot for group changes to apply."
echo "============================================================"
echo ""
echo " --------------------------------------------------------"
echo " HOW TO CONFIGURE INPUT-REMAPPER (mouse button -> $PTT_KEY)"
echo " --------------------------------------------------------"
echo " 1. Run:  sudo input-remapper-gtk"
echo " 2. Select your mouse from the device list"
echo " 3. Click 'New Preset', name it 'ptt'"
echo " 4. Click 'Add Mapping'"
echo " 5. INPUT field: click it and press your mouse forward button"
echo " 6. OUTPUT field: type '$PTT_KEY'"
echo " 7. Click 'Apply'"
echo " 8. Toggle 'Autoload' ON"
echo ""
echo " To identify your mouse button code if unsure:"
echo "   sudo evtest  (select mouse, press button, note the code)"
echo ""
echo " --------------------------------------------------------"
echo " HOW TO CONFIGURE DISCORD"
echo " --------------------------------------------------------"
echo " 1. Settings -> Voice & Video"
echo " 2. Set Input Mode to: Voice Activity"
echo " push2talk mutes/unmutes the mic directly - Discord"
echo " does not need to handle PTT itself."
echo ""
echo " Hold '$PTT_KEY' to unmute, release to mute."
echo "============================================================"
