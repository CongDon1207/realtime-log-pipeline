#!/bin/bash

# Quick test script to generate a few sample log entries
# Usage: ./test-log-format.sh

LOG_FILE="../data/access.log"

echo "Generating sample log entries for testing..."

# Ghi 2 dòng log mẫu
echo '192.168.1.100 - - [15/Jul/2025:10:30:15 +0700] "GET /api/users HTTP/1.1" 200 1254 "https://google.com" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"' >> "$LOG_FILE"
echo '10.0.0.15 - - [15/Jul/2025:10:30:16 +0700] "POST /api/orders HTTP/1.1" 201 523 "https://example.com" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"' >> "$LOG_FILE"


# Simple validation using grep with basic pattern
if tail -1 "$LOG_FILE" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ - - \[[^]]+\] "[^"]+" [0-9]+ [0-9]+ "[^"]*" "[^"]*"$'; then
    echo "✓ Log format appears valid"
else
    echo "✗ Log format validation failed"
    echo "Debugging last line:"
    tail -1 "$LOG_FILE" | cat -A
fi
