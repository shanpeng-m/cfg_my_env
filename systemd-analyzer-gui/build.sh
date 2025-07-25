#!/bin/bash

# SystemD Analyzer GUI Build Script
# This script will create a standalone executable for Ubuntu with desktop integration

echo "SystemD Analyzer GUI - Build Script"
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get absolute path of current directory
INSTALL_DIR="$(pwd)"
EXECUTABLE_PATH="$INSTALL_DIR/SystemD_Analyzer"

# Check if Python3 is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python3 is not installed${NC}"
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

# Install required packages
echo -e "${YELLOW}Installing required Python packages...${NC}"
pip3 install --user pyinstaller

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}Warning: sshpass is not installed${NC}"
    echo "The application will require sshpass to function properly"
    echo "Install with: sudo apt-get install sshpass"
else
    echo -e "${GREEN}sshpass found: $(sshpass -V 2>&1 | head -1)${NC}"
fi

# Create build directory
BUILD_DIR="systemd_analyzer_build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Copy the Python script
cp ../systemd_analyzer_gui.py .

# Create spec file for PyInstaller
cat > systemd_analyzer.spec << 'EOF'
# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['systemd_analyzer_gui.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=['tkinter', 'tkinter.ttk', 'tkinter.scrolledtext', 'tkinter.messagebox', 'tkinter.filedialog'],
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
    name='SystemD_Analyzer',
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
~/.local/bin/pyinstaller systemd_analyzer.spec

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Build successful!${NC}"
    
    # Copy executable to parent directory
    cp dist/SystemD_Analyzer ../
    
    # Make it executable
    chmod +x ../SystemD_Analyzer
    
    echo -e "${GREEN}Executable created: SystemD_Analyzer${NC}"
    echo -e "${BLUE}File size: $(du -h ../SystemD_Analyzer | cut -f1)${NC}"
    
    # Create desktop entry with absolute path
    cat > ../systemd-analyzer.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=SystemD Analyzer
Comment=SystemD Analysis Tool with GUI
Exec=$EXECUTABLE_PATH
Icon=utilities-system-monitor
Terminal=false
Categories=System;Monitor;
StartupNotify=true
EOF
    
    chmod +x ../systemd-analyzer.desktop
    
    echo -e "${GREEN}Desktop entry created: systemd-analyzer.desktop${NC}"
    
    # Install desktop entry
    DESKTOP_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_DIR"
    cp ../systemd-analyzer.desktop "$DESKTOP_DIR/"
    
    echo -e "${GREEN}Desktop entry installed to: $DESKTOP_DIR${NC}"
    
    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$DESKTOP_DIR"
        echo -e "${GREEN}Desktop database updated${NC}"
    fi
    
    # Create launcher script for easier execution
    cat > ../systemd-analyzer << 'EOF'
#!/bin/bash
# SystemD Analyzer Launcher Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXECUTABLE="$SCRIPT_DIR/SystemD_Analyzer"

if [ -f "$EXECUTABLE" ]; then
    cd "$SCRIPT_DIR"
    exec "$EXECUTABLE" "$@"
else
    echo "Error: SystemD_Analyzer executable not found in $SCRIPT_DIR"
    exit 1
fi
EOF
    
    chmod +x ../systemd-analyzer
    
    echo ""
    echo -e "${YELLOW}Installation complete!${NC}"
    echo ""
    echo -e "${GREEN}You can now run the application in several ways:${NC}"
    echo "1. ${BLUE}Direct execution:${NC} ./SystemD_Analyzer"
    echo "2. ${BLUE}Using launcher:${NC} ./systemd-analyzer"
    echo "3. ${BLUE}From applications menu:${NC} Search for 'SystemD Analyzer'"
    echo "4. ${BLUE}Command line anywhere:${NC} Add this directory to PATH"
    echo ""
    echo -e "${YELLOW}Files created:${NC}"
    echo "- SystemD_Analyzer (main executable)"
    echo "- systemd-analyzer (launcher script)"
    echo "- systemd-analyzer.desktop (desktop entry)"
    echo ""
    echo -e "${BLUE}Desktop entry installed to:${NC} $DESKTOP_DIR/systemd-analyzer.desktop"
    
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

# Clean up build files
cd ..
echo -e "${BLUE}Cleaning up build files...${NC}"
rm -rf "$BUILD_DIR"

echo -e "${GREEN}Done!${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} If the application doesn't appear in the menu immediately,"
echo "try logging out and back in, or run: killall gnome-panel (for GNOME)"