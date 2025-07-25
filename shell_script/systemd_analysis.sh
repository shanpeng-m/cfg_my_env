#!/bin/bash

# Host configuration with passwords
declare -A HOSTS=(
  ["main"]="autoware@192.168.20.11"
  ["sub"]="autoware@192.168.20.21"
  ["perception1"]="autoware@192.168.20.31"
  ["perception2"]="autoware@192.168.20.32"
  ["logging"]="autoware@192.168.20.71"
)

# Password configuration (set your password here)
SSH_PASSWORD="autoware"
SUDO_PASSWORD="autoware"  # If different from SSH password

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
  echo -e "${RED}Error: sshpass is not installed. Please install it first:${NC}"
  echo "   Ubuntu/Debian: sudo apt-get install sshpass"
  echo "   CentOS/RHEL: sudo yum install sshpass"
  echo "   macOS: brew install sshpass"
  exit 1
fi

# Get current timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create local result directory
LOCAL_DIR="systemd_analysis_${TIMESTAMP}"
mkdir -p "$LOCAL_DIR"

echo -e "${CYAN}Starting SystemD analysis task...${NC}"
echo "Timestamp: $TIMESTAMP"
echo "Results will be saved to: $LOCAL_DIR"
echo "----------------------------------------"

# Iterate through all hosts
for hostname in "${!HOSTS[@]}"; do
  host_addr="${HOSTS[$hostname]}"
  echo -e "${BLUE}Processing host: $hostname ($host_addr)${NC}"
  
  # Check SSH connection with password
  if ! sshpass -p "$SSH_PASSWORD" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$host_addr" "echo 'SSH connection successful'" 2>/dev/null; then
      echo -e "  ${RED}x Cannot connect to $hostname ($host_addr)${NC}"
      continue
  fi
  
  echo -e "  ${GREEN}+ SSH connection successful${NC}"
  
  # Execute commands on remote host
  echo -e "  ${YELLOW}> Executing systemd-analyze commands...${NC}"
  sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$host_addr" << EOF
      # Create temporary directory
      TEMP_DIR="/tmp/systemd_analysis_\$(date +%s)"
      mkdir -p "\$TEMP_DIR"
      cd "\$TEMP_DIR"
      
      # Execute systemd-analyze commands with sudo password
      echo "Executing systemd-analyze dump..."
      echo "$SUDO_PASSWORD" | sudo -S systemd-analyze dump > dump.log 2>&1
      
      echo "Executing systemd-analyze plot..."
      echo "$SUDO_PASSWORD" | sudo -S systemd-analyze plot > plot.svg 2>&1
      
      # Check if files were generated successfully
      if [ -f dump.log ] && [ -f plot.svg ]; then
          echo "Files generated successfully"
          echo "\$TEMP_DIR"
      else
          echo "File generation failed"
          exit 1
      fi
EOF
  
  if [ $? -eq 0 ]; then
      echo -e "  ${GREEN}+ Remote commands executed successfully${NC}"
      
      # Get remote temporary directory path
      REMOTE_TEMP_DIR=$(sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$host_addr" "ls -dt /tmp/systemd_analysis_* | head -1" 2>/dev/null)
      
      if [ -n "$REMOTE_TEMP_DIR" ]; then
          echo -e "  ${YELLOW}> Downloading files...${NC}"
          
          # Download dump.log file
          sshpass -p "$SSH_PASSWORD" scp -o StrictHostKeyChecking=no "$host_addr:$REMOTE_TEMP_DIR/dump.log" "$LOCAL_DIR/${hostname}_${TIMESTAMP}_dump.log" 2>/dev/null
          if [ $? -eq 0 ]; then
              echo -e "    ${GREEN}+ dump.log downloaded successfully${NC}"
          else
              echo -e "    ${RED}x dump.log download failed${NC}"
          fi
          
          # Download plot.svg file
          sshpass -p "$SSH_PASSWORD" scp -o StrictHostKeyChecking=no "$host_addr:$REMOTE_TEMP_DIR/plot.svg" "$LOCAL_DIR/${hostname}_${TIMESTAMP}_plot.svg" 2>/dev/null
          if [ $? -eq 0 ]; then
              echo -e "    ${GREEN}+ plot.svg downloaded successfully${NC}"
          else
              echo -e "    ${RED}x plot.svg download failed${NC}"
          fi
          
          # Clean up remote temporary files
          sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$host_addr" "rm -rf $REMOTE_TEMP_DIR" 2>/dev/null
          echo -e "  ${CYAN}~ Remote temporary files cleaned up${NC}"
      else
          echo -e "  ${RED}x Cannot find remote temporary directory${NC}"
      fi
  else
      echo -e "  ${RED}x Remote command execution failed${NC}"
  fi
  
  echo "----------------------------------------"
done

echo -e "${GREEN}Task completed!${NC}"
echo "Result files saved in: $LOCAL_DIR"

# Set proper permissions for the directory and files
echo -e "${YELLOW}> Setting file permissions...${NC}"

# Set directory permissions (755: owner can read/write/execute, group and others can read/execute)
chmod 755 "$LOCAL_DIR" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}+ Directory permissions set (755)${NC}"
else
    echo -e "  ${YELLOW}! Could not set directory permissions${NC}"
fi

# Set file permissions (644: owner can read/write, group and others can read)
if [ -n "$(ls -A "$LOCAL_DIR" 2>/dev/null)" ]; then
    chmod 644 "$LOCAL_DIR"/* 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}+ File permissions set (644)${NC}"
    else
        echo -e "  ${YELLOW}! Could not set file permissions${NC}"
    fi
fi

# Change ownership to current user (in case files were created with different ownership)
CURRENT_USER=$(whoami)
if [ -n "$CURRENT_USER" ]; then
    chown -R "$CURRENT_USER:$CURRENT_USER" "$LOCAL_DIR" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}+ Ownership changed to $CURRENT_USER${NC}"
    else
        echo -e "  ${YELLOW}! Could not change ownership (may require sudo)${NC}"
    fi
fi

echo "File list:"
ls -la "$LOCAL_DIR"

# Generate summary report
echo -e "${YELLOW}Generating summary report...${NC}"
cat > "$LOCAL_DIR/README.txt" << EOF
SystemD Analysis Report
======================
Generated at: $(date)
Timestamp: $TIMESTAMP

File descriptions:
- *_dump.log: systemd-analyze dump output
- *_plot.svg: systemd-analyze plot output

Host list:
EOF

for hostname in "${!HOSTS[@]}"; do
  echo "- $hostname: ${HOSTS[$hostname]}" >> "$LOCAL_DIR/README.txt"
done

# Set permissions for the README file as well
chmod 644 "$LOCAL_DIR/README.txt" 2>/dev/null

echo -e "${GREEN}+ All tasks completed!${NC}"