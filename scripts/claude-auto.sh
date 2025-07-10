#!/bin/bash

# Claude Auto Launcher with Context Loading
# Automatically loads context when Claude starts

CONTEXT_MANAGER="$HOME/vps-management/scripts/claude-context-manager.sh"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
CONTEXT_DIR="$HOME/.claude/context"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Claude Auto Launcher ===${NC}"
echo ""

# 1. Load and display context summary
echo -e "${GREEN}Loading session context...${NC}"
if [ -f "$CONTEXT_DIR/summary.md" ]; then
    echo ""
    cat "$CONTEXT_DIR/summary.md"
    echo ""
else
    # Generate summary if it doesn't exist
    $CONTEXT_MANAGER summary
fi

# 2. Log session start
$CONTEXT_MANAGER log "SESSION_START" "Claude session initiated"

# 3. Check system status
echo -e "${YELLOW}Current System Status:${NC}"
df -h / | grep -E "Filesystem|/"
echo ""
free -h | grep -E "Mem:|total"
echo ""

# 4. Check for any alerts
DISK_USAGE=$(df -h / | awk 'NR==2 {print int($5)}')
if [ $DISK_USAGE -gt 80 ]; then
    echo -e "${YELLOW}⚠️  WARNING: High disk usage detected (${DISK_USAGE}%)${NC}"
    echo "Run 'vps-clean' to free up space"
    echo ""
fi

# 5. Update CLAUDE.md with current context
cat > "$CLAUDE_MD" << 'EOF'
## System Administration
- Always use sudo for system commands and any permission errors. Use sudo for any command that may produce an eperm error

## Current Context
This system has automated VPS management tools installed:
- **Scripts Location**: ~/vps-management/scripts/
- **GitHub Repo**: https://github.com/cchub62/vps-management
- **Key Commands**: vps-clean, vps-backup, vps-health, vps-status

## Active Projects
1. **VPS Management Tools** - Automated scripts for system maintenance
2. **Church Care Hub (CCH)** - Main application at ~/cch

## Important Reminders
- Check disk usage before creating large files
- Use the automated scripts for maintenance tasks
- All backups are managed automatically
- Logs are rotated daily at 2 AM
- Context is saved between sessions

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.
EOF

# 6. Save initial context
$CONTEXT_MANAGER save >/dev/null 2>&1

# 7. Set up auto-save on exit
trap '$CONTEXT_MANAGER save; $CONTEXT_MANAGER log "SESSION_END" "Claude session terminated"' EXIT

# 8. Launch Claude or provide instructions
CLAUDE_BIN="/home/rmlve/.npm-global/bin/claude"

if [ -x "$CLAUDE_BIN" ]; then
    echo -e "${GREEN}Launching Claude with context loaded...${NC}"
    echo ""
    # Launch Claude with dangerous permissions flag
    exec $CLAUDE_BIN --dangerously-skip-permissions "$@"
else
    echo -e "${GREEN}Context loaded successfully!${NC}"
    echo ""
    echo "Claude binary not found at: $CLAUDE_BIN"
    echo "Please update the path in this script"
fi