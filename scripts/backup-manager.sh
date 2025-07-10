#!/bin/bash

# Backup Manager Script for VPS
# Handles intelligent backups with space management

BACKUP_ROOT="/home/rmlve/backups"
PROJECT_DIR="/home/rmlve/cch"
MAX_BACKUPS=5  # Keep only last 5 backups of each type
GITHUB_BACKUP_REPO="cchub62/vps-backups"  # Update with your repo

# Create backup directories
mkdir -p "$BACKUP_ROOT"/{daily,weekly,configs}

# Function to create backup
create_backup() {
    local backup_type="$1"
    local source_dir="$2"
    local backup_name="$3"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_ROOT}/${backup_type}/${backup_name}-${timestamp}.tar.gz"
    
    echo "Creating $backup_type backup: $backup_name"
    
    # Exclude unnecessary files
    tar -czf "$backup_file" \
        --exclude="node_modules" \
        --exclude="*.log" \
        --exclude=".git" \
        --exclude="dist" \
        --exclude=".cache" \
        --exclude="*.tar.gz" \
        -C "$(dirname "$source_dir")" \
        "$(basename "$source_dir")"
    
    if [ $? -eq 0 ]; then
        echo "Backup created: $backup_file"
        echo "Size: $(du -h "$backup_file" | cut -f1)"
        
        # Upload to GitHub if configured
        if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_BACKUP_REPO" ]; then
            upload_to_github "$backup_file" "$backup_type"
        fi
        
        return 0
    else
        echo "Backup failed for $backup_name"
        return 1
    fi
}

# Function to clean old backups
clean_old_backups() {
    local backup_type="$1"
    local backup_pattern="$2"
    
    echo "Cleaning old $backup_type backups (keeping last $MAX_BACKUPS)"
    
    cd "$BACKUP_ROOT/$backup_type"
    ls -t | grep "$backup_pattern" | tail -n +$((MAX_BACKUPS + 1)) | while read old_backup; do
        echo "Removing old backup: $old_backup"
        rm -f "$old_backup"
    done
}

# Function to upload to GitHub
upload_to_github() {
    local backup_file="$1"
    local backup_type="$2"
    
    if [ -f ~/gh_2.40.1_linux_amd64/bin/gh ]; then
        echo "Uploading to GitHub..."
        # This is a placeholder - actual implementation would use GitHub releases or LFS
        echo "GitHub upload not implemented yet"
    fi
}

# Function to backup configs
backup_configs() {
    echo "Backing up configuration files..."
    
    # Backup nginx configs
    if [ -d "/etc/nginx" ]; then
        sudo tar -czf "$BACKUP_ROOT/configs/nginx-$(date +%Y%m%d).tar.gz" /etc/nginx 2>/dev/null
    fi
    
    # Backup PM2 configs
    if [ -d ~/.pm2 ]; then
        tar -czf "$BACKUP_ROOT/configs/pm2-$(date +%Y%m%d).tar.gz" ~/.pm2
    fi
    
    # Backup environment files
    cp ~/.env* "$BACKUP_ROOT/configs/" 2>/dev/null
    cp ~/.bashrc "$BACKUP_ROOT/configs/bashrc-$(date +%Y%m%d)" 2>/dev/null
}

# Main backup routine
echo "=== VPS Backup Manager ==="
echo "Started at: $(date)"

# Check disk space
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "WARNING: Disk usage is at ${DISK_USAGE}%"
    echo "Running emergency cleanup..."
    
    # Clean all old backups
    find "$BACKUP_ROOT" -name "*.tar.gz" -mtime +3 -delete
    
    # Clean package manager cache
    sudo apt-get clean 2>/dev/null || echo "Skipping apt cleanup"
fi

# Perform backups based on day
DAY_OF_WEEK=$(date +%u)
DAY_OF_MONTH=$(date +%d)

# Daily backup (small, essential files only)
create_backup "daily" "$PROJECT_DIR" "cch-daily"
clean_old_backups "daily" "cch-daily"

# Weekly backup (full project) - Sundays
if [ $DAY_OF_WEEK -eq 7 ]; then
    create_backup "weekly" "$PROJECT_DIR" "cch-weekly-full"
    clean_old_backups "weekly" "cch-weekly"
fi

# Monthly config backup - 1st of month
if [ $DAY_OF_MONTH -eq 1 ]; then
    backup_configs
fi

# Report disk usage
echo ""
echo "=== Disk Usage Report ==="
df -h /
echo ""
echo "=== Backup Directory Sizes ==="
du -sh "$BACKUP_ROOT"/*

echo ""
echo "Backup completed at: $(date)"