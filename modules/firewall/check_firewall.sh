#!/bin/bash
# =============================================================================
# Linux Setup - Firewall Module Health Check
# =============================================================================
# Author: Anshul Yadav
# Description: Check the health and status of firewall services
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
    print_header "Firewall Module Health Check"
    
    local overall_status=0
    local ufw_status=0
    local fail2ban_status=0
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Run comprehensive firewall module check
    print_step "Running comprehensive firewall module check..."
    if check_firewall_module; then
        print_success "Firewall module check passed"
    else
        print_error "Firewall module check failed"
        overall_status=1
    fi
    
    echo ""
    
    # Individual component checks
    print_step "Checking individual firewall components..."
    
    # Check UFW
    echo ""
    print_substep "UFW Firewall Check:"
    if systemctl is-active --quiet ufw && ufw status | grep -q "Status: active"; then
        ufw_status=1
        print_success "UFW Service: Active"
        
        # Show UFW status
        local ufw_rules=$(ufw status numbered 2>/dev/null | grep -c "^\[")
        print_info "UFW Rules: $ufw_rules configured"
        
        # Check default policies
        local incoming_policy=$(ufw status verbose 2>/dev/null | grep "Default:" | awk '{print $2}')
        local outgoing_policy=$(ufw status verbose 2>/dev/null | grep "Default:" | awk '{print $4}')
        print_info "Default Policy: Incoming=$incoming_policy, Outgoing=$outgoing_policy"
    else
        print_warning "UFW not active or not installed"
        
        # Check if UFW is installed but not active
        if command -v ufw >/dev/null 2>&1; then
            print_info "UFW is installed but not enabled"
        else
            print_error "UFW is not installed"
        fi
    fi
    
    # Check Fail2Ban
    echo ""
    print_substep "Fail2Ban Check:"
    if systemctl is-active --quiet fail2ban; then
        fail2ban_status=1
        print_success "Fail2Ban Service: Active"
        
        # Show active jails
        if command -v fail2ban-client >/dev/null 2>&1; then
            local active_jails=$(fail2ban-client status 2>/dev/null | grep "Jail list:" | cut -d: -f2 | tr ',' '\n' | wc -w)
            print_info "Fail2Ban Jails: $active_jails active"
            
            # Show banned IPs count
            local banned_ips=0
            for jail in $(fail2ban-client status 2>/dev/null | grep "Jail list:" | cut -d: -f2 | tr ',' ' '); do
                local jail_banned=$(fail2ban-client status $jail 2>/dev/null | grep "Currently banned:" | awk '{print $3}' | head -1)
                banned_ips=$((banned_ips + jail_banned))
            done
            print_info "Currently Banned IPs: $banned_ips"
        fi
    else
        print_warning "Fail2Ban not running or not installed"
        
        # Check if Fail2Ban is installed but not running
        if command -v fail2ban-server >/dev/null 2>&1; then
            print_info "Fail2Ban is installed but not running"
        else
            print_error "Fail2Ban is not installed"
        fi
    fi
    
    echo ""
    
    # Check iptables rules
    print_step "Checking iptables rules..."
    local iptables_rules=$(iptables -L 2>/dev/null | grep -c "^Chain\|^target")
    if [[ $iptables_rules -gt 0 ]]; then
        print_info "Iptables rules: $iptables_rules chains/rules found"
    else
        print_warning "No iptables rules found"
    fi
    
    # Check for available updates
    print_step "Checking for available updates..."
    if check_firewall_update; then
        print_success "Firewall module is up to date"
    else
        print_warning "Firewall updates are available"
        print_info "Run 'sudo bash update_firewall.sh' to update"
    fi
    
    echo ""
    
    # Port security check
    print_step "Checking port security..."
    
    # Check SSH port access
    if ufw status 2>/dev/null | grep -q "22/tcp"; then
        print_success "SSH port (22) is configured in UFW"
    else
        print_warning "SSH port (22) not found in UFW rules"
    fi
    
    # Check for common vulnerable services
    local vulnerable_ports=("23" "21" "53" "25")
    for port in "${vulnerable_ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            if ufw status 2>/dev/null | grep -q "$port"; then
                print_info "Port $port: Open and configured in UFW"
            else
                print_warning "Port $port: Open but not configured in UFW"
            fi
        fi
    done
    
    echo ""
    
    # Summary
    print_header "Firewall Module Summary"
    
    if [[ $ufw_status -eq 1 ]]; then
        print_success "✓ UFW: Active and protecting system"
    else
        print_error "✗ UFW: Not active - system is unprotected"
    fi
    
    if [[ $fail2ban_status -eq 1 ]]; then
        print_success "✓ Fail2Ban: Active and monitoring"
    else
        print_warning "○ Fail2Ban: Not active - no intrusion detection"
    fi
    
    if [[ $ufw_status -eq 1 && $fail2ban_status -eq 1 ]]; then
        print_success "Firewall module is fully operational"
        exit 0
    elif [[ $ufw_status -eq 1 ]]; then
        print_warning "Firewall module is partially operational (UFW only)"
        exit 0
    else
        print_error "Firewall module is not operational - SECURITY RISK"
        print_info "Run 'sudo bash install.sh' to install firewall services"
        exit 2
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
        echo "  --quiet, -q    Quiet mode (minimal output)"
        echo "  --verbose, -v  Verbose mode (detailed output)"
        echo ""
        echo "This script checks the health and status of firewall services."
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
