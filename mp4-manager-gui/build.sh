#!/bin/bash

# Remote MP4 Manager GUI Build Script
# This script will create a standalone executable for Ubuntu with desktop integration

echo "Remote MP4 Manager GUI - Build Script"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get absolute path of current directory
INSTALL_DIR="$(pwd)"
EXECUTABLE_PATH="$INSTALL_DIR/Remote_MP4_Manager"

# Check if Python3 is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python3 is not installed${NC}"
    echo "Install with: sudo apt-get install python3"
    exit 1
fi

echo -e "${BLUE}Python3 found: $(python3 --version)${NC}"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}Error: pip3 is not installed${NC}"
    echo "Install with: sudo apt-get install python3-pip"
    exit 1
fi

echo -e "${BLUE}pip3 found: $(pip3 --version)${NC}"

# Check if tkinter is available
if ! python3 -c "import tkinter" 2>/dev/null; then
    echo -e "${RED}Error: tkinter is not installed${NC}"
    echo "Install with: sudo apt-get install python3-tk"
    exit 1
fi

echo -e "${GREEN}tkinter is available${NC}"

# Install required packages
echo -e "${YELLOW}Installing required Python packages...${NC}"
pip3 install --user pyinstaller

# Check if PyInstaller was installed successfully
if ! command -v ~/.local/bin/pyinstaller &> /dev/null; then
    echo -e "${RED}Error: PyInstaller installation failed${NC}"
    exit 1
fi

echo -e "${GREEN}PyInstaller installed successfully${NC}"

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}Warning: sshpass is not installed${NC}"
    echo "The application will require sshpass to function properly"
    echo "Install with: sudo apt-get install sshpass"
else
    echo -e "${GREEN}sshpass found: $(sshpass -V 2>&1 | head -1)${NC}"
fi

# Create build directory
BUILD_DIR="mp4_manager_build"
if [ -d "$BUILD_DIR" ]; then
    echo -e "${YELLOW}Removing existing build directory...${NC}"
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Copy the Python script
if [ ! -f "../mp4_manager_gui.py" ]; then
    echo -e "${RED}Error: mp4_manager_gui.py not found${NC}"
    echo "Please make sure the Python GUI script is named 'mp4_manager_gui.py' and is in the current directory"
    exit 1
fi

cp ../mp4_manager_gui.py .

# Create spec file for PyInstaller
cat > mp4_manager.spec << 'EOF'
# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['mp4_manager_gui.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[
        'tkinter', 
        'tkinter.ttk', 
        'tkinter.scrolledtext', 
        'tkinter.messagebox', 
        'tkinter.filedialog',
        'queue',
        'threading',
        'subprocess',
        'tempfile',
        'datetime',
        'json'
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='Remote_MP4_Manager',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
EOF

# Build the executable
echo -e "${YELLOW}Building executable...${NC}"
~/.local/bin/pyinstaller mp4_manager.spec

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Build successful!${NC}"
    
    # Copy executable to parent directory
    cp dist/Remote_MP4_Manager ../
    
    # Make it executable
    chmod +x ../Remote_MP4_Manager
    
    echo -e "${GREEN}Executable created: Remote_MP4_Manager${NC}"
    echo -e "${BLUE}File size: $(du -h ../Remote_MP4_Manager | cut -f1)${NC}"
    
    # Create desktop entry with absolute path
    cat > ../remote-mp4-manager.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Remote MP4 Manager
Comment=Remote MP4 File Management Tool with GUI
Exec=$EXECUTABLE_PATH
Icon=video-x-generic
Terminal=false
Categories=AudioVideo;Video;Network;
StartupNotify=true
Keywords=mp4;video;remote;ssh;download;
EOF
    
    chmod +x ../remote-mp4-manager.desktop
    
    echo -e "${GREEN}Desktop entry created: remote-mp4-manager.desktop${NC}"
    
    # Install desktop entry
    DESKTOP_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_DIR"
    cp ../remote-mp4-manager.desktop "$DESKTOP_DIR/"
    
    echo -e "${GREEN}Desktop entry installed to: $DESKTOP_DIR${NC}"
    
    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$DESKTOP_DIR"
        echo -e "${GREEN}Desktop database updated${NC}"
    fi
    
    # Create launcher script for easier execution
    cat > ../mp4-manager << 'EOF'
#!/bin/bash
# Remote MP4 Manager Launcher Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXECUTABLE="$SCRIPT_DIR/Remote_MP4_Manager"

if [ -f "$EXECUTABLE" ]; then
    cd "$SCRIPT_DIR"
    exec "$EXECUTABLE" "$@"
else
    echo "Error: Remote_MP4_Manager executable not found in $SCRIPT_DIR"
    exit 1
fi
EOF
    
    chmod +x ../mp4-manager
    
    # Create installation script
    cat > ../install.sh << 'EOF'
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
EOF
    
    chmod +x ../install.sh
    
    echo ""
    echo -e "${YELLOW}Build and packaging complete!${NC}"
    echo ""
    echo -e "${GREEN}You can now run the application in several ways:${NC}"
    echo "1. ${BLUE}Direct execution:${NC} ./Remote_MP4_Manager"
    echo "2. ${BLUE}Using launcher:${NC} ./mp4-manager"
    echo "3. ${BLUE}From applications menu:${NC} Search for 'Remote MP4 Manager'"
    echo "4. ${BLUE}System-wide install:${NC} sudo ./install.sh"
    echo ""
    echo -e "${YELLOW}Files created:${NC}"
    echo "- Remote_MP4_Manager (main executable)"
    echo "- mp4-manager (launcher script)"
    echo "- remote-mp4-manager.desktop (desktop entry)"
    echo "- install.sh (system installation script)"
    echo ""
    echo -e "${BLUE}Desktop entry installed to:${NC} $DESKTOP_DIR/remote-mp4-manager.desktop"
    
else
    echo -e "${RED}Build failed!${NC}"
    echo "Check the error messages above for details"
    exit 1
fi

# Clean up build files
cd ..
echo -e "${BLUE}Cleaning up build files...${NC}"
rm -rf "$BUILD_DIR"

echo -e "${GREEN}Done!${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} If the application doesn't appear in the menu immediately,"
echo "try logging out and back in, or restart your desktop environment"
echo ""
echo -e "${BLUE}Dependencies required at runtime:${NC}"
echo "- sshpass (for SSH connections)"
echo "- python3-tk (for GUI, usually pre-installed)"
echo ""
echo "Install missing dependencies with:"
echo "sudo apt-get install sshpass python3-tk"