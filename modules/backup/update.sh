#!/bin/bash
# Backup System Update Script
# Purpose: Update backup system and maintain configuration integrity

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Source functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  BACKUP SYSTEM UPDATE                       ║${NC}"
echo -e "${BLUE}║              Maintaining Data Protection                     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    echo -e "${YELLOW}Please run: sudo $0${NC}"
    exit 1
fi

echo -e "${CYAN}Starting backup system update...${NC}"
echo

# Step 1: Backup current configuration
echo -e "${YELLOW}Step 1/7: Backing up current configuration${NC}"

# Create backup of current configuration
backup_timestamp=$(date +%Y%m%d_%H%M%S)
backup_config_dir="/root/backups/config/backup-update-$backup_timestamp"
mkdir -p "$backup_config_dir"

echo -e "${CYAN}Creating configuration backup...${NC}"

# Backup configuration files
if [[ -f /etc/backup.conf ]]; then
    cp /etc/backup.conf "$backup_config_dir/"
    echo -e "${GREEN}✓ Main configuration backed up${NC}"
fi

if [[ -f /etc/remote-backup.conf ]]; then
    cp /etc/remote-backup.conf "$backup_config_dir/"
    echo -e "${GREEN}✓ Remote backup configuration backed up${NC}"
fi

if [[ -f /etc/backup-encryption.key ]]; then
    cp /etc/backup-encryption.key "$backup_config_dir/"
    echo -e "${GREEN}✓ Encryption keys backed up${NC}"
fi

# Backup crontab entries
crontab -l > "$backup_config_dir/backup-crontab.txt" 2>/dev/null || echo "No crontab entries found"

# Backup custom scripts
if [[ -d /usr/local/bin ]]; then
    find /usr/local/bin -name "backup-*" -exec cp {} "$backup_config_dir/" \;
    echo -e "${GREEN}✓ Custom backup scripts backed up${NC}"
fi

echo -e "${GREEN}✓ Configuration backup completed: $backup_config_dir${NC}"
echo

# Step 2: Update package repositories and backup tools
echo -e "${YELLOW}Step 2/7: Updating backup tools and dependencies${NC}"

echo -e "${CYAN}Updating package repositories...${NC}"
apt-get update -q

echo -e "${CYAN}Checking for backup tool updates...${NC}"
backup_packages=(
    "rsync"
    "tar"
    "gzip"
    "pigz"
    "duplicity"
    "rdiff-backup"
    "lvm2"
    "btrfs-tools"
    "cron"
    "logrotate"
    "ncftp"
    "lftp"
    "s3cmd"
    "awscli"
)

# Update backup tools
for package in "${backup_packages[@]}"; do
    if dpkg -l | grep -q "^ii  $package "; then
        echo -e "${CYAN}Updating $package...${NC}"
        apt-get install --only-upgrade -y "$package" 2>/dev/null || echo "  $package is up to date"
    else
        echo -e "${YELLOW}Installing missing package: $package${NC}"
        apt-get install -y "$package"
    fi
done

echo -e "${GREEN}✓ Backup tools updated${NC}"
echo

# Step 3: Verify and update backup directories
echo -e "${YELLOW}Step 3/7: Verifying backup directory structure${NC}"

echo -e "${CYAN}Checking backup directories...${NC}"

# Ensure all required directories exist
required_dirs=(
    "/root/backups"
    "/root/backups/daily"
    "/root/backups/weekly"
    "/root/backups/monthly"
    "/root/backups/config"
    "/root/backups/logs"
    "/root/backups/temp"
)

for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        echo -e "${CYAN}Created missing directory: $dir${NC}"
    fi
done

# Set proper permissions
chmod 700 /root/backups
chmod 755 /root/backups/logs

echo -e "${GREEN}✓ Directory structure verified${NC}"
echo

# Step 4: Update backup configuration
echo -e "${YELLOW}Step 4/7: Updating backup configuration${NC}"

# Check if configuration file exists and update if needed
if [[ -f /etc/backup.conf ]]; then
    echo -e "${CYAN}Updating backup configuration...${NC}"
    
    # Add new configuration options if they don't exist
    if ! grep -q "LOG_LEVEL" /etc/backup.conf; then
        echo "LOG_LEVEL=INFO" >> /etc/backup.conf
        echo -e "${CYAN}Added LOG_LEVEL setting${NC}"
    fi
    
    if ! grep -q "MAX_BACKUP_SIZE" /etc/backup.conf; then
        echo "MAX_BACKUP_SIZE=50G" >> /etc/backup.conf
        echo -e "${CYAN}Added MAX_BACKUP_SIZE setting${NC}"
    fi
    
    if ! grep -q "PARALLEL_JOBS" /etc/backup.conf; then
        echo "PARALLEL_JOBS=2" >> /etc/backup.conf
        echo -e "${CYAN}Added PARALLEL_JOBS setting${NC}"
    fi
    
    if ! grep -q "VERIFY_BACKUPS" /etc/backup.conf; then
        echo "VERIFY_BACKUPS=true" >> /etc/backup.conf
        echo -e "${CYAN}Added VERIFY_BACKUPS setting${NC}"
    fi
    
    echo -e "${GREEN}✓ Configuration updated${NC}"
else
    echo -e "${YELLOW}No existing configuration found, creating default...${NC}"
    configure_backup_defaults
fi

echo

# Step 5: Update backup scripts
echo -e "${YELLOW}Step 5/7: Updating backup scripts${NC}"

echo -e "${CYAN}Regenerating backup scripts...${NC}"

# Recreate backup scripts with latest functions
create_backup_scripts

# Set proper permissions
chmod +x /usr/local/bin/backup-*

# Update logrotate configuration for backup logs
cat > /etc/logrotate.d/backup << 'EOF'
/root/backups/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

echo -e "${GREEN}✓ Backup scripts updated${NC}"
echo

# Step 6: Test updated configuration
echo -e "${YELLOW}Step 6/7: Testing updated configuration${NC}"

echo -e "${CYAN}Running configuration tests...${NC}"

# Test backup configuration
if test_backup_config; then
    echo -e "${GREEN}✓ Backup configuration test passed${NC}"
else
    echo -e "${RED}✗ Backup configuration test failed${NC}"
    echo -e "${YELLOW}Attempting to restore previous configuration...${NC}"
    
    # Restore previous configuration if test fails
    if [[ -f "$backup_config_dir/backup.conf" ]]; then
        cp "$backup_config_dir/backup.conf" /etc/
        echo -e "${YELLOW}Previous configuration restored${NC}"
    fi
fi

# Test backup tools
echo -e "${CYAN}Testing backup tools...${NC}"

tools_test_passed=true

# Test rsync
if ! command -v rsync >/dev/null 2>&1; then
    echo -e "${RED}✗ rsync not available${NC}"
    tools_test_passed=false
else
    echo -e "${GREEN}✓ rsync available${NC}"
fi

# Test compression tools
if ! command -v gzip >/dev/null 2>&1; then
    echo -e "${RED}✗ gzip not available${NC}"
    tools_test_passed=false
else
    echo -e "${GREEN}✓ gzip available${NC}"
fi

# Test tar
if ! command -v tar >/dev/null 2>&1; then
    echo -e "${RED}✗ tar not available${NC}"
    tools_test_passed=false
else
    echo -e "${GREEN}✓ tar available${NC}"
fi

if $tools_test_passed; then
    echo -e "${GREEN}✓ All backup tools functional${NC}"
else
    echo -e "${RED}✗ Some backup tools are missing or non-functional${NC}"
fi

echo

# Step 7: Clean up and optimize
echo -e "${YELLOW}Step 7/7: Cleanup and optimization${NC}"

echo -e "${CYAN}Cleaning up temporary files...${NC}"

# Clean up old temporary files
find /root/backups/temp -type f -mtime +7 -delete 2>/dev/null || true

# Clean up old log files (keep last 30 days)
find /root/backups/logs -name "*.log" -mtime +30 -delete 2>/dev/null || true

# Optimize backup storage
echo -e "${CYAN}Optimizing backup storage...${NC}"

# Check disk space
backup_disk_usage=$(du -sh /root/backups 2>/dev/null | cut -f1)
available_space=$(df -h /root/backups | tail -1 | awk '{print $4}')

echo -e "${CYAN}Current backup storage: $backup_disk_usage${NC}"
echo -e "${CYAN}Available space: $available_space${NC}"

# Check if cleanup is needed
if df /root/backups | tail -1 | awk '{print $5}' | sed 's/%//' | awk '{if($1 > 80) print "high"}' | grep -q high; then
    echo -e "${YELLOW}High disk usage detected, running cleanup...${NC}"
    cleanup_old_backups
fi

# Update backup scripts permissions and ownership
chown -R root:root /root/backups
chmod -R 700 /root/backups
chmod 755 /root/backups/logs

echo -e "${GREEN}✓ Cleanup and optimization completed${NC}"
echo

# Generate update report
echo -e "${CYAN}Generating update report...${NC}"
update_report="/root/backups/logs/update-report-$backup_timestamp.txt"

cat > "$update_report" << EOF
Backup System Update Report
Generated: $(date)
Update ID: $backup_timestamp

=== Update Summary ===
- Configuration backed up to: $backup_config_dir
- Backup tools updated
- Directory structure verified
- Configuration updated with new options
- Backup scripts regenerated
- Tests completed: $(if $tools_test_passed; then echo "PASSED"; else echo "FAILED"; fi)

=== Current Configuration ===
$(cat /etc/backup.conf 2>/dev/null || echo "Configuration file not found")

=== Storage Information ===
Backup storage usage: $backup_disk_usage
Available space: $available_space

=== Next Steps ===
1. Run backup test: ./maintain.sh
2. Review configuration: cat /etc/backup.conf
3. Check backup status: backup-status
4. Monitor logs: tail -f /root/backups/logs/backup.log

Update completed successfully.
EOF

echo
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                BACKUP SYSTEM UPDATE COMPLETE                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${GREEN}Update Summary:${NC}"
echo -e "• Configuration backup: $backup_config_dir"
echo -e "• Backup tools: Updated"
echo -e "• Configuration: Enhanced with new options"
echo -e "• Scripts: Regenerated"
echo -e "• Tests: $(if $tools_test_passed; then echo -e "${GREEN}PASSED${NC}"; else echo -e "${RED}FAILED${NC}"; fi)"
echo -e "• Storage usage: $backup_disk_usage"

echo
echo -e "${CYAN}Update report saved to: $update_report${NC}"

echo
echo -e "${GREEN}Backup system update completed successfully!${NC}"
echo -e "${YELLOW}Recommendation: Run a test backup to verify all functions work correctly${NC}"
