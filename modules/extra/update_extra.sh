#!/bin/bash
# =============================================================================
# Linux Setup - Extra Module Update
# =============================================================================
# Author: Anshul Yadav
# Description: Update extra services (mail server, spamassassin, etc.)
# =============================================================================

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common functions
source "$SCRIPT_DIR/../common.sh" 2>/dev/null || {
    echo "[ERROR] Could not load common functions"
    exit 1
}

# Load extra functions
source "$SCRIPT_DIR/functions.sh" 2>/dev/null || {
    echo "[ERROR] Could not load extra functions"
    exit 1
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "Extra Module Update"
    
    local overall_status=0
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Check for available updates first
    print_step "Checking for available updates..."
    if check_extra_update; then
        print_info "No updates available"
        if [[ "${FORCE_UPDATE:-}" != "1" ]]; then
            print_success "Extra module is already up to date"
            exit 0
        fi
    else
        print_info "Updates are available, proceeding with update..."
    fi
    
    echo ""
    
    # Backup configuration before updating
    print_step "Creating backup before update..."
    
    local backup_dir="/root/backups/extra"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$backup_dir"
    
    # Backup mail server configurations
    if [[ -d /etc/postfix ]]; then
        tar -czf "$backup_dir/postfix_$timestamp.tar.gz" -C /etc postfix 2>/dev/null
        print_info "Postfix configuration backed up"
    fi
    
    if [[ -d /etc/dovecot ]]; then
        tar -czf "$backup_dir/dovecot_$timestamp.tar.gz" -C /etc dovecot 2>/dev/null
        print_info "Dovecot configuration backed up"
    fi
    
    if [[ -d /etc/spamassassin ]]; then
        tar -czf "$backup_dir/spamassassin_$timestamp.tar.gz" -C /etc spamassassin 2>/dev/null
        print_info "SpamAssassin configuration backed up"
    fi
    
    echo ""
    
    # Run comprehensive extra module update
    print_step "Running comprehensive extra module update..."
    if update_extra_module; then
        print_success "Extra module updated successfully"
    else
        print_error "Extra module update failed"
        overall_status=1
    fi
    
    echo ""
    
    # Update mail server components
    print_step "Updating mail server components..."
    
    # Update Postfix
    echo ""
    print_substep "Updating Postfix..."
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y postfix >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "Postfix updated successfully"
        
        # Restart Postfix if it was running
        if systemctl is-active postfix >/dev/null 2>&1; then
            systemctl restart postfix
            if systemctl is-active postfix >/dev/null 2>&1; then
                print_success "Postfix restarted successfully"
            else
                print_error "Postfix restart failed"
                overall_status=1
            fi
        fi
        
        # Verify Postfix configuration
        if postfix check >/dev/null 2>&1; then
            print_success "Postfix configuration: Valid"
        else
            print_error "Postfix configuration: Invalid"
            overall_status=1
        fi
    else
        print_error "Postfix update failed"
        overall_status=1
    fi
    
    # Update Dovecot
    echo ""
    print_substep "Updating Dovecot..."
    apt-get upgrade -y dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "Dovecot updated successfully"
        
        # Restart Dovecot if it was running
        if systemctl is-active dovecot >/dev/null 2>&1; then
            systemctl restart dovecot
            if systemctl is-active dovecot >/dev/null 2>&1; then
                print_success "Dovecot restarted successfully"
            else
                print_error "Dovecot restart failed"
                overall_status=1
            fi
        fi
        
        # Verify Dovecot configuration
        if doveconf -n >/dev/null 2>&1; then
            print_success "Dovecot configuration: Valid"
        else
            print_error "Dovecot configuration: Invalid"
            overall_status=1
        fi
    else
        print_error "Dovecot update failed"
        overall_status=1
    fi
    
    echo ""
    
    # Update SpamAssassin
    print_step "Updating SpamAssassin..."
    
    apt-get upgrade -y spamassassin spamc spamass-milter >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "SpamAssassin updated successfully"
        
        # Update SpamAssassin rules
        print_info "Updating SpamAssassin rules..."
        if sa-update >/dev/null 2>&1; then
            print_success "SpamAssassin rules updated"
        else
            print_warning "SpamAssassin rules update failed (may be normal if no updates available)"
        fi
        
        # Restart SpamAssassin services if they were running
        if systemctl is-active spamassassin >/dev/null 2>&1; then
            systemctl restart spamassassin
            if systemctl is-active spamassassin >/dev/null 2>&1; then
                print_success "SpamAssassin daemon restarted"
            else
                print_error "SpamAssassin daemon restart failed"
                overall_status=1
            fi
        fi
        
        if systemctl is-active spamass-milter >/dev/null 2>&1; then
            systemctl restart spamass-milter
            if systemctl is-active spamass-milter >/dev/null 2>&1; then
                print_success "SpamAssassin milter restarted"
            else
                print_error "SpamAssassin milter restart failed"
                overall_status=1
            fi
        fi
        
        # Verify SpamAssassin configuration
        if spamassassin --lint >/dev/null 2>&1; then
            print_success "SpamAssassin configuration: Valid"
        else
            print_error "SpamAssassin configuration: Invalid"
            overall_status=1
        fi
    else
        print_error "SpamAssassin update failed"
        overall_status=1
    fi
    
    echo ""
    
    # Update ClamAV
    print_step "Updating ClamAV antivirus..."
    
    apt-get upgrade -y clamav clamav-daemon clamav-freshclam >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "ClamAV updated successfully"
        
        # Stop freshclam before updating database
        systemctl stop clamav-freshclam 2>/dev/null || true
        
        # Update virus database
        print_info "Updating ClamAV virus database..."
        if freshclam >/dev/null 2>&1; then
            print_success "ClamAV database updated"
        else
            print_warning "ClamAV database update failed (may be rate-limited)"
        fi
        
        # Restart ClamAV services if they were running
        if systemctl is-enabled clamav-daemon >/dev/null 2>&1; then
            systemctl start clamav-freshclam
            systemctl start clamav-daemon
            
            if systemctl is-active clamav-daemon >/dev/null 2>&1; then
                print_success "ClamAV daemon restarted"
            else
                print_error "ClamAV daemon restart failed"
                overall_status=1
            fi
        fi
    else
        print_error "ClamAV update failed"
        overall_status=1
    fi
    
    echo ""
    
    # Update DKIM and DMARC
    print_step "Updating DKIM and DMARC services..."
    
    apt-get upgrade -y opendkim opendkim-tools opendmarc >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "DKIM/DMARC services updated"
        
        # Restart services if they were running
        if systemctl is-active opendkim >/dev/null 2>&1; then
            systemctl restart opendkim
            if systemctl is-active opendkim >/dev/null 2>&1; then
                print_success "OpenDKIM restarted successfully"
            else
                print_error "OpenDKIM restart failed"
                overall_status=1
            fi
        fi
        
        if systemctl is-active opendmarc >/dev/null 2>&1; then
            systemctl restart opendmarc
            if systemctl is-active opendmarc >/dev/null 2>&1; then
                print_success "OpenDMARC restarted successfully"
            else
                print_error "OpenDMARC restart failed"
                overall_status=1
            fi
        fi
    else
        print_error "DKIM/DMARC update failed"
        overall_status=1
    fi
    
    echo ""
    
    # Post-update verification
    print_step "Verifying services after update..."
    
    local postfix_ok=0
    local dovecot_ok=0
    local spamassassin_ok=0
    local clamav_ok=0
    
    # Verify Postfix
    if systemctl is-active postfix >/dev/null 2>&1 && postfix check >/dev/null 2>&1; then
        print_success "Postfix verification: PASSED"
        postfix_ok=1
    else
        print_error "Postfix verification: FAILED"
        overall_status=1
    fi
    
    # Verify Dovecot
    if systemctl is-active dovecot >/dev/null 2>&1 && doveconf -n >/dev/null 2>&1; then
        print_success "Dovecot verification: PASSED"
        dovecot_ok=1
    else
        print_info "Dovecot verification: Not active or not configured"
    fi
    
    # Verify SpamAssassin
    if systemctl is-active spamassassin >/dev/null 2>&1 && spamassassin --lint >/dev/null 2>&1; then
        print_success "SpamAssassin verification: PASSED"
        spamassassin_ok=1
    else
        print_info "SpamAssassin verification: Not active or not configured"
    fi
    
    # Verify ClamAV
    if systemctl is-active clamav-daemon >/dev/null 2>&1; then
        print_success "ClamAV verification: PASSED"
        clamav_ok=1
    else
        print_info "ClamAV verification: Not active or not configured"
    fi
    
    # Test mail functionality if services are running
    if [[ $postfix_ok -eq 1 ]]; then
        if timeout 5 telnet localhost 25 </dev/null >/dev/null 2>&1; then
            print_success "SMTP connectivity test: PASSED"
        else
            print_warning "SMTP connectivity test: FAILED"
        fi
    fi
    
    if [[ $dovecot_ok -eq 1 ]]; then
        if timeout 5 telnet localhost 143 </dev/null >/dev/null 2>&1; then
            print_success "IMAP connectivity test: PASSED"
        else
            print_warning "IMAP connectivity test: FAILED"
        fi
    fi
    
    echo ""
    
    # Final status
    print_header "Extra Update Summary"
    
    if [[ $overall_status -eq 0 ]]; then
        print_success "Extra module update completed successfully"
        
        if [[ $postfix_ok -eq 1 ]]; then
            print_success "✓ Postfix: Updated and verified"
        fi
        
        if [[ $dovecot_ok -eq 1 ]]; then
            print_success "✓ Dovecot: Updated and verified"
        fi
        
        if [[ $spamassassin_ok -eq 1 ]]; then
            print_success "✓ SpamAssassin: Updated and verified"
        fi
        
        if [[ $clamav_ok -eq 1 ]]; then
            print_success "✓ ClamAV: Updated and verified"
        fi
        
        print_info "Extra services are ready for operation"
        exit 0
    else
        print_error "Extra module update completed with errors"
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
        echo "This script updates extra services (mail server, antivirus, etc.)."
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
