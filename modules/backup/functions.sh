#!/bin/bash
# Backup Functions Library
# Reusable functions for backup and restore operations

#===========================================
# BACKUP CONFIGURATION FUNCTIONS
#===========================================

configure_backup_defaults() {
    echo "[INFO] Configuring backup defaults..."
    
    # Create backup directories
    mkdir -p /root/backups
    mkdir -p /root/backups/daily
    mkdir -p /root/backups/weekly
    mkdir -p /root/backups/monthly
    mkdir -p /root/backups/config
    
    # Set backup retention policies
    export DAILY_RETENTION=7     # Keep 7 daily backups
    export WEEKLY_RETENTION=4    # Keep 4 weekly backups
    export MONTHLY_RETENTION=12  # Keep 12 monthly backups
    
    # Create backup configuration file
    cat > /etc/backup.conf << 'EOF'
# Backup Configuration
BACKUP_BASE_DIR="/root/backups"
DAILY_RETENTION=7
WEEKLY_RETENTION=4
MONTHLY_RETENTION=12
COMPRESSION="gzip"
EXCLUDE_PATTERNS="/tmp /proc /sys /dev /run /mnt /media"
EOF
    
    echo "[SUCCESS] Backup configuration completed"
}

set_backup_schedule() {
    local schedule_type="$1"  # daily, weekly, monthly
    local time="$2"           # e.g., "02:00" for 2 AM
    
    if [[ -z "$schedule_type" || -z "$time" ]]; then
        echo "[ERROR] Schedule type and time parameters required"
        echo "Usage: set_backup_schedule <daily|weekly|monthly> <HH:MM>"
        return 1
    fi
    
    echo "[INFO] Setting up $schedule_type backup at $time"
    
    local hour=$(echo "$time" | cut -d: -f1)
    local minute=$(echo "$time" | cut -d: -f2)
    
    case "$schedule_type" in
        "daily")
            # Remove existing daily backup cron
            crontab -l 2>/dev/null | grep -v "daily_backup" | crontab -
            # Add new daily backup cron
            (crontab -l 2>/dev/null; echo "$minute $hour * * * /usr/local/bin/backup.sh daily") | crontab -
            ;;
        "weekly")
            # Weekly backup on Sunday
            crontab -l 2>/dev/null | grep -v "weekly_backup" | crontab -
            (crontab -l 2>/dev/null; echo "$minute $hour * * 0 /usr/local/bin/backup.sh weekly") | crontab -
            ;;
        "monthly")
            # Monthly backup on 1st day of month
            crontab -l 2>/dev/null | grep -v "monthly_backup" | crontab -
            (crontab -l 2>/dev/null; echo "$minute $hour 1 * * /usr/local/bin/backup.sh monthly") | crontab -
            ;;
        *)
            echo "[ERROR] Invalid schedule type. Use: daily, weekly, or monthly"
            return 1
            ;;
    esac
    
    echo "[SUCCESS] $schedule_type backup scheduled for $time"
}

#===========================================
# FILE SYSTEM BACKUP FUNCTIONS
#===========================================

backup_directory() {
    local source_dir="$1"
    local backup_name="${2:-$(basename $source_dir)-$(date +%Y%m%d_%H%M%S)}"
    local destination="${3:-/root/backups}"
    
    if [[ -z "$source_dir" || ! -d "$source_dir" ]]; then
        echo "[ERROR] Source directory parameter required and must exist"
        return 1
    fi
    
    echo "[INFO] Backing up directory: $source_dir"
    
    # Create destination directory if it doesn't exist
    mkdir -p "$destination"
    
    # Create backup with compression
    tar -czf "$destination/$backup_name.tar.gz" -C "$(dirname $source_dir)" "$(basename $source_dir)" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        local backup_size=$(du -h "$destination/$backup_name.tar.gz" | cut -f1)
        echo "[SUCCESS] Directory backed up: $destination/$backup_name.tar.gz ($backup_size)"
    else
        echo "[ERROR] Backup failed"
        return 1
    fi
}

backup_files() {
    local file_list="$1"
    local backup_name="${2:-files-backup-$(date +%Y%m%d_%H%M%S)}"
    local destination="${3:-/root/backups}"
    
    if [[ -z "$file_list" ]]; then
        echo "[ERROR] File list parameter required"
        return 1
    fi
    
    echo "[INFO] Backing up specified files..."
    
    # Create destination directory
    mkdir -p "$destination"
    
    # Create backup archive
    tar -czf "$destination/$backup_name.tar.gz" $file_list 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        local backup_size=$(du -h "$destination/$backup_name.tar.gz" | cut -f1)
        echo "[SUCCESS] Files backed up: $destination/$backup_name.tar.gz ($backup_size)"
    else
        echo "[ERROR] Backup failed"
        return 1
    fi
}

backup_full_system() {
    local backup_name="${1:-system-full-$(date +%Y%m%d_%H%M%S)}"
    local destination="${2:-/root/backups}"
    
    echo "[INFO] Performing full system backup..."
    echo "[WARNING] This may take a long time and use significant disk space"
    
    # Create destination directory
    mkdir -p "$destination"
    
    # Perform full system backup excluding standard system directories
    tar --exclude='/proc' --exclude='/tmp' --exclude='/sys' --exclude='/dev' \
        --exclude='/run' --exclude='/mnt' --exclude='/media' --exclude="$destination" \
        --exclude='/var/cache' --exclude='/var/tmp' \
        -czf "$destination/$backup_name.tar.gz" / 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        local backup_size=$(du -h "$destination/$backup_name.tar.gz" | cut -f1)
        echo "[SUCCESS] Full system backup completed: $destination/$backup_name.tar.gz ($backup_size)"
    else
        echo "[ERROR] Full system backup failed"
        return 1
    fi
}

#===========================================
# DATABASE BACKUP FUNCTIONS
#===========================================

backup_mysql_all() {
    local backup_name="${1:-mysql-all-$(date +%Y%m%d_%H%M%S)}"
    local destination="${2:-/root/backups}"
    
    echo "[INFO] Backing up all MySQL databases..."
    
    # Check if MySQL is running
    if ! systemctl is-active --quiet mysql; then
        echo "[ERROR] MySQL service is not running"
        return 1
    fi
    
    mkdir -p "$destination"
    
    # Backup all databases
    mysqldump -u root -padmin123 --all-databases > "$destination/$backup_name.sql" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        # Compress the backup
        gzip "$destination/$backup_name.sql"
        local backup_size=$(du -h "$destination/$backup_name.sql.gz" | cut -f1)
        echo "[SUCCESS] MySQL backup completed: $destination/$backup_name.sql.gz ($backup_size)"
    else
        echo "[ERROR] MySQL backup failed"
        return 1
    fi
}

backup_postgresql_all() {
    local backup_name="${1:-postgresql-all-$(date +%Y%m%d_%H%M%S)}"
    local destination="${2:-/root/backups}"
    
    echo "[INFO] Backing up all PostgreSQL databases..."
    
    # Check if PostgreSQL is running
    if ! systemctl is-active --quiet postgresql; then
        echo "[ERROR] PostgreSQL service is not running"
        return 1
    fi
    
    mkdir -p "$destination"
    
    # Backup all databases
    sudo -u postgres pg_dumpall > "$destination/$backup_name.sql" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        # Compress the backup
        gzip "$destination/$backup_name.sql"
        local backup_size=$(du -h "$destination/$backup_name.sql.gz" | cut -f1)
        echo "[SUCCESS] PostgreSQL backup completed: $destination/$backup_name.sql.gz ($backup_size)"
    else
        echo "[ERROR] PostgreSQL backup failed"
        return 1
    fi
}

#===========================================
# CONFIGURATION BACKUP FUNCTIONS
#===========================================

backup_web_configs() {
    local backup_name="${1:-web-configs-$(date +%Y%m%d_%H%M%S)}"
    local destination="${2:-/root/backups/config}"
    
    echo "[INFO] Backing up web server configurations..."
    
    mkdir -p "$destination"
    
    # Backup Apache configurations
    if [[ -d /etc/apache2 ]]; then
        tar -czf "$destination/$backup_name-apache.tar.gz" -C /etc apache2 2>/dev/null
        echo "[INFO] Apache configuration backed up"
    fi
    
    # Backup Nginx configurations
    if [[ -d /etc/nginx ]]; then
        tar -czf "$destination/$backup_name-nginx.tar.gz" -C /etc nginx 2>/dev/null
        echo "[INFO] Nginx configuration backed up"
    fi
    
    # Backup web directories
    if [[ -d /var/www ]]; then
        tar -czf "$destination/$backup_name-www.tar.gz" -C /var www 2>/dev/null
        echo "[INFO] Web directories backed up"
    fi
    
    echo "[SUCCESS] Web configurations backup completed"
}

backup_mail_configs() {
    local backup_name="${1:-mail-configs-$(date +%Y%m%d_%H%M%S)}"
    local destination="${2:-/root/backups/config}"
    
    echo "[INFO] Backing up mail server configurations..."
    
    mkdir -p "$destination"
    
    # Backup mail configurations
    local configs=("/etc/postfix" "/etc/dovecot" "/etc/opendkim" "/etc/aliases")
    
    for config in "${configs[@]}"; do
        if [[ -e "$config" ]]; then
            local config_name=$(basename "$config")
            tar -czf "$destination/$backup_name-$config_name.tar.gz" -C /etc "$config_name" 2>/dev/null
            echo "[INFO] $config_name configuration backed up"
        fi
    done
    
    echo "[SUCCESS] Mail configurations backup completed"
}

backup_ssl_certs() {
    local backup_name="${1:-ssl-certs-$(date +%Y%m%d_%H%M%S)}"
    local destination="${2:-/root/backups/config}"
    
    echo "[INFO] Backing up SSL certificates..."
    
    mkdir -p "$destination"
    
    # Backup SSL directories
    local ssl_dirs=("/etc/ssl" "/etc/letsencrypt")
    
    for ssl_dir in "${ssl_dirs[@]}"; do
        if [[ -d "$ssl_dir" ]]; then
            local dir_name=$(basename "$ssl_dir")
            tar -czf "$destination/$backup_name-$dir_name.tar.gz" -C /etc "$dir_name" 2>/dev/null
            echo "[INFO] $dir_name backed up"
        fi
    done
    
    echo "[SUCCESS] SSL certificates backup completed"
}

backup_system_configs() {
    local backup_name="${1:-system-configs-$(date +%Y%m%d_%H%M%S)}"
    local destination="${2:-/root/backups/config}"
    
    echo "[INFO] Backing up system configurations..."
    
    mkdir -p "$destination"
    
    # Important configuration directories and files
    local configs=(
        "/etc/passwd" "/etc/shadow" "/etc/group" "/etc/sudoers"
        "/etc/ssh" "/etc/cron.d" "/etc/systemd"
        "/etc/hosts" "/etc/fstab" "/etc/network"
    )
    
    # Create temporary directory for configs
    local temp_dir="/tmp/system-configs-$$"
    mkdir -p "$temp_dir"
    
    for config in "${configs[@]}"; do
        if [[ -e "$config" ]]; then
            cp -r "$config" "$temp_dir/" 2>/dev/null
        fi
    done
    
    # Create archive
    tar -czf "$destination/$backup_name.tar.gz" -C "$temp_dir" . 2>/dev/null
    rm -rf "$temp_dir"
    
    local backup_size=$(du -h "$destination/$backup_name.tar.gz" | cut -f1)
    echo "[SUCCESS] System configurations backed up: $destination/$backup_name.tar.gz ($backup_size)"
}

#===========================================
# RESTORE FUNCTIONS
#===========================================

restore_backup() {
    local backup_file="$1"
    local destination="${2:-/}"
    
    if [[ -z "$backup_file" || ! -f "$backup_file" ]]; then
        echo "[ERROR] Backup file parameter required and must exist"
        return 1
    fi
    
    echo "[WARNING] This will restore from: $backup_file"
    echo "[WARNING] Destination: $destination"
    read -p "Are you sure? This may overwrite existing files! (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "[INFO] Restoring backup..."
        
        # Handle different compression formats
        if [[ "$backup_file" == *.tar.gz ]]; then
            tar -xzf "$backup_file" -C "$destination"
        elif [[ "$backup_file" == *.tar ]]; then
            tar -xf "$backup_file" -C "$destination"
        elif [[ "$backup_file" == *.sql.gz ]]; then
            echo "[INFO] SQL backup detected. Please specify database type for restore."
            return 1
        else
            echo "[ERROR] Unsupported backup format"
            return 1
        fi
        
        if [[ $? -eq 0 ]]; then
            echo "[SUCCESS] Backup restored successfully"
        else
            echo "[ERROR] Restore failed"
            return 1
        fi
    else
        echo "[INFO] Restore cancelled"
    fi
}

restore_mysql_backup() {
    local backup_file="$1"
    local database="${2:-all}"
    
    if [[ -z "$backup_file" || ! -f "$backup_file" ]]; then
        echo "[ERROR] Backup file parameter required and must exist"
        return 1
    fi
    
    echo "[WARNING] This will restore MySQL from: $backup_file"
    read -p "Are you sure? This may overwrite existing data! (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "[INFO] Restoring MySQL backup..."
        
        # Handle compressed files
        if [[ "$backup_file" == *.gz ]]; then
            if [[ "$database" == "all" ]]; then
                zcat "$backup_file" | mysql -u root -padmin123
            else
                zcat "$backup_file" | mysql -u root -padmin123 "$database"
            fi
        else
            if [[ "$database" == "all" ]]; then
                mysql -u root -padmin123 < "$backup_file"
            else
                mysql -u root -padmin123 "$database" < "$backup_file"
            fi
        fi
        
        if [[ $? -eq 0 ]]; then
            echo "[SUCCESS] MySQL backup restored successfully"
        else
            echo "[ERROR] MySQL restore failed"
            return 1
        fi
    else
        echo "[INFO] Restore cancelled"
    fi
}

restore_postgresql_backup() {
    local backup_file="$1"
    local database="${2:-all}"
    
    if [[ -z "$backup_file" || ! -f "$backup_file" ]]; then
        echo "[ERROR] Backup file parameter required and must exist"
        return 1
    fi
    
    echo "[WARNING] This will restore PostgreSQL from: $backup_file"
    read -p "Are you sure? This may overwrite existing data! (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "[INFO] Restoring PostgreSQL backup..."
        
        # Handle compressed files
        if [[ "$backup_file" == *.gz ]]; then
            if [[ "$database" == "all" ]]; then
                zcat "$backup_file" | sudo -u postgres psql
            else
                zcat "$backup_file" | sudo -u postgres psql "$database"
            fi
        else
            if [[ "$database" == "all" ]]; then
                sudo -u postgres psql < "$backup_file"
            else
                sudo -u postgres psql "$database" < "$backup_file"
            fi
        fi
        
        if [[ $? -eq 0 ]]; then
            echo "[SUCCESS] PostgreSQL backup restored successfully"
        else
            echo "[ERROR] PostgreSQL restore failed"
            return 1
        fi
    else
        echo "[INFO] Restore cancelled"
    fi
}

#===========================================
# BACKUP MANAGEMENT FUNCTIONS
#===========================================

list_backups() {
    local backup_dir="${1:-/root/backups}"
    
    echo "[INFO] Available backups in: $backup_dir"
    echo "==========================================="
    
    if [[ -d "$backup_dir" ]]; then
        find "$backup_dir" -name "*.tar.gz" -o -name "*.sql.gz" -o -name "*.tar" | sort | while read backup; do
            local size=$(du -h "$backup" | cut -f1)
            local date=$(stat -c %y "$backup" | cut -d. -f1)
            echo "$(basename $backup) - $size - $date"
        done
    else
        echo "Backup directory does not exist"
    fi
}

cleanup_old_backups() {
    local backup_dir="${1:-/root/backups}"
    local days="${2:-30}"
    
    echo "[INFO] Cleaning up backups older than $days days in: $backup_dir"
    
    if [[ -d "$backup_dir" ]]; then
        local count=$(find "$backup_dir" -name "*.tar.gz" -o -name "*.sql.gz" -o -name "*.tar" -mtime +$days | wc -l)
        
        if [[ $count -gt 0 ]]; then
            echo "[INFO] Found $count old backup(s) to remove"
            find "$backup_dir" -name "*.tar.gz" -o -name "*.sql.gz" -o -name "*.tar" -mtime +$days -delete
            echo "[SUCCESS] Old backups cleaned up"
        else
            echo "[INFO] No old backups found"
        fi
    else
        echo "[ERROR] Backup directory does not exist"
    fi
}

verify_backup() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" || ! -f "$backup_file" ]]; then
        echo "[ERROR] Backup file parameter required and must exist"
        return 1
    fi
    
    echo "[INFO] Verifying backup: $backup_file"
    
    if [[ "$backup_file" == *.tar.gz ]]; then
        tar -tzf "$backup_file" >/dev/null 2>&1
    elif [[ "$backup_file" == *.tar ]]; then
        tar -tf "$backup_file" >/dev/null 2>&1
    elif [[ "$backup_file" == *.sql.gz ]]; then
        zcat "$backup_file" | head -1 | grep -q "^--" 2>/dev/null
    else
        echo "[ERROR] Unsupported backup format for verification"
        return 1
    fi
    
    if [[ $? -eq 0 ]]; then
        echo "[SUCCESS] Backup verification passed"
    else
        echo "[ERROR] Backup verification failed - file may be corrupted"
        return 1
    fi
}

#===========================================
# AUTOMATED BACKUP FUNCTIONS
#===========================================

run_scheduled_backup() {
    local backup_type="${1:-daily}"  # daily, weekly, monthly
    
    echo "[INFO] Running $backup_type backup..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="/root/backups/$backup_type"
    
    mkdir -p "$backup_dir"
    
    # Perform different types of backups based on schedule
    case "$backup_type" in
        "daily")
            # Daily: System configs and databases
            backup_system_configs "system-configs-daily-$timestamp" "$backup_dir"
            
            if systemctl is-active --quiet mysql; then
                backup_mysql_all "mysql-daily-$timestamp" "$backup_dir"
            fi
            
            if systemctl is-active --quiet postgresql; then
                backup_postgresql_all "postgresql-daily-$timestamp" "$backup_dir"
            fi
            
            # Cleanup old daily backups (keep 7 days)
            find "$backup_dir" -name "*.tar.gz" -o -name "*.sql.gz" -mtime +7 -delete
            ;;
            
        "weekly")
            # Weekly: Full web and mail configs
            backup_web_configs "web-configs-weekly-$timestamp" "$backup_dir"
            backup_mail_configs "mail-configs-weekly-$timestamp" "$backup_dir"
            backup_ssl_certs "ssl-certs-weekly-$timestamp" "$backup_dir"
            
            # Cleanup old weekly backups (keep 4 weeks)
            find "$backup_dir" -name "*.tar.gz" -mtime +28 -delete
            ;;
            
        "monthly")
            # Monthly: Full system backup
            backup_full_system "system-full-monthly-$timestamp" "$backup_dir"
            
            # Cleanup old monthly backups (keep 12 months)
            find "$backup_dir" -name "*.tar.gz" -mtime +365 -delete
            ;;
    esac
    
    echo "[SUCCESS] $backup_type backup completed"
}

#===========================================
# REMOTE BACKUP FUNCTIONS
#===========================================

setup_remote_backup() {
    local remote_host="$1"
    local remote_path="$2"
    local ssh_key="${3:-/root/.ssh/id_rsa}"
    
    if [[ -z "$remote_host" || -z "$remote_path" ]]; then
        echo "[ERROR] Remote host and path parameters required"
        return 1
    fi
    
    echo "[INFO] Setting up remote backup to: $remote_host:$remote_path"
    
    # Generate SSH key if it doesn't exist
    if [[ ! -f "$ssh_key" ]]; then
        ssh-keygen -t rsa -b 4096 -f "$ssh_key" -N ""
        echo "[INFO] SSH key generated: $ssh_key"
        echo "[INFO] Copy this public key to the remote server:"
        cat "$ssh_key.pub"
    fi
    
    # Test connection
    if ssh -i "$ssh_key" -o ConnectTimeout=10 "$remote_host" "mkdir -p $remote_path" 2>/dev/null; then
        echo "[SUCCESS] Remote backup location configured"
        
        # Save configuration
        cat > /etc/remote-backup.conf << EOF
REMOTE_HOST="$remote_host"
REMOTE_PATH="$remote_path"
SSH_KEY="$ssh_key"
EOF
    else
        echo "[ERROR] Failed to connect to remote server"
        echo "Make sure SSH key is authorized on the remote server"
        return 1
    fi
}

sync_backup_remote() {
    local local_backup_dir="${1:-/root/backups}"
    
    # Load remote backup configuration
    if [[ -f /etc/remote-backup.conf ]]; then
        source /etc/remote-backup.conf
    else
        echo "[ERROR] Remote backup not configured. Run setup_remote_backup first."
        return 1
    fi
    
    echo "[INFO] Syncing backups to remote server..."
    
    # Sync backups using rsync
    rsync -avz --delete -e "ssh -i $SSH_KEY" "$local_backup_dir/" "$REMOTE_HOST:$REMOTE_PATH/"
    
    if [[ $? -eq 0 ]]; then
        echo "[SUCCESS] Backups synced to remote server"
    else
        echo "[ERROR] Remote backup sync failed"
        return 1
    fi
}

#===========================================
# BACKUP MODULE MAIN FUNCTIONS
#===========================================

install_backup_module() {
    print_header "Installing Backup Module"
    
    # Configure backup defaults
    if configure_backup_defaults; then
        print_success "Backup module installed successfully"
        return 0
    else
        print_error "Backup module installation failed"
        return 1
    fi
}

check_backup_module() {
    print_header "Checking Backup Module"
    
    local config_status=0
    local directory_status=0
    local cron_status=0
    
    # Check backup configuration
    if [[ -f /etc/backup.conf ]]; then
        print_success "Backup configuration file exists"
        config_status=1
    else
        print_error "Backup configuration file not found"
    fi
    
    # Check backup directories
    if [[ -d /root/backups ]]; then
        print_success "Backup directory structure exists"
        directory_status=1
    else
        print_error "Backup directory structure not found"
    fi
    
    # Check for scheduled backups
    if crontab -l 2>/dev/null | grep -q "backup"; then
        print_success "Scheduled backups found"
        cron_status=1
    else
        print_info "No scheduled backups configured"
    fi
    
    if [[ $config_status -eq 1 && $directory_status -eq 1 ]]; then
        print_success "Backup module is operational"
        return 0
    else
        print_error "Backup module is not fully operational"
        return 1
    fi
}

update_backup_module() {
    print_header "Updating Backup Module"
    
    # Update backup tools
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y tar gzip rsync >/dev/null 2>&1
    
    # Clean up old backups
    cleanup_old_backups
    
    print_success "Backup module updated successfully"
    return 0
}

check_backup_update() {
    print_header "Checking Backup Module Updates"
    
    # Check for available updates
    apt-get update >/dev/null 2>&1
    
    local updates_available=0
    
    # Check for backup-related tool updates
    if apt list --upgradable 2>/dev/null | grep -E "tar|gzip|rsync"; then
        print_info "Backup tool updates available"
        updates_available=1
    fi
    
    if [[ $updates_available -eq 1 ]]; then
        print_warning "Backup module updates available"
        return 1
    else
        print_success "Backup module is up to date"
        return 0
    fi
}

#===========================================
# BACKUP MODULE MAIN FUNCTIONS
#===========================================

install_backup_module() {
    print_header "Installing Backup Module"
    
    # Configure backup defaults
    if configure_backup_defaults; then
        print_success "Backup module installed successfully"
        return 0
    else
        print_error "Backup module installation failed"
        return 1
    fi
}

check_backup_module() {
    print_header "Checking Backup Module"
    
    local config_status=0
    local directory_status=0
    local cron_status=0
    
    # Check backup configuration
    if [[ -f /etc/backup.conf ]]; then
        print_success "Backup configuration file exists"
        config_status=1
    else
        print_error "Backup configuration file not found"
    fi
    
    # Check backup directories
    if [[ -d /root/backups ]]; then
        print_success "Backup directory structure exists"
        directory_status=1
    else
        print_error "Backup directory structure not found"
    fi
    
    # Check for scheduled backups
    if crontab -l 2>/dev/null | grep -q "backup"; then
        print_success "Scheduled backups found"
        cron_status=1
    else
        print_info "No scheduled backups configured"
    fi
    
    if [[ $config_status -eq 1 && $directory_status -eq 1 ]]; then
        print_success "Backup module is operational"
        return 0
    else
        print_error "Backup module is not fully operational"
        return 1
    fi
}

update_backup_module() {
    print_header "Updating Backup Module"
    
    # Update backup tools
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y tar gzip rsync >/dev/null 2>&1
    
    # Clean up old backups
    cleanup_old_backups
    
    print_success "Backup module updated successfully"
    return 0
}

check_backup_update() {
    print_header "Checking Backup Module Updates"
    
    # Check for available updates
    apt-get update >/dev/null 2>&1
    
    local updates_available=0
    
    # Check for backup-related tool updates
    if apt list --upgradable 2>/dev/null | grep -E "tar|gzip|rsync"; then
        print_info "Backup tool updates available"
        updates_available=1
    fi
    
    if [[ $updates_available -eq 1 ]]; then
        print_warning "Backup module updates available"
        return 1
    else
        print_success "Backup module is up to date"
        return 0
    fi
}
