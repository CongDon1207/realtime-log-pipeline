# Scripts Usage Guide

This guide explains how to use the utility scripts in the realtime-log-pipeline project.

## Available Scripts

### 1. `generate-logs.sh`
Basic log generator that creates Nginx access log format entries.

**Usage:**
```bash
cd scripts
./generate-logs.sh
```

**Features:**
- Generates realistic Nginx access log entries
- Configurable interval (default: 1 second)
- Configurable duration (default: 1 hour)
- Outputs to `../data/access.log`
- Compatible with Fluent Bit parser configuration

### 2. `generate-logs-advanced.sh`
Advanced log generator with more configuration options.

**Usage:**
```bash
cd scripts
./generate-logs-advanced.sh [OPTIONS]
```

**Options:**
- `-f, --file FILE`: Output log file (default: ../data/access.log)
- `-i, --interval SECONDS`: Interval between log entries (default: 1)
- `-d, --duration SECONDS`: Total duration in seconds (default: 3600)
- `-b, --burst`: Enable burst mode (generates more traffic)
- `-c, --clear`: Clear existing log file before starting
- `-q, --quiet`: Quiet mode (less verbose output)
- `-h, --help`: Show help message

**Examples:**
```bash
# Run with defaults
./generate-logs-advanced.sh

# Custom file, 0.5s interval, 5min duration
./generate-logs-advanced.sh -f /tmp/test.log -i 0.5 -d 300

# Burst mode with cleared log
./generate-logs-advanced.sh --burst --clear

# Quiet mode for 1 minute
./generate-logs-advanced.sh -q -d 60
```

### 3. `test-log-format.sh`
Quick test script to generate sample log entries and validate format.

**Usage:**
```bash
cd scripts
./test-log-format.sh
```

**Features:**
- Generates 8 sample log entries
- Validates format against Fluent Bit parser regex
- Shows current log file statistics

### 4. `clean-logs.sh`
Utility to clean up log files.

**Usage:**
```bash
cd scripts
./clean-logs.sh [OPTIONS]
```

**Options:**
- `-f, --file FILE`: Log file to clean (default: ../data/access.log)
- `-b, --backup`: Create backup before cleaning
- `--force`: Skip confirmation prompt
- `-h, --help`: Show help message

**Examples:**
```bash
# Clean default log file with confirmation
./clean-logs.sh

# Clean with backup
./clean-logs.sh --backup

# Clean without confirmation
./clean-logs.sh --force

# Clean specific file with backup
./clean-logs.sh -f /tmp/test.log -b
```

### 5. `deploy-flink-job.sh`
Deploy Flink jobs for log processing (to be implemented).

### 6. `health-check.sh`
Check health status of all services (to be implemented).

## Log Format

All generated logs follow the Nginx access log format compatible with the Fluent Bit parser:

```
remote_addr - remote_user [time_local] "request" status body_bytes_sent "http_referer" "http_user_agent"
```

**Example:**
```
192.168.1.100 - - [15/Jul/2025:10:30:15 +0700] "GET /api/v1/users HTTP/1.1" 200 1254 "https://google.com" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
```

## Quick Start

1. **Generate test logs:**
   ```bash
   cd scripts
   ./test-log-format.sh
   ```

2. **Start continuous log generation:**
   ```bash
   cd scripts
   ./generate-logs-advanced.sh --clear -d 300  # Generate for 5 minutes
   ```

3. **Monitor the logs:**
   ```bash
   tail -f ../data/access.log
   ```

4. **Clean up when done:**
   ```bash
   cd scripts
   ./clean-logs.sh --backup
   ```

## File Permissions

Make sure all scripts are executable:

```bash
chmod +x scripts/*.sh
```

## Integration with Pipeline

These generated logs will be:
1. Read by Fluent Bit from `data/access.log`
2. Parsed using the regex parser in `compose/conf/fluent-bit/parsers.conf`
3. Sent to Pulsar topic `persistent://public/default/logs-nginx-access`
4. Processed by Flink for real-time analytics
5. Stored in MinIO/Iceberg for historical analysis
6. Visualized in Grafana/Superset dashboards
