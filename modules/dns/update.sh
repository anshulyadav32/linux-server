#!/bin/bash
# DNS Server Update Script

# Get base directory and source functions
BASE_DIR="$(dirname "$0")"
source "$BASE_DIR/functions.sh"
source "$(dirname "$BASE_DIR")/common.sh"

# Main update function
main() {
    clear
    show_header "DNS SERVER UPDATE"
    
    log_info "Starting DNS server update process..."
    echo ""
    
    # Check if DNS server is installed
    if ! check_package_installed "bind9"; then
        log_error "BIND9 DNS server is not installed"
        echo "Please install the DNS server first using the installation option"
        pause "Press Enter to continue..."
        exit 1
    fi
    
    log_info "Current DNS server status:"
    if systemctl is-active --quiet bind9; then
        echo "  ✓ BIND9 service is running"
    else
        echo "  ✗ BIND9 service is stopped"
    fi
    
    # Show current version
    local bind_version=$(named -v 2>&1 | head -1)
    echo "  Current version: $bind_version"
    echo ""
    
    if confirm_action "Do you want to proceed with updating DNS server components?"; then
        # Perform update
        update_dns
        
        log_ok "DNS server update completed!"
        echo ""
        log_info "Update summary:"
        echo "  ✓ Package cache refreshed"
        echo "  ✓ BIND9 and utilities updated"
        echo "  ✓ Root hints file updated"
        echo "  ✓ DNS service restarted"
        echo ""
        
        # Show updated version information
        show_updated_version_info
        
        # Verify service is running
        if systemctl is-active --quiet bind9; then
            log_ok "DNS service is running properly after update"
        else
            log_error "DNS service is not running after update"
            log_info "Attempting to start service..."
            restart_dns
        fi
    else
        log_info "Update cancelled by user"
    fi
    
    pause "Press Enter to return to DNS management menu..."
}

# Show updated version information
show_updated_version_info() {
    echo "=== Updated Version Information ==="
    
    local bind_version=$(named -v 2>&1 | head -1)
    echo "BIND9: $bind_version"
    
    if command_exists dig; then
        local dig_version=$(dig -v 2>&1)
        echo "Dig utility: $dig_version"
    fi
    
    echo ""
    echo "=== Service Status ==="
    systemctl status bind9 --no-pager | head -5
    
    echo ""
    echo "=== Configuration Test ==="
    if named-checkconf; then
        log_ok "Configuration is valid after update"
    else
        log_error "Configuration has issues after update"
    fi
}

# Run main function
main "$@"
