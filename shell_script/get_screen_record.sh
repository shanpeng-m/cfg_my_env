#!/bin/bash

# Remote MP4 File Retrieval Script with Screen Recorder Control
# Connect to remote host and manage screen recorder service + retrieve MP4 files

# Configuration - MODIFY THESE VALUES
REMOTE_USER="autoware"
REMOTE_HOST="192.168.20.21"
REMOTE_PASSWORD="autoware"  # Put your actual password here
REMOTE_DIR="/tmp"
LOCAL_DIR="./downloaded_videos"
SERVICE_NAME="screen-recorder.service"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if password is set
if [ "$REMOTE_PASSWORD" = "your_password_here" ]; then
  echo -e "${RED}Error: Please set your actual password in the REMOTE_PASSWORD variable${NC}"
  echo "Edit the script and change 'your_password_here' to your actual password"
  exit 1
fi

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
  echo -e "${RED}Error: sshpass is not installed${NC}"
  echo "Please install sshpass:"
  echo "  Ubuntu/Debian: sudo apt-get install sshpass"
  echo "  CentOS/RHEL: sudo yum install sshpass"
  echo "  macOS: brew install sshpass"
  exit 1
fi

# Function to execute remote command
execute_remote_command() {
  local command="$1"
  sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" "$command" 2>/dev/null
}

# Function to test SSH connection
test_ssh_connection() {
  echo -e "${YELLOW}Testing SSH connection...${NC}"
  if ! execute_remote_command "echo 'Connection test successful'" >/dev/null; then
      echo -e "${RED}Error: Cannot connect to remote host ${REMOTE_USER}@${REMOTE_HOST}${NC}"
      echo "Please check:"
      echo "1. Network connectivity (can you ping ${REMOTE_HOST}?)"
      echo "2. SSH service is running on remote host"
      echo "3. Username and password are correct"
      echo "4. Firewall settings"
      echo
      echo "Debug: Try manual connection:"
      echo "ssh ${REMOTE_USER}@${REMOTE_HOST}"
      return 1
  fi
  echo -e "${GREEN}SSH connection successful!${NC}"
  return 0
}

# Function to check screen recorder service status
check_screen_recorder_status() {
  echo -e "${CYAN}=== Checking Screen Recorder Service Status ===${NC}"
  
  if ! test_ssh_connection; then
      return 1
  fi
  
  echo -e "${YELLOW}Checking ${SERVICE_NAME} status...${NC}"
  
  # Get service status
  status_output=$(execute_remote_command "systemctl status ${SERVICE_NAME}")
  exit_code=$?
  
  if [ $exit_code -eq 0 ]; then
      # Service exists, check if it's active
      if echo "$status_output" | grep -q "Active: active (running)"; then
          echo -e "${GREEN}✓ ${SERVICE_NAME} is RUNNING${NC}"
      elif echo "$status_output" | grep -q "Active: inactive"; then
          echo -e "${YELLOW}⚠ ${SERVICE_NAME} is STOPPED${NC}"
      elif echo "$status_output" | grep -q "Active: failed"; then
          echo -e "${RED}✗ ${SERVICE_NAME} has FAILED${NC}"
      else
          echo -e "${BLUE}? ${SERVICE_NAME} status is UNKNOWN${NC}"
      fi
      
      # Show detailed status
      echo -e "${BLUE}Detailed status:${NC}"
      echo "$status_output" | head -10
      
  else
      echo -e "${RED}✗ ${SERVICE_NAME} not found or not accessible${NC}"
      echo "Service may not exist or you may not have permission to check it"
  fi
  
  echo
}

# Function to enable screen recorder service
enable_screen_recorder() {
  echo -e "${CYAN}=== Enabling Screen Recorder Service ===${NC}"
  
  if ! test_ssh_connection; then
      return 1
  fi
  
  echo -e "${YELLOW}Enabling ${SERVICE_NAME}...${NC}"
  
  # Enable the service
  enable_output=$(execute_remote_command "sudo systemctl enable ${SERVICE_NAME}" 2>&1)
  enable_exit_code=$?
  
  if [ $enable_exit_code -eq 0 ]; then
      echo -e "${GREEN}✓ ${SERVICE_NAME} enabled successfully${NC}"
  else
      echo -e "${RED}✗ Failed to enable ${SERVICE_NAME}${NC}"
      echo "Error output: $enable_output"
      echo
      return 1
  fi
  
  # Start the service
  echo -e "${YELLOW}Starting ${SERVICE_NAME}...${NC}"
  start_output=$(execute_remote_command "sudo systemctl start ${SERVICE_NAME}" 2>&1)
  start_exit_code=$?
  
  if [ $start_exit_code -eq 0 ]; then
      echo -e "${GREEN}✓ ${SERVICE_NAME} started successfully${NC}"
  else
      echo -e "${RED}✗ Failed to start ${SERVICE_NAME}${NC}"
      echo "Error output: $start_output"
      echo
      return 1
  fi
  
  # Verify the service is running
  echo -e "${YELLOW}Verifying service status...${NC}"
  sleep 2
  check_screen_recorder_status
}

# Function to download MP4 files
download_mp4_files() {
  echo -e "${CYAN}=== Downloading MP4 Files ===${NC}"
  
  if ! test_ssh_connection; then
      return 1
  fi
  
  # Create local directory
  if [ ! -d "$LOCAL_DIR" ]; then
      mkdir -p "$LOCAL_DIR"
      echo -e "${GREEN}Created local directory: $LOCAL_DIR${NC}"
  fi
  
  # Get remote MP4 file list
  echo -e "${YELLOW}Retrieving remote MP4 file list...${NC}"
  MP4_FILES=$(execute_remote_command "find ${REMOTE_DIR} -maxdepth 1 -name '*.mp4' -type f 2>/dev/null")
  
  if [ -z "$MP4_FILES" ]; then
      echo -e "${YELLOW}No .mp4 files found in ${REMOTE_DIR} directory${NC}"
      
      # Check if directory exists
      echo -e "${YELLOW}Checking if directory exists...${NC}"
      DIR_CHECK=$(execute_remote_command "ls -la ${REMOTE_DIR} 2>/dev/null")
      if [ -n "$DIR_CHECK" ]; then
          echo -e "${BLUE}Directory contents:${NC}"
          echo "$DIR_CHECK"
      else
          echo -e "${RED}Directory ${REMOTE_DIR} does not exist or is not accessible${NC}"
      fi
      return 0
  fi
  
  # Display found files
  echo -e "${GREEN}Found MP4 files:${NC}"
  FILE_COUNT=0
  
  while IFS= read -r file; do
      if [ -n "$file" ]; then
          filename=$(basename "$file")
          fileinfo=$(execute_remote_command "ls -lh '$file' 2>/dev/null | awk '{print \$5, \$6, \$7, \$8}'")
          echo -e "  ${BLUE}•${NC} $filename ($fileinfo)"
          FILE_COUNT=$((FILE_COUNT + 1))
      fi
  done <<< "$MP4_FILES"
  
  echo
  echo -e "${GREEN}Total files found: $FILE_COUNT${NC}"
  
  # Ask user confirmation for download
  echo -e "${YELLOW}Do you want to download these files? (y/N):${NC} "
  read -r REPLY
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Download cancelled"
      return 0
  fi
  
  # Download files
  echo -e "${YELLOW}Starting file download...${NC}"
  DOWNLOAD_COUNT=0
  FAILED_COUNT=0
  
  while IFS= read -r remote_file; do
      if [ -n "$remote_file" ]; then
          filename=$(basename "$remote_file")
          local_file="${LOCAL_DIR}/${filename}"
          
          echo -e "${YELLOW}Downloading: $filename${NC}"
          
          if sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}:${remote_file}" "$local_file" 2>/dev/null; then
              echo -e "${GREEN}✓ Download completed: $filename${NC}"
              DOWNLOAD_COUNT=$((DOWNLOAD_COUNT + 1))
          else
              echo -e "${RED}✗ Download failed: $filename${NC}"
              FAILED_COUNT=$((FAILED_COUNT + 1))
          fi
          echo
      fi
  done <<< "$MP4_FILES"
  
  echo -e "${GREEN}=== Download Summary ===${NC}"
  echo "Local files saved in: $LOCAL_DIR"
  echo "Total files processed: $FILE_COUNT"
  echo -e "Successfully downloaded: ${GREEN}$DOWNLOAD_COUNT${NC}"
  echo -e "Failed downloads: ${RED}$FAILED_COUNT${NC}"
  echo
  echo "View downloaded files with:"
  echo "ls -la \"$LOCAL_DIR\""
  
  # Show disk usage of downloaded files
  if [ -d "$LOCAL_DIR" ] && [ "$(ls -A "$LOCAL_DIR" 2>/dev/null)" ]; then
      echo
      echo -e "${BLUE}Downloaded files disk usage:${NC}"
      du -sh "$LOCAL_DIR"/* 2>/dev/null
  fi
}

# Function to show main menu
show_menu() {
  echo -e "${GREEN}=== Remote MP4 Management Tool ===${NC}"
  echo "Remote host: ${REMOTE_USER}@${REMOTE_HOST}"
  echo "Remote directory: ${REMOTE_DIR}"
  echo "Local directory: ${LOCAL_DIR}"
  echo "Service: ${SERVICE_NAME}"
  echo
  echo -e "${CYAN}Please select an option:${NC}"
  echo "1) Check screen recorder service status"
  echo "2) Enable and start screen recorder service"
  echo "3) Download MP4 files from remote host"
  echo "4) Exit"
  echo
  echo -n "Enter your choice (1-4): "
}

# Main program loop
main() {
  while true; do
      echo
      show_menu
      read -r choice
      
      case $choice in
          1)
              echo
              check_screen_recorder_status
              echo -e "${BLUE}Press Enter to continue...${NC}"
              read -r
              ;;
          2)
              echo
              enable_screen_recorder
              echo -e "${BLUE}Press Enter to continue...${NC}"
              read -r
              ;;
          3)
              echo
              download_mp4_files
              echo -e "${BLUE}Press Enter to continue...${NC}"
              read -r
              ;;
          4)
              echo -e "${GREEN}Goodbye!${NC}"
              exit 0
              ;;
          *)
              echo -e "${RED}Invalid option. Please enter 1-4.${NC}"
              sleep 1
              ;;
      esac
  done
}

# Start the program
main