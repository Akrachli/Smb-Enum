#!/bin/bash

# Function to display a header
print_header() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

# Function to display a message in red
print_red() {
    echo -e "\033[31m$1\033[0m"
}

# Function to display a message in blue
print_blue() {
    echo -e "\033[34m$1\033[0m"
}

# Check if at least 1 argument is provided
if [ "$#" -lt 1 ]; then
    print_header "Usage"
    echo "Usage: ./check <ip_range> [-n] [output_file]"
    exit 1
fi

# Parse arguments
IP_RANGE="$1"
RUN_NETEXEC=false  # Default to not running netexec
OUTPUT_FILE=""

# Check for the -n flag
if [ "$#" -ge 2 ] && [ "$2" == "-n" ]; then
    RUN_NETEXEC=true
    print_blue "Netexec will be run on alive hosts."
    shift  # Move arguments so that we can process the next ones
fi

# Check if an output file is specified
if [ "$#" -eq 2 ]; then
    OUTPUT_FILE="$2"
    print_blue "Results will be saved to: $OUTPUT_FILE"
fi

# Determine if it's a /16 (x.x) or /24 (x.x.x) range
IFS='.' read -r -a octets <<< "$IP_RANGE"
OCTET_COUNT=${#octets[@]}

# Validate the input IP format
if [[ $OCTET_COUNT -ne 2 && $OCTET_COUNT -ne 3 ]]; then
    print_red "Error: Invalid IP range format. Use either x.x or x.x.x"
    exit 1
fi

# Print start message
print_header "Scanning IP Range: $IP_RANGE"

# Function to check if a host is alive
check_host() {
    local ip="$1"
    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        echo -e "\033[32m[+] Alive: $ip\033[0m"
        
        # If netexec should run, do so
        if $RUN_NETEXEC; then
            run_netexec "$ip"
        fi

        # If an output file is provided, save the alive IP to the file
        if [ -n "$OUTPUT_FILE" ]; then
            echo "$ip" >> "$OUTPUT_FILE"
        fi
    fi
}

# Function to run netexec on the given IP
run_netexec() {
    local ip="$1"
    echo -e "\033[34mRunning netexec on $ip...\033[0m"
    netexec smb "$ip" -u '' -p '' --shares --users --sessions
    echo -e "\033[34mFinished netexec on $ip.\033[0m"
}

# Scan IPs based on the IP range
if [ $OCTET_COUNT -eq 3 ]; then
    # For x.x.x (24-bit subnet), scan x.x.x.1 - x.x.x.254
    for i in $(seq 1 254); do
        IP="${IP_RANGE}.${i}"
        check_host "$IP" &
    done
elif [ $OCTET_COUNT -eq 2 ]; then
    # For x.x (16-bit subnet), scan x.x.1.1 - x.x.254.254
    for i in $(seq 1 254); do
        for j in $(seq 1 254); do
            IP="${IP_RANGE}.${i}.${j}"
            check_host "$IP" &
        done
    done
fi

# Wait for all background jobs to finish
wait

# Print scan completion message
print_header "Scanning Complete"

# If an output file was specified, print its full path
if [ -n "$OUTPUT_FILE" ]; then
    FULL_PATH=$(realpath "$OUTPUT_FILE")
    print_blue "Results have been saved to: $FULL_PATH"
fi
