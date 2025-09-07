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

echo "[INFO] === Webserver Module Installation Started ==="
echo "[INFO] Script directory: $SCRIPT_DIR"
echo "[INFO] Base directory: $BASE_DIR"

# Source common functions
if [[ -f "$BASE_DIR/modules/common.sh" ]]; then
    echo "[INFO] Sourcing common.sh from: $BASE_DIR/modules/common.sh"
    source "$BASE_DIR/modules/common.sh"
else
    echo "[ERROR] common.sh not found at: $BASE_DIR/modules/common.sh"
    exit 1
fi

# Ensure critical functions are available (fallback definitions)
if ! command -v get_total_memory >/dev/null 2>&1; then
    get_total_memory() {
        local memory_kb
        if [[ -f /proc/meminfo ]]; then
            memory_kb=$(grep "MemTotal:" /proc/meminfo | awk '{print $2}')
            echo $((memory_kb / 1024))  # Convert to MB
        else
            echo "1024"  # Default fallback
        fi
    }
fi

if ! command -v get_available_space >/dev/null 2>&1; then
    get_available_space() {
        local path="${1:-/}"
        if command -v df >/dev/null 2>&1; then
            # Get available space in KB and convert to GB
            local space_kb=$(df "$path" | tail -1 | awk '{print $4}')
            echo $((space_kb / 1024 / 1024))  # Convert KB to GB
        else
            echo "10"  # Default fallback
        fi
    }
fi

if ! command -v check_port_availability >/dev/null 2>&1; then
    check_port_availability() {
        local port="$1"
        local service_name="${2:-Service}"
        
        if command -v netstat >/dev/null 2>&1; then
            if netstat -tuln | grep -q ":$port "; then
                log_warning "$service_name port $port is already in use"
                return 1
            fi
        elif command -v ss >/dev/null 2>&1; then
            if ss -tuln | grep -q ":$port "; then
                log_warning "$service_name port $port is already in use"
                return 1
            fi
        else
            log_info "Cannot check port availability. Proceeding..."
        fi
        
        log_info "$service_name port $port is available"
        return 0
    }
fi

# Source webserver functions
if [[ -f "$SCRIPT_DIR/functions.sh" ]]; then
    source "$SCRIPT_DIR/functions.sh"
fi

# ==========================================
# ADDITIONAL FUNCTION DEFINITIONS
# ==========================================

check_webserver_requirements() {
    log_info "Checking webserver requirements..."
    
    # Check available disk space (need at least 1GB)
    available_space=$(df / | awk 'NR==2 {print $4}')
    required_space=1048576  # 1GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        log_error "Insufficient disk space. Need at least 1GB free."
        exit 1
    fi
    
    # Check if we can install packages
    if command -v apt-get >/dev/null 2>&1; then
        log_info "Using APT package manager"
    elif command -v yum >/dev/null 2>&1; then
        log_info "Using YUM package manager"
    elif command -v dnf >/dev/null 2>&1; then
        log_info "Using DNF package manager"
    else
        log_error "No supported package manager found"
        exit 1
    fi
    
    log_success "System requirements check passed"
}

install_web_packages() {
    log_info "Installing web server packages..."
    
    if command -v apt-get >/dev/null 2>&1; then
        # Ubuntu/Debian
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y apache2 nginx php php-fpm php-mysql php-xml php-curl php-zip php-gd php-mbstring \
                          certbot python3-certbot-apache python3-certbot-nginx \
                          ufw fail2ban curl wget unzip
    elif command -v yum >/dev/null 2>&1; then
        # CentOS/RHEL 7
        yum install -y epel-release
        yum install -y httpd nginx php php-fpm php-mysqlnd php-xml php-curl php-zip php-gd php-mbstring \
                      certbot python2-certbot-apache python2-certbot-nginx \
                      firewalld fail2ban curl wget unzip
    elif command -v dnf >/dev/null 2>&1; then
        # CentOS/RHEL 8+/Fedora
        dnf install -y epel-release
        dnf install -y httpd nginx php php-fpm php-mysqlnd php-xml php-curl php-zip php-gd php-mbstring \
                      certbot python3-certbot-apache python3-certbot-nginx \
                      firewalld fail2ban curl wget unzip
    else
        log_error "Unsupported package manager"
        exit 1
    fi
    
    log_success "Web server packages installed"
}

configure_apache() {
    log_info "Configuring Apache..."
    
    # Enable necessary modules
    if command -v a2enmod >/dev/null 2>&1; then
        a2enmod rewrite
        a2enmod ssl
        a2enmod headers
        a2enmod proxy
        a2enmod proxy_http
    fi
    
    # Start and enable Apache
    systemctl start apache2 2>/dev/null || systemctl start httpd 2>/dev/null || true
    systemctl enable apache2 2>/dev/null || systemctl enable httpd 2>/dev/null || true
    
    log_success "Apache configured"
}

configure_nginx() {
    log_info "Configuring Nginx..."
    
    # Start and enable Nginx (but don't conflict with Apache on port 80)
    systemctl start nginx 2>/dev/null || true
    systemctl enable nginx 2>/dev/null || true
    
    # Configure Nginx as reverse proxy (default config)
    if [[ -f /etc/nginx/sites-available/default ]]; then
        # Backup original config
        cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup
    fi
    
    log_success "Nginx configured"
}

configure_php() {
    log_info "Configuring PHP..."
    
    # Start and enable PHP-FPM
    systemctl start php-fpm 2>/dev/null || systemctl start php8.1-fpm 2>/dev/null || systemctl start php7.4-fpm 2>/dev/null || true
    systemctl enable php-fpm 2>/dev/null || systemctl enable php8.1-fpm 2>/dev/null || systemctl enable php7.4-fpm 2>/dev/null || true
    
    log_success "PHP configured"
}

setup_firewall() {
    log_info "Setting up firewall rules..."
    
    if command -v ufw >/dev/null 2>&1; then
        # Ubuntu/Debian with UFW
        ufw allow 22/tcp    # SSH
        ufw allow 80/tcp    # HTTP
        ufw allow 443/tcp   # HTTPS
        ufw --force enable
    elif command -v firewall-cmd >/dev/null 2>&1; then
        # CentOS/RHEL with firewalld
        systemctl start firewalld
        systemctl enable firewalld
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
    fi
    
    log_success "Firewall configured"
}

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
    
    print_step "Configuring Apache..."
    configure_apache
    
    print_step "Configuring Nginx..."
    configure_nginx
    
    print_step "Configuring PHP..."
    configure_php
    
    print_step "Setting up firewall..."
    setup_firewall
    
    # Create a simple test page
    create_test_page
    
    # Final status check
    verify_installation
    
    print_section_header "✅ WEBSERVER INSTALLATION COMPLETED"
    
    log_success "Webserver module installation completed successfully!"
    
    # Display summary
    echo ""
    log_info "Webserver Configuration Summary:"
    echo "  • Apache: Installed and running on port 80"
    echo "  • Nginx: Installed (can be configured as reverse proxy)"
    echo "  • PHP: Installed with essential modules"
    echo "  • SSL: Ready for Let's Encrypt certificates"
    echo "  • Firewall: Configured for web traffic"
    echo ""
    echo "Management Commands:"
    echo "  • Webserver menu: $(dirname "$0")/menu.sh"
    echo "  • Check status: systemctl status apache2 nginx"
    echo "  • View logs: journalctl -u apache2 -f"
    echo ""
}

create_test_page() {
    log_info "Creating test page..."
    
    # Create simple index page
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to Your Web Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; }
        .status { background: #2ecc71; color: white; padding: 10px; border-radius: 5px; margin: 10px 0; }
        .info { background: #3498db; color: white; padding: 10px; border-radius: 5px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Web Server Successfully Installed!</h1>
        <div class="status">✅ Apache HTTP Server is running</div>
        <div class="info">📁 Document root: /var/www/html</div>
        <div class="info">🔧 Configuration: /etc/apache2/</div>
        <div class="info">📊 Logs: /var/log/apache2/</div>
        <h2>Next Steps:</h2>
        <ul>
            <li>Configure virtual hosts for your domains</li>
            <li>Install SSL certificates with Let's Encrypt</li>
            <li>Upload your website files to /var/www/html</li>
            <li>Configure security settings</li>
        </ul>
        <p><strong>Installed by:</strong> Linux Setup - Complete Server Management System</p>
    </div>
</body>
</html>
EOF

    # Set proper permissions
    chown -R www-data:www-data /var/www/html 2>/dev/null || chown -R apache:apache /var/www/html 2>/dev/null || true
    chmod -R 644 /var/www/html/*
    
    log_success "Test page created at /var/www/html/index.html"
}

verify_installation() {
    log_info "Verifying installation..."
    
    # Check if Apache is running
    if systemctl is-active --quiet apache2 2>/dev/null || systemctl is-active --quiet httpd 2>/dev/null; then
        log_success "Apache is running"
    else
        log_warning "Apache is not running"
    fi
    
    # Check if Nginx is installed
    if command -v nginx >/dev/null 2>&1; then
        log_success "Nginx is installed"
    else
        log_warning "Nginx installation may have failed"
    fi
    
    # Check if PHP is installed
    if command -v php >/dev/null 2>&1; then
        local php_version=$(php -v | head -1 | awk '{print $2}')
        log_success "PHP $php_version is installed"
    else
        log_warning "PHP installation may have failed"
    fi
    
    # Test web server response
    if curl -s http://localhost >/dev/null 2>&1; then
        log_success "Web server is responding to HTTP requests"
    else
        log_warning "Web server is not responding on port 80"
    fi
}

# ==========================================
# WEBSERVER REQUIREMENTS CHECK
# ==========================================

check_webserver_requirements() {
    print_step "Checking webserver requirements..."
    
    # Check minimum system requirements
    local total_memory=$(get_total_memory)
    log_info "Total system memory: ${total_memory}MB"
    if [[ $total_memory -lt 1024 ]]; then
        log_warning "Low memory detected: ${total_memory}MB. Recommended: 1GB+"
    fi
    
    # Check disk space (need at least 2GB)
    local available_space=$(get_available_space "/")
    log_info "Available disk space: ${available_space}GB"
    if [[ $available_space -lt 2 ]]; then
        log_error "Insufficient disk space. Need at least 2GB available, found ${available_space}GB"
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
