#!/bin/bash
# Backup System Maintenance
# Purpose: Daily operational checks and maintenance for backup system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Source functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Function to check backup health
check_backup_health() {
    echo -e "${YELLOW}Checking backup health...${NC}"
    local errors=0
    
    # Check backup directories
    for dir in daily weekly monthly logs; do
        if [ ! -d "/var/backups/$dir" ]; then
            echo -e "${RED}✗ /var/backups/$dir directory is missing${NC}"
            errors=$((errors + 1))
        fi
    done
    
    # Check recent backups
    local last_daily=$(find /var/backups/daily -type d -mtime -1 | wc -l)
    if [ "$last_daily" -eq 0 ]; then
        echo -e "${RED}✗ No daily backup in the last 24 hours${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ Daily backup is recent${NC}"
    fi
    
    # Check disk space
    local space_used=$(df -h /var/backups | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$space_used" -gt 90 ]; then
        echo -e "${RED}✗ Backup disk space critical ($space_used%)${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ Backup disk space ok ($space_used%)${NC}"
    fi
    
    return $errors
}

# Function to repair backup system
repair_backup_system() {
    echo -e "${YELLOW}Attempting to repair backup system...${NC}"
    
    # Recreate missing directories
    for dir in daily weekly monthly logs; do
        if [ ! -d "/var/backups/$dir" ]; then
            mkdir -p "/var/backups/$dir"
            chmod 700 "/var/backups/$dir"
            echo -e "${GREEN}✓ Recreated /var/backups/$dir${NC}"
        fi
    done
    
    # Fix permissions
    find /var/backups -type d -exec chmod 700 {} \;
    find /var/backups/logs -type d -exec chmod 755 {} \;
    
    # Verify backup scripts
    for script in daily-backup.sh weekly-backup.sh monthly-backup.sh; do
        if [ ! -x "/usr/local/sbin/backup-scripts/$script" ]; then
            echo -e "${RED}✗ Recreating $script${NC}"
            configure_backup_scripts
            break
        fi
    done
    
    # Check and fix cron jobs
    if ! crontab -l | grep -q "backup-scripts"; then
        echo -e "${YELLOW}Reinstalling backup schedule...${NC}"
        setup_backup_schedule
    fi
}

# Function to clean old backups
clean_old_backups() {
    echo -e "${YELLOW}Cleaning old backups...${NC}"
    
    # Remove daily backups older than 7 days
    find /var/backups/daily -type d -mtime +7 -exec rm -rf {} \;
    
    # Remove weekly backups older than 4 weeks
    find /var/backups/weekly -type d -mtime +28 -exec rm -rf {} \;
    
    # Remove monthly backups older than 3 months
    find /var/backups/monthly -type d -mtime +90 -exec rm -rf {} \;
    
    # Clean old log files
    find /var/backups/logs -type f -mtime +90 -delete
    
    echo -e "${GREEN}✓ Cleaned old backups${NC}"
}

# Function to show backup status
show_backup_status() {
    echo -e "${YELLOW}Backup System Status${NC}"
    echo "----------------------------------------"
    
    # Show disk usage
    echo "Disk Usage:"
    df -h /var/backups
    echo
    
    # Show recent backups
    echo "Recent Backups:"
    echo "Daily:"
    ls -lt /var/backups/daily | head -n 5
    echo
    echo "Weekly:"
    ls -lt /var/backups/weekly | head -n 3
    echo
    echo "Monthly:"
    ls -lt /var/backups/monthly | head -n 3
    echo
    
    # Show last backup logs
    echo "Last Backup Log:"
    tail -n 10 "$(ls -t /var/backups/logs/*.log | head -n 1)"
}

# Main menu
while true; do
    echo -e "\n${YELLOW}Backup System Maintenance${NC}"
    echo "1. Check backup health"
    echo "2. Repair backup system"
    echo "3. Clean old backups"
    echo "4. Show backup status"
    echo "5. Exit"
    
    read -p "Select an option: " choice
    
    case $choice in
        1)
            check_backup_health
            ;;
        2)
            repair_backup_system
            ;;
        3)
            clean_old_backups
            ;;
        4)
            show_backup_status
            ;;
        5)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}      BACKUP SYSTEM MAINTENANCE        ${NC}"
echo -e "${BLUE}========================================${NC}"

# Function to show maintenance menu
show_maintenance_menu() {
    clear
    echo -e "${BLUE}Backup System Maintenance Options:${NC}"
    echo -e "${GREEN}1)${NC} Check backup status"
    echo -e "${GREEN}2)${NC} Run test backup"
    echo -e "${GREEN}3)${NC} View backup logs"
    echo -e "${GREEN}4)${NC} Manage backup schedules"
    echo -e "${GREEN}5)${NC} Storage management"
    echo -e "${GREEN}6)${NC} Backup verification"
    echo -e "${GREEN}7)${NC} Restore operations"
    echo -e "${GREEN}8)${NC} Remote backup sync"
    echo -e "${GREEN}9)${NC} Database backup operations"
    echo -e "${GREEN}10)${NC} Configuration management"
    echo -e "${GREEN}11)${NC} Performance monitoring"
    echo -e "${GREEN}12)${NC} Cleanup operations"
    echo -e "${YELLOW}0)${NC} Return to main menu"
    echo
}

# Function to check backup status
check_backup_status() {
    echo -e "${YELLOW}Checking backup system status...${NC}"
    echo
    
    # Check backup directories
    echo -e "${CYAN}Backup Directory Status:${NC}"
    if [[ -d /root/backups ]]; then
        echo -e "${GREEN}✓ Main backup directory exists${NC}"
        
        local backup_size=$(du -sh /root/backups 2>/dev/null | cut -f1)
        echo -e "${CYAN}  Total backup size: $backup_size${NC}"
        
        # Check individual backup types
        for backup_type in daily weekly monthly; do
            if [[ -d "/root/backups/$backup_type" ]]; then
                local count=$(ls -1 "/root/backups/$backup_type" 2>/dev/null | wc -l)
                local size=$(du -sh "/root/backups/$backup_type" 2>/dev/null | cut -f1)
                echo -e "${CYAN}  $backup_type backups: $count files ($size)${NC}"
            fi
        done
    else
        echo -e "${RED}✗ Main backup directory missing${NC}"
    fi
    
    echo
    
    # Check backup services
    echo -e "${CYAN}Backup Services Status:${NC}"
    if systemctl is-active --quiet cron; then
        echo -e "${GREEN}✓ Cron service is running${NC}"
    else
        echo -e "${RED}✗ Cron service is not running${NC}"
    fi
    
    # Check scheduled backups
    echo -e "${CYAN}Scheduled Backups:${NC}"
    if crontab -l 2>/dev/null | grep -q "backup"; then
        echo -e "${GREEN}✓ Backup schedules configured${NC}"
        crontab -l | grep backup | head -5
    else
        echo -e "${YELLOW}⚠ No backup schedules found${NC}"
    fi
    
    echo
    
    # Check recent backup activity
    echo -e "${CYAN}Recent Backup Activity:${NC}"
    if [[ -f /root/backups/logs/backup.log ]]; then
        echo -e "${CYAN}Last 5 backup operations:${NC}"
        tail -5 /root/backups/logs/backup.log | while read line; do
            echo -e "${CYAN}  $line${NC}"
        done
    else
        echo -e "${YELLOW}No backup logs found${NC}"
    fi
    
    echo
    
    # Storage status
    echo -e "${CYAN}Storage Status:${NC}"
    local disk_usage=$(df -h /root/backups | tail -1 | awk '{print $5}' | sed 's/%//')
    local available_space=$(df -h /root/backups | tail -1 | awk '{print $4}')
    
    echo -e "${CYAN}  Disk usage: ${disk_usage}%${NC}"
    echo -e "${CYAN}  Available space: $available_space${NC}"
    
    if [[ $disk_usage -gt 80 ]]; then
        echo -e "${RED}  ⚠ High disk usage - cleanup recommended${NC}"
    elif [[ $disk_usage -gt 60 ]]; then
        echo -e "${YELLOW}  ⚠ Moderate disk usage - monitor closely${NC}"
    else
        echo -e "${GREEN}  ✓ Disk usage is healthy${NC}"
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Function to run test backup
run_test_backup() {
    echo -e "${YELLOW}Running test backup...${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required for backup operations${NC}"
        sleep 2
        return
    fi
    
    # Create test data
    test_dir="/tmp/backup-test-$(date +%s)"
    mkdir -p "$test_dir"
    
    echo "Test backup data" > "$test_dir/test-file.txt"
    echo "Created: $(date)" > "$test_dir/timestamp.txt"
    
    echo -e "${CYAN}Created test data in: $test_dir${NC}"
    
    # Run backup
    echo -e "${CYAN}Performing test backup...${NC}"
    if create_backup "$test_dir" "test-backup" "manual"; then
        echo -e "${GREEN}✓ Test backup completed successfully${NC}"
        
        # Verify backup
        echo -e "${CYAN}Verifying backup integrity...${NC}"
        if verify_backup "test-backup"; then
            echo -e "${GREEN}✓ Backup verification passed${NC}"
        else
            echo -e "${RED}✗ Backup verification failed${NC}"
        fi
    else
        echo -e "${RED}✗ Test backup failed${NC}"
    fi
    
    # Cleanup
    rm -rf "$test_dir"
    echo -e "${CYAN}Test data cleaned up${NC}"
    
    echo
    read -p "Press Enter to continue..."
}

# Function to view backup logs
view_backup_logs() {
    clear
    echo -e "${BLUE}Backup System Logs${NC}"
    echo
    echo -e "${GREEN}Log Options:${NC}"
    echo -e "1) Recent backup operations"
    echo -e "2) Error logs"
    echo -e "3) Full backup log"
    echo -e "4) Restore operation logs"
    echo -e "5) Real-time log monitoring"
    echo -e "0) Back to maintenance menu"
    echo
    
    read -p "Select log option [0-5]: " log_choice
    
    case $log_choice in
        1)
            echo -e "${CYAN}Recent backup operations:${NC}"
            if [[ -f /root/backups/logs/backup.log ]]; then
                tail -20 /root/backups/logs/backup.log
            else
                echo "No backup logs found"
            fi
            ;;
        2)
            echo -e "${CYAN}Error logs:${NC}"
            if [[ -f /root/backups/logs/backup-error.log ]]; then
                tail -20 /root/backups/logs/backup-error.log
            else
                echo "No error logs found"
            fi
            ;;
        3)
            echo -e "${CYAN}Full backup log:${NC}"
            if [[ -f /root/backups/logs/backup.log ]]; then
                less /root/backups/logs/backup.log
            else
                echo "No backup logs found"
            fi
            ;;
        4)
            echo -e "${CYAN}Restore operation logs:${NC}"
            if [[ -f /root/backups/logs/restore.log ]]; then
                tail -20 /root/backups/logs/restore.log
            else
                echo "No restore logs found"
            fi
            ;;
        5)
            echo -e "${YELLOW}Starting real-time log monitoring (Ctrl+C to stop)...${NC}"
            if [[ -f /root/backups/logs/backup.log ]]; then
                tail -f /root/backups/logs/backup.log
            else
                echo "No backup logs found"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function to manage backup schedules
manage_schedules() {
    clear
    echo -e "${BLUE}Backup Schedule Management${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required to manage schedules${NC}"
        sleep 2
        return
    fi
    
    echo -e "${GREEN}Schedule Options:${NC}"
    echo -e "1) View current schedules"
    echo -e "2) Add new schedule"
    echo -e "3) Modify existing schedule"
    echo -e "4) Remove schedule"
    echo -e "5) Enable/disable schedules"
    echo -e "0) Back to maintenance menu"
    echo
    
    read -p "Select option [0-5]: " schedule_choice
    
    case $schedule_choice in
        1)
            echo -e "${CYAN}Current backup schedules:${NC}"
            crontab -l | grep backup || echo "No backup schedules found"
            ;;
        2)
            echo -e "${CYAN}Add new backup schedule:${NC}"
            echo -e "Schedule types:"
            echo -e "1) Daily backup"
            echo -e "2) Weekly backup"
            echo -e "3) Monthly backup"
            echo -e "4) Custom schedule"
            
            read -p "Select schedule type [1-4]: " sched_type
            read -p "Enter time (HH:MM): " sched_time
            
            case $sched_type in
                1) set_backup_schedule "daily" "$sched_time" ;;
                2) set_backup_schedule "weekly" "$sched_time" ;;
                3) set_backup_schedule "monthly" "$sched_time" ;;
                4) 
                    read -p "Enter cron expression: " cron_expr
                    echo "$cron_expr /usr/local/bin/backup-custom" | crontab -
                    ;;
            esac
            echo -e "${GREEN}Schedule added successfully${NC}"
            ;;
        3)
            echo -e "${CYAN}Current schedules:${NC}"
            crontab -l | grep backup | nl
            read -p "Enter line number to modify: " line_num
            echo -e "${YELLOW}Please edit manually using: crontab -e${NC}"
            ;;
        4)
            echo -e "${CYAN}Current schedules:${NC}"
            crontab -l | grep backup | nl
            read -p "Enter line number to remove: " line_num
            # Remove specific line from crontab
            temp_cron=$(mktemp)
            crontab -l | grep -v backup > "$temp_cron"
            crontab "$temp_cron"
            rm "$temp_cron"
            echo -e "${GREEN}Schedule removed${NC}"
            ;;
        5)
            echo -e "${CYAN}Schedule management:${NC}"
            echo -e "1) Disable all backup schedules"
            echo -e "2) Enable backup schedules"
            read -p "Select [1-2]: " enable_choice
            
            if [[ $enable_choice == "1" ]]; then
                crontab -r
                echo -e "${YELLOW}All schedules disabled${NC}"
            else
                echo -e "${YELLOW}Use 'Add new schedule' to re-enable${NC}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function for storage management
storage_management() {
    clear
    echo -e "${BLUE}Backup Storage Management${NC}"
    echo
    
    echo -e "${GREEN}Storage Options:${NC}"
    echo -e "1) View storage usage"
    echo -e "2) Cleanup old backups"
    echo -e "3) Compress backups"
    echo -e "4) Move backups to external storage"
    echo -e "5) Check backup integrity"
    echo -e "6) Backup retention management"
    echo -e "0) Back to maintenance menu"
    echo
    
    read -p "Select option [0-6]: " storage_choice
    
    case $storage_choice in
        1)
            echo -e "${CYAN}Backup storage analysis:${NC}"
            echo
            echo -e "${CYAN}Directory sizes:${NC}"
            du -sh /root/backups/* 2>/dev/null | sort -hr
            echo
            echo -e "${CYAN}Disk usage:${NC}"
            df -h /root/backups
            echo
            echo -e "${CYAN}Largest backup files:${NC}"
            find /root/backups -type f -size +100M -exec ls -lh {} \; 2>/dev/null | head -10
            ;;
        2)
            if [[ $EUID -eq 0 ]]; then
                echo -e "${YELLOW}Cleaning up old backups...${NC}"
                cleanup_old_backups
                echo -e "${GREEN}Cleanup completed${NC}"
            else
                echo -e "${RED}Root privileges required for cleanup${NC}"
            fi
            ;;
        3)
            echo -e "${YELLOW}Compressing uncompressed backups...${NC}"
            find /root/backups -name "*.tar" -not -name "*.gz" -exec gzip {} \;
            echo -e "${GREEN}Compression completed${NC}"
            ;;
        4)
            echo -e "${CYAN}External storage options:${NC}"
            read -p "Enter external storage path: " ext_path
            if [[ -n "$ext_path" && -d "$ext_path" ]]; then
                echo -e "${YELLOW}Moving oldest backups to external storage...${NC}"
                find /root/backups -name "*.tar.gz" -mtime +30 -exec mv {} "$ext_path/" \;
                echo -e "${GREEN}Backups moved to external storage${NC}"
            else
                echo -e "${RED}Invalid external storage path${NC}"
            fi
            ;;
        5)
            echo -e "${YELLOW}Checking backup integrity...${NC}"
            if [[ $EUID -eq 0 ]]; then
                verify_all_backups
            else
                echo -e "${RED}Root privileges required for verification${NC}"
            fi
            ;;
        6)
            echo -e "${CYAN}Current retention policy:${NC}"
            if [[ -f /etc/backup.conf ]]; then
                grep -E "(DAILY_RETENTION|WEEKLY_RETENTION|MONTHLY_RETENTION)" /etc/backup.conf
            fi
            echo
            echo -e "${CYAN}Modify retention policy:${NC}"
            read -p "Daily retention days [7]: " daily_ret
            read -p "Weekly retention weeks [4]: " weekly_ret
            read -p "Monthly retention months [12]: " monthly_ret
            
            daily_ret=${daily_ret:-7}
            weekly_ret=${weekly_ret:-4}
            monthly_ret=${monthly_ret:-12}
            
            if [[ $EUID -eq 0 ]]; then
                configure_retention_policy "$daily_ret" "$weekly_ret" "$monthly_ret"
                echo -e "${GREEN}Retention policy updated${NC}"
            else
                echo -e "${RED}Root privileges required to update policy${NC}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function for backup verification
backup_verification() {
    clear
    echo -e "${BLUE}Backup Verification${NC}"
    echo
    
    echo -e "${GREEN}Verification Options:${NC}"
    echo -e "1) Verify specific backup"
    echo -e "2) Verify all recent backups"
    echo -e "3) Quick integrity check"
    echo -e "4) Deep verification with restore test"
    echo -e "5) Generate verification report"
    echo -e "0) Back to maintenance menu"
    echo
    
    read -p "Select option [0-5]: " verify_choice
    
    case $verify_choice in
        1)
            echo -e "${CYAN}Available backups:${NC}"
            ls -la /root/backups/daily/ /root/backups/weekly/ /root/backups/monthly/ 2>/dev/null | head -20
            echo
            read -p "Enter backup filename: " backup_file
            if [[ -n "$backup_file" ]]; then
                verify_backup "$backup_file"
            fi
            ;;
        2)
            echo -e "${YELLOW}Verifying all recent backups...${NC}"
            verify_all_backups
            ;;
        3)
            echo -e "${YELLOW}Running quick integrity check...${NC}"
            find /root/backups -name "*.tar.gz" -exec gzip -t {} \; 2>&1 | grep -v "OK" || echo -e "${GREEN}All compressed backups passed integrity check${NC}"
            ;;
        4)
            echo -e "${YELLOW}Deep verification with restore test...${NC}"
            echo -e "${CYAN}This will restore a backup to a temporary location for testing${NC}"
            read -p "Continue? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                # Find most recent backup
                recent_backup=$(find /root/backups -name "*.tar.gz" -mtime -1 | head -1)
                if [[ -n "$recent_backup" ]]; then
                    test_restore_backup "$recent_backup"
                else
                    echo -e "${YELLOW}No recent backups found for testing${NC}"
                fi
            fi
            ;;
        5)
            echo -e "${YELLOW}Generating verification report...${NC}"
            generate_verification_report
            echo -e "${GREEN}Report saved to: /root/backups/logs/verification-report-$(date +%Y%m%d).txt${NC}"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function for restore operations
restore_operations() {
    clear
    echo -e "${BLUE}Backup Restore Operations${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required for restore operations${NC}"
        sleep 2
        return
    fi
    
    echo -e "${GREEN}Restore Options:${NC}"
    echo -e "1) List available backups"
    echo -e "2) Restore specific files/directories"
    echo -e "3) Full system restore"
    echo -e "4) Database restore"
    echo -e "5) Configuration restore"
    echo -e "6) Test restore (to temporary location)"
    echo -e "0) Back to maintenance menu"
    echo
    
    read -p "Select option [0-6]: " restore_choice
    
    case $restore_choice in
        1)
            echo -e "${CYAN}Available backups:${NC}"
            echo
            echo -e "${CYAN}Daily backups:${NC}"
            ls -la /root/backups/daily/ 2>/dev/null | head -10
            echo
            echo -e "${CYAN}Weekly backups:${NC}"
            ls -la /root/backups/weekly/ 2>/dev/null | head -5
            echo
            echo -e "${CYAN}Monthly backups:${NC}"
            ls -la /root/backups/monthly/ 2>/dev/null | head -5
            ;;
        2)
            echo -e "${CYAN}Selective file/directory restore:${NC}"
            read -p "Enter backup file path: " backup_path
            read -p "Enter destination path: " dest_path
            read -p "Enter files/directories to restore (space-separated): " restore_items
            
            if [[ -n "$backup_path" && -n "$dest_path" && -n "$restore_items" ]]; then
                restore_selective "$backup_path" "$dest_path" "$restore_items"
            else
                echo -e "${RED}All parameters required${NC}"
            fi
            ;;
        3)
            echo -e "${RED}WARNING: Full system restore will overwrite current data!${NC}"
            read -p "Are you absolutely sure? Type 'RESTORE' to confirm: " confirm
            if [[ "$confirm" == "RESTORE" ]]; then
                read -p "Enter backup file for full restore: " backup_file
                if [[ -n "$backup_file" ]]; then
                    restore_full_system "$backup_file"
                fi
            else
                echo -e "${GREEN}Restore cancelled${NC}"
            fi
            ;;
        4)
            echo -e "${CYAN}Database restore options:${NC}"
            echo -e "1) MySQL/MariaDB restore"
            echo -e "2) PostgreSQL restore"
            echo -e "3) MongoDB restore"
            read -p "Select database type [1-3]: " db_type
            
            case $db_type in
                1) restore_mysql_backup ;;
                2) restore_postgresql_backup ;;
                3) restore_mongodb_backup ;;
            esac
            ;;
        5)
            echo -e "${CYAN}Configuration restore:${NC}"
            read -p "Enter configuration backup file: " config_backup
            if [[ -n "$config_backup" && -f "$config_backup" ]]; then
                restore_configuration "$config_backup"
            else
                echo -e "${RED}Configuration backup file not found${NC}"
            fi
            ;;
        6)
            echo -e "${CYAN}Test restore to temporary location:${NC}"
            read -p "Enter backup file to test: " test_backup_file
            if [[ -n "$test_backup_file" ]]; then
                test_restore_backup "$test_backup_file"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function for remote backup sync
remote_backup_sync() {
    clear
    echo -e "${BLUE}Remote Backup Synchronization${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required for remote operations${NC}"
        sleep 2
        return
    fi
    
    echo -e "${GREEN}Remote Sync Options:${NC}"
    echo -e "1) Sync to remote server"
    echo -e "2) Check remote backup status"
    echo -e "3) Configure remote backup"
    echo -e "4) Test remote connection"
    echo -e "5) Download from remote"
    echo -e "0) Back to maintenance menu"
    echo
    
    read -p "Select option [0-5]: " remote_choice
    
    case $remote_choice in
        1)
            echo -e "${YELLOW}Syncing backups to remote server...${NC}"
            if sync_backup_remote; then
                echo -e "${GREEN}Remote sync completed${NC}"
            else
                echo -e "${RED}Remote sync failed${NC}"
            fi
            ;;
        2)
            echo -e "${CYAN}Checking remote backup status...${NC}"
            check_remote_backup_status
            ;;
        3)
            echo -e "${CYAN}Remote backup configuration:${NC}"
            read -p "Remote server hostname/IP: " remote_host
            read -p "Remote backup path: " remote_path
            setup_remote_backup "$remote_host" "$remote_path"
            ;;
        4)
            echo -e "${CYAN}Testing remote connection...${NC}"
            if [[ -f /etc/remote-backup.conf ]]; then
                source /etc/remote-backup.conf
                ssh -i "$SSH_KEY" -o ConnectTimeout=10 "$REMOTE_HOST" "echo 'Connection successful'"
            else
                echo -e "${RED}Remote backup not configured${NC}"
            fi
            ;;
        5)
            echo -e "${CYAN}Download backups from remote:${NC}"
            read -p "Remote backup file to download: " remote_file
            if [[ -n "$remote_file" ]]; then
                download_remote_backup "$remote_file"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function for database backup operations
database_backup_ops() {
    clear
    echo -e "${BLUE}Database Backup Operations${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required for database operations${NC}"
        sleep 2
        return
    fi
    
    echo -e "${GREEN}Database Options:${NC}"
    echo -e "1) Backup all databases"
    echo -e "2) Backup specific database"
    echo -e "3) Schedule automatic DB backups"
    echo -e "4) Verify database backups"
    echo -e "5) Restore database from backup"
    echo -e "0) Back to maintenance menu"
    echo
    
    read -p "Select option [0-5]: " db_choice
    
    case $db_choice in
        1)
            echo -e "${YELLOW}Backing up all databases...${NC}"
            backup_all_databases
            ;;
        2)
            echo -e "${CYAN}Available databases:${NC}"
            list_databases
            echo
            read -p "Enter database name to backup: " db_name
            if [[ -n "$db_name" ]]; then
                backup_single_database "$db_name"
            fi
            ;;
        3)
            echo -e "${CYAN}Schedule automatic database backups:${NC}"
            read -p "Backup frequency (daily/weekly) [daily]: " freq
            freq=${freq:-daily}
            read -p "Backup time (HH:MM) [03:00]: " db_time
            db_time=${db_time:-03:00}
            
            schedule_database_backup "$freq" "$db_time"
            echo -e "${GREEN}Database backup scheduled${NC}"
            ;;
        4)
            echo -e "${YELLOW}Verifying database backups...${NC}"
            verify_database_backups
            ;;
        5)
            restore_operations
            return
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function for configuration management
config_management() {
    clear
    echo -e "${BLUE}Backup Configuration Management${NC}"
    echo
    
    echo -e "${GREEN}Configuration Options:${NC}"
    echo -e "1) View current configuration"
    echo -e "2) Edit backup configuration"
    echo -e "3) Reset to defaults"
    echo -e "4) Export configuration"
    echo -e "5) Import configuration"
    echo -e "6) Backup configuration files"
    echo -e "0) Back to maintenance menu"
    echo
    
    read -p "Select option [0-6]: " config_choice
    
    case $config_choice in
        1)
            echo -e "${CYAN}Current backup configuration:${NC}"
            if [[ -f /etc/backup.conf ]]; then
                cat /etc/backup.conf
            else
                echo "No configuration file found"
            fi
            ;;
        2)
            if [[ $EUID -eq 0 ]]; then
                echo -e "${CYAN}Opening configuration editor...${NC}"
                ${EDITOR:-nano} /etc/backup.conf
            else
                echo -e "${RED}Root privileges required to edit configuration${NC}"
            fi
            ;;
        3)
            if [[ $EUID -eq 0 ]]; then
                echo -e "${YELLOW}Resetting to default configuration...${NC}"
                configure_backup_defaults
                echo -e "${GREEN}Configuration reset to defaults${NC}"
            else
                echo -e "${RED}Root privileges required to reset configuration${NC}"
            fi
            ;;
        4)
            echo -e "${CYAN}Exporting configuration...${NC}"
            export_backup_config
            ;;
        5)
            echo -e "${CYAN}Import configuration:${NC}"
            read -p "Enter configuration file path: " config_file
            if [[ -n "$config_file" && -f "$config_file" ]]; then
                import_backup_config "$config_file"
            else
                echo -e "${RED}Configuration file not found${NC}"
            fi
            ;;
        6)
            if [[ $EUID -eq 0 ]]; then
                echo -e "${YELLOW}Backing up configuration files...${NC}"
                backup_configuration_files
                echo -e "${GREEN}Configuration backup completed${NC}"
            else
                echo -e "${RED}Root privileges required for configuration backup${NC}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function for performance monitoring
performance_monitoring() {
    clear
    echo -e "${BLUE}Backup Performance Monitoring${NC}"
    echo
    
    echo -e "${GREEN}Performance Options:${NC}"
    echo -e "1) View backup performance stats"
    echo -e "2) Monitor real-time backup activity"
    echo -e "3) Generate performance report"
    echo -e "4) Optimize backup performance"
    echo -e "5) Set performance alerts"
    echo -e "0) Back to maintenance menu"
    echo
    
    read -p "Select option [0-5]: " perf_choice
    
    case $perf_choice in
        1)
            echo -e "${CYAN}Backup performance statistics:${NC}"
            generate_performance_stats
            ;;
        2)
            echo -e "${YELLOW}Monitoring real-time backup activity...${NC}"
            echo -e "${CYAN}Press Ctrl+C to stop monitoring${NC}"
            monitor_backup_activity
            ;;
        3)
            echo -e "${YELLOW}Generating performance report...${NC}"
            generate_performance_report
            echo -e "${GREEN}Report saved to: /root/backups/logs/performance-report-$(date +%Y%m%d).txt${NC}"
            ;;
        4)
            echo -e "${CYAN}Backup performance optimization:${NC}"
            optimize_backup_performance
            ;;
        5)
            echo -e "${CYAN}Performance alert configuration:${NC}"
            configure_performance_alerts
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function for cleanup operations
cleanup_operations() {
    clear
    echo -e "${BLUE}Backup Cleanup Operations${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required for cleanup operations${NC}"
        sleep 2
        return
    fi
    
    echo -e "${GREEN}Cleanup Options:${NC}"
    echo -e "1) Remove old backup files"
    echo -e "2) Clean temporary files"
    echo -e "3) Purge corrupted backups"
    echo -e "4) Archive old backups"
    echo -e "5) Deep cleanup (all unnecessary files)"
    echo -e "6) Custom cleanup"
    echo -e "0) Back to maintenance menu"
    echo
    
    read -p "Select option [0-6]: " cleanup_choice
    
    case $cleanup_choice in
        1)
            echo -e "${YELLOW}Removing old backup files...${NC}"
            cleanup_old_backups
            echo -e "${GREEN}Old backup cleanup completed${NC}"
            ;;
        2)
            echo -e "${YELLOW}Cleaning temporary files...${NC}"
            find /root/backups/temp -type f -delete 2>/dev/null || true
            find /tmp -name "backup-*" -mtime +1 -delete 2>/dev/null || true
            echo -e "${GREEN}Temporary file cleanup completed${NC}"
            ;;
        3)
            echo -e "${YELLOW}Checking for corrupted backups...${NC}"
            find /root/backups -name "*.tar.gz" -exec gzip -t {} \; 2>&1 | grep -v "OK" | while read line; do
                echo -e "${RED}Corrupted: $line${NC}"
                # Optionally remove corrupted files
                read -p "Remove corrupted backup? (y/N): " remove_corrupt
                if [[ $remove_corrupt =~ ^[Yy]$ ]]; then
                    rm -f "$(echo $line | cut -d: -f1)"
                fi
            done
            ;;
        4)
            echo -e "${CYAN}Archive old backups:${NC}"
            read -p "Archive backups older than (days) [90]: " archive_days
            archive_days=${archive_days:-90}
            
            mkdir -p /root/backups/archive
            find /root/backups -name "*.tar.gz" -mtime +$archive_days -exec mv {} /root/backups/archive/ \;
            echo -e "${GREEN}Old backups archived${NC}"
            ;;
        5)
            echo -e "${RED}WARNING: Deep cleanup will remove all unnecessary files!${NC}"
            read -p "Continue with deep cleanup? (y/N): " confirm_deep
            if [[ $confirm_deep =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Performing deep cleanup...${NC}"
                cleanup_old_backups
                find /root/backups/temp -delete 2>/dev/null || true
                find /root/backups/logs -name "*.log" -mtime +30 -delete 2>/dev/null || true
                echo -e "${GREEN}Deep cleanup completed${NC}"
            fi
            ;;
        6)
            echo -e "${CYAN}Custom cleanup options:${NC}"
            read -p "Enter pattern to clean (e.g., *.tmp): " clean_pattern
            read -p "Enter directory to clean: " clean_dir
            
            if [[ -n "$clean_pattern" && -n "$clean_dir" && -d "$clean_dir" ]]; then
                find "$clean_dir" -name "$clean_pattern" -delete
                echo -e "${GREEN}Custom cleanup completed${NC}"
            else
                echo -e "${RED}Invalid parameters${NC}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Main maintenance loop
while true; do
    show_maintenance_menu
    read -p "Select an option [0-12]: " choice
    
    case $choice in
        1)
            check_backup_status
            ;;
        2)
            run_test_backup
            ;;
        3)
            view_backup_logs
            ;;
        4)
            manage_schedules
            ;;
        5)
            storage_management
            ;;
        6)
            backup_verification
            ;;
        7)
            restore_operations
            ;;
        8)
            remote_backup_sync
            ;;
        9)
            database_backup_ops
            ;;
        10)
            config_management
            ;;
        11)
            performance_monitoring
            ;;
        12)
            cleanup_operations
            ;;
        0)
            echo -e "${YELLOW}Returning to main menu...${NC}"
            break
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 2
            ;;
    esac
done
