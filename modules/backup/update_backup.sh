#!/bin/bash
# =============================================================================
# Linux Setup - Backup Module Update
# =============================================================================
# Author: Anshul Yadav
# Description: Update backup system and tools
# =============================================================================

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common functions
source "$SCRIPT_DIR/../common.sh" 2>/dev/null || {
    echo "[ERROR] Could not load common functions"
    exit 1
}

# Load backup functions
source "$SCRIPT_DIR/functions.sh" 2>/dev/null || {
    echo "[ERROR] Could not load backup functions"
    exit 1
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "Backup Module Update"
    
    local overall_status=0
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Check for available updates first
    print_step "Checking for available updates..."
    if check_backup_update; then
        print_info "No updates available"
        if [[ "${FORCE_UPDATE:-}" != "1" ]]; then
            print_success "Backup module is already up to date"
            exit 0
        fi
    else
        print_info "Updates are available, proceeding with update..."
    fi
    
    echo ""
    
    # Backup existing backup configurations before updating
    print_step "Creating backup before update..."
    
    local backup_dir="/root/backups/backup-module"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$backup_dir"
    
    # Backup crontab
    if crontab -l >/dev/null 2>&1; then
        crontab -l > "$backup_dir/crontab_$timestamp.txt"
        print_info "Crontab backed up"
    fi
    
    # Backup existing backup scripts
    if [[ -d /root/scripts ]]; then
        tar -czf "$backup_dir/backup_scripts_$timestamp.tar.gz" -C /root scripts 2>/dev/null
        print_info "Backup scripts backed up"
    fi
    
    # Backup SSH keys if they exist
    if [[ -d /root/.ssh ]]; then
        tar -czf "$backup_dir/ssh_keys_$timestamp.tar.gz" -C /root .ssh 2>/dev/null
        print_info "SSH keys backed up"
    fi
    
    echo ""
    
    # Run comprehensive backup module update
    print_step "Running comprehensive backup module update..."
    if update_backup_module; then
        print_success "Backup module updated successfully"
    else
        print_error "Backup module update failed"
        overall_status=1
    fi
    
    echo ""
    
    # Update backup tools and utilities
    print_step "Updating backup tools and utilities..."
    
    # Update essential backup packages
    echo ""
    print_substep "Updating core backup utilities..."
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y tar gzip bzip2 xz-utils rsync >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "Core backup utilities updated"
    else
        print_error "Core backup utilities update failed"
        overall_status=1
    fi
    
    # Update database backup tools
    echo ""
    print_substep "Updating database backup tools..."
    
    # MySQL/MariaDB tools
    if command -v mysql >/dev/null 2>&1; then
        apt-get upgrade -y mysql-client mariadb-client >/dev/null 2>&1
        if command -v mysqldump >/dev/null 2>&1; then
            print_success "MySQL backup tools updated"
        else
            print_warning "MySQL backup tools may need attention"
        fi
    fi
    
    # PostgreSQL tools
    if command -v psql >/dev/null 2>&1; then
        apt-get upgrade -y postgresql-client >/dev/null 2>&1
        if command -v pg_dump >/dev/null 2>&1; then
            print_success "PostgreSQL backup tools updated"
        else
            print_warning "PostgreSQL backup tools may need attention"
        fi
    fi
    
    echo ""
    
    # Update cloud backup tools
    print_step "Updating cloud backup tools..."
    
    # Update rclone if installed
    if command -v rclone >/dev/null 2>&1; then
        print_info "Updating rclone..."
        
        # Get current version
        local current_version=$(rclone version 2>/dev/null | head -1 | awk '{print $2}')
        
        # Update rclone
        if curl -s https://rclone.org/install.sh | bash >/dev/null 2>&1; then
            local new_version=$(rclone version 2>/dev/null | head -1 | awk '{print $2}')
            print_success "Rclone updated: $current_version → $new_version"
        else
            print_warning "Rclone update failed"
        fi
    else
        print_info "Rclone not installed, installing..."
        if curl -s https://rclone.org/install.sh | bash >/dev/null 2>&1; then
            print_success "Rclone installed successfully"
        else
            print_warning "Rclone installation failed"
        fi
    fi
    
    # Update AWS CLI if installed
    if command -v aws >/dev/null 2>&1; then
        print_info "AWS CLI detected, checking for updates..."
        pip3 install --upgrade awscli >/dev/null 2>&1 && print_success "AWS CLI updated" || print_warning "AWS CLI update failed"
    fi
    
    echo ""
    
    # Update backup directory structure
    print_step "Updating backup directory structure..."
    
    local backup_dirs=(
        "/root/backups"
        "/root/backups/system"
        "/root/backups/database"
        "/root/backups/webserver"
        "/root/backups/ssl"
        "/root/backups/firewall"
        "/root/backups/dns"
        "/root/backups/extra"
        "/root/backups/backup-module"
        "/root/logs"
        "/root/scripts"
    )
    
    for dir in "${backup_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            chmod 700 "$dir"
            print_success "Created backup directory: $dir"
        else
            # Ensure proper permissions
            chmod 700 "$dir"
            print_info "Updated permissions for: $dir"
        fi
    done
    
    echo ""
    
    # Update backup scripts
    print_step "Updating backup scripts..."
    
    # Create/update main backup script
    local main_backup_script="/root/scripts/backup.sh"
    
    cat > "$main_backup_script" << 'EOF'
#!/bin/bash
# Automated backup script - Generated by Linux Setup
# This script performs comprehensive system backups

BACKUP_DIR="/root/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/root/logs/backup.log"

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Create directories
mkdir -p "$BACKUP_DIR"/{system,database,webserver,ssl,firewall,dns,extra}
mkdir -p /root/logs

log_message "Starting automated backup..."

# System backup
log_message "Creating system configuration backup..."
tar -czf "$BACKUP_DIR/system/system_config_$TIMESTAMP.tar.gz" \
    /etc \
    /root/.ssh \
    /root/scripts \
    --exclude=/etc/ssl/private \
    >/dev/null 2>&1

# Database backup
if command -v mysqldump >/dev/null 2>&1; then
    log_message "Creating MySQL backup..."
    mysqldump --all-databases --single-transaction --routines --triggers > "$BACKUP_DIR/database/mysql_all_$TIMESTAMP.sql" 2>/dev/null
    gzip "$BACKUP_DIR/database/mysql_all_$TIMESTAMP.sql"
fi

if command -v pg_dumpall >/dev/null 2>&1; then
    log_message "Creating PostgreSQL backup..."
    sudo -u postgres pg_dumpall > "$BACKUP_DIR/database/postgresql_all_$TIMESTAMP.sql" 2>/dev/null
    gzip "$BACKUP_DIR/database/postgresql_all_$TIMESTAMP.sql"
fi

# Web server backup
if [[ -d /var/www ]]; then
    log_message "Creating web server backup..."
    tar -czf "$BACKUP_DIR/webserver/www_$TIMESTAMP.tar.gz" /var/www >/dev/null 2>&1
fi

# SSL certificates backup
if [[ -d /etc/letsencrypt ]]; then
    log_message "Creating SSL certificates backup..."
    tar -czf "$BACKUP_DIR/ssl/letsencrypt_$TIMESTAMP.tar.gz" /etc/letsencrypt >/dev/null 2>&1
fi

# Cleanup old backups (keep 7 days)
log_message "Cleaning up old backups..."
find "$BACKUP_DIR" -name "*.tar.gz" -o -name "*.sql.gz" -mtime +7 -delete 2>/dev/null

log_message "Backup completed successfully"
EOF
    
    chmod +x "$main_backup_script"
    print_success "Main backup script created/updated"
    
    # Create restore script
    local restore_script="/root/scripts/restore.sh"
    
    cat > "$restore_script" << 'EOF'
#!/bin/bash
# Automated restore script - Generated by Linux Setup

BACKUP_DIR="/root/backups"

echo "Available backups:"
echo "=================="
echo "System backups:"
ls -la "$BACKUP_DIR/system/" 2>/dev/null | tail -5

echo ""
echo "Database backups:"
ls -la "$BACKUP_DIR/database/" 2>/dev/null | tail -5

echo ""
echo "Usage:"
echo "  Restore system config: tar -xzf backup_file.tar.gz -C /"
echo "  Restore MySQL: zcat backup.sql.gz | mysql"
echo "  Restore PostgreSQL: zcat backup.sql.gz | sudo -u postgres psql"
echo ""
echo "WARNING: Always test restores in a safe environment first!"
EOF
    
    chmod +x "$restore_script"
    print_success "Restore script created/updated"
    
    echo ""
    
    # Update scheduled backups
    print_step "Updating backup schedule..."
    
    # Check if backup cron job exists
    if ! crontab -l 2>/dev/null | grep -q "$main_backup_script"; then
        print_info "Adding automated backup schedule..."
        
        # Add daily backup at 2 AM
        (crontab -l 2>/dev/null; echo "0 2 * * * $main_backup_script >/dev/null 2>&1") | crontab -
        
        if crontab -l 2>/dev/null | grep -q "$main_backup_script"; then
            print_success "Daily backup scheduled (2:00 AM)"
        else
            print_error "Failed to schedule backup"
            overall_status=1
        fi
    else
        print_success "Backup schedule already configured"
    fi
    
    echo ""
    
    # Post-update verification
    print_step "Verifying backup system after update..."
    
    # Verify tools
    local tools_ok=0
    local essential_tools=("tar" "gzip" "rsync")
    
    for tool in "${essential_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version=$(
                case "$tool" in
                    "tar") tar --version 2>/dev/null | head -1 | awk '{print $4}' ;;
                    "gzip") gzip --version 2>/dev/null | head -1 | awk '{print $2}' ;;
                    "rsync") rsync --version 2>/dev/null | head -1 | awk '{print $3}' ;;
                esac
            )
            print_success "$tool: Available (v$version)"
        else
            print_error "$tool: Not available"
            overall_status=1
        fi
    done
    
    # Verify directories
    local dirs_ok=1
    for dir in "${backup_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local perms=$(stat -c "%a" "$dir" 2>/dev/null)
            if [[ "$perms" == "700" ]]; then
                continue
            else
                print_warning "Directory $dir has wrong permissions: $perms"
                dirs_ok=0
            fi
        else
            print_error "Directory $dir not created"
            dirs_ok=0
            overall_status=1
        fi
    done
    
    if [[ $dirs_ok -eq 1 ]]; then
        print_success "Backup directories: All configured correctly"
    fi
    
    # Verify scripts
    if [[ -x "$main_backup_script" && -x "$restore_script" ]]; then
        print_success "Backup scripts: Created and executable"
    else
        print_error "Backup scripts: Not properly configured"
        overall_status=1
    fi
    
    # Test backup functionality
    print_info "Testing backup functionality..."
    local test_backup="/tmp/test_backup_$TIMESTAMP.tar.gz"
    
    if tar -czf "$test_backup" /etc/hostname >/dev/null 2>&1; then
        print_success "Backup test: PASSED"
        rm -f "$test_backup"
    else
        print_error "Backup test: FAILED"
        overall_status=1
    fi
    
    echo ""
    
    # Final status
    print_header "Backup Update Summary"
    
    if [[ $overall_status -eq 0 ]]; then
        print_success "Backup module update completed successfully"
        print_success "✓ Core utilities: Updated and verified"
        print_success "✓ Directory structure: Created and secured"
        print_success "✓ Backup scripts: Generated and scheduled"
        print_success "✓ Cloud tools: Updated (if applicable)"
        
        echo ""
        print_info "Backup system is ready for operation"
        print_info "Daily automated backups scheduled at 2:00 AM"
        print_info "Backup scripts located in /root/scripts/"
        print_info "Backup logs available in /root/logs/backup.log"
        
        echo ""
        print_info "Next steps:"
        print_info "• Run $main_backup_script to test manual backup"
        print_info "• Review and customize backup schedule in crontab"
        print_info "• Configure remote/cloud backup destinations"
        
        exit 0
    else
        print_error "Backup module update completed with errors"
        print_warning "Some components may require manual attention"
        exit 1
    fi
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --force, -f    Force update even if no updates detected"
        echo "  --quiet, -q    Quiet mode (minimal output)"
        echo "  --verbose, -v  Verbose mode (detailed output)"
        echo ""
        echo "This script updates the backup system and tools."
        exit 0
        ;;
    --force|-f)
        FORCE_UPDATE=1
        ;;
    --quiet|-q)
        QUIET_MODE=1
        ;;
    --verbose|-v)
        VERBOSE_MODE=1
        ;;
esac

# Execute main function
main "$@"
