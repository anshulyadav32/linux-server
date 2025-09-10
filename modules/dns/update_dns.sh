#!/bin/bash
# =============================================================================
# Linux Setup - DNS Module Update
# =============================================================================
# Author: Anshul Yadav
# Description: Update DNS services and components
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
    print_header "DNS Module Update"
    
    local overall_status=0
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Check for available updates first
    print_step "Checking for available updates..."
    if check_dns_update; then
        print_info "No updates available"
        if [[ "${FORCE_UPDATE:-}" != "1" ]]; then
            print_success "DNS module is already up to date"
            exit 0
        fi
    else
        print_info "Updates are available, proceeding with update..."
    fi
    
    echo ""
    
    # Backup DNS configuration before updating
    print_step "Creating backup before update..."
    if command -v backup_dns_config >/dev/null 2>&1; then
        backup_dns_config
    else
        print_warning "Backup function not available, skipping backup"
    fi
    
    echo ""
    
    # Run comprehensive DNS module update
    print_step "Running comprehensive DNS module update..."
    if update_dns_module; then
        print_success "DNS module updated successfully"
    else
        print_error "DNS module update failed"
        overall_status=1
    fi
    
    echo ""
    
    # Individual component updates
    print_step "Updating individual DNS components..."
    
    # Update BIND9 if installed
    if systemctl list-unit-files | grep -q "bind9.service\|named.service"; then
        echo ""
        print_substep "Updating BIND9..."
        if update_bind9; then
            print_success "BIND9 updated successfully"
            
            # Verify service is running after update
            if systemctl is-active --quiet bind9 || systemctl is-active --quiet named; then
                print_success "BIND9 service is running after update"
            else
                print_warning "BIND9 service not running, attempting restart..."
                systemctl restart bind9 2>/dev/null || systemctl restart named 2>/dev/null
            fi
            
            # Verify configuration
            if named-checkconf >/dev/null 2>&1; then
                print_success "BIND9 configuration is valid"
            else
                print_warning "BIND9 configuration has issues"
            fi
        else
            print_error "BIND9 update failed"
            overall_status=1
        fi
    else
        print_info "BIND9 not installed, skipping"
    fi
    
    # Update dnsmasq if installed
    if systemctl list-unit-files | grep -q "dnsmasq.service"; then
        echo ""
        print_substep "Updating dnsmasq..."
        if update_dnsmasq; then
            print_success "dnsmasq updated successfully"
            
            # Verify service is running after update
            if systemctl is-active --quiet dnsmasq; then
                print_success "dnsmasq service is running after update"
            else
                print_warning "dnsmasq service not running, attempting restart..."
                systemctl restart dnsmasq
            fi
            
            # Verify configuration
            if dnsmasq --test >/dev/null 2>&1; then
                print_success "dnsmasq configuration is valid"
            else
                print_warning "dnsmasq configuration has issues"
            fi
        else
            print_error "dnsmasq update failed"
            overall_status=1
        fi
    else
        print_info "dnsmasq not installed, skipping"
    fi
    
    echo ""
    
    # Update DNS utilities
    print_step "Updating DNS utilities..."
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y dnsutils dig nslookup >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        print_success "DNS utilities updated"
    else
        print_warning "Some DNS utilities may not have updated properly"
    fi
    
    echo ""
    
    # Post-update verification
    print_step "Verifying DNS services after update..."
    
    local bind9_ok=0
    local dnsmasq_ok=0
    
    # Verify BIND9
    if systemctl list-unit-files | grep -q "bind9.service\|named.service"; then
        if check_bind9 >/dev/null 2>&1; then
            print_success "BIND9 verification: PASSED"
            bind9_ok=1
        else
            print_error "BIND9 verification: FAILED"
            overall_status=1
        fi
    fi
    
    # Verify dnsmasq
    if systemctl list-unit-files | grep -q "dnsmasq.service"; then
        if check_dnsmasq >/dev/null 2>&1; then
            print_success "dnsmasq verification: PASSED"
            dnsmasq_ok=1
        else
            print_error "dnsmasq verification: FAILED"
            overall_status=1
        fi
    fi
    
    # Test DNS resolution
    if test_dns_resolution >/dev/null 2>&1; then
        print_success "DNS resolution test: PASSED"
    else
        print_warning "DNS resolution test: FAILED"
        overall_status=1
    fi
    
    echo ""
    
    # Final status
    print_header "DNS Update Summary"
    
    if [[ $overall_status -eq 0 ]]; then
        print_success "DNS module update completed successfully"
        
        if [[ $bind9_ok -eq 1 ]]; then
            print_success "✓ BIND9: Updated and verified"
        fi
        
        if [[ $dnsmasq_ok -eq 1 ]]; then
            print_success "✓ dnsmasq: Updated and verified"
        fi
        
        print_info "DNS services are ready for use"
        exit 0
    else
        print_error "DNS module update completed with errors"
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
        echo "This script updates DNS services and components."
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
