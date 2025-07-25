#!/bin/bash

# Remote MP4 Manager Debian Package Build Script

echo "Remote MP4 Manager - Debian Package Build Script"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we have the executable
if [ ! -f "Remote_MP4_Manager" ]; then
    echo -e "${RED}Error: Remote_MP4_Manager executable not found${NC}"
    echo "Please run build.sh first to create the executable"
    exit 1
fi

# Check if debian directory exists
if [ ! -d "debian" ]; then
    echo -e "${RED}Error: debian directory not found${NC}"
    echo "Please run the setup script first"
    exit 1
fi

# Clean up any existing package
if [ -f "remote-mp4-manager_*.deb" ]; then
    echo -e "${YELLOW}Removing existing package files...${NC}"
    rm -f remote-mp4-manager_*.deb
fi

# Copy files to debian structure
echo -e "${BLUE}Copying files to debian structure...${NC}"
cp Remote_MP4_Manager debian/opt/remote-mp4-manager/
cp remote-mp4-manager.desktop debian/usr/share/applications/
cp remote-mp4-manager.svg debian/usr/share/icons/hicolor/256x256/apps/ 2>/dev/null || true

# Set proper permissions
chmod +x debian/opt/remote-mp4-manager/Remote_MP4_Manager
chmod +x debian/usr/bin/mp4-manager

# Build the package
echo -e "${YELLOW}Building Debian package...${NC}"
dpkg-deb --build debian

if [ $? -eq 0 ]; then
    # Rename the package
    mv debian.deb remote-mp4-manager_1.0.0-1_amd64.deb
    
    echo -e "${GREEN}Package built successfully!${NC}"
    echo -e "${BLUE}Package file:${NC} remote-mp4-manager_1.0.0-1_amd64.deb"
    echo -e "${BLUE}File size:${NC} $(du -h remote-mp4-manager_1.0.0-1_amd64.deb | cut -f1)"
    
    echo ""
    echo -e "${YELLOW}Installation instructions:${NC}"
    echo "1. ${BLUE}Install the package:${NC} sudo dpkg -i remote-mp4-manager_1.0.0-1_amd64.deb"
    echo "2. ${BLUE}Fix dependencies (if needed):${NC} sudo apt-get install -f"
    echo "3. ${BLUE}Run the application:${NC} mp4-manager"
    echo ""
    echo -e "${YELLOW}Uninstall:${NC}"
    echo "sudo apt-get remove remote-mp4-manager"
    
else
    echo -e "${RED}Package build failed!${NC}"
    exit 1
fi 