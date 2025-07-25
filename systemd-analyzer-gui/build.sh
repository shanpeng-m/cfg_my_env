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

# Check if we're in the right directory
if [ ! -f "systemd_analyzer_gui.py" ]; then
    echo -e "${RED}Error: systemd_analyzer_gui.py not found${NC}"
    echo "Please run this script from the systemd-analyzer-gui directory"
    exit 1
fi

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
echo -e "${YELLOW}Next steps:${NC}"
echo "1. ${BLUE}Build Debian package:${NC} ./build-deb.sh"
echo "2. ${BLUE}Or run directly:${NC} ./SystemD_Analyzer"
echo ""
echo -e "${BLUE}Dependencies required at runtime:${NC}"
echo "- sshpass (for SSH connections)"
echo "- python3-tk (for GUI, usually pre-installed)"
echo ""
echo "Install missing dependencies with:"
echo "sudo apt-get install sshpass python3-tk"