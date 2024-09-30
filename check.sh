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

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    print_header "Usage"
    echo "Usage: ./check <ip_range>"
    exit 1
fi

# Get the IP range from the argument
IP_RANGE="$1"

# Print start message
print_header "Scanning IP Range: $IP_RANGE"

# Function to check if a host is alive
check_host() {
    local ip="$1"
    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        echo -e "\033[32m[+] Alive: $ip\033[0m"
        run_netexec "$ip"  # Run netexec on alive hosts
    fi
}

# Function to run netexec on the given IP
run_netexec() {
    local ip="$1"
    echo -e "\033[34mRunning netexec on $ip...\033[0m"
    netexec smb "$ip" -u '' -p '' --shares --users --sessions
    echo -e "\033[34mFinished netexec on $ip.\033[0m"
}

# Scan the IP range
for i in $(seq 1 254); do
    IP="${IP_RANGE}.${i}"
    check_host "$IP" &
done

# Wait for all background jobs to finish
wait

# Print scan completion message
print_header "Scanning Complete"
