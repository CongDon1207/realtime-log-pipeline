#!/bin/bash

# Quick test script to generate a few sample log entries
# Usage: ./test-log-format.sh

LOG_FILE="../data/access.log"

echo "Generating sample log entries for testing..."

# Sample realistic log entries
cat >> "$LOG_FILE" << 'EOF'
192.168.1.100 - - [15/Jul/2025:10:30:15 +0700] "GET /api/v1/users HTTP/1.1" 200 1254 "https://google.com/search?q=api" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
10.0.0.15 - - [15/Jul/2025:10:30:16 +0700] "POST /api/v1/orders HTTP/1.1" 201 523 "https://example.com/cart" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
172.16.0.5 - - [15/Jul/2025:10:30:17 +0700] "GET /dashboard HTTP/1.1" 200 15678 "https://example.com/login" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
203.0.113.10 - - [15/Jul/2025:10:30:18 +0700] "GET /api/v1/products?page=2 HTTP/1.1" 200 8934 "https://example.com/search" "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1"
198.51.100.42 - - [15/Jul/2025:10:30:19 +0700] "GET /nonexistent HTTP/1.1" 404 345 "-" "curl/7.68.0"
192.0.2.1 - - [15/Jul/2025:10:30:20 +0700] "PUT /api/v1/users/123 HTTP/1.1" 200 456 "https://example.com/profile" "Mozilla/5.0 (Android 11; Mobile; rv:89.0) Gecko/89.0 Firefox/89.0"
10.1.1.50 - - [15/Jul/2025:10:30:21 +0700] "GET /admin/dashboard HTTP/1.1" 403 234 "https://example.com/admin" "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0"
172.20.0.100 - - [15/Jul/2025:10:30:22 +0700] "POST /api/v1/login HTTP/1.1" 500 789 "https://example.com/login" "python-requests/2.25.1"
EOF

echo "Sample log entries added to: $LOG_FILE"
echo ""
echo "Generated entries:"
tail -8 "$LOG_FILE"
echo ""
echo "Total lines in log file: $(wc -l < "$LOG_FILE")"

# Validate format against the regex pattern from parsers.conf
echo ""
echo "Validating format against Fluent Bit parser regex..."
echo "Pattern: ^(?<remote_addr>[^ ]*) - (?<remote_user>[^ ]*) \[(?<time_local>[^\]]*)\] \"(?<request>[^\"]*)\" (?<status>[0-9]*) (?<body_bytes_sent>[0-9]*) \"(?<http_referer>[^\"]*)\" \"(?<http_user_agent>[^\"]*)\""

# Simple validation using grep with basic pattern
if tail -1 "$LOG_FILE" | grep -qE '^[0-9.]+ - - \[[^\]]+\] "[^"]+" [0-9]+ [0-9]+ "[^"]*" "[^"]*"$'; then
    echo "✓ Log format appears valid"
else
    echo "✗ Log format validation failed"
fi
