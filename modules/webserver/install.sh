#!/bin/bash
# =============================================================================
# Linux Setup - Webserver Module Installer
# =============================================================================
# Author: Anshul Yadav
# curl -sSL ls.r-u.live/webserver.sh | sudo bash
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
# WEBSERVER INSTALLATION MAIN FUNCTION
# ==========================================

install_webserver() {
    print_section_header "🌐 WEBSERVER MODULE INSTALLATION"
    
    log_info "Starting webserver module installation..."
    
    # Check if running as root
    check_root
    
    # Detect system
    detect_system
    
    # Check system requirements
    check_webserver_requirements
    
    print_step "Installing webserver components..."
    
    # Install web server packages
    install_web_packages
    
    # Configure Apache/Nginx
    configure_webserver
    
    # Install PHP and modules
    install_php
    
    # Configure virtual hosts
    setup_virtual_hosts
    
    # Configure SSL/TLS
    configure_webserver_ssl
    
    # Set up security configurations
    configure_webserver_security
    
    # Install additional tools
    install_web_tools
    
    # Configure firewall rules
    configure_webserver_firewall
    
    # Start and enable services
    start_webserver_services
    
    # Run post-installation checks
    verify_webserver_installation
    
    print_success "Webserver module installation completed successfully!"
    
    # Display summary
    display_webserver_summary
    
    log_info "Webserver module installation completed"
}

# ==========================================
# WEBSERVER REQUIREMENTS CHECK
# ==========================================

check_webserver_requirements() {
    print_step "Checking webserver requirements..."
    
    # Check minimum system requirements
    local total_memory=$(get_total_memory)
    if [[ $total_memory -lt 1024 ]]; then
        log_warning "Low memory detected: ${total_memory}MB. Recommended: 1GB+"
    fi
    
    # Check disk space
    local available_space=$(get_available_space "/")
    if [[ $available_space -lt 2048 ]]; then
        log_error "Insufficient disk space. Need at least 2GB available"
        exit 1
    fi
    
    # Check if ports are available
    check_port_availability 80 "HTTP"
    check_port_availability 443 "HTTPS"
    
    log_info "Webserver requirements check completed"
}

# ==========================================
# PACKAGE INSTALLATION
# ==========================================

install_web_packages() {
    print_step "Installing web server packages..."
    
    case $OS in
        "ubuntu"|"debian")
            apt_update
            apt_install "apache2 apache2-utils"
            apt_install "nginx"
            apt_install "certbot python3-certbot-apache python3-certbot-nginx"
            ;;
        "centos"|"rhel"|"rocky"|"alma")
            dnf_install "httpd httpd-tools"
            dnf_install "nginx"
            dnf_install "certbot python3-certbot-apache python3-certbot-nginx"
            ;;
        "arch")
            pacman_install "apache nginx certbot certbot-apache certbot-nginx"
            ;;
        *)
            log_error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
    
    log_info "Web server packages installed successfully"
}

# ==========================================
# WEBSERVER CONFIGURATION
# ==========================================

configure_webserver() {
    print_step "Configuring web server..."
    
    # Configure Apache
    configure_apache
    
    # Configure Nginx (as reverse proxy/load balancer)
    configure_nginx
    
    # Set up default configurations
    setup_default_configs
    
    log_info "Web server configuration completed"
}

configure_apache() {
    print_substep "Configuring Apache..."
    
    # Enable required modules
    local apache_modules=(
        "rewrite"
        "ssl" 
        "headers"
        "expires"
        "deflate"
        "proxy"
        "proxy_http"
        "proxy_balancer"
        "lbmethod_byrequests"
    )
    
    for module in "${apache_modules[@]}"; do
        enable_apache_module "$module"
    done
    
    # Configure Apache security
    configure_apache_security
    
    # Set up virtual host directory
    mkdir -p /var/www/html
    mkdir -p /etc/apache2/sites-available
    mkdir -p /etc/apache2/sites-enabled
    
    log_info "Apache configuration completed"
}

configure_nginx() {
    print_substep "Configuring Nginx..."
    
    # Create Nginx directories
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    mkdir -p /var/www/html
    
    # Configure Nginx as reverse proxy
    setup_nginx_reverse_proxy
    
    # Configure Nginx security
    configure_nginx_security
    
    log_info "Nginx configuration completed"
}

# ==========================================
# PHP INSTALLATION AND CONFIGURATION
# ==========================================

install_php() {
    print_step "Installing PHP and modules..."
    
    case $OS in
        "ubuntu"|"debian")
            apt_install "php php-cli php-fpm"
            apt_install "php-mysql php-pgsql php-sqlite3"
            apt_install "php-curl php-gd php-mbstring php-xml php-zip"
            apt_install "php-json php-bcmath php-intl php-soap"
            apt_install "libapache2-mod-php"
            ;;
        "centos"|"rhel"|"rocky"|"alma")
            dnf_install "php php-cli php-fpm"
            dnf_install "php-mysqlnd php-pgsql php-pdo"
            dnf_install "php-curl php-gd php-mbstring php-xml php-zip"
            dnf_install "php-json php-bcmath php-intl php-soap"
            ;;
        "arch")
            pacman_install "php php-fpm php-apache"
            pacman_install "php-gd php-intl php-sqlite"
            ;;
    esac
    
    # Configure PHP
    configure_php_settings
    
    log_info "PHP installation and configuration completed"
}

configure_php_settings() {
    print_substep "Configuring PHP settings..."
    
    local php_ini="/etc/php/*/apache2/php.ini"
    
    # Update PHP settings for security and performance
    sed -i 's/;date.timezone =/date.timezone = UTC/' $php_ini 2>/dev/null || true
    sed -i 's/expose_php = On/expose_php = Off/' $php_ini 2>/dev/null || true
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' $php_ini 2>/dev/null || true
    sed -i 's/post_max_size = 8M/post_max_size = 100M/' $php_ini 2>/dev/null || true
    sed -i 's/memory_limit = 128M/memory_limit = 256M/' $php_ini 2>/dev/null || true
    
    log_info "PHP settings configured"
}

# ==========================================
# SERVICE MANAGEMENT
# ==========================================

start_webserver_services() {
    print_step "Starting webserver services..."
    
    # Start and enable Apache
    systemctl_enable_start "apache2" 2>/dev/null || systemctl_enable_start "httpd"
    
    # Start and enable Nginx
    systemctl_enable_start "nginx"
    
    # Start and enable PHP-FPM
    systemctl_enable_start "php-fpm" 2>/dev/null || systemctl_enable_start "php*-fpm"
    
    log_info "Webserver services started and enabled"
}

# ==========================================
# VERIFICATION
# ==========================================

verify_webserver_installation() {
    print_step "Verifying webserver installation..."
    
    # Check if services are running
    check_service_status "apache2" || check_service_status "httpd"
    check_service_status "nginx"
    
    # Check if ports are listening
    check_port_listening 80
    check_port_listening 443
    
    # Test web server response
    test_webserver_response
    
    log_info "Webserver installation verification completed"
}

test_webserver_response() {
    print_substep "Testing web server response..."
    
    # Test HTTP response
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|403"; then
        log_success "HTTP server responding correctly"
    else
        log_warning "HTTP server may not be responding correctly"
    fi
}

# ==========================================
# SUMMARY DISPLAY
# ==========================================

display_webserver_summary() {
    print_section_header "🌐 WEBSERVER INSTALLATION SUMMARY"
    
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                    🌐 WEBSERVER MODULE                     │${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│                                                             │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Apache Web Server installed and configured        │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Nginx reverse proxy configured                    │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} PHP and extensions installed                      │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} SSL/TLS certificates ready                        │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Security configurations applied                   │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Firewall rules configured                         │${NC}"
    echo -e "${BLUE}│                                                             │${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│  ${CYAN}📊 SERVICES STATUS:${NC}                                  │${NC}"
    echo -e "${BLUE}│    • Apache: $(systemctl is-active apache2 2>/dev/null || systemctl is-active httpd 2>/dev/null || echo 'inactive')                                │${NC}"
    echo -e "${BLUE}│    • Nginx:  $(systemctl is-active nginx 2>/dev/null || echo 'inactive')                                │${NC}"
    echo -e "${BLUE}│    • PHP-FPM: $(systemctl is-active php-fpm 2>/dev/null || echo 'inactive')                               │${NC}"
    echo -e "${BLUE}│                                                             │${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│  ${CYAN}🌐 ACCESS INFORMATION:${NC}                              │${NC}"
    echo -e "${BLUE}│    • HTTP:  http://$(hostname -I | awk '{print $1}')                    │${NC}"
    echo -e "${BLUE}│    • HTTPS: https://$(hostname -I | awk '{print $1}')                   │${NC}"
    echo -e "${BLUE}│    • Document Root: /var/www/html                          │${NC}"
    echo -e "${BLUE}│                                                             │${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│  ${CYAN}🔧 MANAGEMENT COMMANDS:${NC}                             │${NC}"
    echo -e "${BLUE}│    • Restart: sudo systemctl restart apache2 nginx        │${NC}"
    echo -e "${BLUE}│    • Status:  sudo systemctl status apache2 nginx         │${NC}"
    echo -e "${BLUE}│    • Logs:    sudo tail -f /var/log/apache2/error.log     │${NC}"
    echo -e "${BLUE}│                                                             │${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${GREEN}🎉 Webserver module installation completed successfully!${NC}"
    echo -e "${CYAN}📚 Run './master.sh' for interactive management${NC}"
    echo ""
}

# ==========================================
# MAIN EXECUTION
# ==========================================

main() {
    # Create log entry
    log_info "=== Webserver Module Installation Started ==="
    
    # Run installation
    install_webserver
    
    # Create log entry
    log_info "=== Webserver Module Installation Completed ==="
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
