#!/bin/bash
# Backup System Interactive Menu
# Purpose: Main menu interface for comprehensive backup system management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Source functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

# Function to display banner
show_banner() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                   BACKUP SYSTEM MANAGER                     ║${NC}"
    echo -e "${BLUE}║              Comprehensive Data Protection                   ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Function to display system status
show_system_status() {
    echo -e "${CYAN}System Status:${NC}"
    
    # Check backup directories
    if [[ -d /root/backups ]]; then
        local backup_size=$(du -sh /root/backups 2>/dev/null | cut -f1)
        echo -e "${GREEN}  ✓ Backup System: Active${NC}"
        echo -e "${CYAN}    Storage used: $backup_size${NC}"
    else
        echo -e "${RED}  ✗ Backup System: Not configured${NC}"
    fi
    
    # Check scheduled backups
    if crontab -l 2>/dev/null | grep -q "backup"; then
        local schedule_count=$(crontab -l 2>/dev/null | grep -c "backup")
        echo -e "${GREEN}  ✓ Scheduled Backups: $schedule_count active${NC}"
    else
        echo -e "${YELLOW}  ⚠ Scheduled Backups: None configured${NC}"
    fi
    
    # Check remote backup
    if [[ -f /etc/remote-backup.conf ]]; then
        echo -e "${GREEN}  ✓ Remote Backup: Configured${NC}"
    else
        echo -e "${YELLOW}  ⚠ Remote Backup: Not configured${NC}"
    fi
    
    # Check recent backup activity
    if [[ -f /root/backups/logs/backup.log ]]; then
        local last_backup=$(tail -1 /root/backups/logs/backup.log 2>/dev/null | cut -d' ' -f1-2)
        echo -e "${CYAN}    Last backup: $last_backup${NC}"
    fi
    
    # Check disk space
    if [[ -d /root/backups ]]; then
        local disk_usage=$(df -h /root/backups | tail -1 | awk '{print $5}' | sed 's/%//')
        if [[ $disk_usage -gt 80 ]]; then
            echo -e "${RED}  ⚠ Disk Usage: ${disk_usage}% (High)${NC}"
        elif [[ $disk_usage -gt 60 ]]; then
            echo -e "${YELLOW}  ⚠ Disk Usage: ${disk_usage}% (Moderate)${NC}"
        else
            echo -e "${GREEN}  ✓ Disk Usage: ${disk_usage}% (Healthy)${NC}"
        fi
    fi
    
    echo
}

# Function to display main menu
show_main_menu() {
    show_banner
    show_system_status
    
    echo -e "${BLUE}Main Menu Options:${NC}"
    echo
    echo -e "${GREEN}SYSTEM SETUP${NC}"
    echo -e "  ${CYAN}1)${NC} Install backup system"
    echo -e "  ${CYAN}2)${NC} Update backup system"
    echo -e "  ${CYAN}3)${NC} Configure backup settings"
    echo
    echo -e "${GREEN}BACKUP OPERATIONS${NC}"
    echo -e "  ${CYAN}4)${NC} Run immediate backup"
    echo -e "  ${CYAN}5)${NC} Schedule automatic backups"
    echo -e "  ${CYAN}6)${NC} Backup specific directories"
    echo -e "  ${CYAN}7)${NC} Database backup operations"
    echo
    echo -e "${GREEN}RESTORE OPERATIONS${NC}"
    echo -e "  ${CYAN}8)${NC} Restore from backup"
    echo -e "  ${CYAN}9)${NC} List available backups"
    echo -e "  ${CYAN}10)${NC} Test restore operations"
    echo -e "  ${CYAN}11)${NC} Emergency restore wizard"
    echo
    echo -e "${GREEN}MONITORING & VERIFICATION${NC}"
    echo -e "  ${CYAN}12)${NC} Check backup status"
    echo -e "  ${CYAN}13)${NC} Verify backup integrity"
    echo -e "  ${CYAN}14)${NC} View backup logs"
    echo -e "  ${CYAN}15)${NC} Performance monitoring"
    echo
    echo -e "${GREEN}STORAGE MANAGEMENT${NC}"
    echo -e "  ${CYAN}16)${NC} Storage analysis"
    echo -e "  ${CYAN}17)${NC} Cleanup old backups"
    echo -e "  ${CYAN}18)${NC} Remote backup sync"
    echo -e "  ${CYAN}19)${NC} Archive management"
    echo
    echo -e "${GREEN}ADVANCED OPTIONS${NC}"
    echo -e "  ${CYAN}20)${NC} Encryption management"
    echo -e "  ${CYAN}21)${NC} Compression settings"
    echo -e "  ${CYAN}22)${NC} Custom backup scripts"
    echo -e "  ${CYAN}23)${NC} System maintenance"
    echo
    echo -e "${YELLOW}0) Exit${NC}"
    echo
}

# Function to install backup system
install_system() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Installation requires root privileges${NC}"
        echo -e "${YELLOW}Please run: sudo $SCRIPT_DIR/install.sh${NC}"
        sleep 3
        return
    fi
    
    echo -e "${YELLOW}Starting backup system installation...${NC}"
    "$SCRIPT_DIR/install.sh"
    echo
    read -p "Press Enter to continue..."
}

# Function to update system
update_system() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Update requires root privileges${NC}"
        echo -e "${YELLOW}Please run: sudo $SCRIPT_DIR/update.sh${NC}"
        sleep 3
        return
    fi
    
    echo -e "${YELLOW}Starting backup system update...${NC}"
    "$SCRIPT_DIR/update.sh"
    echo
    read -p "Press Enter to continue..."
}

# Function to configure backup settings
configure_settings() {
    clear
    echo -e "${BLUE}Backup System Configuration${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Configuration requires root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Configuration options:${NC}"
    echo -e "1) Basic configuration wizard"
    echo -e "2) Advanced settings"
    echo -e "3) Retention policy"
    echo -e "4) Compression settings"
    echo -e "5) Encryption setup"
    echo -e "6) Remote backup configuration"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select configuration option [0-6]: " config_choice
    
    case $config_choice in
        1)
            echo -e "${CYAN}Basic configuration wizard:${NC}"
            configure_backup_defaults
            echo -e "${GREEN}Basic configuration completed${NC}"
            ;;
        2)
            echo -e "${CYAN}Opening advanced settings...${NC}"
            ${EDITOR:-nano} /etc/backup.conf
            ;;
        3)
            echo -e "${CYAN}Retention policy configuration:${NC}"
            read -p "Daily backups to keep [7]: " daily_ret
            read -p "Weekly backups to keep [4]: " weekly_ret
            read -p "Monthly backups to keep [12]: " monthly_ret
            
            daily_ret=${daily_ret:-7}
            weekly_ret=${weekly_ret:-4}
            monthly_ret=${monthly_ret:-12}
            
            configure_retention_policy "$daily_ret" "$weekly_ret" "$monthly_ret"
            echo -e "${GREEN}Retention policy updated${NC}"
            ;;
        4)
            echo -e "${CYAN}Compression settings:${NC}"
            echo -e "1) Standard gzip"
            echo -e "2) Parallel pigz"
            echo -e "3) No compression"
            
            read -p "Select compression method [1-3]: " comp_choice
            case $comp_choice in
                1) setup_compression "gzip" ;;
                2) setup_compression "pigz" ;;
                3) setup_compression "none" ;;
            esac
            ;;
        5)
            echo -e "${CYAN}Setting up backup encryption...${NC}"
            setup_backup_encryption
            echo -e "${GREEN}Encryption configured${NC}"
            ;;
        6)
            echo -e "${CYAN}Remote backup configuration:${NC}"
            read -p "Remote server hostname or IP: " remote_host
            read -p "Remote backup path [/backups]: " remote_path
            remote_path=${remote_path:-/backups}
            
            setup_remote_backup "$remote_host" "$remote_path"
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

# Function to run immediate backup
run_immediate_backup() {
    clear
    echo -e "${BLUE}Immediate Backup Operations${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Backup operations require root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Backup options:${NC}"
    echo -e "1) Full system backup"
    echo -e "2) User data backup"
    echo -e "3) Configuration backup"
    echo -e "4) Custom directory backup"
    echo -e "5) Database backup"
    echo -e "6) Quick backup (essential files)"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select backup type [0-6]: " backup_choice
    
    case $backup_choice in
        1)
            echo -e "${YELLOW}Starting full system backup...${NC}"
            create_backup "/" "full-system" "manual"
            echo -e "${GREEN}Full system backup completed${NC}"
            ;;
        2)
            echo -e "${YELLOW}Starting user data backup...${NC}"
            create_backup "/home" "user-data" "manual"
            echo -e "${GREEN}User data backup completed${NC}"
            ;;
        3)
            echo -e "${YELLOW}Starting configuration backup...${NC}"
            backup_configuration_files
            echo -e "${GREEN}Configuration backup completed${NC}"
            ;;
        4)
            echo -e "${CYAN}Custom directory backup:${NC}"
            read -p "Enter directory path to backup: " custom_dir
            read -p "Enter backup description: " backup_desc
            
            if [[ -n "$custom_dir" && -d "$custom_dir" ]]; then
                create_backup "$custom_dir" "$backup_desc" "manual"
                echo -e "${GREEN}Custom backup completed${NC}"
            else
                echo -e "${RED}Invalid directory path${NC}"
            fi
            ;;
        5)
            echo -e "${YELLOW}Starting database backup...${NC}"
            backup_all_databases
            echo -e "${GREEN}Database backup completed${NC}"
            ;;
        6)
            echo -e "${YELLOW}Starting quick backup...${NC}"
            backup_essential_files
            echo -e "${GREEN}Quick backup completed${NC}"
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

# Function to schedule backups
schedule_backups() {
    clear
    echo -e "${BLUE}Backup Scheduling${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Scheduling requires root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Scheduling options:${NC}"
    echo -e "1) Quick schedule setup"
    echo -e "2) Custom schedule"
    echo -e "3) View current schedules"
    echo -e "4) Modify existing schedule"
    echo -e "5) Remove schedule"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select scheduling option [0-5]: " sched_choice
    
    case $sched_choice in
        1)
            echo -e "${CYAN}Quick schedule setup:${NC}"
            echo -e "This will set up daily, weekly, and monthly backups"
            read -p "Daily backup time [02:00]: " daily_time
            read -p "Weekly backup time [03:00]: " weekly_time
            read -p "Monthly backup time [04:00]: " monthly_time
            
            daily_time=${daily_time:-02:00}
            weekly_time=${weekly_time:-03:00}
            monthly_time=${monthly_time:-04:00}
            
            set_backup_schedule "daily" "$daily_time"
            set_backup_schedule "weekly" "$weekly_time"
            set_backup_schedule "monthly" "$monthly_time"
            
            echo -e "${GREEN}Quick schedule setup completed${NC}"
            ;;
        2)
            echo -e "${CYAN}Custom schedule configuration:${NC}"
            read -p "Enter backup type (daily/weekly/monthly/custom): " backup_type
            read -p "Enter time (HH:MM): " backup_time
            
            set_backup_schedule "$backup_type" "$backup_time"
            echo -e "${GREEN}Custom schedule configured${NC}"
            ;;
        3)
            echo -e "${CYAN}Current backup schedules:${NC}"
            crontab -l | grep backup || echo "No backup schedules found"
            ;;
        4)
            echo -e "${CYAN}Current schedules:${NC}"
            crontab -l | grep backup | nl
            echo
            echo -e "${YELLOW}To modify schedules, use: crontab -e${NC}"
            ;;
        5)
            echo -e "${CYAN}Remove backup schedule:${NC}"
            crontab -l | grep backup | nl
            read -p "Enter line number to remove (or 'all' for all): " remove_choice
            
            if [[ "$remove_choice" == "all" ]]; then
                # Remove all backup schedules
                temp_cron=$(mktemp)
                crontab -l | grep -v backup > "$temp_cron"
                crontab "$temp_cron"
                rm "$temp_cron"
                echo -e "${GREEN}All backup schedules removed${NC}"
            else
                echo -e "${YELLOW}Use crontab -e to remove specific schedules${NC}"
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

# Function for directory-specific backup
backup_directories() {
    clear
    echo -e "${BLUE}Directory-Specific Backup${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Backup operations require root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Common directories to backup:${NC}"
    echo -e "1) Web files (/var/www)"
    echo -e "2) User homes (/home)"
    echo -e "3) System configuration (/etc)"
    echo -e "4) Log files (/var/log)"
    echo -e "5) Application data (/opt)"
    echo -e "6) Custom directory"
    echo -e "7) Multiple directories"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select directory option [0-7]: " dir_choice
    
    case $dir_choice in
        1)
            if [[ -d /var/www ]]; then
                create_backup "/var/www" "web-files" "manual"
                echo -e "${GREEN}Web files backup completed${NC}"
            else
                echo -e "${RED}/var/www directory not found${NC}"
            fi
            ;;
        2)
            create_backup "/home" "user-homes" "manual"
            echo -e "${GREEN}User homes backup completed${NC}"
            ;;
        3)
            create_backup "/etc" "system-config" "manual"
            echo -e "${GREEN}System configuration backup completed${NC}"
            ;;
        4)
            create_backup "/var/log" "log-files" "manual"
            echo -e "${GREEN}Log files backup completed${NC}"
            ;;
        5)
            if [[ -d /opt ]]; then
                create_backup "/opt" "application-data" "manual"
                echo -e "${GREEN}Application data backup completed${NC}"
            else
                echo -e "${RED}/opt directory not found${NC}"
            fi
            ;;
        6)
            read -p "Enter directory path: " custom_path
            read -p "Enter backup description: " custom_desc
            
            if [[ -n "$custom_path" && -d "$custom_path" ]]; then
                create_backup "$custom_path" "$custom_desc" "manual"
                echo -e "${GREEN}Custom directory backup completed${NC}"
            else
                echo -e "${RED}Invalid directory path${NC}"
            fi
            ;;
        7)
            echo -e "${CYAN}Multiple directory backup:${NC}"
            echo -e "Enter directories to backup (one per line, empty line to finish):"
            dirs_to_backup=()
            while true; do
                read -p "Directory: " dir_path
                if [[ -z "$dir_path" ]]; then
                    break
                fi
                if [[ -d "$dir_path" ]]; then
                    dirs_to_backup+=("$dir_path")
                else
                    echo -e "${RED}Directory $dir_path not found${NC}"
                fi
            done
            
            if [[ ${#dirs_to_backup[@]} -gt 0 ]]; then
                for dir in "${dirs_to_backup[@]}"; do
                    echo -e "${CYAN}Backing up: $dir${NC}"
                    create_backup "$dir" "$(basename $dir)" "manual"
                done
                echo -e "${GREEN}Multiple directory backup completed${NC}"
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

# Function for database operations
database_operations() {
    "$SCRIPT_DIR/maintain.sh"
}

# Function for restore operations
restore_operations() {
    "$SCRIPT_DIR/maintain.sh"
}

# Function to list backups
list_backups() {
    clear
    echo -e "${BLUE}Available Backups${NC}"
    echo
    
    echo -e "${CYAN}Daily Backups:${NC}"
    if [[ -d /root/backups/daily ]]; then
        ls -lah /root/backups/daily/ | head -10
    else
        echo "No daily backups found"
    fi
    
    echo
    echo -e "${CYAN}Weekly Backups:${NC}"
    if [[ -d /root/backups/weekly ]]; then
        ls -lah /root/backups/weekly/ | head -5
    else
        echo "No weekly backups found"
    fi
    
    echo
    echo -e "${CYAN}Monthly Backups:${NC}"
    if [[ -d /root/backups/monthly ]]; then
        ls -lah /root/backups/monthly/ | head -5
    else
        echo "No monthly backups found"
    fi
    
    echo
    echo -e "${CYAN}Storage Summary:${NC}"
    if [[ -d /root/backups ]]; then
        du -sh /root/backups/* 2>/dev/null | sort -hr
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Function for test restore
test_restore() {
    clear
    echo -e "${BLUE}Test Restore Operations${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Restore operations require root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Available backups for testing:${NC}"
    find /root/backups -name "*.tar.gz" -mtime -7 | head -10
    echo
    
    read -p "Enter backup file path for testing: " test_backup_file
    
    if [[ -n "$test_backup_file" && -f "$test_backup_file" ]]; then
        echo -e "${YELLOW}Starting test restore...${NC}"
        test_restore_backup "$test_backup_file"
        echo -e "${GREEN}Test restore completed${NC}"
    else
        echo -e "${RED}Backup file not found${NC}"
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Function for emergency restore wizard
emergency_restore() {
    clear
    echo -e "${RED}EMERGENCY RESTORE WIZARD${NC}"
    echo -e "${YELLOW}⚠ This will restore data and may overwrite current files ⚠${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Emergency restore requires root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Emergency restore options:${NC}"
    echo -e "1) System configuration restore"
    echo -e "2) User data restore"
    echo -e "3) Database restore"
    echo -e "4) Full system restore"
    echo -e "5) Custom file restore"
    echo -e "0) Cancel and return"
    echo
    
    read -p "Select emergency restore type [0-5]: " emergency_choice
    
    case $emergency_choice in
        1)
            echo -e "${RED}WARNING: This will overwrite current system configuration!${NC}"
            read -p "Type 'RESTORE' to confirm: " confirm
            if [[ "$confirm" == "RESTORE" ]]; then
                restore_system_configuration
            else
                echo -e "${GREEN}Restore cancelled${NC}"
            fi
            ;;
        2)
            echo -e "${CYAN}User data emergency restore:${NC}"
            read -p "Enter username to restore: " username
            if [[ -n "$username" ]]; then
                restore_user_data "$username"
            fi
            ;;
        3)
            echo -e "${CYAN}Database emergency restore:${NC}"
            restore_database_emergency
            ;;
        4)
            echo -e "${RED}WARNING: Full system restore will overwrite ALL data!${NC}"
            read -p "Type 'EMERGENCY_RESTORE' to confirm: " confirm
            if [[ "$confirm" == "EMERGENCY_RESTORE" ]]; then
                read -p "Enter full system backup file: " full_backup
                if [[ -n "$full_backup" ]]; then
                    restore_full_system "$full_backup"
                fi
            else
                echo -e "${GREEN}Emergency restore cancelled${NC}"
            fi
            ;;
        5)
            echo -e "${CYAN}Custom file restore:${NC}"
            read -p "Enter backup file: " backup_file
            read -p "Enter files to restore (space-separated): " restore_files
            read -p "Enter destination path: " dest_path
            
            if [[ -n "$backup_file" && -n "$restore_files" && -n "$dest_path" ]]; then
                restore_selective "$backup_file" "$dest_path" "$restore_files"
            fi
            ;;
        0)
            echo -e "${GREEN}Emergency restore cancelled${NC}"
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function to check backup status
check_status() {
    echo -e "${YELLOW}Checking comprehensive backup status...${NC}"
    echo
    
    # Generate backup report
    generate_backup_report
    
    echo
    read -p "Press Enter to continue..."
}

# Function for verification
verify_integrity() {
    echo -e "${YELLOW}Verifying backup integrity...${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Verification requires root privileges${NC}"
        sleep 2
        return
    fi
    
    verify_all_backups
    
    echo
    read -p "Press Enter to continue..."
}

# Function to view logs
view_logs() {
    "$SCRIPT_DIR/maintain.sh"
}

# Function for performance monitoring
performance_monitor() {
    "$SCRIPT_DIR/maintain.sh"
}

# Function for storage analysis
storage_analysis() {
    clear
    echo -e "${BLUE}Storage Analysis${NC}"
    echo
    
    echo -e "${CYAN}Backup Storage Breakdown:${NC}"
    if [[ -d /root/backups ]]; then
        echo -e "${CYAN}Total backup storage:${NC}"
        du -sh /root/backups
        echo
        
        echo -e "${CYAN}Storage by backup type:${NC}"
        for backup_type in daily weekly monthly; do
            if [[ -d "/root/backups/$backup_type" ]]; then
                size=$(du -sh "/root/backups/$backup_type" | cut -f1)
                count=$(ls -1 "/root/backups/$backup_type" 2>/dev/null | wc -l)
                echo -e "${CYAN}  $backup_type: $size ($count files)${NC}"
            fi
        done
        
        echo
        echo -e "${CYAN}Largest backup files:${NC}"
        find /root/backups -type f -exec ls -lh {} \; | sort -k5 -hr | head -10
        
        echo
        echo -e "${CYAN}Disk space information:${NC}"
        df -h /root/backups
    else
        echo -e "${RED}Backup directory not found${NC}"
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Function for cleanup operations
cleanup_old() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Cleanup requires root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${YELLOW}Cleaning up old backups...${NC}"
    cleanup_old_backups
    echo -e "${GREEN}Cleanup completed${NC}"
    echo
    read -p "Press Enter to continue..."
}

# Function for remote sync
remote_sync() {
    "$SCRIPT_DIR/maintain.sh"
}

# Function for archive management
archive_management() {
    clear
    echo -e "${BLUE}Archive Management${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Archive management requires root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Archive options:${NC}"
    echo -e "1) Create archive from old backups"
    echo -e "2) List archived backups"
    echo -e "3) Restore from archive"
    echo -e "4) Archive to external storage"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select archive option [0-4]: " archive_choice
    
    case $archive_choice in
        1)
            read -p "Archive backups older than (days) [90]: " archive_days
            archive_days=${archive_days:-90}
            
            mkdir -p /root/backups/archive
            find /root/backups -name "*.tar.gz" -mtime +$archive_days -exec mv {} /root/backups/archive/ \;
            echo -e "${GREEN}Backups archived${NC}"
            ;;
        2)
            echo -e "${CYAN}Archived backups:${NC}"
            if [[ -d /root/backups/archive ]]; then
                ls -lah /root/backups/archive/
            else
                echo "No archived backups found"
            fi
            ;;
        3)
            echo -e "${CYAN}Available archived backups:${NC}"
            ls /root/backups/archive/ 2>/dev/null | head -10
            echo
            read -p "Enter archived backup filename: " archive_file
            
            if [[ -n "$archive_file" && -f "/root/backups/archive/$archive_file" ]]; then
                mv "/root/backups/archive/$archive_file" /root/backups/daily/
                echo -e "${GREEN}Backup restored from archive${NC}"
            fi
            ;;
        4)
            read -p "Enter external storage path: " ext_storage
            if [[ -n "$ext_storage" && -d "$ext_storage" ]]; then
                cp /root/backups/archive/* "$ext_storage/" 2>/dev/null
                echo -e "${GREEN}Archive copied to external storage${NC}"
            else
                echo -e "${RED}Invalid external storage path${NC}"
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

# Function for encryption management
encryption_management() {
    clear
    echo -e "${BLUE}Backup Encryption Management${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Encryption management requires root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Encryption options:${NC}"
    echo -e "1) Setup backup encryption"
    echo -e "2) Change encryption key"
    echo -e "3) Decrypt backup file"
    echo -e "4) Check encryption status"
    echo -e "5) Disable encryption"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select encryption option [0-5]: " encrypt_choice
    
    case $encrypt_choice in
        1)
            setup_backup_encryption
            echo -e "${GREEN}Backup encryption configured${NC}"
            ;;
        2)
            echo -e "${YELLOW}Changing encryption key...${NC}"
            setup_backup_encryption
            echo -e "${GREEN}Encryption key updated${NC}"
            ;;
        3)
            read -p "Enter encrypted backup file path: " encrypted_file
            if [[ -n "$encrypted_file" && -f "$encrypted_file" ]]; then
                decrypt_backup "$encrypted_file"
            else
                echo -e "${RED}Encrypted backup file not found${NC}"
            fi
            ;;
        4)
            if [[ -f /etc/backup-encryption.key ]]; then
                echo -e "${GREEN}✓ Backup encryption is enabled${NC}"
                echo -e "${CYAN}Key file: /etc/backup-encryption.key${NC}"
            else
                echo -e "${YELLOW}Backup encryption is not configured${NC}"
            fi
            ;;
        5)
            read -p "Are you sure you want to disable encryption? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                rm -f /etc/backup-encryption.key
                echo -e "${YELLOW}Backup encryption disabled${NC}"
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

# Function for compression settings
compression_settings() {
    clear
    echo -e "${BLUE}Backup Compression Settings${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Compression settings require root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Current compression setting:${NC}"
    if [[ -f /etc/backup.conf ]]; then
        grep COMPRESSION /etc/backup.conf || echo "No compression setting found"
    fi
    
    echo
    echo -e "${CYAN}Compression options:${NC}"
    echo -e "1) Standard gzip compression"
    echo -e "2) High-speed pigz compression (parallel)"
    echo -e "3) High compression (slower, smaller files)"
    echo -e "4) No compression"
    echo -e "5) Test compression methods"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select compression option [0-5]: " comp_choice
    
    case $comp_choice in
        1)
            setup_compression "gzip"
            echo -e "${GREEN}Standard compression configured${NC}"
            ;;
        2)
            setup_compression "pigz"
            echo -e "${GREEN}Parallel compression configured${NC}"
            ;;
        3)
            setup_compression "gzip-9"
            echo -e "${GREEN}High compression configured${NC}"
            ;;
        4)
            setup_compression "none"
            echo -e "${YELLOW}Compression disabled${NC}"
            ;;
        5)
            echo -e "${YELLOW}Testing compression methods...${NC}"
            test_compression_methods
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

# Function for custom backup scripts
custom_scripts() {
    clear
    echo -e "${BLUE}Custom Backup Scripts${NC}"
    echo
    
    echo -e "${CYAN}Custom script options:${NC}"
    echo -e "1) Create pre-backup script"
    echo -e "2) Create post-backup script"
    echo -e "3) View existing scripts"
    echo -e "4) Edit custom script"
    echo -e "5) Test custom script"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select script option [0-5]: " script_choice
    
    case $script_choice in
        1)
            echo -e "${CYAN}Creating pre-backup script...${NC}"
            echo -e "${YELLOW}This script will run before each backup${NC}"
            read -p "Enter script name: " script_name
            
            if [[ -n "$script_name" ]]; then
                create_custom_backup_script "pre" "$script_name"
                echo -e "${GREEN}Pre-backup script created${NC}"
            fi
            ;;
        2)
            echo -e "${CYAN}Creating post-backup script...${NC}"
            echo -e "${YELLOW}This script will run after each backup${NC}"
            read -p "Enter script name: " script_name
            
            if [[ -n "$script_name" ]]; then
                create_custom_backup_script "post" "$script_name"
                echo -e "${GREEN}Post-backup script created${NC}"
            fi
            ;;
        3)
            echo -e "${CYAN}Existing custom scripts:${NC}"
            find /usr/local/bin -name "backup-custom-*" -ls 2>/dev/null || echo "No custom scripts found"
            ;;
        4)
            echo -e "${CYAN}Available scripts:${NC}"
            find /usr/local/bin -name "backup-custom-*" | nl
            read -p "Enter script path to edit: " script_path
            
            if [[ -n "$script_path" && -f "$script_path" ]]; then
                ${EDITOR:-nano} "$script_path"
            fi
            ;;
        5)
            read -p "Enter script path to test: " test_script
            if [[ -n "$test_script" && -f "$test_script" ]]; then
                echo -e "${YELLOW}Testing script...${NC}"
                bash "$test_script"
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

# Function for system maintenance
system_maintenance() {
    "$SCRIPT_DIR/maintain.sh"
}

# Main menu loop
while true; do
    show_main_menu
    read -p "Select an option [0-23]: " choice
    
    case $choice in
        1) install_system ;;
        2) update_system ;;
        3) configure_settings ;;
        4) run_immediate_backup ;;
        5) schedule_backups ;;
        6) backup_directories ;;
        7) database_operations ;;
        8) restore_operations ;;
        9) list_backups ;;
        10) test_restore ;;
        11) emergency_restore ;;
        12) check_status ;;
        13) verify_integrity ;;
        14) view_logs ;;
        15) performance_monitor ;;
        16) storage_analysis ;;
        17) cleanup_old ;;
        18) remote_sync ;;
        19) archive_management ;;
        20) encryption_management ;;
        21) compression_settings ;;
        22) custom_scripts ;;
        23) system_maintenance ;;
        0)
            echo -e "${YELLOW}Thank you for using Backup System Manager!${NC}"
            echo -e "${CYAN}Remember to regularly verify your backups.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 2
            ;;
    esac
done
