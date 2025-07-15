#!/bin/bash

# Script to clean up log files
# Usage: ./clean-logs.sh [OPTIONS]

LOG_FILE="../data/access.log"
BACKUP=false
FORCE=false

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -f, --file FILE    Log file to clean (default: ../data/access.log)
    -b, --backup       Create backup before cleaning
    --force            Skip confirmation prompt
    -h, --help         Show this help message

Examples:
    $0                        # Clean default log file with confirmation
    $0 --backup              # Clean with backup
    $0 --force               # Clean without confirmation
    $0 -f /tmp/test.log -b   # Clean specific file with backup

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            LOG_FILE="$2"
            shift 2
            ;;
        -b|--backup)
            BACKUP=true
            shift
            ;;
        --force)
            FORCE=true
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

# Check if file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "Log file does not exist: $LOG_FILE"
    exit 1
fi

# Show current file info
echo "Log file: $LOG_FILE"
echo "Current size: $(du -h "$LOG_FILE" | cut -f1)"
echo "Current lines: $(wc -l < "$LOG_FILE")"

# Confirmation
if [ "$FORCE" != true ]; then
    echo ""
    read -p "Are you sure you want to clean this log file? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

# Create backup if requested
if [ "$BACKUP" = true ]; then
    backup_file="${LOG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$LOG_FILE" "$backup_file"
    echo "Backup created: $backup_file"
fi

# Clean the file
> "$LOG_FILE"
echo "Log file cleaned: $LOG_FILE"
