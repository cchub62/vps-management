#!/bin/bash

# Log Rotation Script for VPS
# Manages log files to prevent disk space issues

LOG_DIR="/home/rmlve/logs"
BACKUP_LOG_DIR="/home/rmlve/backups/logs"
MAX_LOG_SIZE="100M"
MAX_LOG_AGE=7  # days
COMPRESSION="gzip"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_LOG_DIR"

# Function to rotate a single log file
rotate_log() {
    local log_file="$1"
    local base_name=$(basename "$log_file")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    if [ -f "$log_file" ]; then
        # Check file size
        size=$(stat -c%s "$log_file" 2>/dev/null || stat -f%z "$log_file" 2>/dev/null)
        size_mb=$((size / 1048576))
        
        if [ $size_mb -gt 100 ]; then
            echo "Rotating $log_file (${size_mb}MB)"
            
            # Compress and move to backup
            gzip -c "$log_file" > "$BACKUP_LOG_DIR/${base_name}.${timestamp}.gz"
            
            # Clear the original log file
            > "$log_file"
            
            echo "Rotated $log_file successfully"
        fi
    fi
}

# Rotate application logs
echo "Starting log rotation - $(date)"

# Rotate PM2 logs
rotate_log "$LOG_DIR/pm2-out.log"
rotate_log "$LOG_DIR/pm2-error.log"
rotate_log "$LOG_DIR/pm2-combined.log"

# Rotate backup logs
rotate_log "$LOG_DIR/backup.log"

# Rotate system logs (requires sudo)
if [ -w "/var/log" ]; then
    find /var/log -name "*.log" -size +${MAX_LOG_SIZE} -type f | while read log; do
        rotate_log "$log"
    done
fi

# Clean up old compressed logs
echo "Cleaning up old logs older than $MAX_LOG_AGE days"
find "$BACKUP_LOG_DIR" -name "*.gz" -mtime +$MAX_LOG_AGE -delete

# Clean up journal logs (systemd)
if command -v journalctl &> /dev/null; then
    echo "Cleaning systemd journal logs older than $MAX_LOG_AGE days"
    sudo journalctl --vacuum-time=${MAX_LOG_AGE}d 2>/dev/null || echo "Skipping journal cleanup (requires sudo)"
fi

echo "Log rotation completed - $(date)"