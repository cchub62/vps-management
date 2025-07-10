# VPS Management Tools

This repository contains scripts and configurations for managing your VPS efficiently.

## Directory Structure

```
vps-management/
├── scripts/          # Automation scripts
├── configs/          # Configuration files
├── docs/            # Documentation
├── backups/         # Backup storage
└── monitoring/      # Monitoring configs
```

## Scripts

### 1. Log Rotation (`scripts/log-rotation.sh`)
- Automatically rotates logs when they exceed 100MB
- Compresses old logs to save space
- Cleans up logs older than 7 days
- Handles PM2, application, and system logs

### 2. Backup Manager (`scripts/backup-manager.sh`)
- Creates daily and weekly backups
- Excludes unnecessary files (node_modules, logs, etc.)
- Maintains only the last 5 backups of each type
- Monitors disk space and triggers cleanup if needed

### 3. Space Cleaner (`scripts/space-cleaner.sh`)
- Removes old backup files
- Cleans orphaned node_modules
- Clears package manager caches
- Truncates large log files
- Removes temporary files and build artifacts

### 4. Health Check (`scripts/health-check.sh`)
- Monitors disk usage, memory, and CPU load
- Checks service status (PM2, Nginx)
- Scans logs for errors
- Triggers automatic cleanup when thresholds are exceeded

## Setup Cron Jobs

Add these to your crontab (`crontab -e`):

```bash
# Log rotation - daily at 2 AM
0 2 * * * /home/rmlve/vps-management/scripts/log-rotation.sh >> /home/rmlve/logs/cron.log 2>&1

# Backup - daily at 3 AM
0 3 * * * /home/rmlve/vps-management/scripts/backup-manager.sh >> /home/rmlve/logs/backup.log 2>&1

# Space cleanup - weekly on Sundays at 4 AM
0 4 * * 0 /home/rmlve/vps-management/scripts/space-cleaner.sh >> /home/rmlve/logs/cleanup.log 2>&1

# Health check - every hour
0 * * * * /home/rmlve/vps-management/scripts/health-check.sh

# Emergency space cleanup - when disk usage is critical
*/30 * * * * [ $(df / | awk 'NR==2 {print int($5)}') -gt 85 ] && /home/rmlve/vps-management/scripts/space-cleaner.sh
```

## GitHub Integration

1. Create a GitHub repository for your VPS management tools
2. Set up GitHub token as environment variable:
   ```bash
   export GITHUB_TOKEN=your_token_here
   ```

3. Initialize the repository:
   ```bash
   cd ~/vps-management
   git init
   git add .
   git commit -m "Initial VPS management setup"
   git branch -M main
   git remote add origin https://github.com/cchub62/vps-management.git
   git push -u origin main
   ```

## Usage in Other Projects

To use these scripts in other projects, you can:

1. Clone specific scripts:
   ```bash
   wget https://raw.githubusercontent.com/cchub62/vps-management/main/scripts/log-rotation.sh
   ```

2. Use as a submodule:
   ```bash
   git submodule add https://github.com/cchub62/vps-management.git vps-tools
   ```

3. Create aliases in `.bashrc`:
   ```bash
   alias vps-clean='~/vps-management/scripts/space-cleaner.sh'
   alias vps-backup='~/vps-management/scripts/backup-manager.sh'
   alias vps-health='~/vps-management/scripts/health-check.sh'
   ```

## Monitoring

The health check script logs to `/home/rmlve/logs/health-check.log`. You can monitor this file for issues:

```bash
tail -f ~/logs/health-check.log
```

## Customization

Edit the scripts to adjust:
- Disk usage thresholds
- Backup retention policies
- Log rotation sizes
- Memory usage alerts

## Troubleshooting

1. **High Disk Usage**: Run `~/vps-management/scripts/space-cleaner.sh`
2. **Service Issues**: Check PM2 with `pm2 list` and `pm2 logs`
3. **Backup Failures**: Check `/home/rmlve/logs/backup.log`

## License

MIT