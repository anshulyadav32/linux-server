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
    
    # Check for available updates
    echo "Checking for available updates..."
    apt-get update -y >/dev/null
    local updates=$(apt list --upgradable 2>/dev/null | grep -E "bind9|dnsutils")
    
    if [[ -n "$updates" ]]; then
        echo -e "\nAvailable updates:"
        echo "$updates"
    else
        echo -e "\nNo updates available for DNS components"
    fi
    
    echo -e "\nUpdate Options:"
    echo "1) Update DNS server packages only"
    echo "2) Update root hints file only"
    echo "3) Update security policies"
    echo "4) Full system update"
    echo "5) Cancel"
    echo
    
    read -p "Select update option [1-5]: " update_choice
    
    case $update_choice in
        1)
            if confirm_action "Update DNS server packages?"; then
                update_dns
            fi
            ;;
        2)
            echo "Updating root hints file..."
            wget -O /etc/bind/db.root https://www.internic.net/domain/named.root
            reload_dns
            ;;
        3)
            echo "Updating security policies..."
            # Update DNSSEC trust anchors
            dnssec-keygen -a RSASHA256 -b 2048 -n ZONE example.com
            reload_dns
            ;;
        4)
            if confirm_action "Perform full system update? This may take some time."; then
                # Create backup first
                backup_dns_config
                
                # Full system update
                apt-get update -y
                apt-get upgrade -y
                
                # Update DNS components
                update_dns
                
                echo "Full system update completed"
            fi
            ;;
        5)
            log_info "Update cancelled"
            return
            ;;
        *)
            log_error "Invalid option"
            return
            ;;
    esac
    
    log_ok "Update process completed!"
    echo ""
    log_info "Update summary:"
        
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
