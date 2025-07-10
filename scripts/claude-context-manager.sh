#!/bin/bash

# Claude Context Manager
# Automatically saves and loads context between Claude sessions

CONTEXT_DIR="$HOME/.claude/context"
CONTEXT_FILE="$CONTEXT_DIR/session-context.json"
ACTIVITY_LOG="$CONTEXT_DIR/activity.log"
SUMMARY_FILE="$CONTEXT_DIR/summary.md"
MAX_CONTEXT_SIZE=50000  # Max characters to keep in context

# Create directories if they don't exist
mkdir -p "$CONTEXT_DIR"

# Function to log activity
log_activity() {
    local action="$1"
    local details="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $action: $details" >> "$ACTIVITY_LOG"
}

# Function to save current session context
save_context() {
    log_activity "SAVE_CONTEXT" "Saving current session context"
    
    # Create context JSON
    cat > "$CONTEXT_FILE" << EOF
{
    "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "system_info": {
        "hostname": "$(hostname)",
        "user": "$USER",
        "working_directory": "$(pwd)",
        "disk_usage": "$(df -h / | awk 'NR==2 {print $5}')",
        "memory_usage": "$(free -h | awk 'NR==2 {print $3"/"$2}')"
    },
    "current_projects": {
        "vps_management": {
            "path": "$HOME/vps-management",
            "github": "https://github.com/cchub62/vps-management",
            "description": "VPS management tools with automated scripts"
        },
        "cch": {
            "path": "$HOME/cch",
            "description": "Church Care Hub application",
            "pm2_processes": $(pm2 jlist 2>/dev/null || echo '[]')
        }
    },
    "recent_activities": [
EOF
    
    # Add recent activities (last 20 entries)
    tail -20 "$ACTIVITY_LOG" 2>/dev/null | while IFS= read -r line; do
        echo "        \"$line\","
    done | sed '$ s/,$//' >> "$CONTEXT_FILE"
    
    cat >> "$CONTEXT_FILE" << EOF
    ],
    "important_paths": {
        "logs": "$HOME/logs",
        "backups": "$HOME/backups",
        "scripts": "$HOME/vps-management/scripts",
        "cch_app": "$HOME/cch"
    },
    "github_token": {
        "status": "configured",
        "user": "cchub62",
        "note": "Token stored in gh config"
    },
    "system_services": {
        "pm2": "$(pm2 list 2>/dev/null | grep -c "online" || echo "0") processes online",
        "nginx": "$(systemctl is-active nginx 2>/dev/null || echo "unknown")",
        "disk_space_alerts": "$(df -h / | awk 'NR==2 {print int($5)}' | awk '{if($1>80) print "WARNING"; else print "OK"}')"
    }
}
EOF
    
    log_activity "SAVE_CONTEXT" "Context saved to $CONTEXT_FILE"
}

# Function to load context
load_context() {
    if [ -f "$CONTEXT_FILE" ]; then
        log_activity "LOAD_CONTEXT" "Loading saved context"
        cat "$CONTEXT_FILE"
        return 0
    else
        log_activity "LOAD_CONTEXT" "No saved context found"
        return 1
    fi
}

# Function to update summary
update_summary() {
    log_activity "UPDATE_SUMMARY" "Generating context summary"
    
    cat > "$SUMMARY_FILE" << EOF
# Claude Session Context Summary

Last Updated: $(date)

## System Status
- Disk Usage: $(df -h / | awk 'NR==2 {print $5}')
- Memory: $(free -h | awk 'NR==2 {print $3"/"$2}')
- Load: $(uptime | awk -F'load average:' '{print $2}')

## Active Projects

### VPS Management Tools
- Location: ~/vps-management
- GitHub: https://github.com/cchub62/vps-management
- Scripts: log-rotation, backup-manager, space-cleaner, health-check

### Church Care Hub (CCH)
- Location: ~/cch
- PM2 Status: $(pm2 list 2>/dev/null | grep -c "online" || echo "0") processes online
- Port: 5001 (backend), 5173 (frontend)

## Recent Activities (Last 10)
$(tail -10 "$ACTIVITY_LOG" 2>/dev/null || echo "No recent activities")

## Key Commands
- \`vps-clean\` - Free up disk space
- \`vps-backup\` - Create manual backup
- \`vps-health\` - Check system health
- \`pm2 list\` - Check application status

## Scheduled Tasks (Cron)
- 2:00 AM - Log rotation
- 3:00 AM - Daily backup
- 4:00 AM Sunday - Weekly cleanup
- Every hour - Health check
- Every 30 min - Emergency cleanup (if disk >85%)

## Important Notes
- GitHub token configured for user: cchub62
- Backup retention: 5 backups per type
- Log retention: 7 days
- System monitors disk usage and triggers cleanup at 80%
EOF
    
    log_activity "UPDATE_SUMMARY" "Summary updated at $SUMMARY_FILE"
}

# Function to track command execution
track_command() {
    local command="$1"
    log_activity "COMMAND" "$command"
}

# Function to track file changes
track_file_change() {
    local file="$1"
    local action="$2"  # created, modified, deleted
    log_activity "FILE_$action" "$file"
}

# Main execution based on arguments
case "$1" in
    save)
        save_context
        update_summary
        echo "Context saved successfully"
        ;;
    load)
        load_context
        ;;
    summary)
        if [ -f "$SUMMARY_FILE" ]; then
            cat "$SUMMARY_FILE"
        else
            update_summary
            cat "$SUMMARY_FILE"
        fi
        ;;
    log)
        shift
        log_activity "$@"
        ;;
    track-cmd)
        shift
        track_command "$@"
        ;;
    track-file)
        shift
        track_file_change "$@"
        ;;
    show-log)
        tail -50 "$ACTIVITY_LOG"
        ;;
    *)
        echo "Claude Context Manager"
        echo "Usage: $0 {save|load|summary|log|track-cmd|track-file|show-log}"
        echo ""
        echo "  save       - Save current context"
        echo "  load       - Load saved context (returns JSON)"
        echo "  summary    - Show human-readable summary"
        echo "  log        - Log an activity"
        echo "  track-cmd  - Track a command execution"
        echo "  track-file - Track a file change"
        echo "  show-log   - Show recent activity log"
        ;;
esac