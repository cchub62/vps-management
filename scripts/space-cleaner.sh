#!/bin/bash

# Space Cleaner Script for VPS
# Automatically frees up disk space

echo "=== VPS Space Cleaner ==="
echo "Started at: $(date)"

# Function to report space saved
report_space() {
    local before=$1
    local after=$2
    local saved=$((before - after))
    local saved_mb=$((saved / 1024))
    echo "Space saved: ${saved_mb}MB"
}

# Get initial disk usage
INITIAL_USAGE=$(df / | awk 'NR==2 {print $3}')

# 1. Clean old backup files
echo "1. Cleaning old backup files..."
find ~/backups -name "*.tar.gz" -mtime +7 -delete
find ~ -name "cch-backup-*.tar.gz" -mtime +7 -delete

# 2. Clean node_modules in old directories
echo "2. Cleaning orphaned node_modules..."
find ~ -name "node_modules" -type d -not -path "*/cch/node_modules" | while read dir; do
    echo "Removing: $dir"
    rm -rf "$dir"
done

# 3. Clean package manager caches
echo "3. Cleaning package caches..."
npm cache clean --force 2>/dev/null

# 4. Clean log files
echo "4. Cleaning old log files..."
find ~/logs -name "*.log" -mtime +7 -delete
find ~ -name "*.log" -size +50M -exec truncate -s 0 {} \;

# 5. Remove old PM2 logs
echo "5. Cleaning PM2 logs..."
~/.pm2/pm2 flush 2>/dev/null || echo "PM2 not running"

# 6. Clean temporary files
echo "6. Cleaning temporary files..."
find /tmp -type f -atime +7 -delete 2>/dev/null
rm -rf ~/.cache/puppeteer 2>/dev/null

# 7. Remove duplicate backup files
echo "7. Removing duplicate backups..."
# Keep only the latest backup of each type
cd ~ && ls -t cch-backup-*.tar.gz 2>/dev/null | awk '!seen[$1]++ {print} seen[$1]++ {print "rm -f", $0}' | sh

# 8. Clean build artifacts
echo "8. Cleaning build artifacts..."
find ~/cch -name "dist" -type d | while read dir; do
    if [ "$dir" != "/home/rmlve/cch/dist" ]; then
        echo "Removing old dist: $dir"
        rm -rf "$dir"
    fi
done

# 9. Remove old GitHub CLI downloads
echo "9. Cleaning old downloads..."
find ~ -name "gh_*.tar.gz" -delete
find ~ -name "gh_*_linux_amd64" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null

# 10. System journal cleanup (if sudo available)
echo "10. Cleaning system journals..."
sudo journalctl --vacuum-size=100M 2>/dev/null || echo "Skipping journal cleanup"

# Get final disk usage
FINAL_USAGE=$(df / | awk 'NR==2 {print $3}')

echo ""
echo "=== Cleanup Summary ==="
report_space $INITIAL_USAGE $FINAL_USAGE
echo ""
echo "=== Current Disk Usage ==="
df -h /
echo ""
echo "=== Largest Directories ==="
du -sh ~/* | sort -hr | head -10

echo ""
echo "Cleanup completed at: $(date)"