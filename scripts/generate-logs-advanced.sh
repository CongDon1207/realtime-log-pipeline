#!/bin/bash

# Advanced log generator with configurable parameters
# Usage: ./generate-logs-advanced.sh [OPTIONS]

# Default values
LOG_FILE="../data/access.log"
INTERVAL=1
DURATION=3600
BURST_MODE=false
QUIET=false
CLEAR_LOG=false

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -f, --file FILE         Output log file (default: ../data/access.log)
    -i, --interval SECONDS  Interval between log entries (default: 1)
    -d, --duration SECONDS  Total duration in seconds (default: 3600)
    -b, --burst             Enable burst mode (generates more traffic)
    -c, --clear             Clear existing log file before starting
    -q, --quiet             Quiet mode (less verbose output)
    -h, --help              Show this help message

Examples:
    $0                                          # Run with defaults
    $0 -f /tmp/test.log -i 0.5 -d 300          # Custom file, 0.5s interval, 5min duration
    $0 --burst --clear                         # Burst mode with cleared log
    $0 -q -d 60                                # Quiet mode for 1 minute

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            LOG_FILE="$2"
            shift 2
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -b|--burst)
            BURST_MODE=true
            shift
            ;;
        -c|--clear)
            CLEAR_LOG=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Enhanced data arrays for more realistic logs
IPS=(
    "192.168.1.100" "10.0.0.15" "172.16.0.5" "203.0.113.10" "198.51.100.42"
    "192.0.2.1" "10.1.1.50" "172.20.0.100" "203.0.113.195" "198.51.100.178"
    "10.0.0.25" "172.16.0.15" "192.168.0.50" "10.1.2.30" "172.20.1.45"
)

USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1"
    "Mozilla/5.0 (Android 11; Mobile; rv:89.0) Gecko/89.0 Firefox/89.0"
    "curl/7.68.0"
    "python-requests/2.25.1"
)

PATHS=(
    "/api/v1/users" "/api/v1/orders" "/api/v1/products" "/api/v1/analytics"
    "/dashboard" "/login" "/search" "/cart" "/checkout" "/profile" "/admin"
    "/health" "/metrics" "/status" "/favicon.ico" "/robots.txt"
    "/api/v2/users" "/api/v2/orders" "/static/css/main.css" "/static/js/app.js"
    "/images/logo.png" "/docs" "/support" "/contact" "/about"
)

REFERERS=(
    "https://google.com/search?q=example"
    "https://www.facebook.com/"
    "https://twitter.com/home"
    "https://www.linkedin.com/feed/"
    "https://example.com/"
    "https://github.com/"
    "https://stackoverflow.com/"
    "-"
    "-"
    "-"
)

HTTP_METHODS=("GET" "GET" "GET" "GET" "POST" "PUT" "DELETE" "PATCH" "HEAD" "OPTIONS")

# Enhanced random functions
random_element() {
    local arr=("$@")
    echo "${arr[$((RANDOM % ${#arr[@]}))]}"
}

random_status() {
    local weight=$((RANDOM % 100))
    if [ "$BURST_MODE" = true ]; then
        # More varied status codes in burst mode
        if [ $weight -lt 60 ]; then
            echo "200"
        elif [ $weight -lt 70 ]; then
            echo "404"
        elif [ $weight -lt 75 ]; then
            echo "302"
        elif [ $weight -lt 85 ]; then
            echo "500"
        elif [ $weight -lt 90 ]; then
            echo "401"
        elif [ $weight -lt 95 ]; then
            echo "403"
        else
            echo "503"
        fi
    else
        # Normal distribution
        if [ $weight -lt 80 ]; then
            echo "200"
        elif [ $weight -lt 88 ]; then
            echo "404"
        elif [ $weight -lt 93 ]; then
            echo "302"
        elif [ $weight -lt 97 ]; then
            echo "500"
        else
            echo "401"
        fi
    fi
}

response_size() {
    local status=$1
    case $status in
        200) 
            if [ "$BURST_MODE" = true ]; then
                echo $((RANDOM % 100000 + 1000))  # Larger responses in burst mode
            else
                echo $((RANDOM % 50000 + 1000))
            fi
            ;;
        404) echo $((RANDOM % 500 + 200)) ;;
        500|503) echo $((RANDOM % 1000 + 500)) ;;
        302) echo "0" ;;
        401|403) echo $((RANDOM % 300 + 100)) ;;
        *) echo $((RANDOM % 10000 + 500)) ;;
    esac
}

generate_log_entry() {
    local timestamp=$(date '+%d/%b/%Y:%H:%M:%S %z')
    local ip=$(random_element "${IPS[@]}")
    local method=$(random_element "${HTTP_METHODS[@]}")
    local path=$(random_element "${PATHS[@]}")
    local status=$(random_status)
    local size=$(response_size $status)
    local referer=$(random_element "${REFERERS[@]}")
    local user_agent=$(random_element "${USER_AGENTS[@]}")
    
    # Add query parameters based on path
    if [[ "$path" == *"/api/"* && $((RANDOM % 2)) -eq 0 ]]; then
        case $((RANDOM % 4)) in
            0) path="${path}?id=$((RANDOM % 1000))" ;;
            1) path="${path}?page=$((RANDOM % 10 + 1))" ;;
            2) path="${path}?limit=$((RANDOM % 50 + 10))" ;;
            3) path="${path}?filter=active&sort=created_at" ;;
        esac
    elif [[ "$path" == "/search" && $((RANDOM % 3)) -eq 0 ]]; then
        local queries=("product" "order" "user" "analytics" "dashboard")
        local query=$(random_element "${queries[@]}")
        path="${path}?q=${query}"
    fi
    
    # Format: IP - - [timestamp] "METHOD path HTTP/1.1" status size "referer" "user_agent"
    echo "$ip - - [$timestamp] \"$method $path HTTP/1.1\" $status $size \"$referer\" \"$user_agent\""
}

# Logging function
log_message() {
    if [ "$QUIET" != true ]; then
        echo "$1"
    fi
}

# Main execution
log_message "Starting advanced log generation..."
log_message "Configuration:"
log_message "  Log file: $LOG_FILE"
log_message "  Interval: ${INTERVAL}s"
log_message "  Duration: ${DURATION}s"
log_message "  Burst mode: $BURST_MODE"
log_message "  Clear log: $CLEAR_LOG"
log_message "Press Ctrl+C to stop"

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Handle log file
if [ "$CLEAR_LOG" = true ] || [ ! -f "$LOG_FILE" ]; then
    > "$LOG_FILE"
    log_message "Created/cleared log file: $LOG_FILE"
else
    log_message "Appending to existing log file: $LOG_FILE"
fi

# Generate logs
start_time=$(date +%s)
end_time=$((start_time + DURATION))
total_entries=0

while [ $(date +%s) -lt $end_time ]; do
    # Determine number of entries per interval
    if [ "$BURST_MODE" = true ]; then
        # Variable traffic simulation
        time_of_day=$(date +%H)
        if [ $time_of_day -ge 9 ] && [ $time_of_day -le 17 ]; then
            # Business hours: more traffic
            entries=$((RANDOM % 8 + 2))
        elif [ $time_of_day -ge 19 ] && [ $time_of_day -le 23 ]; then
            # Evening: moderate traffic
            entries=$((RANDOM % 5 + 1))
        else
            # Night/early morning: low traffic
            entries=$((RANDOM % 2 + 1))
        fi
    else
        entries=$((RANDOM % 3 + 1))
    fi
    
    for ((i=0; i<entries; i++)); do
        generate_log_entry >> "$LOG_FILE"
        ((total_entries++))
    done
    
    log_message "Generated $entries log entries at $(date) | Total: $total_entries"
    sleep $INTERVAL
done

log_message "Log generation completed!"
log_message "Total entries generated: $total_entries"
log_message "Total runtime: ${DURATION}s"
log_message "Check log file: $LOG_FILE"
