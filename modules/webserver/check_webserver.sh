#!/bin/bash
# =============================================================================
# Linux Setup - Webserver Module Health Check
# =============================================================================
# Author: Anshul Yadav
# Description: Check the health and status of webserver services
# =============================================================================

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common functions
source "$SCRIPT_DIR/../common.sh" 2>/dev/null || {
    echo "[ERROR] Could not load common functions"
    exit 1
}

# Load webserver functions
source "$SCRIPT_DIR/functions.sh" 2>/dev/null || {
    echo "[ERROR] Could not load webserver functions"
    exit 1
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "Webserver Module Health Check"
    
    local overall_status=0
    local apache_status=0
    local nginx_status=0
    local php_status=0
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Run comprehensive webserver module check
    print_step "Running comprehensive webserver module check..."
    if check_webserver_module; then
        print_success "Webserver module check passed"
    else
        print_error "Webserver module check failed"
        overall_status=1
    fi
    
    echo ""
    
    # Individual component checks
    print_step "Checking individual webserver components..."
    
    # Check Apache
    echo ""
    print_substep "Apache Web Server Check:"
    if check_apache; then
        apache_status=1
        
        # Additional Apache checks
        if systemctl is-active --quiet apache2 || systemctl is-active --quiet httpd; then
            print_info "Apache Service: Active"
            
            # Test configuration
            if apache2ctl configtest >/dev/null 2>&1 || httpd -t >/dev/null 2>&1; then
                print_success "Apache Configuration: Valid"
            else
                print_warning "Apache Configuration: Issues detected"
            fi
            
            # Test web response
            if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|403"; then
                print_success "Apache Web Response: OK"
            else
                print_warning "Apache Web Response: Failed"
            fi
        fi
    else
        print_info "Apache not installed or not running"
    fi
    
    # Check Nginx
    echo ""
    print_substep "Nginx Web Server Check:"
    if check_nginx; then
        nginx_status=1
        
        # Additional Nginx checks
        if systemctl is-active --quiet nginx; then
            print_info "Nginx Service: Active"
            
            # Test configuration
            if nginx -t >/dev/null 2>&1; then
                print_success "Nginx Configuration: Valid"
            else
                print_warning "Nginx Configuration: Issues detected"
            fi
        fi
    else
        print_info "Nginx not installed or not running"
    fi
    
    # Check PHP
    echo ""
    print_substep "PHP Check:"
    if check_php; then
        php_status=1
        
        # Additional PHP checks
        local php_version=$(php -v 2>/dev/null | head -1 | awk '{print $2}')
        if [[ -n "$php_version" ]]; then
            print_info "PHP Version: $php_version"
        fi
        
        # Check PHP-FPM
        if systemctl is-active --quiet php*-fpm 2>/dev/null; then
            print_success "PHP-FPM Service: Active"
        else
            print_info "PHP-FPM Service: Not running (using mod_php)"
        fi
        
        # Test PHP functionality
        if php -r "echo 'PHP Test: OK';" >/dev/null 2>&1; then
            print_success "PHP Functionality: OK"
        else
            print_warning "PHP Functionality: Issues detected"
        fi
    else
        print_info "PHP not installed"
    fi
    
    echo ""
    
    # Check for available updates
    print_step "Checking for available updates..."
    if check_webserver_update; then
        print_success "Webserver module is up to date"
    else
        print_warning "Webserver updates are available"
        print_info "Run 'sudo bash update_webserver.sh' to update"
    fi
    
    echo ""
    
    # Port checks
    print_step "Checking web server ports..."
    
    # Check port 80 (HTTP)
    if netstat -tuln 2>/dev/null | grep -q ":80 "; then
        print_success "Port 80 (HTTP): Listening"
    else
        print_warning "Port 80 (HTTP): Not listening"
    fi
    
    # Check port 443 (HTTPS)
    if netstat -tuln 2>/dev/null | grep -q ":443 "; then
        print_success "Port 443 (HTTPS): Listening"
    else
        print_info "Port 443 (HTTPS): Not listening (SSL not configured)"
    fi
    
    echo ""
    
    # Summary
    print_header "Webserver Module Summary"
    
    if [[ $apache_status -eq 1 ]]; then
        print_success "✓ Apache: Operational"
        if command -v apache2ctl >/dev/null 2>&1; then
            apache_modules=$(apache2ctl -M 2>/dev/null | wc -l)
            print_info "Apache Modules: $apache_modules loaded"
        fi
    else
        if command -v apache2 >/dev/null 2>&1; then
            if systemctl is-active --quiet apache2; then
                print_success "Apache is installed and running"
            else
                print_warning "Apache is installed but not running"
            fi
        else
            print_error "Apache is not installed"
        fi
    fi
    
    if [[ $nginx_status -eq 1 ]]; then
        print_success "✓ Nginx: Operational"
        if command -v nginx >/dev/null 2>&1; then
            nginx_config=$(nginx -T 2>/dev/null | wc -l)
            print_info "Nginx Config Lines: $nginx_config"
        fi
    else
        if command -v nginx >/dev/null 2>&1; then
            if systemctl is-active --quiet nginx; then
                print_success "Nginx is installed and running"
            else
                print_warning "Nginx is installed but not running"
            fi
        else
            print_error "Nginx is not installed"
        fi
    fi
    
    if command -v php >/dev/null 2>&1; then
        if systemctl is-active --quiet php8.3-fpm; then
            php_version=$(php -v 2>/dev/null | head -n1)
            print_info "PHP Version: $php_version"
        else
            print_warning "PHP-FPM is installed but not running"
        fi
    else
        print_error "PHP is not installed"
    fi
# =============================================================================

# Handle command line arguments
case "${1:-}" in
        if command -v nginx >/dev/null 2>&1; then
            if systemctl is-active --quiet nginx; then
        echo "Usage: $0 [options]"
        echo ""
                # Show Nginx config
                local nginx_config=$(nginx -T 2>/dev/null | wc -l)
                print_info "Nginx Config Lines: $nginx_config"
            else
                print_warning "Nginx is installed but not running"
            fi
        else
            print_error "Nginx is not installed"
        fi
    --verbose|-v)
        VERBOSE_MODE=1
        ;;
esac
        if command -v php >/dev/null 2>&1; then
            if systemctl is-active --quiet php8.3-fpm; then
# Execute main function
main "$@"
                # Show PHP version
                local php_version=$(php -v 2>/dev/null | head -n1)
                print_info "PHP Version: $php_version"
            else
                print_warning "PHP-FPM is installed but not running"
            fi
        else
            print_error "PHP is not installed"
        fi
