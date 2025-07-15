#!/bin/bash

# Script to generate sample log data for testing
# Generates Nginx access log format compatible with Fluent Bit parser

LOG_FILE="../data/access.log"
INTERVAL=1  # Seconds between log entries
DURATION=3600  # Total duration in seconds (1 hour)

# Arrays for generating realistic log data
IPS=("192.168.1.100" "10.0.0.15" "172.16.0.5" "203.0.113.10" "198.51.100.42" "192.0.2.1" "10.1.1.50" "172.20.0.100")
USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1"
    "Mozilla/5.0 (Android 11; Mobile; rv:89.0) Gecko/89.0 Firefox/89.0"
)
PATHS=("/api/users" "/api/orders" "/api/products" "/dashboard" "/login" "/search" "/cart" "/checkout" "/profile" "/admin" "/health" "/metrics")
REFERERS=("https://google.com" "https://facebook.com" "https://twitter.com" "https://linkedin.com" "-" "https://example.com")
HTTP_METHODS=("GET" "POST" "PUT" "DELETE" "PATCH")
STATUS_CODES=(200 200 200 200 201 404 500 302 401 403)  # Weighted towards 200

# Function to generate random element from array
random_element() {
    local arr=("$@")
    echo "${arr[$((RANDOM % ${#arr[@]}))]}"
}

# Function to generate random status code (weighted)
random_status() {
    local weight=$((RANDOM % 100))
    if [ $weight -lt 70 ]; then
        echo "200"
    elif [ $weight -lt 80 ]; then
        echo "404"
    elif [ $weight -lt 85 ]; then
        echo "302"
    elif [ $weight -lt 90 ]; then
        echo "500"
    elif [ $weight -lt 95 ]; then
        echo "401"
    else
        echo "403"
    fi
}

# Function to generate response size based on status
response_size() {
    local status=$1
    case $status in
        200) echo $((RANDOM % 50000 + 1000)) ;;  # 1KB - 50KB
        404) echo $((RANDOM % 500 + 200)) ;;     # 200B - 700B
        500) echo $((RANDOM % 1000 + 500)) ;;    # 500B - 1.5KB
        302) echo "0" ;;                         # Redirect
        401|403) echo $((RANDOM % 300 + 100)) ;; # 100B - 400B
        *) echo $((RANDOM % 10000 + 500)) ;;     # Default
    esac
}

# Function to generate log entry
generate_log_entry() {
    local timestamp=$(date '+%d/%b/%Y:%H:%M:%S %z')
    local ip=$(random_element "${IPS[@]}")
    local method=$(random_element "${HTTP_METHODS[@]}")
    local path=$(random_element "${PATHS[@]}")
    local status=$(random_status)
    local size=$(response_size $status)
    local referer=$(random_element "${REFERERS[@]}")
    local user_agent=$(random_element "${USER_AGENTS[@]}")
    
    # Add query parameters occasionally
    if [ $((RANDOM % 3)) -eq 0 ]; then
        path="${path}?id=$((RANDOM % 1000))"
    fi
    
    # Nginx access log format
    echo "$ip - - [$timestamp] \"$method $path HTTP/1.1\" $status $size \"$referer\" \"$user_agent\""
}

echo "Starting log generation..."
echo "Log file: $LOG_FILE"
echo "Interval: ${INTERVAL}s"
echo "Duration: ${DURATION}s"
echo "Press Ctrl+C to stop"

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Initialize or append to log file
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    echo "Created new log file: $LOG_FILE"
else
    echo "Appending to existing log file: $LOG_FILE"
fi

# Generate logs
start_time=$(date +%s)
end_time=$((start_time + DURATION))

while [ $(date +%s) -lt $end_time ]; do
    # Generate 1-3 log entries per interval to simulate varying traffic
    entries=$((RANDOM % 3 + 1))
    
    for ((i=0; i<entries; i++)); do
        generate_log_entry >> "$LOG_FILE"
    done
    
    echo "Generated $entries log entries at $(date)"
    sleep $INTERVAL
done

echo "Log generation completed. Total runtime: ${DURATION}s"
echo "Check log file: $LOG_FILE"
