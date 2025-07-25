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

# Function to get MP4 file list with detailed info
get_mp4_file_list() {
  # Use find with -print0 and process with null delimiter for better handling of filenames with spaces
  local mp4_list_raw
  mp4_list_raw=$(execute_remote_command "find '${REMOTE_DIR}' -maxdepth 1 -name '*.mp4' -type f -print0 2>/dev/null")
  
  if [ -z "$mp4_list_raw" ]; then
      return 1
  fi
  
  # Convert null-delimited list to array
  local mp4_files=()
  while IFS= read -r -d '' file; do
      if [ -n "$file" ]; then
          mp4_files+=("$file")
      fi
  done <<< "$mp4_list_raw"
  
  # Export the array for use in other functions
  printf '%s\n' "${mp4_files[@]}"
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
  
  # Create a temporary file to store the file list
  local temp_file_list
  temp_file_list=$(mktemp)
  
  # Get file list using a more robust method
  execute_remote_command "find '${REMOTE_DIR}' -maxdepth 1 -name '*.mp4' -type f -exec ls -lh {} \; 2>/dev/null" > "$temp_file_list"
  
  if [ ! -s "$temp_file_list" ]; then
      echo -e "${YELLOW}No .mp4 files found in ${REMOTE_DIR} directory${NC}"
      
      # Check if directory exists
      echo -e "${YELLOW}Checking if directory exists...${NC}"
      DIR_CHECK=$(execute_remote_command "ls -la '${REMOTE_DIR}' 2>/dev/null")
      if [ -n "$DIR_CHECK" ]; then
          echo -e "${BLUE}Directory contents:${NC}"
          echo "$DIR_CHECK"
      else
          echo -e "${RED}Directory ${REMOTE_DIR} does not exist or is not accessible${NC}"
      fi
      rm -f "$temp_file_list"
      return 0
  fi
  
  # Parse and display found files
  echo -e "${GREEN}Found MP4 files:${NC}"
  local file_count=0
  local -a mp4_files_array
  
  # Read file information and build array
  while IFS= read -r line; do
      if [ -n "$line" ]; then
          # Extract filename from ls -lh output (last field)
          local filename
          filename=$(echo "$line" | awk '{print $NF}')
          local basename_file
          basename_file=$(basename "$filename")
          
          # Extract file size and date
          local filesize
          local filedate
          filesize=$(echo "$line" | awk '{print $5}')
          filedate=$(echo "$line" | awk '{print $6, $7, $8}')
          
          echo -e "  ${BLUE}•${NC} $basename_file (${filesize}, ${filedate})"
          mp4_files_array+=("$filename")
          file_count=$((file_count + 1))
      fi
  done < "$temp_file_list"
  
  rm -f "$temp_file_list"
  
  echo
  echo -e "${GREEN}Total files found: $file_count${NC}"
  
  if [ $file_count -eq 0 ]; then
      echo -e "${YELLOW}No MP4 files to download${NC}"
      return 0
  fi
  
  # Ask user confirmation for download
  echo -e "${YELLOW}Do you want to download these files? (y/N):${NC} "
  read -r REPLY
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Download cancelled"
      return 0
  fi
  
  # Download files
  echo -e "${YELLOW}Starting file download...${NC}"
  local download_count=0
  local failed_count=0
  
  for remote_file in "${mp4_files_array[@]}"; do
      if [ -n "$remote_file" ]; then
          local filename
          filename=$(basename "$remote_file")
          local local_file="${LOCAL_DIR}/${filename}"
          
          echo -e "${YELLOW}Downloading: $filename${NC}"
          
          # Use quotes to handle filenames with spaces
          if sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}:${remote_file}" "$local_file" 2>/dev/null; then
              echo -e "${GREEN}✓ Download completed: $filename${NC}"
              download_count=$((download_count + 1))
          else
              echo -e "${RED}✗ Download failed: $filename${NC}"
              failed_count=$((failed_count + 1))
          fi
          echo
      fi
  done
  
  echo -e "${GREEN}=== Download Summary ===${NC}"
  echo "Local files saved in: $LOCAL_DIR"
  echo "Total files processed: $file_count"
  echo -e "Successfully downloaded: ${GREEN}$download_count${NC}"
  echo -e "Failed downloads: ${RED}$failed_count${NC}"
  echo
  echo "View downloaded files with:"
  echo "ls -la \"$LOCAL_DIR\""
  
  # Show disk usage of downloaded files
  if [ -d "$LOCAL_DIR" ] && [ "$(ls -A "$LOCAL_DIR" 2>/dev/null)" ]; then
      echo
      echo -e "${BLUE}Downloaded files disk usage:${NC}"
      du -sh "$LOCAL_DIR"/* 2>/dev/null | sort -hr
      echo
      echo -e "${BLUE}Total size:${NC}"
      du -sh "$LOCAL_DIR" 2>/dev/null
  fi
}

# Function to list remote MP4 files (new feature)
list_remote_mp4_files() {
  echo -e "${CYAN}=== Remote MP4 Files List ===${NC}"
  
  if ! test_ssh_connection; then
      return 1
  fi
  
  echo -e "${YELLOW}Scanning remote directory: ${REMOTE_DIR}${NC}"
  
  # Get detailed file list
  local file_list
  file_list=$(execute_remote_command "find '${REMOTE_DIR}' -maxdepth 1 -name '*.mp4' -type f -exec ls -lh {} \; 2>/dev/null | sort -k9")
  
  if [ -z "$file_list" ]; then
      echo -e "${YELLOW}No .mp4 files found in ${REMOTE_DIR}${NC}"
      
      # Show directory contents for debugging
      echo -e "${BLUE}Directory contents (first 10 items):${NC}"
      execute_remote_command "ls -la '${REMOTE_DIR}' 2>/dev/null | head -10"
      return 0
  fi
  
  echo -e "${GREEN}MP4 files found:${NC}"
  echo
  printf "%-40s %-10s %-20s\n" "FILENAME" "SIZE" "DATE"
  printf "%-40s %-10s %-20s\n" "--------" "----" "----"
  
  local file_count=0
  local total_size=0
  
  while IFS= read -r line; do
      if [ -n "$line" ]; then
          local filename
          filename=$(echo "$line" | awk '{print $NF}')
          local basename_file
          basename_file=$(basename "$filename")
          local filesize
          filesize=$(echo "$line" | awk '{print $5}')
          local filedate
          filedate=$(echo "$line" | awk '{print $6, $7, $8}')
          
          printf "%-40s %-10s %-20s\n" "$basename_file" "$filesize" "$filedate"
          file_count=$((file_count + 1))
      fi
  done <<< "$file_list"
  
  echo
  echo -e "${GREEN}Total files: $file_count${NC}"
  
  # Calculate total size
  local total_size_output
  total_size_output=$(execute_remote_command "find '${REMOTE_DIR}' -maxdepth 1 -name '*.mp4' -type f -exec du -ch {} + 2>/dev/null | tail -1")
  if [ -n "$total_size_output" ]; then
      echo -e "${BLUE}Total size: $(echo "$total_size_output" | awk '{print $1}')${NC}"
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
  echo "3) List remote MP4 files"
  echo "4) Download MP4 files from remote host"
  echo "5) Exit"
  echo
  echo -n "Enter your choice (1-5): "
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
              list_remote_mp4_files
              echo -e "${BLUE}Press Enter to continue...${NC}"
              read -r
              ;;
          4)
              echo
              download_mp4_files
              echo -e "${BLUE}Press Enter to continue...${NC}"
              read -r
              ;;
          5)
              echo -e "${GREEN}Goodbye!${NC}"
              exit 0
              ;;
          *)
              echo -e "${RED}Invalid option. Please enter 1-5.${NC}"
              sleep 1
              ;;
      esac
  done
}

# Start the program
main