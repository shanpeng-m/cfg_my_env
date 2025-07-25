#!/bin/bash
# Installation script for Remote MP4 Manager

INSTALL_DIR="/opt/remote-mp4-manager"
BIN_DIR="/usr/local/bin"
DESKTOP_DIR="/usr/share/applications"

echo "Installing Remote MP4 Manager..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Copy files
cp Remote_MP4_Manager "$INSTALL_DIR/"
cp remote-mp4-manager.desktop "$DESKTOP_DIR/"

# Create symlink in bin directory
ln -sf "$INSTALL_DIR/Remote_MP4_Manager" "$BIN_DIR/mp4-manager"

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$DESKTOP_DIR"
fi

echo "Installation complete!"
echo "You can now run the application with: mp4-manager"
echo "Or find it in your applications menu as 'Remote MP4 Manager'"
