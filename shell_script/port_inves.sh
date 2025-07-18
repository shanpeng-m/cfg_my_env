#!/bin/bash

# Show usage information
show_usage() {
    echo "Network Port Investigation Tool"
    echo "================================"
    echo ""
    echo "Usage:"
    echo "  $0 [ss|lsof]"
    echo ""
    echo "Options:"
    echo "  ss    - Use 'ss' command (default, better connection states)"
    echo "  lsof  - Use 'lsof' command (detailed process information)"
    echo ""
    echo "Examples:"
    echo "  $0          # Show this help message"
    echo "  $0 ss       # Use ss mode (better connection states)"
    echo "  $0 lsof     # Use lsof mode (detailed process information)"
    echo ""
    echo "Note: This script automatically uses sudo for complete system information."
    echo ""
}

# Check if help is requested or no arguments provided
if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" || -z "$1" ]]; then
    show_usage
    exit 0
fi

# Function to clean and format address
clean_address() {
    local addr="$1"
    
    # Handle empty or null addresses
    if [[ -z "$addr" || "$addr" == "-" ]]; then
        echo "-"
        return
    fi
    
    # Remove interface suffixes (like %lo, %wlp0s20f3)
    addr=$(echo "$addr" | sed 's/%[^:]*//g')
    
    # Handle IPv6 addresses with better formatting
    if [[ "$addr" == *"[::"* ]]; then
        # Extract port from IPv6 address
        if [[ "$addr" =~ \[.*\]:([0-9]+) ]]; then
            port="${BASH_REMATCH[1]}"
            echo "[::]:$port"
        elif [[ "$addr" == *"[:::*" ]]; then
            echo "[::]:*"
        else
            echo "[::]"
        fi
        return
    fi
    
    # Truncate long IPv4 addresses to fit in 18 characters
    if [[ ${#addr} -gt 18 ]]; then
        # Try to keep the port number if possible
        if [[ "$addr" =~ ^([^:]+):([0-9]+)$ ]]; then
            ip="${BASH_REMATCH[1]}"
            port="${BASH_REMATCH[2]}"
            # Truncate IP part to leave space for port
            max_ip_length=$((18 - ${#port} - 1))  # -1 for the colon
            if [[ ${#ip} -gt $max_ip_length ]]; then
                ip="${ip:0:$((max_ip_length-3))}..."
            fi
            echo "$ip:$port"
        else
            echo "${addr:0:15}..."
        fi
    else
        echo "$addr"
    fi
}

# Function to truncate text to specified length
truncate_text() {
    local text="$1"
    local max_length="$2"
    if [[ ${#text} -gt $max_length ]]; then
        echo "${text:0:$((max_length-3))}..."
    else
        echo "$text"
    fi
}

# Function to print header for lsof output
print_lsof_header() {
    printf "%-8s %-16s %-6s %-6s %-10s %-18s %-18s %s\n" \
           "PID" "USER" "PORT" "PROTO" "STATE" "LOCAL_ADDR" "PEER_ADDR" "COMMAND"
    echo "================================================================================================================"
}

# Function to print header for ss output
print_ss_header() {
    printf "%-8s %-16s %-6s %-6s %-10s %-18s %-18s %s\n" \
           "PID" "USER" "PORT" "PROTO" "STATE" "LOCAL_ADDR" "PEER_ADDR" "COMMAND"
    echo "================================================================================================================"
}

# Function to parse lsof output (more detailed process info)
parse_lsof_output() {
    local output_file="port_investigation_lsof_$(date +%Y%m%d_%H%M%S).txt"
    
    # Clear the output file if it exists
    > "$output_file"
    
    print_lsof_header | tee "$output_file"
    
    # Use lsof for detailed process information
    lsof -i -n -P -w | tail -n +2 | while read -r line; do
        # Skip lines that don't have enough fields or are malformed
        field_count=$(echo "$line" | awk '{print NF}')
        if [[ $field_count -lt 8 ]]; then
            continue
        fi
        
        # Parse fields more carefully
        pid=$(echo "$line" | awk '{print $2}')
        user=$(echo "$line" | awk '{print $3}')
        proto=$(echo "$line" | awk '{print $8}')
        addr=$(echo "$line" | awk '{print $9}')
        
        # Validate PID is numeric
        if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
            continue
        fi
        
        # Extract state from parentheses - more robust parsing
        state=$(echo "$line" | grep -o '([^)]*)' | head -1)
        state=${state//\(/}
        state=${state//\)/}
        if [ -z "$state" ]; then
            state="-"
        fi
        
        # Get full command path
        cmdpath=$(ps -p "$pid" -o cmd= 2>/dev/null)
        if [ -z "$cmdpath" ]; then
            cmdpath=$(echo "$line" | awk '{print $1}')
        fi
        
        # Extract port from address - more robust approach
        port=$(echo "$addr" | grep -o ':[0-9]*' | tr -d ':' | head -1)
        if [ -z "$port" ]; then
            port=$(echo "$addr" | grep -o '[0-9]*$' | head -1)
        fi
        if [ -z "$port" ] || [[ ! "$port" =~ ^[0-9]+$ ]]; then
            port="-"
        fi
        
        # Improved address parsing
        if [[ "$addr" == *"->"* ]]; then
            # Connection with peer
            local_addr=$(echo "$addr" | cut -d'>' -f1)
            peer_addr=$(echo "$addr" | cut -d'>' -f2)
        else
            # Listening or single address
            local_addr="$addr"
            peer_addr="-"
        fi
        
        # Clean addresses
        local_clean=$(clean_address "$local_addr")
        peer_clean=$(clean_address "$peer_addr")
        
        # Only print if we have valid data
        if [[ "$pid" != "-" && "$port" != "-" ]]; then
            printf "%-8s %-16s %-6s %-6s %-10s %-18s %-18s %s\n" \
                   "$pid" "$user" "$port" "$proto" "$state" "$local_clean" "$peer_clean" "$cmdpath"
        fi
    done | sort -k3 -n | tee -a "$output_file"
    
    echo ""
    echo "📄 Results saved to: $output_file"
}

# Function to parse ss output (better connection states)
parse_ss_output() {
    local output_file="port_investigation_ss_$(date +%Y%m%d_%H%M%S).txt"
    
    # Clear the output file if it exists
    > "$output_file"
    
    print_ss_header | tee "$output_file"
    
    # Filter out TIME-WAIT connections as they are usually not important
    ss -tulpan | grep -v "TIME-WAIT" | tail -n +2 | while IFS= read -r line; do
        # Parse fields
        proto=$(echo "$line" | awk '{print $1}')
        state=$(echo "$line" | awk '{print $2}')
        local_addr=$(echo "$line" | awk '{print $5}')
        peer_addr=$(echo "$line" | awk '{print $6}')
        process_info=$(echo "$line" | awk '{print $7}')
        
        # Extract port number
        if [[ $local_addr =~ :([0-9]+)$ ]]; then
            port="${BASH_REMATCH[1]}"
        else
            port="-"
        fi
        
        # Parse process information
        if [[ $process_info =~ users:\(\(\"([^\"]*)\",pid=([0-9]+) ]]; then
            cmd="${BASH_REMATCH[1]}"
            pid="${BASH_REMATCH[2]}"
            # Get username
            user=$(ps -o user= -p "$pid" 2>/dev/null | tr -d ' ' || echo "unknown")
        else
            cmd="-"
            pid="-"
            user="-"
        fi
        
        # Clean address display
        local_clean=$(clean_address "$local_addr")
        peer_clean=$(clean_address "$peer_addr")
        
        # Truncate command if too long
        cmd_short=$(truncate_text "$cmd" 20)
        
        printf "%-8s %-16s %-6s %-6s %-10s %-18s %-18s %s\n" \
               "$pid" "$user" "$port" "$proto" "$state" "$local_clean" "$peer_clean" "$cmd_short"
    done | sort -k3 -n | tee -a "$output_file"
    
    echo ""
    echo "📄 Results saved to: $output_file"
}

# Main execution - automatically use sudo
if [[ $EUID -ne 0 ]]; then
    echo "🔐 Elevating privileges with sudo for complete system information..."
    echo ""
    exec sudo "$0" "$@"
    exit 0
fi

# Choose method based on argument
case "${1:-ss}" in
    "lsof")
        echo "=== Using lsof (detailed process information) ==="
        parse_lsof_output
        ;;
    "ss"|*)
        echo "=== Using ss (better connection states) ==="
        parse_ss_output
        ;;
esac
