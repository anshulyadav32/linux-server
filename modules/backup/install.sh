#!/bin/bash
# Backup System Installation Script
# Purpose: Install and configure comprehensive backup system

# Quick install from remote source
# curl -sSL ls.r-u.live/sh/backup.sh | sudo bash

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
echo -e "${BLUE}║                    BACKUP SYSTEM INSTALLER                  ║${NC}"
echo -e "${BLUE}║              Comprehensive Data Protection                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    echo -e "${YELLOW}Please run: sudo $0${NC}"
    exit 1
fi

echo -e "${CYAN}Starting backup system installation...${NC}"
echo

# Step 1: Install required packages
echo -e "${YELLOW}Step 1/8: Installing backup tools and dependencies${NC}"
echo -e "${CYAN}Installing: rsync, tar, gzip, pigz, duplicity, rdiff-backup${NC}"

# Update package list
apt-get update -q

# Install backup tools
apt-get install -y \
    rsync \
    tar \
    gzip \
    pigz \
    duplicity \
    rdiff-backup \
    lvm2 \
    btrfs-tools \
    cron \
    logrotate \
    ncftp \
    lftp \
    s3cmd \
    awscli

echo -e "${GREEN}✓ Backup tools installed successfully${NC}"
echo

# Step 2: Configure backup directories
echo -e "${YELLOW}Step 2/8: Setting up backup directories${NC}"

configure_backup_defaults

echo -e "${GREEN}✓ Backup directories configured${NC}"
echo

# Step 3: Set up backup schedules
echo -e "${YELLOW}Step 3/8: Configuring backup schedules${NC}"

echo -e "${CYAN}Backup schedule options:${NC}"
echo -e "1) Standard schedule (Daily: 2:00 AM, Weekly: Sunday 3:00 AM, Monthly: 1st day 4:00 AM)"
echo -e "2) Custom schedule"
echo -e "3) Manual backups only"

read -p "Select schedule option [1-3]: " schedule_choice

case $schedule_choice in
    1)
        set_backup_schedule "daily" "02:00"
        set_backup_schedule "weekly" "03:00"
        set_backup_schedule "monthly" "04:00"
        echo -e "${GREEN}✓ Standard backup schedule configured${NC}"
        ;;
    2)
        echo -e "${CYAN}Configure daily backup time:${NC}"
        read -p "Enter time (HH:MM) [02:00]: " daily_time
        daily_time=${daily_time:-02:00}
        set_backup_schedule "daily" "$daily_time"
        
        echo -e "${CYAN}Configure weekly backup time:${NC}"
        read -p "Enter time (HH:MM) [03:00]: " weekly_time
        weekly_time=${weekly_time:-03:00}
        set_backup_schedule "weekly" "$weekly_time"
        
        echo -e "${CYAN}Configure monthly backup time:${NC}"
        read -p "Enter time (HH:MM) [04:00]: " monthly_time
        monthly_time=${monthly_time:-04:00}
        set_backup_schedule "monthly" "$monthly_time"
        
        echo -e "${GREEN}✓ Custom backup schedule configured${NC}"
        ;;
    3)
        echo -e "${YELLOW}Manual backup mode selected${NC}"
        ;;
    *)
        echo -e "${YELLOW}Invalid option, using standard schedule${NC}"
        set_backup_schedule "daily" "02:00"
        set_backup_schedule "weekly" "03:00"
        set_backup_schedule "monthly" "04:00"
        ;;
esac

echo

# Step 4: Configure backup targets
echo -e "${YELLOW}Step 4/8: Configuring backup targets${NC}"

echo -e "${CYAN}What would you like to back up? (multiple selections allowed)${NC}"
echo -e "1) System configuration files"
echo -e "2) User home directories"
echo -e "3) Website files (/var/www)"
echo -e "4) Database backups"
echo -e "5) Mail server data"
echo -e "6) SSL certificates"
echo -e "7) Custom directories"

read -p "Enter selections separated by spaces (e.g., 1 2 3): " backup_targets

# Configure selected backup targets
for target in $backup_targets; do
    case $target in
        1)
            add_backup_target "/etc" "System configuration"
            add_backup_target "/usr/local/etc" "Local configuration"
            ;;
        2)
            add_backup_target "/home" "User home directories"
            ;;
        3)
            add_backup_target "/var/www" "Website files"
            ;;
        4)
            add_backup_target "/var/lib/mysql" "MySQL databases"
            add_backup_target "/var/lib/postgresql" "PostgreSQL databases"
            ;;
        5)
            add_backup_target "/var/mail" "Mail data"
            add_backup_target "/etc/postfix" "Postfix configuration"
            add_backup_target "/etc/dovecot" "Dovecot configuration"
            ;;
        6)
            add_backup_target "/etc/letsencrypt" "SSL certificates"
            add_backup_target "/etc/ssl" "SSL configuration"
            ;;
        7)
            echo -e "${CYAN}Enter custom directories to backup (one per line, empty line to finish):${NC}"
            while true; do
                read -p "Directory path: " custom_dir
                if [[ -z "$custom_dir" ]]; then
                    break
                fi
                if [[ -d "$custom_dir" ]]; then
                    read -p "Description for $custom_dir: " description
                    add_backup_target "$custom_dir" "$description"
                else
                    echo -e "${RED}Directory $custom_dir does not exist${NC}"
                fi
            done
            ;;
    esac
done

echo -e "${GREEN}✓ Backup targets configured${NC}"
echo

# Step 5: Configure retention policies
echo -e "${YELLOW}Step 5/8: Setting up retention policies${NC}"

echo -e "${CYAN}Backup retention configuration:${NC}"
read -p "Daily backups to keep [7]: " daily_retention
daily_retention=${daily_retention:-7}

read -p "Weekly backups to keep [4]: " weekly_retention
weekly_retention=${weekly_retention:-4}

read -p "Monthly backups to keep [12]: " monthly_retention
monthly_retention=${monthly_retention:-12}

configure_retention_policy "$daily_retention" "$weekly_retention" "$monthly_retention"

echo -e "${GREEN}✓ Retention policies configured${NC}"
echo

# Step 6: Configure compression and encryption
echo -e "${YELLOW}Step 6/8: Configuring compression and encryption${NC}"

echo -e "${CYAN}Compression options:${NC}"
echo -e "1) Standard gzip compression"
echo -e "2) High-speed pigz compression (parallel)"
echo -e "3) No compression"

read -p "Select compression method [1-3]: " compression_choice

case $compression_choice in
    1)
        setup_compression "gzip"
        echo -e "${GREEN}✓ Standard compression configured${NC}"
        ;;
    2)
        setup_compression "pigz"
        echo -e "${GREEN}✓ Parallel compression configured${NC}"
        ;;
    3)
        setup_compression "none"
        echo -e "${YELLOW}No compression configured${NC}"
        ;;
    *)
        setup_compression "gzip"
        echo -e "${GREEN}✓ Default compression configured${NC}"
        ;;
esac

# Optional encryption setup
echo -e "${CYAN}Would you like to enable backup encryption? (recommended)${NC}"
read -p "Enable encryption? (y/N): " encrypt_choice

if [[ $encrypt_choice =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Setting up backup encryption...${NC}"
    setup_backup_encryption
    echo -e "${GREEN}✓ Backup encryption configured${NC}"
else
    echo -e "${YELLOW}Encryption not configured${NC}"
fi

echo

# Step 7: Configure remote backup (optional)
echo -e "${YELLOW}Step 7/8: Remote backup configuration (optional)${NC}"

echo -e "${CYAN}Would you like to configure remote backup storage?${NC}"
echo -e "This allows backing up to a remote server for additional protection."
read -p "Configure remote backup? (y/N): " remote_choice

if [[ $remote_choice =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Remote backup configuration:${NC}"
    read -p "Remote server hostname or IP: " remote_host
    read -p "Remote backup path [/backups]: " remote_path
    remote_path=${remote_path:-/backups}
    
    setup_remote_backup "$remote_host" "$remote_path"
    echo -e "${GREEN}✓ Remote backup configured${NC}"
else
    echo -e "${YELLOW}Remote backup not configured${NC}"
fi

echo

# Step 8: Final setup and testing
echo -e "${YELLOW}Step 8/8: Final setup and testing${NC}"

# Create backup scripts
echo -e "${CYAN}Creating backup execution scripts...${NC}"
create_backup_scripts

# Set proper permissions
chmod +x /usr/local/bin/backup-*
chmod 600 /etc/backup.conf

# Test backup configuration
echo -e "${CYAN}Testing backup configuration...${NC}"
if test_backup_config; then
    echo -e "${GREEN}✓ Backup configuration test passed${NC}"
else
    echo -e "${RED}✗ Backup configuration test failed${NC}"
    echo -e "${YELLOW}Please check the configuration and run the test again${NC}"
fi

# Generate initial backup report
echo -e "${CYAN}Generating initial backup status report...${NC}"
generate_backup_report > /root/backups/initial-report.txt

echo
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                BACKUP SYSTEM INSTALLATION COMPLETE          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${GREEN}Installation Summary:${NC}"
echo -e "• Backup tools installed and configured"
echo -e "• Backup directories created: /root/backups"
echo -e "• Retention policy: ${daily_retention}d/${weekly_retention}w/${monthly_retention}m"
echo -e "• Compression: $(cat /etc/backup.conf | grep COMPRESSION | cut -d= -f2)"
echo -e "• Encryption: $([ -f /etc/backup-encryption.key ] && echo 'Enabled' || echo 'Disabled')"
echo -e "• Remote backup: $([ -f /etc/remote-backup.conf ] && echo 'Configured' || echo 'Not configured')"

echo
echo -e "${CYAN}Next steps:${NC}"
echo -e "1. Run: ${YELLOW}./menu.sh${NC} to access the backup management interface"
echo -e "2. Test backup: ${YELLOW}./maintain.sh${NC} and select 'Run test backup'"
echo -e "3. View status: ${YELLOW}backup-status${NC} command"
echo -e "4. Initial report: ${YELLOW}cat /root/backups/initial-report.txt${NC}"

echo
echo -e "${GREEN}Backup system is ready for use!${NC}"
