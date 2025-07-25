#!/bin/bash

# Script to generate test nginx logs
LOG_FILE="/var/log/nginx/access.log"

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Generate sample nginx access logs
generate_log_entry() {
    local ip="192.168.1.$((RANDOM % 255 + 1))"
    local timestamp=$(date +'%d/%b/%Y:%H:%M:%S %z')
    local method="GET"
    local url="/api/users/$((RANDOM % 1000))"
    local status=$((200 + RANDOM % 300))
    local size=$((100 + RANDOM % 9900))
    local referer="https://example.com"
    local user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
    
    echo "$ip - - [$timestamp] \"$method $url HTTP/1.1\" $status $size \"$referer\" \"$user_agent\""
}

echo "Generating test nginx access logs to $LOG_FILE"
echo "Press Ctrl+C to stop"

while true; do
    generate_log_entry >> "$LOG_FILE"
    echo "Generated log entry at $(date)"
    sleep 2
done
