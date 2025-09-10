#!/bin/bash
# =============================================================================
# Linux Setup - Extra Module Health Check
# =============================================================================
# Author: Anshul Yadav
# Description: Health check for extra services (mail server, spamassassin, etc.)
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
    print_header "Extra Module Health Check"
    
    local overall_status=0
    
    # Run comprehensive extra module check
    print_step "Running comprehensive extra module check..."
    if check_extra_module; then
        print_success "Extra module check: PASSED"
    else
        print_error "Extra module check: FAILED"
        overall_status=1
    fi
    
    echo ""
    
    # Mail Server Health Check
    print_step "Checking mail server components..."
    
    # Check Postfix
    echo ""
    print_substep "Checking Postfix mail server..."
    
    if systemctl is-active postfix >/dev/null 2>&1; then
        print_success "Postfix service: Running"
        
        # Check Postfix configuration
        if postfix check >/dev/null 2>&1; then
            print_success "Postfix configuration: Valid"
        else
            print_error "Postfix configuration: Invalid"
            overall_status=1
        fi
        
        # Check mail queue
        local queue_count=$(mailq 2>/dev/null | tail -n 1 | grep -o "^[0-9]*" || echo "0")
        if [[ "${queue_count:-0}" -lt 100 ]]; then
            print_success "Mail queue: Normal ($queue_count messages)"
        else
            print_warning "Mail queue: High ($queue_count messages)"
        fi
        
        # Check SMTP connectivity
        if timeout 5 telnet localhost 25 </dev/null >/dev/null 2>&1; then
            print_success "SMTP connectivity: Available (port 25)"
        else
            print_warning "SMTP connectivity: Failed (port 25)"
        fi
        
    elif systemctl is-enabled postfix >/dev/null 2>&1; then
        print_warning "Postfix service: Enabled but not running"
        overall_status=1
    else
        print_info "Postfix service: Not installed/configured"
    fi
    
    # Check Dovecot
    echo ""
    print_substep "Checking Dovecot IMAP/POP3 server..."
    
    if systemctl is-active dovecot >/dev/null 2>&1; then
        print_success "Dovecot service: Running"
        
        # Check IMAP connectivity
        if timeout 5 telnet localhost 143 </dev/null >/dev/null 2>&1; then
            print_success "IMAP connectivity: Available (port 143)"
        else
            print_warning "IMAP connectivity: Failed (port 143)"
        fi
        
        # Check IMAPS connectivity
        if timeout 5 telnet localhost 993 </dev/null >/dev/null 2>&1; then
            print_success "IMAPS connectivity: Available (port 993)"
        else
            print_warning "IMAPS connectivity: Failed (port 993)"
        fi
        
        # Check POP3 connectivity
        if timeout 5 telnet localhost 110 </dev/null >/dev/null 2>&1; then
            print_success "POP3 connectivity: Available (port 110)"
        else
            print_info "POP3 connectivity: Not available (port 110)"
        fi
        
    elif systemctl is-enabled dovecot >/dev/null 2>&1; then
        print_warning "Dovecot service: Enabled but not running"
        overall_status=1
    else
        print_info "Dovecot service: Not installed/configured"
    fi
    
    echo ""
    
    # SpamAssassin Health Check
    print_step "Checking SpamAssassin anti-spam system..."
    
    # Check SpamAssassin daemon
    if systemctl is-active spamassassin >/dev/null 2>&1; then
        print_success "SpamAssassin daemon: Running"
        
        # Check SpamAssassin configuration
        if spamassassin --lint >/dev/null 2>&1; then
            print_success "SpamAssassin configuration: Valid"
        else
            print_error "SpamAssassin configuration: Invalid"
            overall_status=1
        fi
        
        # Check rule updates
        local rules_date=$(find /var/lib/spamassassin -name "*.cf" -type f -printf "%T@\n" 2>/dev/null | sort -n | tail -1)
        if [[ -n "$rules_date" ]]; then
            local days_old=$(( ($(date +%s) - ${rules_date%.*}) / 86400 ))
            if [[ $days_old -lt 7 ]]; then
                print_success "SpamAssassin rules: Recent (${days_old} days old)"
            else
                print_warning "SpamAssassin rules: Outdated (${days_old} days old)"
            fi
        else
            print_warning "SpamAssassin rules: Unable to check date"
        fi
        
    elif systemctl is-enabled spamassassin >/dev/null 2>&1; then
        print_warning "SpamAssassin daemon: Enabled but not running"
        overall_status=1
    else
        print_info "SpamAssassin daemon: Not installed/configured"
    fi
    
    # Check spamass-milter
    if systemctl is-active spamass-milter >/dev/null 2>&1; then
        print_success "SpamAssassin milter: Running"
        
        # Check milter socket
        if [[ -S /run/spamass-milter/spamass-milter.sock ]]; then
            print_success "SpamAssassin milter socket: Available"
        else
            print_warning "SpamAssassin milter socket: Not found"
        fi
        
    elif systemctl is-enabled spamass-milter >/dev/null 2>&1; then
        print_warning "SpamAssassin milter: Enabled but not running"
    else
        print_info "SpamAssassin milter: Not installed/configured"
    fi
    
    echo ""
    
    # ClamAV Antivirus Check
    print_step "Checking ClamAV antivirus system..."
    
    if systemctl is-active clamav-daemon >/dev/null 2>&1; then
        print_success "ClamAV daemon: Running"
        
        # Check ClamAV freshness
        if systemctl is-active clamav-freshclam >/dev/null 2>&1; then
            print_success "ClamAV freshclam: Running"
            
            # Check virus database freshness
            local db_date=$(stat -c %Y /var/lib/clamav/main.cvd 2>/dev/null || stat -c %Y /var/lib/clamav/main.cld 2>/dev/null || echo "0")
            if [[ $db_date -gt 0 ]]; then
                local days_old=$(( ($(date +%s) - $db_date) / 86400 ))
                if [[ $days_old -lt 2 ]]; then
                    print_success "ClamAV database: Recent (${days_old} days old)"
                else
                    print_warning "ClamAV database: Outdated (${days_old} days old)"
                fi
            else
                print_warning "ClamAV database: Unable to check date"
            fi
        else
            print_warning "ClamAV freshclam: Not running"
        fi
        
        # Test ClamAV scanning capability
        if echo "X5O!P%@AP[4\PZX54(P^)7CC)7}\$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!\$H+H*" | clamdscan - 2>/dev/null | grep -q "FOUND"; then
            print_success "ClamAV scanning: Functional"
        else
            print_warning "ClamAV scanning: May not be functional"
        fi
        
    elif systemctl is-enabled clamav-daemon >/dev/null 2>&1; then
        print_warning "ClamAV daemon: Enabled but not running"
    else
        print_info "ClamAV daemon: Not installed/configured"
    fi
    
    echo ""
    
    # Additional Services Check
    print_step "Checking additional services..."
    
    # Check OpenDKIM
    if systemctl is-active opendkim >/dev/null 2>&1; then
        print_success "OpenDKIM: Running"
        
        # Check DKIM socket
        if [[ -S /run/opendkim/opendkim.sock ]]; then
            print_success "OpenDKIM socket: Available"
        else
            print_warning "OpenDKIM socket: Not found"
        fi
        
    elif systemctl is-enabled opendkim >/dev/null 2>&1; then
        print_warning "OpenDKIM: Enabled but not running"
    else
        print_info "OpenDKIM: Not installed/configured"
    fi
    
    # Check OpenDMARC
    if systemctl is-active opendmarc >/dev/null 2>&1; then
        print_success "OpenDMARC: Running"
    elif systemctl is-enabled opendmarc >/dev/null 2>&1; then
        print_warning "OpenDMARC: Enabled but not running"
    else
        print_info "OpenDMARC: Not installed/configured"
    fi
    
    echo ""
    
    # Configuration File Validation
    print_step "Validating configuration files..."
    
    # Check Postfix configuration
    if [[ -f /etc/postfix/main.cf ]]; then
        if postfix check >/dev/null 2>&1; then
            print_success "Postfix main.cf: Valid"
        else
            print_error "Postfix main.cf: Invalid syntax"
            overall_status=1
        fi
    else
        print_info "Postfix main.cf: Not found"
    fi
    
    # Check Dovecot configuration
    if [[ -f /etc/dovecot/dovecot.conf ]]; then
        if doveconf -n >/dev/null 2>&1; then
            print_success "Dovecot configuration: Valid"
        else
            print_error "Dovecot configuration: Invalid syntax"
            overall_status=1
        fi
    else
        print_info "Dovecot configuration: Not found"
    fi
    
    # Check SpamAssassin configuration
    if [[ -f /etc/spamassassin/local.cf ]]; then
        if spamassassin --lint >/dev/null 2>&1; then
            print_success "SpamAssassin configuration: Valid"
        else
            print_error "SpamAssassin configuration: Invalid"
            overall_status=1
        fi
    else
        print_info "SpamAssassin configuration: Not found"
    fi
    
    echo ""
    
    # Log File Analysis
    print_step "Analyzing log files for issues..."
    
    # Check mail logs for errors
    if [[ -f /var/log/mail.log ]]; then
        local error_count=$(grep -c "error\|Error\|ERROR" /var/log/mail.log 2>/dev/null | tail -100 || echo "0")
        if [[ "${error_count:-0}" -eq 0 ]]; then
            print_success "Mail logs: No recent errors"
        elif [[ "${error_count:-0}" -lt 10 ]]; then
            print_warning "Mail logs: ${error_count} recent errors"
        else
            print_error "Mail logs: ${error_count} recent errors (investigate required)"
            overall_status=1
        fi
    else
        print_info "Mail logs: Not available"
    fi
    
    # Check for failed authentication attempts
    if [[ -f /var/log/auth.log ]]; then
        local failed_auth=$(grep "authentication failure" /var/log/auth.log 2>/dev/null | tail -10 | wc -l)
        if [[ "${failed_auth:-0}" -eq 0 ]]; then
            print_success "Authentication logs: No recent failures"
        elif [[ "${failed_auth:-0}" -lt 5 ]]; then
            print_warning "Authentication logs: ${failed_auth} recent failures"
        else
            print_error "Authentication logs: ${failed_auth} recent failures"
            overall_status=1
        fi
    fi
    
    echo ""
    
    # Final status summary
    print_header "Extra Module Check Summary"
    
    if [[ $overall_status -eq 0 ]]; then
        print_success "Extra module health check: PASSED"
        print_info "All extra services are functioning properly"
    else
        print_error "Extra module health check: FAILED"
        print_warning "Some issues detected, review output above"
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
        echo "This script performs a comprehensive health check of extra services."
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
