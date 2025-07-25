#!/bin/bash

# SystemD Analyzer GUI Complete Build Script
# This script builds both the executable and the Debian package

echo "SystemD Analyzer GUI - Complete Build Script"
echo "============================================"

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

# Step 1: Build the executable
echo -e "${YELLOW}Step 1: Building executable...${NC}"
if [ -f "build.sh" ]; then
    ./build.sh
    if [ $? -ne 0 ]; then
        echo -e "${RED}Executable build failed!${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: build.sh not found${NC}"
    exit 1
fi

# Step 2: Build the Debian package
echo -e "${YELLOW}Step 2: Building Debian package...${NC}"
if [ -f "build-deb.sh" ]; then
    ./build-deb.sh
    if [ $? -ne 0 ]; then
        echo -e "${RED}Debian package build failed!${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: build-deb.sh not found${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Complete build successful!${NC}"
echo ""
echo -e "${YELLOW}Files created:${NC}"
echo "- SystemD_Analyzer (executable)"
echo "- systemd-analyzer-gui_1.0.0-1_amd64.deb (Debian package)"
echo ""
echo -e "${YELLOW}Installation options:${NC}"
echo "1. ${BLUE}Install Debian package:${NC} sudo dpkg -i systemd-analyzer-gui_1.0.0-1_amd64.deb"
echo "2. ${BLUE}Run executable directly:${NC} ./SystemD_Analyzer"
echo ""
echo -e "${BLUE}After installing the package, you can run:${NC} systemd-analyzer"
echo -e "${BLUE}Or find it in your applications menu as 'SystemD Analyzer'${NC}" 