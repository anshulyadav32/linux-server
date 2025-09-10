#!/bin/bash
# =============================================================================
# Linux Setup - DNS Module Health Check
# =============================================================================
# Author: Anshul Yadav
# Description: Check the health and status of DNS services
# =============================================================================

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common functions
source "$SCRIPT_DIR/../common.sh" 2>/dev/null || {
    echo "[ERROR] Could not load common functions"
    exit 1
}

# Load DNS functions
source "$SCRIPT_DIR/functions.sh" 2>/dev/null || {
    echo "[ERROR] Could not load DNS functions"
    exit 1
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "DNS Module Health Check"
    
    local overall_status=0
    local bind9_status=0
    local dnsmasq_status=0
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Run comprehensive DNS module check
    print_step "Running comprehensive DNS module check..."
    if check_dns_module; then
        print_success "DNS module check passed"
    else
        print_error "DNS module check failed"
        overall_status=1
    fi
    
    echo ""
    
    # Individual component checks
    print_step "Checking individual DNS components..."
    
    # Check BIND9
    echo ""
    print_substep "BIND9 DNS Server Check:"
    if check_bind9; then
        bind9_status=1
        
        # Additional BIND9 checks
        if systemctl is-active --quiet bind9 || systemctl is-active --quiet named; then
            print_info "BIND9 Service: Active"
            
            # Test DNS resolution
            if nslookup localhost 127.0.0.1 >/dev/null 2>&1; then
                print_success "DNS Resolution: OK"
            else
                print_warning "DNS Resolution: Failed"
            fi
            
            # Check configuration
            if named-checkconf >/dev/null 2>&1; then
                print_success "BIND9 Configuration: Valid"
            else
                print_warning "BIND9 Configuration: Issues detected"
            fi
        fi
    else
        print_info "BIND9 not installed or not running"
    fi
    
    # Check dnsmasq
    echo ""
    print_substep "dnsmasq DNS Server Check:"
    if check_dnsmasq; then
        dnsmasq_status=1
        
        # Additional dnsmasq checks
        if systemctl is-active --quiet dnsmasq; then
            print_info "dnsmasq Service: Active"
            
            # Test DNS resolution
            if nslookup localhost 127.0.0.1 >/dev/null 2>&1; then
                print_success "DNS Resolution: OK"
            else
                print_warning "DNS Resolution: Failed"
            fi
            
            # Check configuration
            if dnsmasq --test >/dev/null 2>&1; then
                print_success "dnsmasq Configuration: Valid"
            else
                print_warning "dnsmasq Configuration: Issues detected"
            fi
        fi
    else
        print_info "dnsmasq not installed or not running"
    fi
    
    echo ""
    
    # DNS resolution testing
    print_step "Testing DNS resolution..."
    if test_dns_resolution >/dev/null 2>&1; then
        print_success "External DNS resolution working"
    else
        print_warning "External DNS resolution issues detected"
    fi
    
    echo ""
    
    # Check for available updates
    print_step "Checking for available updates..."
    if check_dns_update; then
        print_success "DNS module is up to date"
    else
        print_warning "DNS updates are available"
        print_info "Run 'sudo bash update_dns.sh' to update"
    fi
    
    echo ""
    
    # Summary
    print_header "DNS Module Summary"
    
    if [[ $bind9_status -eq 1 ]]; then
        print_success "✓ BIND9: Operational"
    else
        print_info "○ BIND9: Not installed"
    fi
    
    if [[ $dnsmasq_status -eq 1 ]]; then
        print_success "✓ dnsmasq: Operational"
    else
        print_info "○ dnsmasq: Not installed"
    fi
    
    if [[ $bind9_status -eq 1 || $dnsmasq_status -eq 1 ]]; then
        print_success "DNS module is operational"
        exit 0
    else
        print_warning "No DNS services are currently operational"
        print_info "Run 'sudo bash install.sh' to install DNS services"
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
        echo "This script checks the health and status of DNS services."
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
