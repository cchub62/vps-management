#!/bin/bash

# Activity Tracker for Claude Sessions
# Monitors and logs all activities during Claude sessions

CONTEXT_MANAGER="$HOME/vps-management/scripts/claude-context-manager.sh"
WATCH_DIRS="$HOME/cch $HOME/vps-management"
ACTIVITY_FIFO="/tmp/claude-activity-fifo"

# Create named pipe for activity tracking
[ ! -p "$ACTIVITY_FIFO" ] && mkfifo "$ACTIVITY_FIFO"

# Function to monitor file changes
monitor_files() {
    if command -v inotifywait &> /dev/null; then
        inotifywait -mr --format '%w%f %e' \
            -e create -e modify -e delete -e moved_to -e moved_from \
            $WATCH_DIRS 2>/dev/null | while read file event; do
            case $event in
                CREATE*)
                    $CONTEXT_MANAGER track-file "$file" "created"
                    ;;
                MODIFY*)
                    $CONTEXT_MANAGER track-file "$file" "modified"
                    ;;
                DELETE*)
                    $CONTEXT_MANAGER track-file "$file" "deleted"
                    ;;
                MOVED*)
                    $CONTEXT_MANAGER track-file "$file" "moved"
                    ;;
            esac
        done
    else
        echo "inotifywait not installed. File monitoring disabled."
        echo "Install with: sudo apt-get install inotify-tools"
    fi
}

# Function to monitor commands (bash history)
monitor_commands() {
    # Get initial history position
    local last_history=$(history 1 | awk '{print $1}')
    
    while true; do
        sleep 2
        local current_history=$(history 1 | awk '{print $1}')
        
        if [ "$current_history" != "$last_history" ]; then
            # New command executed
            local cmd=$(history 1 | sed 's/^[ ]*[0-9]*[ ]*//')
            $CONTEXT_MANAGER track-cmd "$cmd"
            last_history=$current_history
        fi
    done
}

# Function to periodic context save
periodic_save() {
    while true; do
        sleep 300  # Save every 5 minutes
        $CONTEXT_MANAGER save >/dev/null 2>&1
        $CONTEXT_MANAGER log "AUTO_SAVE" "Periodic context save"
    done
}

# Main execution
case "$1" in
    start)
        echo "Starting Claude activity tracker..."
        
        # Start monitors in background
        monitor_files &
        MONITOR_FILES_PID=$!
        
        monitor_commands &
        MONITOR_CMD_PID=$!
        
        periodic_save &
        PERIODIC_SAVE_PID=$!
        
        # Save PIDs
        echo "$MONITOR_FILES_PID $MONITOR_CMD_PID $PERIODIC_SAVE_PID" > /tmp/claude-tracker.pids
        
        echo "Activity tracker started (PIDs: $MONITOR_FILES_PID $MONITOR_CMD_PID $PERIODIC_SAVE_PID)"
        $CONTEXT_MANAGER log "TRACKER_START" "Activity tracking initiated"
        ;;
        
    stop)
        echo "Stopping Claude activity tracker..."
        
        if [ -f /tmp/claude-tracker.pids ]; then
            cat /tmp/claude-tracker.pids | xargs kill 2>/dev/null
            rm /tmp/claude-tracker.pids
            echo "Activity tracker stopped"
            $CONTEXT_MANAGER log "TRACKER_STOP" "Activity tracking stopped"
        else
            echo "No tracker running"
        fi
        ;;
        
    status)
        if [ -f /tmp/claude-tracker.pids ]; then
            echo "Activity tracker is running"
            echo "PIDs: $(cat /tmp/claude-tracker.pids)"
            ps aux | grep -E "$(cat /tmp/claude-tracker.pids | tr ' ' '|')" | grep -v grep
        else
            echo "Activity tracker is not running"
        fi
        ;;
        
    *)
        echo "Usage: $0 {start|stop|status}"
        ;;
esac