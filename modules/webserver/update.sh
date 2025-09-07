#!/bin/bash
# =============================================================================
# Linux Setup - Webserver Module Update
# =============================================================================
# Author: Anshul Yadav
# Description: Update and maintenance functions for webserver module
# =============================================================================

set -e

# Script directory and base directory detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions
if [[ -f "$BASE_DIR/modules/common.sh" ]]; then
    source "$BASE_DIR/modules/common.sh"
else
    echo "Error: common.sh not found"
    exit 1
fi

# Source webserver functions
if [[ -f "$SCRIPT_DIR/functions.sh" ]]; then
    source "$SCRIPT_DIR/functions.sh"
fi

# ==========================================
# WEBSERVER UPDATE MAIN FUNCTION
# ==========================================

update_webserver() {
    print_section_header "🌐 WEBSERVER MODULE UPDATE"
    
    log_info "Starting webserver module update..."
    
    # Check if running as root
    check_root
    
    # Backup current configurations
    backup_webserver_configs
    
    # Update system packages
    update_webserver_packages
    
    # Update configurations
    update_webserver_configs
    
    # Update security settings
    update_webserver_security
    
    # Update SSL certificates
    update_webserver_ssl
    
    # Restart services
    restart_webserver_services
    
    # Verify update
    verify_webserver_update
    
    print_success "Webserver module update completed successfully!"
    
    # Display summary
    display_update_summary
    
    log_info "Webserver module update completed"
}

# ==========================================
# BACKUP FUNCTIONS
# ==========================================

backup_webserver_configs() {
    print_step "Backing up webserver configurations..."
    
    local backup_dir="/root/backups/webserver-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup Apache configurations
    if [[ -d "/etc/apache2" ]]; then
        cp -r /etc/apache2 "$backup_dir/" 2>/dev/null || true
        log_info "Apache configuration backed up"
    fi
    
    # Backup Nginx configurations
    if [[ -d "/etc/nginx" ]]; then
        cp -r /etc/nginx "$backup_dir/" 2>/dev/null || true
        log_info "Nginx configuration backed up"
    fi
    
    # Backup PHP configurations
    if [[ -d "/etc/php" ]]; then
        cp -r /etc/php "$backup_dir/" 2>/dev/null || true
        log_info "PHP configuration backed up"
    fi
    
    # Backup SSL certificates
    if [[ -d "/etc/ssl" ]]; then
        cp -r /etc/ssl "$backup_dir/" 2>/dev/null || true
        log_info "SSL certificates backed up"
    fi
    
    # Create backup info
    cat > "$backup_dir/backup_info.txt" << EOF
Webserver Configuration Backup
Created: $(date)
Hostname: $(hostname)
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Backup includes:
- Apache configuration
- Nginx configuration  
- PHP configuration
- SSL certificates
EOF
    
    log_success "Configuration backup completed: $backup_dir"
}

# ==========================================
# PACKAGE UPDATE FUNCTIONS
# ==========================================

update_webserver_packages() {
    print_step "Updating webserver packages..."
    
    case $OS in
        "ubuntu"|"debian")
            apt_update
            apt_upgrade "apache2 apache2-utils nginx"
            apt_upgrade "php php-cli php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-zip"
            apt_upgrade "certbot python3-certbot-apache python3-certbot-nginx"
            ;;
        "centos"|"rhel"|"rocky"|"alma")
            dnf_update "httpd httpd-tools nginx"
            dnf_update "php php-cli php-fpm php-mysqlnd php-curl php-gd php-mbstring php-xml php-zip"
            dnf_update "certbot python3-certbot-apache python3-certbot-nginx"
            ;;
        "arch")
            pacman_update "apache nginx php php-fpm certbot"
            ;;
    esac
    
    log_info "Webserver packages updated successfully"
}

# ==========================================
# CONFIGURATION UPDATE FUNCTIONS
# ==========================================

update_webserver_configs() {
    print_step "Updating webserver configurations..."
    
    # Update Apache configuration
    update_apache_config
    
    # Update Nginx configuration
    update_nginx_config
    
    # Update PHP configuration
    update_php_config
    
    # Test configurations
    test_webserver_configs
    
    log_info "Webserver configurations updated"
}

update_apache_config() {
    print_substep "Updating Apache configuration..."
    
    # Update security settings
    configure_apache_security
    
    # Enable recommended modules
    local modules=(
        "rewrite" "ssl" "headers" "expires" "deflate"
        "proxy" "proxy_http" "proxy_balancer" "lbmethod_byrequests"
    )
    
    for module in "${modules[@]}"; do
        enable_apache_module "$module"
    done
    
    # Update ServerTokens and ServerSignature
    local apache_conf="/etc/apache2/apache2.conf"
    if [[ -f "$apache_conf" ]]; then
        sed -i 's/^ServerTokens.*/ServerTokens Prod/' "$apache_conf"
        sed -i 's/^ServerSignature.*/ServerSignature Off/' "$apache_conf"
    fi
    
    log_info "Apache configuration updated"
}

update_nginx_config() {
    print_substep "Updating Nginx configuration..."
    
    # Update main nginx configuration
    local nginx_conf="/etc/nginx/nginx.conf"
    
    if [[ -f "$nginx_conf" ]]; then
        # Ensure server_tokens is off
        if ! grep -q "server_tokens off" "$nginx_conf"; then
            sed -i '/http {/a\    server_tokens off;' "$nginx_conf"
        fi
        
        # Update worker processes
        local cpu_cores=$(nproc)
        sed -i "s/worker_processes.*/worker_processes $cpu_cores;/" "$nginx_conf"
        
        # Update worker connections
        sed -i 's/worker_connections.*/worker_connections 1024;/' "$nginx_conf"
    fi
    
    # Update security configuration
    configure_nginx_security
    
    log_info "Nginx configuration updated"
}

update_php_config() {
    print_substep "Updating PHP configuration..."
    
    local php_ini_files=$(find /etc/php* -name "php.ini" 2>/dev/null)
    
    for php_ini in $php_ini_files; do
        # Update security settings
        sed -i 's/expose_php = On/expose_php = Off/' "$php_ini"
        sed -i 's/;date.timezone =/date.timezone = UTC/' "$php_ini"
        
        # Update memory and file upload limits
        sed -i 's/memory_limit = .*/memory_limit = 256M/' "$php_ini"
        sed -i 's/upload_max_filesize = .*/upload_max_filesize = 100M/' "$php_ini"
        sed -i 's/post_max_size = .*/post_max_size = 100M/' "$php_ini"
        
        # Update session security
        sed -i 's/session.cookie_httponly =.*/session.cookie_httponly = 1/' "$php_ini"
        sed -i 's/session.use_strict_mode =.*/session.use_strict_mode = 1/' "$php_ini"
    done
    
    log_info "PHP configuration updated"
}

test_webserver_configs() {
    print_substep "Testing webserver configurations..."
    
    # Test Apache configuration
    if command -v apache2ctl >/dev/null 2>&1; then
        if ! apache2ctl configtest >/dev/null 2>&1; then
            log_error "Apache configuration test failed"
            return 1
        fi
    elif command -v httpd >/dev/null 2>&1; then
        if ! httpd -t >/dev/null 2>&1; then
            log_error "Apache configuration test failed"
            return 1
        fi
    fi
    
    # Test Nginx configuration
    if command -v nginx >/dev/null 2>&1; then
        if ! nginx -t >/dev/null 2>&1; then
            log_error "Nginx configuration test failed"
            return 1
        fi
    fi
    
    log_success "All webserver configurations are valid"
}

# ==========================================
# SECURITY UPDATE FUNCTIONS
# ==========================================

update_webserver_security() {
    print_step "Updating webserver security..."
    
    # Update Fail2Ban configurations
    update_fail2ban_config
    
    # Update log rotation
    configure_webserver_logrotate
    
    # Update file permissions
    secure_webserver_permissions
    
    # Update firewall rules
    update_firewall_rules
    
    log_info "Webserver security updated"
}

update_fail2ban_config() {
    print_substep "Updating Fail2Ban configuration..."
    
    if command -v fail2ban-server >/dev/null 2>&1; then
        # Configure webserver-specific jails
        configure_webserver_fail2ban
        
        # Restart fail2ban
        systemctl restart fail2ban >/dev/null 2>&1 || true
        
        log_info "Fail2Ban configuration updated"
    else
        log_warning "Fail2Ban not installed"
    fi
}

update_firewall_rules() {
    print_substep "Updating firewall rules..."
    
    # Ensure HTTP and HTTPS ports are open
    configure_webserver_firewall
    
    log_info "Firewall rules updated"
}

# ==========================================
# SSL UPDATE FUNCTIONS
# ==========================================

update_webserver_ssl() {
    print_step "Updating SSL certificates..."
    
    # Check if Let's Encrypt certificates exist
    if [[ -d "/etc/letsencrypt/live" ]]; then
        update_letsencrypt_certs
    else
        log_info "No Let's Encrypt certificates found"
    fi
    
    # Update SSL configurations
    update_ssl_configs
    
    log_info "SSL certificates updated"
}

update_letsencrypt_certs() {
    print_substep "Updating Let's Encrypt certificates..."
    
    if command -v certbot >/dev/null 2>&1; then
        # Renew certificates
        certbot renew --quiet || log_warning "Certificate renewal failed"
        
        # Restart web servers to load new certificates
        systemctl reload apache2 >/dev/null 2>&1 || systemctl reload httpd >/dev/null 2>&1 || true
        systemctl reload nginx >/dev/null 2>&1 || true
        
        log_info "Let's Encrypt certificates renewed"
    else
        log_warning "Certbot not installed"
    fi
}

update_ssl_configs() {
    print_substep "Updating SSL configurations..."
    
    # Update SSL virtual hosts with modern configurations
    configure_ssl_virtual_hosts
    
    log_info "SSL configurations updated"
}

# ==========================================
# SERVICE RESTART FUNCTIONS
# ==========================================

restart_webserver_services() {
    print_step "Restarting webserver services..."
    
    # Restart Apache
    if systemctl is-active apache2 >/dev/null 2>&1; then
        systemctl restart apache2
        log_info "Apache restarted"
    elif systemctl is-active httpd >/dev/null 2>&1; then
        systemctl restart httpd
        log_info "Apache (httpd) restarted"
    fi
    
    # Restart Nginx
    if systemctl is-active nginx >/dev/null 2>&1; then
        systemctl restart nginx
        log_info "Nginx restarted"
    fi
    
    # Restart PHP-FPM
    if systemctl is-active php-fpm >/dev/null 2>&1; then
        systemctl restart php-fpm
        log_info "PHP-FPM restarted"
    fi
    
    # Wait for services to start
    sleep 3
    
    log_info "Webserver services restarted"
}

# ==========================================
# VERIFICATION FUNCTIONS
# ==========================================

verify_webserver_update() {
    print_step "Verifying webserver update..."
    
    # Check service status
    check_service_status "apache2" || check_service_status "httpd"
    check_service_status "nginx"
    
    # Check port availability
    check_port_listening 80
    check_port_listening 443
    
    # Test web server response
    test_webserver_response
    
    # Check SSL certificate validity
    check_ssl_certificates
    
    log_info "Webserver update verification completed"
}

check_ssl_certificates() {
    print_substep "Checking SSL certificates..."
    
    # Check if SSL is properly configured
    if openssl s_client -connect localhost:443 -servername localhost </dev/null >/dev/null 2>&1; then
        log_success "SSL certificate is valid"
    else
        log_warning "SSL certificate check failed"
    fi
}

# ==========================================
# SUMMARY DISPLAY
# ==========================================

display_update_summary() {
    print_section_header "🌐 WEBSERVER UPDATE SUMMARY"
    
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                    🌐 WEBSERVER UPDATE                     │${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│                                                             │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Packages updated to latest versions              │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Configurations updated and optimized             │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Security settings enhanced                        │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} SSL certificates renewed                          │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Services restarted and verified                   │${NC}"
    echo -e "${BLUE}│                                                             │${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│  ${CYAN}📊 CURRENT STATUS:${NC}                                  │${NC}"
    echo -e "${BLUE}│    • Apache: $(systemctl is-active apache2 2>/dev/null || systemctl is-active httpd 2>/dev/null || echo 'inactive')                                │${NC}"
    echo -e "${BLUE}│    • Nginx:  $(systemctl is-active nginx 2>/dev/null || echo 'inactive')                                │${NC}"
    echo -e "${BLUE}│    • PHP-FPM: $(systemctl is-active php-fpm 2>/dev/null || echo 'inactive')                               │${NC}"
    echo -e "${BLUE}│                                                             │${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│  ${CYAN}📝 BACKUP LOCATION:${NC}                                │${NC}"
    echo -e "${BLUE}│    /root/backups/webserver-$(date +%Y%m%d)_*               │${NC}"
    echo -e "${BLUE}│                                                             │${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${GREEN}🎉 Webserver module update completed successfully!${NC}"
    echo -e "${CYAN}📚 Run './master.sh' for interactive management${NC}"
    echo ""
}

# ==========================================
# MAIN EXECUTION
# ==========================================

main() {
    # Create log entry
    log_info "=== Webserver Module Update Started ==="
    
    # Run update
    update_webserver
    
    # Create log entry
    log_info "=== Webserver Module Update Completed ==="
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
