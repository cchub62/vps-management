#!/bin/bash

# VPS Management Setup Script
# Run this to configure your VPS management tools

echo "=== VPS Management Setup ==="
echo ""

# 1. Add cron jobs
echo "1. Setting up cron jobs..."
(crontab -l 2>/dev/null; cat ~/vps-management/configs/crontab-setup.txt) | crontab -
echo "   Cron jobs installed"

# 2. Create necessary directories
echo "2. Creating directories..."
mkdir -p ~/logs
mkdir -p ~/backups/{daily,weekly,configs}
echo "   Directories created"

# 3. Set up aliases
echo "3. Adding convenient aliases..."
cat >> ~/.bashrc << 'EOF'

# VPS Management Aliases
alias vps-clean='~/vps-management/scripts/space-cleaner.sh'
alias vps-backup='~/vps-management/scripts/backup-manager.sh'
alias vps-health='~/vps-management/scripts/health-check.sh'
alias vps-logs='~/vps-management/scripts/log-rotation.sh'
alias vps-status='df -h / && echo && free -h && echo && pm2 list'
EOF
echo "   Aliases added to .bashrc"

# 4. Run initial health check
echo "4. Running initial health check..."
~/vps-management/scripts/health-check.sh

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Available commands:"
echo "  vps-clean   - Free up disk space"
echo "  vps-backup  - Create manual backup"
echo "  vps-health  - Check system health"
echo "  vps-logs    - Rotate logs manually"
echo "  vps-status  - Quick system status"
echo ""
echo "Automated tasks will run on schedule via cron."
echo "Check logs in ~/logs/ for details."
echo ""
echo "GitHub repository: https://github.com/cchub62/vps-management"