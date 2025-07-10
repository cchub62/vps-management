#!/bin/bash

# Health Check Script for VPS
# Monitors system health and sends alerts

ALERT_DISK_USAGE=80
ALERT_MEMORY_USAGE=90
ALERT_LOAD_AVERAGE=2.0
LOG_FILE="/home/rmlve/logs/health-check.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check disk usage
check_disk() {
    local usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    log_message "Disk usage: ${usage}%"
    
    if [ $usage -gt $ALERT_DISK_USAGE ]; then
        log_message "WARNING: High disk usage detected!"
        # Trigger automatic cleanup
        ~/vps-management/scripts/space-cleaner.sh
        return 1
    fi
    return 0
}

# Function to check memory
check_memory() {
    local total=$(free -m | awk 'NR==2{print $2}')
    local used=$(free -m | awk 'NR==2{print $3}')
    local usage=$((used * 100 / total))
    
    log_message "Memory usage: ${usage}% (${used}MB/${total}MB)"
    
    if [ $usage -gt $ALERT_MEMORY_USAGE ]; then
        log_message "WARNING: High memory usage detected!"
        # List top memory consumers
        ps aux --sort=-%mem | head -5 >> "$LOG_FILE"
        return 1
    fi
    return 0
}

# Function to check load average
check_load() {
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cores=$(nproc)
    
    log_message "Load average: $load (${cores} cores)"
    
    if (( $(echo "$load > $ALERT_LOAD_AVERAGE" | bc -l) )); then
        log_message "WARNING: High load average detected!"
        return 1
    fi
    return 0
}

# Function to check services
check_services() {
    # Check PM2 processes
    if command -v pm2 &> /dev/null; then
        local pm2_status=$(pm2 list | grep -E "online|stopped|errored")
        if echo "$pm2_status" | grep -q "stopped\|errored"; then
            log_message "WARNING: PM2 processes not running properly"
            pm2 list >> "$LOG_FILE"
            # Attempt to restart
            pm2 restart all
        else
            log_message "PM2 processes: OK"
        fi
    fi
    
    # Check nginx
    if systemctl is-active --quiet nginx; then
        log_message "Nginx: OK"
    else
        log_message "WARNING: Nginx is not running"
    fi
}

# Function to check logs for errors
check_logs() {
    local error_count=$(find ~/logs -name "*.log" -mtime -1 -exec grep -i "error\|critical\|fatal" {} \; | wc -l)
    
    if [ $error_count -gt 50 ]; then
        log_message "WARNING: High error count in logs: $error_count errors in last 24h"
    else
        log_message "Log errors: $error_count in last 24h"
    fi
}

# Main health check
log_message "=== Starting Health Check ==="

# Run all checks
check_disk
disk_status=$?

check_memory
memory_status=$?

check_load
load_status=$?

check_services
check_logs

# Summary
if [ $disk_status -eq 0 ] && [ $memory_status -eq 0 ] && [ $load_status -eq 0 ]; then
    log_message "System health: OK"
else
    log_message "System health: ISSUES DETECTED"
fi

log_message "=== Health Check Completed ==="
echo ""