#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 重置颜色

# Check shell compatibility
if [ -n "$ZSH_VERSION" ]; then
    SHELL_TYPE="zsh"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_TYPE="bash"
else
    echo -e "${RED}Unsupported shell. Please use ${YELLOW}zsh${RED} or ${YELLOW}bash${NC}."
    exit 1
fi

# Function to prompt for GitHub repository URL in SSH format
get_repo_url() {
    echo -e "${YELLOW}Please enter the GitHub repository URL (in SSH format, e.g., git@github.com:tier4/pilot-auto.x2.git):${NC}"
    read -p "> " REPO_URL
    while [[ ! $REPO_URL =~ ^git@github\.com:.*\.git$ ]]; do
        echo -e "${RED}Invalid format.${NC} ${YELLOW}Please enter the repository URL in SSH format (e.g., git@github.com:tier4/pilot-auto.x2.git).${NC}"
        read -p "> " REPO_URL
    done
}

# Function to prompt for branch name
get_branch_name() {
    echo -e "${YELLOW}Please enter the branch name (default: main):${NC}"
    read -p "> " BRANCH_NAME
    BRANCH_NAME=${BRANCH_NAME:-main}
}

# Function to prompt for clone directory path
get_clone_path() {
    echo -e "${YELLOW}Please enter the clone path (default: ~/pilot.auto/[repository_name]-[branch_name]):${NC}"
    read -p "> " CLONE_PATH
    if [ -z "$CLONE_PATH" ]; then
        REPO_NAME=$(basename -s .git "$REPO_URL")
        SAFE_BRANCH_NAME=$(echo "$BRANCH_NAME" | sed 's/[^a-zA-Z0-9.]/-/g')
        CLONE_PATH="$HOME/pilot.auto/${REPO_NAME}-${SAFE_BRANCH_NAME}"
    fi
}

# Main script execution
echo -e "${YELLOW}===== GitHub Repository Clone Script =====${NC}"

get_repo_url
get_branch_name
get_clone_path

# Check if the path exists
if [ -d "$CLONE_PATH" ]; then
    echo -e "${YELLOW}The path ${RED}$CLONE_PATH${YELLOW} already exists.${NC}"
    echo -e "${YELLOW}Do you want to delete this directory and continue? (y/n):${NC}"
    read -p "> " DELETE_CONFIRMATION
    if [[ "$DELETE_CONFIRMATION" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deleting existing directory...${NC}"
        rm -rf "$CLONE_PATH"
        echo -e "${YELLOW}Directory deleted.${NC}"
    else
        echo -e "${RED}Operation cancelled.${NC}"
        exit 1
    fi
fi

# Final confirmation before cloning
echo -e "${YELLOW}Repository URL:${NC} ${RED}$REPO_URL${NC}"
echo -e "${YELLOW}Branch:${NC} ${RED}$BRANCH_NAME${NC}"
echo -e "${YELLOW}Clone Path:${NC} ${RED}$CLONE_PATH${NC}"
echo -e "${YELLOW}Proceed with these settings? (y/n) [y]:${NC}"
read -p "> " CONFIRMATION
CONFIRMATION=${CONFIRMATION:-y} 

if [[ "$CONFIRMATION" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cloning repository...${NC}"
    git clone -b "$BRANCH_NAME" "$REPO_URL" "$CLONE_PATH"
    echo -e "${YELLOW}Repository cloned to ${RED}$CLONE_PATH${YELLOW}.${NC}"
else
    echo -e "${RED}Operation cancelled.${NC}"
    exit 1
fi
