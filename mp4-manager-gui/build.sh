#!/bin/bash

# Remote MP4 Manager GUI Build Script
# This script will create a standalone executable

echo "Remote MP4 Manager GUI - Build Script"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "mp4_manager_gui.py" ]; then
    echo -e "${RED}Error: mp4_manager_gui.py not found${NC}"
    echo "Please run this script from the mp4-manager-gui directory"
    exit 1
fi

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
echo "2. ${BLUE}Or run directly:${NC} ./Remote_MP4_Manager"
echo ""
echo -e "${BLUE}Dependencies required at runtime:${NC}"
echo "- sshpass (for SSH connections)"
echo "- python3-tk (for GUI, usually pre-installed)"
echo ""
echo "Install missing dependencies with:"
echo "sudo apt-get install sshpass python3-tk"