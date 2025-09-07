#!/bin/bash
# Web Server Installation Script

# Get base directory and source functions
BASE_DIR="$(dirname "$0")"
source "$BASE_DIR/functions.sh"
source "$(dirname "$BASE_DIR")/common.sh"

# Main installation function
main() {
    clear
    show_header "WEB SERVER INSTALLATION"
    
    log_info "Starting web server installation..."
    echo ""
    
    # Check if already installed
    if check_package_installed "apache2" || check_package_installed "nginx"; then
        log_warn "Web server appears to be already installed"
        if ! confirm_action "Do you want to continue and reinstall/update?"; then
            log_info "Installation cancelled"
            exit 0
        fi
    fi
    
    # Install web server stack
    install_web
    
    log_ok "Web server installation completed!"
    echo ""
    log_info "You can now:"
    echo "  - Add websites using the web management menu"
    echo "  - Configure virtual hosts"
    echo "  - Install SSL certificates"
    echo ""
    
    pause "Press Enter to return to web management menu..."
}

# Run main function
main "$@"
