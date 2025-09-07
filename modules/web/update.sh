#!/bin/bash
# Web Server Update Script

# Get base directory and source functions
BASE_DIR="$(dirname "$0")"
source "$BASE_DIR/functions.sh"
source "$(dirname "$BASE_DIR")/common.sh"

# Main update function
main() {
    clear
    show_header "WEB SERVER UPDATE"
    
    log_info "Starting web server update process..."
    echo ""
    
    # Check what's installed
    local web_installed=false
    if check_package_installed "apache2" || check_package_installed "nginx"; then
        web_installed=true
    fi
    
    if [[ "$web_installed" = false ]]; then
        log_error "No web server appears to be installed"
        echo "Please install a web server first using the installation option"
        pause "Press Enter to continue..."
        exit 1
    fi
    
    log_info "Detected installed web services:"
    if check_package_installed "apache2"; then
        echo "  ✓ Apache2"
    fi
    if check_package_installed "nginx"; then
        echo "  ✓ Nginx"
    fi
    if check_package_installed "php"; then
        echo "  ✓ PHP"
    fi
    echo ""
    
    if confirm_action "Do you want to proceed with updating web server components?"; then
        # Perform update
        update_web
        
        log_ok "Web server update completed!"
        echo ""
        log_info "Update summary:"
        echo "  ✓ Package cache refreshed"
        echo "  ✓ Web server packages updated"
        echo "  ✓ PHP packages updated (if installed)"
        echo "  ✓ Services restarted"
        echo ""
        
        # Show version information
        show_version_info
    else
        log_info "Update cancelled by user"
    fi
    
    pause "Press Enter to return to web management menu..."
}

# Show version information
show_version_info() {
    echo "=== Updated Version Information ==="
    
    if command_exists apache2; then
        echo "Apache: $(apache2 -v | head -1 | awk '{print $3}')"
    fi
    
    if command_exists nginx; then
        echo "Nginx: $(nginx -v 2>&1 | cut -d/ -f2)"
    fi
    
    if command_exists php; then
        echo "PHP: $(php -v | head -1 | awk '{print $2}')"
    fi
    
    if command_exists node; then
        echo "Node.js: $(node -v)"
    fi
    
    if command_exists npm; then
        echo "NPM: $(npm -v)"
    fi
}

# Run main function
main "$@"
