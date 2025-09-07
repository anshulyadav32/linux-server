#!/bin/bash
# Comprehensive Automated Web Server Installation Script
# This script installs everything required for a complete web server setup
# with checkpoints, testing, and verification

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Installation tracking
INSTALL_LOG="/var/log/web-server-install.log"
COMPONENTS_INSTALLED=()
COMPONENTS_FAILED=()
TOTAL_STEPS=20
CURRENT_STEP=0

# Create log file
mkdir -p "$(dirname "$INSTALL_LOG")"
touch "$INSTALL_LOG"

#===========================================
# UTILITY FUNCTIONS
#===========================================

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$INSTALL_LOG"
}

# Progress indicator
show_progress() {
    local step="$1"
    local description="$2"
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percentage=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}STEP $CURRENT_STEP/$TOTAL_STEPS ($percentage%) - $description${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    
    log_message "INFO" "Starting Step $CURRENT_STEP: $description"
}

# Success indicator
show_success() {
    local message="$1"
    echo -e "${GREEN}✓ $message${NC}"
    log_message "SUCCESS" "$message"
}

# Error indicator
show_error() {
    local message="$1"
    echo -e "${RED}✗ $message${NC}"
    log_message "ERROR" "$message"
}

# Warning indicator
show_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠ $message${NC}"
    log_message "WARNING" "$message"
}

# Info indicator
show_info() {
    local message="$1"
    echo -e "${BLUE}ℹ $message${NC}"
    log_message "INFO" "$message"
}

# Install package with verification
install_package() {
    local package="$1"
    local description="$2"
    
    echo -n "Installing $description... "
    
    if apt-get install -y "$package" >/dev/null 2>&1; then
        show_success "$description installed successfully"
        COMPONENTS_INSTALLED+=("$description")
        return 0
    else
        show_error "Failed to install $description"
        COMPONENTS_FAILED+=("$description")
        return 1
    fi
}

# Check if service is running
check_service() {
    local service="$1"
    local description="$2"
    
    if systemctl is-active --quiet "$service"; then
        show_success "$description is running"
        return 0
    else
        show_error "$description is not running"
        return 1
    fi
}

# Test web server response
test_web_response() {
    local url="$1"
    local description="$2"
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|403"; then
        show_success "$description is responding"
        return 0
    else
        show_error "$description is not responding"
        return 1
    fi
}

# Checkpoint function
checkpoint() {
    local checkpoint_name="$1"
    echo ""
    echo -e "${PURPLE}🔍 CHECKPOINT: $checkpoint_name${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    
    # Run verification based on checkpoint
    case "$checkpoint_name" in
        "System Preparation")
            verify_system_preparation
            ;;
        "Package Installation")
            verify_package_installation
            ;;
        "Web Server Setup")
            verify_webserver_setup
            ;;
        "Database Installation")
            verify_database_installation
            ;;
        "SSL Configuration")
            verify_ssl_configuration
            ;;
        "Security Setup")
            verify_security_setup
            ;;
        "Performance Optimization")
            verify_performance_optimization
            ;;
        "Final Verification")
            verify_final_installation
            ;;
    esac
    
    echo -e "${PURPLE}Checkpoint completed: $checkpoint_name${NC}"
    echo ""
    sleep 2
}

#===========================================
# VERIFICATION FUNCTIONS
#===========================================

verify_system_preparation() {
    echo "Verifying system preparation..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        show_success "Running with administrative privileges"
    else
        show_error "Script must be run with sudo privileges"
        exit 1
    fi
    
    # Check internet connectivity
    if ping -c 1 google.com >/dev/null 2>&1; then
        show_success "Internet connectivity available"
    else
        show_error "No internet connectivity"
        exit 1
    fi
    
    # Check disk space (minimum 2GB)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -gt 2000000 ]]; then
        show_success "Sufficient disk space available ($(($available_space/1024/1024))GB)"
    else
        show_warning "Low disk space ($(($available_space/1024/1024))GB available)"
    fi
}

verify_package_installation() {
    echo "Verifying package installation..."
    
    # Check critical packages
    local critical_packages=("apache2" "php" "mysql-server" "curl" "wget")
    
    for package in "${critical_packages[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            show_success "$package is installed"
        else
            show_error "$package is not installed"
        fi
    done
}

verify_webserver_setup() {
    echo "Verifying web server setup..."
    
    # Check Apache service
    check_service "apache2" "Apache Web Server"
    
    # Check PHP installation
    if command -v php >/dev/null 2>&1; then
        local php_version=$(php -v | head -1 | awk '{print $2}')
        show_success "PHP $php_version is installed"
    else
        show_error "PHP is not available"
    fi
    
    # Test web server response
    test_web_response "http://localhost" "Web server"
    
    # Check PHP processing
    echo "<?php echo 'PHP is working'; ?>" > /var/www/html/test.php
    if curl -s http://localhost/test.php | grep -q "PHP is working"; then
        show_success "PHP is processing correctly"
    else
        show_error "PHP is not processing correctly"
    fi
    rm -f /var/www/html/test.php
}

verify_database_installation() {
    echo "Verifying database installation..."
    
    # Check MySQL service
    if systemctl is-enabled mysql >/dev/null 2>&1; then
        check_service "mysql" "MySQL Database Server"
    fi
    
    # Check Redis service
    if systemctl is-enabled redis-server >/dev/null 2>&1; then
        check_service "redis-server" "Redis Cache Server"
    fi
    
    # Test MySQL connection
    if command -v mysql >/dev/null 2>&1; then
        if mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
            show_success "MySQL connection successful"
        else
            show_warning "MySQL connection failed (may need configuration)"
        fi
    fi
}

verify_ssl_configuration() {
    echo "Verifying SSL configuration..."
    
    # Check if Certbot is installed
    if command -v certbot >/dev/null 2>&1; then
        show_success "Certbot (Let's Encrypt) is installed"
    else
        show_error "Certbot is not installed"
    fi
    
    # Check SSL modules
    if apache2ctl -M 2>/dev/null | grep -q ssl; then
        show_success "Apache SSL module is enabled"
    else
        show_error "Apache SSL module is not enabled"
    fi
    
    # Check SSL certificates directory
    if [[ -d "/etc/ssl/certs" ]]; then
        show_success "SSL certificates directory exists"
    else
        show_error "SSL certificates directory not found"
    fi
}

verify_security_setup() {
    echo "Verifying security setup..."
    
    # Check UFW firewall
    if command -v ufw >/dev/null 2>&1; then
        show_success "UFW firewall is installed"
        
        if ufw status | grep -q "Status: active"; then
            show_success "UFW firewall is active"
        else
            show_warning "UFW firewall is inactive"
        fi
    else
        show_error "UFW firewall is not installed"
    fi
    
    # Check Fail2Ban
    if command -v fail2ban-server >/dev/null 2>&1; then
        show_success "Fail2Ban is installed"
        check_service "fail2ban" "Fail2Ban Protection"
    else
        show_warning "Fail2Ban is not installed"
    fi
}

verify_performance_optimization() {
    echo "Verifying performance optimization..."
    
    # Check Apache modules
    local apache_modules=("rewrite" "deflate" "expires" "headers")
    for module in "${apache_modules[@]}"; do
        if apache2ctl -M 2>/dev/null | grep -q "$module"; then
            show_success "Apache $module module is enabled"
        else
            show_warning "Apache $module module is not enabled"
        fi
    done
    
    # Check PHP OPCache
    if php -m | grep -q "Zend OPcache"; then
        show_success "PHP OPCache is enabled"
    else
        show_warning "PHP OPCache is not enabled"
    fi
}

verify_final_installation() {
    echo "Performing final comprehensive verification..."
    
    # Test all critical services
    local services=("apache2")
    for service in "${services[@]}"; do
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            check_service "$service" "$service"
        fi
    done
    
    # Test web functionality
    test_web_response "http://localhost" "Main web server"
    
    # Check important ports
    local ports=("80" "443" "22")
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            show_success "Port $port is open"
        else
            show_warning "Port $port is not open"
        fi
    done
    
    # Check web directory permissions
    if [[ -d "/var/www/html" ]]; then
        local owner=$(stat -c '%U' /var/www/html)
        if [[ "$owner" == "www-data" ]]; then
            show_success "Web directory has correct ownership"
        else
            show_warning "Web directory ownership may need adjustment"
        fi
    fi
}

#===========================================
# INSTALLATION FUNCTIONS
#===========================================

# System preparation
prepare_system() {
    show_progress 1 "System Preparation"
    
    show_info "Updating package repositories..."
    apt-get update >/dev/null 2>&1
    show_success "Package repositories updated"
    
    show_info "Installing essential tools..."
    install_package "curl" "CURL HTTP client"
    install_package "wget" "WGET downloader"
    install_package "gnupg" "GnuPG encryption"
    install_package "software-properties-common" "Software properties"
    install_package "apt-transport-https" "HTTPS transport"
    
    checkpoint "System Preparation"
}

# Install web server
install_webserver() {
    show_progress 2 "Apache Web Server Installation"
    
    install_package "apache2" "Apache Web Server"
    install_package "apache2-utils" "Apache Utilities"
    
    show_info "Enabling Apache modules..."
    local apache_modules=("rewrite" "ssl" "headers" "deflate" "expires")
    for module in "${apache_modules[@]}"; do
        if a2enmod "$module" >/dev/null 2>&1; then
            show_success "Enabled Apache module: $module"
        else
            show_warning "Failed to enable Apache module: $module"
        fi
    done
    
    # Start and enable Apache
    systemctl enable apache2 >/dev/null 2>&1
    systemctl start apache2 >/dev/null 2>&1
    
    checkpoint "Web Server Setup"
}

# Install PHP
install_php() {
    show_progress 3 "PHP Installation"
    
    # Install PHP and essential extensions
    local php_packages=(
        "php"
        "libapache2-mod-php"
        "php-mysql"
        "php-curl"
        "php-gd"
        "php-mbstring"
        "php-xml"
        "php-zip"
        "php-json"
        "php-bcmath"
        "php-intl"
        "php-soap"
    )
    
    for package in "${php_packages[@]}"; do
        install_package "$package" "PHP: $package"
    done
    
    show_info "Configuring PHP..."
    local php_version=$(php -v | head -1 | awk '{print $2}' | cut -d. -f1,2)
    local php_ini="/etc/php/$php_version/apache2/php.ini"
    
    if [[ -f "$php_ini" ]]; then
        cp "$php_ini" "$php_ini.backup"
        
        # Optimize PHP settings
        sed -i 's/memory_limit = .*/memory_limit = 256M/' "$php_ini"
        sed -i 's/upload_max_filesize = .*/upload_max_filesize = 50M/' "$php_ini"
        sed -i 's/post_max_size = .*/post_max_size = 50M/' "$php_ini"
        sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$php_ini"
        sed -i 's/;date.timezone =.*/date.timezone = UTC/' "$php_ini"
        
        show_success "PHP configuration optimized"
    fi
    
    # Restart Apache to load PHP
    systemctl restart apache2 >/dev/null 2>&1
}

# Install databases
install_databases() {
    show_progress 4 "Database Installation"
    
    # Install MySQL
    show_info "Installing MySQL Server..."
    export DEBIAN_FRONTEND=noninteractive
    
    # Pre-configure MySQL
    echo "mysql-server mysql-server/root_password password" | debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password" | debconf-set-selections
    
    install_package "mysql-server" "MySQL Database Server"
    
    # Start and enable MySQL
    systemctl enable mysql >/dev/null 2>&1
    systemctl start mysql >/dev/null 2>&1
    
    # Install additional databases
    install_package "sqlite3" "SQLite Database"
    install_package "redis-server" "Redis Cache Server"
    
    # Start Redis
    systemctl enable redis-server >/dev/null 2>&1
    systemctl start redis-server >/dev/null 2>&1
    
    checkpoint "Database Installation"
}

# Install SSL components
install_ssl() {
    show_progress 5 "SSL/TLS Installation"
    
    install_package "certbot" "Let's Encrypt Certbot"
    install_package "python3-certbot-apache" "Certbot Apache Plugin"
    install_package "openssl" "OpenSSL"
    install_package "ca-certificates" "Certificate Authorities"
    
    # Enable SSL module
    a2enmod ssl >/dev/null 2>&1
    a2ensite default-ssl >/dev/null 2>&1
    
    checkpoint "SSL Configuration"
}

# Install security tools
install_security() {
    show_progress 6 "Security Tools Installation"
    
    install_package "ufw" "UFW Firewall"
    install_package "fail2ban" "Fail2Ban Intrusion Prevention"
    
    # Configure UFW
    show_info "Configuring UFW firewall..."
    ufw --force reset >/dev/null 2>&1
    ufw default deny incoming >/dev/null 2>&1
    ufw default allow outgoing >/dev/null 2>&1
    ufw allow ssh >/dev/null 2>&1
    ufw allow 80/tcp >/dev/null 2>&1
    ufw allow 443/tcp >/dev/null 2>&1
    ufw --force enable >/dev/null 2>&1
    show_success "UFW firewall configured"
    
    # Configure Fail2Ban
    show_info "Configuring Fail2Ban..."
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true

[apache-auth]
enabled = true

[apache-badbots]
enabled = true
EOF
    
    systemctl enable fail2ban >/dev/null 2>&1
    systemctl start fail2ban >/dev/null 2>&1
    show_success "Fail2Ban configured"
    
    checkpoint "Security Setup"
}

# Install development tools
install_development_tools() {
    show_progress 7 "Development Tools Installation"
    
    install_package "git" "Git Version Control"
    install_package "nodejs" "Node.js Runtime"
    install_package "npm" "NPM Package Manager"
    install_package "composer" "PHP Composer"
    install_package "vim" "Vim Editor"
    install_package "nano" "Nano Editor"
    install_package "htop" "System Monitor"
    install_package "tree" "Directory Tree"
    install_package "zip" "ZIP Archive Tool"
    install_package "unzip" "ZIP Extract Tool"
}

# Install monitoring tools
install_monitoring() {
    show_progress 8 "Monitoring Tools Installation"
    
    install_package "netstat-nat" "Network Statistics"
    install_package "iotop" "I/O Monitor"
    install_package "nload" "Network Load Monitor"
    install_package "tcpdump" "Network Packet Analyzer"
    
    # Install web-based monitoring
    install_package "awstats" "Web Statistics"
}

# Install additional PHP extensions
install_php_extensions() {
    show_progress 9 "Additional PHP Extensions"
    
    local additional_php=(
        "php-redis"
        "php-memcached"
        "php-imagick"
        "php-xdebug"
        "php-dev"
        "php-pear"
    )
    
    for package in "${additional_php[@]}"; do
        install_package "$package" "PHP Extension: $package"
    done
}

# Install performance tools
install_performance_tools() {
    show_progress 10 "Performance Optimization Tools"
    
    install_package "memcached" "Memcached Caching"
    install_package "imagemagick" "Image Processing"
    install_package "optipng" "PNG Optimization"
    install_package "jpegoptim" "JPEG Optimization"
    
    # Enable memcached
    systemctl enable memcached >/dev/null 2>&1
    systemctl start memcached >/dev/null 2>&1
}

# Performance optimization
optimize_performance() {
    show_progress 11 "Performance Optimization"
    
    show_info "Optimizing Apache configuration..."
    
    # Create performance configuration
    cat > /etc/apache2/conf-available/performance.conf << 'EOF'
# Performance optimization
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 15

# Compression
LoadModule deflate_module modules/mod_deflate.so
<Location />
    SetOutputFilter DEFLATE
    SetEnvIfNoCase Request_URI \
        \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    SetEnvIfNoCase Request_URI \
        \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
</Location>

# Security headers
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection "1; mode=block"

# Hide version
ServerTokens Prod
ServerSignature Off
EOF
    
    a2enconf performance >/dev/null 2>&1
    show_success "Apache performance configuration applied"
    
    checkpoint "Performance Optimization"
}

# Create default website
create_default_website() {
    show_progress 12 "Default Website Creation"
    
    # Create index page
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Web Server Successfully Installed</title>
    <style>
        body { 
            font-family: 'Segoe UI', Arial, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container { 
            max-width: 900px; 
            background: rgba(255,255,255,0.1); 
            padding: 40px; 
            border-radius: 20px; 
            box-shadow: 0 20px 40px rgba(0,0,0,0.3);
            backdrop-filter: blur(10px);
            text-align: center;
        }
        h1 { 
            font-size: 3em; 
            margin-bottom: 20px; 
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }
        .success { 
            color: #4CAF50; 
            font-size: 1.5em; 
            margin: 20px 0; 
            font-weight: bold;
        }
        .info { 
            background: rgba(255,255,255,0.2); 
            padding: 20px; 
            border-radius: 15px; 
            margin: 20px 0;
            text-align: left;
        }
        .feature { 
            margin: 10px 0; 
            padding: 15px; 
            background: rgba(255,255,255,0.1); 
            border-left: 4px solid #4CAF50;
            border-radius: 8px;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        .card {
            background: rgba(255,255,255,0.15);
            padding: 20px;
            border-radius: 15px;
            text-align: center;
        }
        .emoji { font-size: 2em; margin-bottom: 10px; }
        .version { 
            font-size: 0.9em; 
            opacity: 0.8; 
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Web Server Installation Complete!</h1>
        <div class="success">Your web server is now running successfully!</div>
        
        <div class="info">
            <h3>🚀 What's Installed & Configured:</h3>
            <div class="feature">✅ Apache Web Server with SSL support</div>
            <div class="feature">✅ PHP with essential extensions</div>
            <div class="feature">✅ MySQL Database Server</div>
            <div class="feature">✅ Redis Cache Server</div>
            <div class="feature">✅ SSL/TLS certificates support (Let's Encrypt)</div>
            <div class="feature">✅ UFW Firewall configured</div>
            <div class="feature">✅ Fail2Ban intrusion prevention</div>
            <div class="feature">✅ Performance optimization applied</div>
            <div class="feature">✅ Development tools installed</div>
            <div class="feature">✅ Monitoring tools configured</div>
        </div>

        <div class="grid">
            <div class="card">
                <div class="emoji">🌐</div>
                <h4>Web Server</h4>
                <p>Apache with SSL</p>
                <div class="version">Port 80 & 443</div>
            </div>
            <div class="card">
                <div class="emoji">🐘</div>
                <h4>Database</h4>
                <p>MySQL + Redis</p>
                <div class="version">Ready for apps</div>
            </div>
            <div class="card">
                <div class="emoji">🔒</div>
                <h4>Security</h4>
                <p>Firewall + Fail2Ban</p>
                <div class="version">Protection active</div>
            </div>
            <div class="card">
                <div class="emoji">⚡</div>
                <h4>Performance</h4>
                <p>Optimized settings</p>
                <div class="version">Cache enabled</div>
            </div>
        </div>
        
        <div class="info">
            <h3>📋 Next Steps:</h3>
            <ul style="text-align: left;">
                <li>Upload your website files to <code>/var/www/html/</code></li>
                <li>Configure virtual hosts for multiple domains</li>
                <li>Install SSL certificates using <code>certbot</code></li>
                <li>Monitor server performance and logs</li>
                <li>Set up database users and permissions</li>
            </ul>
        </div>
        
        <div class="info">
            <h3>🔧 Useful Commands:</h3>
            <ul style="text-align: left;">
                <li><code>sudo systemctl status apache2</code> - Check Apache status</li>
                <li><code>sudo systemctl status mysql</code> - Check MySQL status</li>
                <li><code>sudo ufw status</code> - Check firewall status</li>
                <li><code>sudo certbot --apache</code> - Install SSL certificate</li>
                <li><code>php -v</code> - Check PHP version</li>
            </ul>
        </div>

        <div class="version">
            Installation completed on: $(date)<br>
            Server IP: $(curl -s ipinfo.io/ip 2>/dev/null || echo "Unable to detect")
        </div>
    </div>
</body>
</html>
EOF
    
    # Create PHP info page
    cat > /var/www/html/phpinfo.php << 'EOF'
<?php
// PHP Information Page
// Remove this file in production for security

echo "<h1 style='color: #333; text-align: center; font-family: Arial, sans-serif;'>PHP Configuration</h1>";
echo "<p style='text-align: center; color: #666;'>Server: " . $_SERVER['SERVER_NAME'] . "</p>";
echo "<p style='text-align: center; color: #666;'>Generated: " . date('Y-m-d H:i:s') . "</p>";
echo "<hr style='margin: 20px 0;'>";

phpinfo();
?>
EOF
    
    # Set proper permissions
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
    show_success "Default website created"
}

# Final system configuration
final_configuration() {
    show_progress 13 "Final System Configuration"
    
    # Restart all services
    show_info "Restarting services..."
    systemctl restart apache2 >/dev/null 2>&1
    systemctl restart mysql >/dev/null 2>&1
    systemctl restart redis-server >/dev/null 2>&1
    
    # Set up log rotation
    show_info "Setting up log rotation..."
    cat > /etc/logrotate.d/webserver << 'EOF'
/var/www/*/logs/*.log {
    weekly
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data adm
}
EOF
    
    show_success "Log rotation configured"
    
    checkpoint "Final Verification"
}

# Installation summary
show_installation_summary() {
    show_progress 14 "Installation Summary"
    
    echo ""
    echo -e "${WHITE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              INSTALLATION SUMMARY REPORT${NC}"
    echo -e "${WHITE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Show successful installations
    if [[ ${#COMPONENTS_INSTALLED[@]} -gt 0 ]]; then
        echo -e "${GREEN}✓ SUCCESSFULLY INSTALLED (${#COMPONENTS_INSTALLED[@]} components):${NC}"
        for component in "${COMPONENTS_INSTALLED[@]}"; do
            echo -e "  ${GREEN}✓${NC} $component"
        done
        echo ""
    fi
    
    # Show failed installations
    if [[ ${#COMPONENTS_FAILED[@]} -gt 0 ]]; then
        echo -e "${RED}✗ FAILED INSTALLATIONS (${#COMPONENTS_FAILED[@]} components):${NC}"
        for component in "${COMPONENTS_FAILED[@]}"; do
            echo -e "  ${RED}✗${NC} $component"
        done
        echo ""
    fi
    
    # System information
    echo -e "${BLUE}📊 SYSTEM INFORMATION:${NC}"
    echo -e "  OS: $(lsb_release -d | cut -f2)"
    echo -e "  Kernel: $(uname -r)"
    echo -e "  Architecture: $(uname -m)"
    echo -e "  Memory: $(free -h | grep Mem | awk '{print $2}')"
    echo -e "  Disk Space: $(df -h / | tail -1 | awk '{print $4}') available"
    echo ""
    
    # Service status
    echo -e "${BLUE}🔧 SERVICE STATUS:${NC}"
    local services=("apache2" "mysql" "redis-server" "fail2ban")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $service: Running"
        elif systemctl is-enabled "$service" >/dev/null 2>&1; then
            echo -e "  ${YELLOW}○${NC} $service: Installed but not running"
        else
            echo -e "  ${RED}✗${NC} $service: Not installed"
        fi
    done
    echo ""
    
    # Network information
    echo -e "${BLUE}🌐 NETWORK INFORMATION:${NC}"
    local server_ip=$(curl -s ipinfo.io/ip 2>/dev/null || echo "Unable to detect")
    echo -e "  Server IP: $server_ip"
    echo -e "  Web Access: http://localhost or http://$server_ip"
    echo -e "  PHP Info: http://localhost/phpinfo.php"
    echo ""
    
    # Security status
    echo -e "${BLUE}🔒 SECURITY STATUS:${NC}"
    if ufw status | grep -q "Status: active"; then
        echo -e "  ${GREEN}✓${NC} UFW Firewall: Active"
    else
        echo -e "  ${YELLOW}○${NC} UFW Firewall: Inactive"
    fi
    
    if systemctl is-active --quiet fail2ban; then
        echo -e "  ${GREEN}✓${NC} Fail2Ban: Active"
    else
        echo -e "  ${YELLOW}○${NC} Fail2Ban: Inactive"
    fi
    echo ""
    
    # Important files and directories
    echo -e "${BLUE}📁 IMPORTANT LOCATIONS:${NC}"
    echo -e "  Web Root: /var/www/html/"
    echo -e "  Apache Config: /etc/apache2/"
    echo -e "  PHP Config: /etc/php/"
    echo -e "  MySQL Config: /etc/mysql/"
    echo -e "  SSL Certificates: /etc/letsencrypt/"
    echo -e "  Installation Log: $INSTALL_LOG"
    echo ""
    
    # Next steps
    echo -e "${YELLOW}📋 RECOMMENDED NEXT STEPS:${NC}"
    echo -e "  1. Visit http://localhost to see your website"
    echo -e "  2. Remove /var/www/html/phpinfo.php for security"
    echo -e "  3. Configure MySQL root password: mysql_secure_installation"
    echo -e "  4. Install SSL certificate: certbot --apache"
    echo -e "  5. Upload your website files to /var/www/html/"
    echo -e "  6. Configure virtual hosts for multiple domains"
    echo -e "  7. Set up regular backups"
    echo -e "  8. Monitor server performance and logs"
    echo ""
    
    # Footer
    echo -e "${WHITE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}🎉 Web Server Installation Completed Successfully!${NC}"
    echo -e "${WHITE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Show log location
    echo -e "${CYAN}📝 Detailed installation log: $INSTALL_LOG${NC}"
    echo ""
}

#===========================================
# MAIN INSTALLATION PROCESS
#===========================================

main() {
    clear
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                    AUTOMATED WEB SERVER INSTALLER${NC}"
    echo -e "${WHITE}           Complete LAMP Stack with Security & Optimization${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}This script will install and configure:${NC}"
    echo -e "  ${GREEN}✓${NC} Apache Web Server with SSL support"
    echo -e "  ${GREEN}✓${NC} PHP with essential extensions"
    echo -e "  ${GREEN}✓${NC} MySQL Database Server"
    echo -e "  ${GREEN}✓${NC} Redis Cache Server"
    echo -e "  ${GREEN}✓${NC} SSL/TLS certificates (Let's Encrypt)"
    echo -e "  ${GREEN}✓${NC} UFW Firewall with security rules"
    echo -e "  ${GREEN}✓${NC} Fail2Ban intrusion prevention"
    echo -e "  ${GREEN}✓${NC} Performance optimization"
    echo -e "  ${GREEN}✓${NC} Development and monitoring tools"
    echo -e "  ${GREEN}✓${NC} Automated security configurations"
    echo ""
    echo -e "${YELLOW}⚠ This script requires sudo privileges and will modify system configuration${NC}"
    echo ""
    
    # Confirm installation
    read -p "Do you want to proceed with the installation? [y/N]: " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installation cancelled by user${NC}"
        exit 0
    fi
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run with sudo privileges${NC}"
        echo "Please run: sudo $0"
        exit 1
    fi
    
    # Start installation
    echo -e "${GREEN}Starting automated web server installation...${NC}"
    sleep 2
    
    # Run installation steps
    prepare_system
    install_webserver
    install_php
    install_databases
    install_ssl
    install_security
    install_development_tools
    install_monitoring
    install_php_extensions
    install_performance_tools
    optimize_performance
    create_default_website
    final_configuration
    show_installation_summary
    
    # Final message
    echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
    echo -e "${WHITE}You can now access your website at: http://localhost${NC}"
    echo ""
    echo -e "${CYAN}Thank you for using the Automated Web Server Installer!${NC}"
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
