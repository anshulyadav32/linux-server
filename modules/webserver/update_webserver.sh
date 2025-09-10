#!/bin/bash
# =============================================================================
# Linux Setup - Webserver Module Update
# =============================================================================
# Author: Anshul Yadav
# Description: Update webserver services and components
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
    print_header "Webserver Module Update"
    
    local overall_status=0
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Check for available updates first
    print_step "Checking for available updates..."
    if check_webserver_update; then
        print_info "No updates available"
        if [[ "${FORCE_UPDATE:-}" != "1" ]]; then
            print_success "Webserver module is already up to date"
            exit 0
        fi
    else
        print_info "Updates are available, proceeding with update..."
    fi
    
    echo ""
    
    # Backup webserver configuration before updating
    print_step "Creating backup before update..."
    if command -v backup_web_configs >/dev/null 2>&1; then
        backup_web_configs
    else
        print_warning "Backup function not available, skipping backup"
    fi
    
    echo ""
    
    # Run comprehensive webserver module update
    print_step "Running comprehensive webserver module update..."
    if update_webserver_module; then
        print_success "Webserver module updated successfully"
    else
        print_error "Webserver module update failed"
        overall_status=1
    fi
    
    echo ""
    
    # Individual component updates
    print_step "Updating individual webserver components..."
    
    # Update Apache if installed
    if systemctl list-unit-files | grep -q "apache2.service\|httpd.service"; then
        echo ""
        print_substep "Updating Apache..."
        if update_apache; then
            print_success "Apache updated successfully"
            
            # Verify service is running after update
            if systemctl is-active --quiet apache2 || systemctl is-active --quiet httpd; then
                print_success "Apache service is running after update"
            else
                print_warning "Apache service not running, attempting restart..."
                systemctl restart apache2 2>/dev/null || systemctl restart httpd 2>/dev/null
            fi
            
            # Verify configuration
            if apache2ctl configtest >/dev/null 2>&1 || httpd -t >/dev/null 2>&1; then
                print_success "Apache configuration is valid"
            else
                print_warning "Apache configuration has issues"
            fi
        else
            print_error "Apache update failed"
            overall_status=1
        fi
    else
        print_info "Apache not installed, skipping"
    fi
    
    # Update Nginx if installed
    if systemctl list-unit-files | grep -q "nginx.service"; then
        echo ""
        print_substep "Updating Nginx..."
        if update_nginx; then
            print_success "Nginx updated successfully"
            
            # Verify service is running after update
            if systemctl is-active --quiet nginx; then
                print_success "Nginx service is running after update"
            else
                print_warning "Nginx service not running, attempting restart..."
                systemctl restart nginx
            fi
            
            # Verify configuration
            if nginx -t >/dev/null 2>&1; then
                print_success "Nginx configuration is valid"
            else
                print_warning "Nginx configuration has issues"
            fi
        else
            print_error "Nginx update failed"
            overall_status=1
        fi
    else
        print_info "Nginx not installed, skipping"
    fi
    
    # Update PHP if installed
    if command -v php >/dev/null 2>&1; then
        echo ""
        print_substep "Updating PHP..."
        if update_php; then
            print_success "PHP updated successfully"
            
            # Verify PHP functionality
            if php -r "echo 'PHP Test OK';" >/dev/null 2>&1; then
                print_success "PHP functionality verified"
            else
                print_warning "PHP functionality issues detected"
            fi
            
            # Restart web servers to load new PHP
            systemctl restart apache2 2>/dev/null || true
            systemctl restart nginx 2>/dev/null || true
            systemctl restart php*-fpm 2>/dev/null || true
        else
            print_error "PHP update failed"
            overall_status=1
        fi
    else
        print_info "PHP not installed, skipping"
    fi
    
    echo ""
    
    # Post-update verification
    print_step "Verifying webserver services after update..."
    
    local apache_ok=0
    local nginx_ok=0
    local php_ok=0
    
    # Verify Apache
    if systemctl list-unit-files | grep -q "apache2.service\|httpd.service"; then
        if check_apache >/dev/null 2>&1; then
            print_success "Apache verification: PASSED"
            apache_ok=1
        else
            print_error "Apache verification: FAILED"
            overall_status=1
        fi
    fi
    
    # Verify Nginx
    if systemctl list-unit-files | grep -q "nginx.service"; then
        if check_nginx >/dev/null 2>&1; then
            print_success "Nginx verification: PASSED"
            nginx_ok=1
        else
            print_error "Nginx verification: FAILED"
            overall_status=1
        fi
    fi
    
    # Verify PHP
    if command -v php >/dev/null 2>&1; then
        if check_php >/dev/null 2>&1; then
            print_success "PHP verification: PASSED"
            php_ok=1
        else
            print_error "PHP verification: FAILED"
            overall_status=1
        fi
    fi
    
    # Test web response
    if curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null | grep -q "200\|403"; then
        print_success "Web response test: PASSED"
    else
        print_warning "Web response test: FAILED"
    fi
    
    echo ""
    
    # Final status
    print_header "Webserver Update Summary"
    
    if [[ $overall_status -eq 0 ]]; then
        print_success "Webserver module update completed successfully"
        
        if [[ $apache_ok -eq 1 ]]; then
            print_success "✓ Apache: Updated and verified"
        fi
        
        if [[ $nginx_ok -eq 1 ]]; then
            print_success "✓ Nginx: Updated and verified"
        fi
        
        if [[ $php_ok -eq 1 ]]; then
            print_success "✓ PHP: Updated and verified"
        fi
        
        print_info "Webserver services are ready for use"
        exit 0
    else
        print_error "Webserver module update completed with errors"
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
        echo "This script updates webserver services and components."
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
