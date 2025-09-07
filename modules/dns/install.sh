#!/bin/bash
# DNS Server Installation Script

# Get base directory and source functions
BASE_DIR="$(dirname "$0")"
source "$BASE_DIR/functions.sh"
source "$(dirname "$BASE_DIR")/common.sh"

# Main installation function
main() {
    clear
    show_header "DNS SERVER INSTALLATION"
    
    log_info "Starting DNS server installation..."
    echo ""
    
    # Check if already installed
    if check_package_installed "bind9"; then
        log_warn "BIND9 DNS server appears to be already installed"
        if ! confirm_action "Do you want to continue and reinstall/update?"; then
            log_info "Installation cancelled"
            exit 0
        fi
    fi
    
    # Install DNS server
    install_dns
    
    # Show configuration information
    echo ""
    log_ok "DNS server installation completed!"
    echo ""
    log_info "DNS server is now running and configured with:"
    echo "  ✓ BIND9 DNS server"
    echo "  ✓ Basic security configuration"
    echo "  ✓ Forwarders configured (Google DNS, Cloudflare)"
    echo "  ✓ Zone management tools"
    echo ""
    echo "Next steps:"
    echo "  - Add DNS zones for your domains"
    echo "  - Configure DNS records (A, CNAME, MX, etc.)"
    echo "  - Update nameserver settings with your domain registrar"
    echo ""
    
    # Show server IP for reference
    local server_ip=$(get_server_ip)
    log_info "Your server IP address: $server_ip"
    echo "Use this IP when configuring nameservers at your domain registrar"
    echo ""
    
    pause "Press Enter to return to DNS management menu..."
}

# Run main function
main "$@"
