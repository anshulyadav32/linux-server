#!/bin/bash
# =============================================================================
# Linux Setup - Backup Module Health Check
# =============================================================================
# Author: Anshul Yadav
# Description: Health check for backup system and storage
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
    print_header "Backup Module Health Check"
    
    local overall_status=0
    
    # Run comprehensive backup module check
    print_step "Running comprehensive backup module check..."
    if check_backup_module; then
        print_success "Backup module check: PASSED"
    else
        print_error "Backup module check: FAILED"
        overall_status=1
    fi
    
    echo ""
    
    # Backup Directory Structure Check
    print_step "Checking backup directory structure..."
    
    local backup_dirs=(
        "/root/backups"
        "/root/backups/system"
        "/root/backups/database"
        "/root/backups/webserver"
        "/root/backups/ssl"
        "/root/backups/firewall"
        "/root/backups/dns"
        "/root/backups/extra"
    )
    
    for dir in "${backup_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_success "Backup directory exists: $dir"
            
            # Check directory permissions
            local perms=$(stat -c "%a" "$dir" 2>/dev/null)
            if [[ "$perms" == "700" ]]; then
                print_success "  Permissions: Secure (700)"
            else
                print_warning "  Permissions: Not optimal ($perms, should be 700)"
            fi
            
            # Check directory size and usage
            local size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
            if [[ -n "$size" ]]; then
                print_info "  Size: $size"
            fi
            
            # Count backup files
            local file_count=$(find "$dir" -type f -name "*.tar.gz" 2>/dev/null | wc -l)
            print_info "  Backup files: $file_count"
            
        else
            print_warning "Backup directory missing: $dir"
        fi
    done
    
    echo ""
    
    # Backup Storage Space Check
    print_step "Checking backup storage space..."
    
    # Check disk space for backup location
    local backup_fs=$(df -h /root/backups 2>/dev/null | tail -1)
    if [[ -n "$backup_fs" ]]; then
        local usage=$(echo "$backup_fs" | awk '{print $5}' | sed 's/%//')
        local available=$(echo "$backup_fs" | awk '{print $4}')
        
        print_info "Backup filesystem usage: ${usage}%"
        print_info "Available space: $available"
        
        if [[ $usage -lt 80 ]]; then
            print_success "Storage space: Adequate"
        elif [[ $usage -lt 90 ]]; then
            print_warning "Storage space: Getting full (${usage}%)"
        else
            print_error "Storage space: Critical (${usage}%)"
            overall_status=1
        fi
    else
        print_warning "Unable to check backup storage space"
    fi
    
    # Check for backup rotation
    local old_backups=$(find /root/backups -type f -name "*.tar.gz" -mtime +30 2>/dev/null | wc -l)
    if [[ $old_backups -gt 0 ]]; then
        print_warning "Old backups found: $old_backups files older than 30 days"
        print_info "Consider implementing backup rotation"
    else
        print_success "Backup retention: No old files detected"
    fi
    
    echo ""
    
    # Recent Backup Check
    print_step "Checking recent backup activity..."
    
    # Check for recent full system backups
    local recent_full=$(find /root/backups/system -name "full_backup_*.tar.gz" -mtime -7 2>/dev/null | wc -l)
    if [[ $recent_full -gt 0 ]]; then
        print_success "Recent full backup: Found ($recent_full in last 7 days)"
        
        # Get most recent backup info
        local latest_full=$(find /root/backups/system -name "full_backup_*.tar.gz" -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        if [[ -n "$latest_full" ]]; then
            local backup_date=$(stat -c %y "$latest_full" 2>/dev/null | cut -d' ' -f1)
            local backup_size=$(du -sh "$latest_full" 2>/dev/null | awk '{print $1}')
            print_info "  Latest: $backup_date ($backup_size)"
        fi
    else
        print_warning "Recent full backup: None found in last 7 days"
    fi
    
    # Check for recent database backups
    local recent_db=$(find /root/backups/database -name "*.sql" -o -name "*.sql.gz" -mtime -1 2>/dev/null | wc -l)
    if [[ $recent_db -gt 0 ]]; then
        print_success "Recent database backup: Found ($recent_db in last 24 hours)"
    else
        print_warning "Recent database backup: None found in last 24 hours"
    fi
    
    echo ""
    
    # Backup Configuration Check
    print_step "Checking backup configuration..."
    
    # Check for crontab entries
    local backup_crons=$(crontab -l 2>/dev/null | grep -c "backup" || echo "0")
    if [[ $backup_crons -gt 0 ]]; then
        print_success "Scheduled backups: $backup_crons cron entries found"
        
        # Show backup schedule
        print_info "Backup schedule:"
        crontab -l 2>/dev/null | grep "backup" | while read -r line; do
            print_info "  $line"
        done
    else
        print_warning "Scheduled backups: No cron entries found"
        print_info "Consider setting up automated backups"
    fi
    
    # Check for backup scripts
    local backup_scripts=(
        "/root/scripts/backup.sh"
        "/usr/local/bin/backup.sh"
        "$SCRIPT_DIR/install.sh"
        "$SCRIPT_DIR/maintain.sh"
    )
    
    for script in "${backup_scripts[@]}"; do
        if [[ -f "$script" && -x "$script" ]]; then
            print_success "Backup script found: $script"
        fi
    done
    
    echo ""
    
    # Backup Integrity Check
    print_step "Checking backup integrity..."
    
    # Test a few recent backups
    local test_count=0
    local failed_tests=0
    
    # Test recent tar.gz backups
    while IFS= read -r -d '' backup_file; do
        if [[ $test_count -ge 3 ]]; then
            break
        fi
        
        print_substep "Testing: $(basename "$backup_file")"
        
        if tar -tzf "$backup_file" >/dev/null 2>&1; then
            print_success "  Integrity: PASSED"
        else
            print_error "  Integrity: FAILED"
            failed_tests=$((failed_tests + 1))
            overall_status=1
        fi
        
        test_count=$((test_count + 1))
        
    done < <(find /root/backups -name "*.tar.gz" -type f -mtime -7 -print0 2>/dev/null | head -z -3)
    
    if [[ $test_count -eq 0 ]]; then
        print_info "No recent backup archives to test"
    elif [[ $failed_tests -eq 0 ]]; then
        print_success "Backup integrity tests: All passed ($test_count tested)"
    else
        print_error "Backup integrity tests: $failed_tests failed out of $test_count"
    fi
    
    echo ""
    
    # Backup Tools Check
    print_step "Checking backup tools and utilities..."
    
    # Essential backup tools
    local backup_tools=(
        "tar:GNU tar archiver"
        "gzip:Compression utility"
        "rsync:File synchronization"
        "mysqldump:MySQL backup utility"
        "pg_dump:PostgreSQL backup utility"
    )
    
    for tool_info in "${backup_tools[@]}"; do
        local tool=$(echo "$tool_info" | cut -d':' -f1)
        local desc=$(echo "$tool_info" | cut -d':' -f2)
        
        if command -v "$tool" >/dev/null 2>&1; then
            print_success "$desc: Available"
            
            # Show version for key tools
            case "$tool" in
                "tar")
                    local version=$(tar --version 2>/dev/null | head -1 | awk '{print $4}')
                    print_info "  Version: $version"
                    ;;
                "rsync")
                    local version=$(rsync --version 2>/dev/null | head -1 | awk '{print $3}')
                    print_info "  Version: $version"
                    ;;
            esac
        else
            print_error "$desc: Not available"
            overall_status=1
        fi
    done
    
    echo ""
    
    # Remote Backup Check
    print_step "Checking remote backup capabilities..."
    
    # Check for SSH key for remote backups
    if [[ -f /root/.ssh/id_rsa ]] || [[ -f /root/.ssh/id_ed25519 ]]; then
        print_success "SSH key: Available for remote backups"
        
        # Check SSH key permissions
        local key_perms=$(find /root/.ssh -name "id_*" -not -name "*.pub" -exec stat -c "%a %n" {} \; 2>/dev/null | head -1)
        if [[ -n "$key_perms" ]]; then
            local perms=$(echo "$key_perms" | awk '{print $1}')
            if [[ "$perms" == "600" ]]; then
                print_success "  SSH key permissions: Secure (600)"
            else
                print_warning "  SSH key permissions: Not optimal ($perms, should be 600)"
            fi
        fi
    else
        print_info "SSH key: Not configured (local backups only)"
    fi
    
    # Check for cloud backup tools
    local cloud_tools=("rclone" "aws" "gsutil")
    local cloud_available=0
    
    for tool in "${cloud_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            print_success "Cloud backup tool: $tool available"
            cloud_available=1
        fi
    done
    
    if [[ $cloud_available -eq 0 ]]; then
        print_info "Cloud backup tools: Not installed"
        print_info "Consider installing rclone, aws-cli, or gsutil for cloud backups"
    fi
    
    echo ""
    
    # Log File Analysis
    print_step "Analyzing backup logs..."
    
    # Check for backup log files
    local log_files=("/var/log/backup.log" "/root/logs/backup.log" "/tmp/backup.log")
    local log_found=0
    
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            log_found=1
            print_success "Backup log found: $log_file"
            
            # Check for recent entries
            local recent_entries=$(find "$log_file" -mtime -1 -type f 2>/dev/null | wc -l)
            if [[ $recent_entries -gt 0 ]]; then
                print_success "  Recent activity: Yes"
                
                # Check for errors in log
                local error_count=$(grep -ci "error\|fail" "$log_file" 2>/dev/null | tail -10 || echo "0")
                if [[ "${error_count:-0}" -eq 0 ]]; then
                    print_success "  Errors in log: None detected"
                else
                    print_warning "  Errors in log: $error_count found"
                fi
            else
                print_info "  Recent activity: No recent entries"
            fi
        fi
    done
    
    if [[ $log_found -eq 0 ]]; then
        print_info "Backup logs: No standard log files found"
    fi
    
    echo ""
    
    # Final status summary
    print_header "Backup Module Check Summary"
    
    if [[ $overall_status -eq 0 ]]; then
        print_success "Backup module health check: PASSED"
        print_info "Backup system is functioning properly"
        
        # Provide recommendations
        echo ""
        print_info "Recommendations:"
        print_info "• Ensure regular backup schedule is maintained"
        print_info "• Monitor storage space regularly"
        print_info "• Test backup restoration periodically"
        print_info "• Consider implementing remote/cloud backups"
        
    else
        print_error "Backup module health check: FAILED"
        print_warning "Issues detected, review output above"
        
        echo ""
        print_warning "Critical items to address:"
        print_warning "• Fix any integrity test failures"
        print_warning "• Resolve storage space issues"
        print_warning "• Install missing backup tools"
    fi
    
    exit $overall_status
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
        echo "  --quiet, -q    Quiet mode (minimal output)"
        echo "  --verbose, -v  Verbose mode (detailed output)"
        echo ""
        echo "This script performs a comprehensive health check of the backup system."
        exit 0
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
