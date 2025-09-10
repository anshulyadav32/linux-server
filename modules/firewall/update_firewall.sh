#!/bin/bash
# =============================================================================
# Linux Setup - Firewall Module Update
# =============================================================================
# Author: Anshul Yadav
# Description: Update firewall services and components
# =============================================================================

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common functions
source "$SCRIPT_DIR/../common.sh" 2>/dev/null || {
    echo "[ERROR] Could not load common functions"
    exit 1
}

# Load firewall functions
source "$SCRIPT_DIR/functions.sh" 2>/dev/null || {
    echo "[ERROR] Could not load firewall functions"
    exit 1
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "Firewall Module Update"
    
    local overall_status=0
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Check for available updates first
    print_step "Checking for available updates..."
    if check_firewall_update; then
        print_info "No updates available"
        if [[ "${FORCE_UPDATE:-}" != "1" ]]; then
            print_success "Firewall module is already up to date"
            exit 0
        fi
    else
        print_info "Updates are available, proceeding with update..."
    fi
    
    echo ""
    
    # Backup firewall configuration before updating
    print_step "Creating backup before update..."
    
    # Backup UFW rules
    if command -v ufw >/dev/null 2>&1; then
        mkdir -p /root/backups/firewall
        ufw status numbered > "/root/backups/firewall/ufw_rules_$(date +%Y%m%d_%H%M%S).txt" 2>/dev/null
        print_info "UFW rules backed up"
    fi
    
    # Backup Fail2Ban configuration
    if [[ -d /etc/fail2ban ]]; then
        tar -czf "/root/backups/firewall/fail2ban_config_$(date +%Y%m%d_%H%M%S).tar.gz" -C /etc fail2ban 2>/dev/null
        print_info "Fail2Ban configuration backed up"
    fi
    
    echo ""
    
    # Run comprehensive firewall module update
    print_step "Running comprehensive firewall module update..."
    if update_firewall_module; then
        print_success "Firewall module updated successfully"
    else
        print_error "Firewall module update failed"
        overall_status=1
    fi
    
    echo ""
    
    # Individual component updates
    print_step "Updating individual firewall components..."
    
    # Update UFW
    echo ""
    print_substep "Updating UFW..."
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y ufw >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "UFW updated successfully"
        
        # Verify UFW is still active after update
        if ufw status | grep -q "Status: active"; then
            print_success "UFW is active after update"
        else
            print_warning "UFW not active, attempting to enable..."
            ufw --force enable >/dev/null 2>&1
            if ufw status | grep -q "Status: active"; then
                print_success "UFW enabled successfully"
            else
                print_error "Failed to enable UFW"
                overall_status=1
            fi
        fi
    else
        print_error "UFW update failed"
        overall_status=1
    fi
    
    # Update Fail2Ban
    echo ""
    print_substep "Updating Fail2Ban..."
    apt-get upgrade -y fail2ban >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "Fail2Ban updated successfully"
        
        # Restart Fail2Ban to ensure it's running with new version
        systemctl restart fail2ban
        
        # Verify Fail2Ban is running after update
        if systemctl is-active --quiet fail2ban; then
            print_success "Fail2Ban is active after update"
        else
            print_error "Fail2Ban not running after update"
            overall_status=1
        fi
    else
        print_error "Fail2Ban update failed"
        overall_status=1
    fi
    
    # Update iptables-persistent
    echo ""
    print_substep "Updating iptables-persistent..."
    apt-get upgrade -y iptables-persistent >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "iptables-persistent updated successfully"
    else
        print_warning "iptables-persistent update may have issues"
    fi
    
    echo ""
    
    # Post-update verification
    print_step "Verifying firewall services after update..."
    
    local ufw_ok=0
    local fail2ban_ok=0
    
    # Verify UFW
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            print_success "UFW verification: PASSED"
            ufw_ok=1
        else
            print_error "UFW verification: FAILED - not active"
            overall_status=1
        fi
    else
        print_error "UFW verification: FAILED - not installed"
        overall_status=1
    fi
    
    # Verify Fail2Ban
    if systemctl is-active --quiet fail2ban; then
        print_success "Fail2Ban verification: PASSED"
        fail2ban_ok=1
    else
        print_error "Fail2Ban verification: FAILED - not running"
        overall_status=1
    fi
    
    # Check that UFW rules are still in place
    local rule_count=$(ufw status numbered 2>/dev/null | grep -c "^\[")
    if [[ $rule_count -gt 0 ]]; then
        print_success "UFW rules verification: PASSED ($rule_count rules)"
    else
        print_warning "UFW rules verification: No rules found"
    fi
    
    # Check Fail2Ban jails
    if command -v fail2ban-client >/dev/null 2>&1; then
        local jail_count=$(fail2ban-client status 2>/dev/null | grep "Jail list:" | cut -d: -f2 | tr ',' ' ' | wc -w)
        if [[ $jail_count -gt 0 ]]; then
            print_success "Fail2Ban jails verification: PASSED ($jail_count jails)"
        else
            print_warning "Fail2Ban jails verification: No active jails"
        fi
    fi
    
    echo ""
    
    # Final status
    print_header "Firewall Update Summary"
    
    if [[ $overall_status -eq 0 ]]; then
        print_success "Firewall module update completed successfully"
        
        if [[ $ufw_ok -eq 1 ]]; then
            print_success "✓ UFW: Updated and verified"
        fi
        
        if [[ $fail2ban_ok -eq 1 ]]; then
            print_success "✓ Fail2Ban: Updated and verified"
        fi
        
        print_info "Firewall services are protecting your system"
        exit 0
    else
        print_error "Firewall module update completed with errors"
        print_warning "Some components may require manual attention"
        print_error "SECURITY WARNING: Verify firewall protection manually"
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
        echo "This script updates firewall services and components."
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
