#!/bin/bash
# Complete Web-server Functions Library
# Comprehensive functions for web server management and maintenance

#===========================================
# CORE INSTALLATION FUNCTIONS
#===========================================

# Install core packages (minimal)
install_core_packages() {
    log_info "Installing core web packages..."
    
    if install_package_with_check "apache2" "Apache Web Server"; then
        COMPONENTS_INSTALLED+=("Apache Web Server")
    else
        COMPONENTS_FAILED+=("Apache Web Server")
    fi
    
    if install_package_with_check "php" "PHP Runtime"; then
        COMPONENTS_INSTALLED+=("PHP Runtime")
    else
        COMPONENTS_FAILED+=("PHP Runtime")
    fi
}

# Install Apache with all modules
install_apache_complete() {
    log_info "Installing Apache web server with all modules..."
    
    local apache_packages=(
        "apache2"
        "apache2-utils"
        "apache2-dev"
        "libapache2-mod-php"
        "libapache2-mod-wsgi-py3"
        "libapache2-mod-security2"
        "libapache2-mod-evasive"
        "libapache2-mod-rewrite"
    )
    
    for package in "${apache_packages[@]}"; do
        if install_package_with_check "$package" "Apache: $package"; then
            COMPONENTS_INSTALLED+=("Apache: $package")
        else
            COMPONENTS_FAILED+=("Apache: $package")
        fi
    done
    
    # Enable essential Apache modules
    local apache_modules=(
        "rewrite"
        "ssl"
        "headers"
        "deflate"
        "expires"
        "security2"
        "evasive24"
        "wsgi"
        "php8.1"
    )
    
    for module in "${apache_modules[@]}"; do
        if a2enmod "$module" >/dev/null 2>&1; then
            log_ok "Enabled Apache module: $module"
            COMPONENTS_INSTALLED+=("Apache Module: $module")
        else
            log_warn "Failed to enable Apache module: $module"
        fi
    done
    
    # Configure Apache
    configure_apache
}

# Install basic Apache
install_apache_basic() {
    log_info "Installing basic Apache web server..."
    
    if install_package_with_check "apache2" "Apache Web Server"; then
        COMPONENTS_INSTALLED+=("Apache Web Server")
        a2enmod rewrite ssl headers >/dev/null 2>&1
        COMPONENTS_INSTALLED+=("Apache Basic Modules")
    else
        COMPONENTS_FAILED+=("Apache Web Server")
    fi
}

# Install Nginx with modules
install_nginx_complete() {
    log_info "Installing Nginx web server with modules..."
    
    local nginx_packages=(
        "nginx"
        "nginx-extras"
        "nginx-common"
        "libnginx-mod-http-geoip"
        "libnginx-mod-http-image-filter"
        "libnginx-mod-http-xslt-filter"
        "libnginx-mod-mail"
        "libnginx-mod-stream"
    )
    
    for package in "${nginx_packages[@]}"; do
        if install_package_with_check "$package" "Nginx: $package"; then
            COMPONENTS_INSTALLED+=("Nginx: $package")
        else
            COMPONENTS_FAILED+=("Nginx: $package")
        fi
    done
    
    # Configure Nginx
    configure_nginx
}

# Install complete PHP with all extensions
install_php_complete() {
    log_info "Installing PHP with all extensions..."
    
    local php_packages=(
        "php"
        "php-fpm"
        "php-cli"
        "php-common"
        "php-curl"
        "php-gd"
        "php-json"
        "php-mbstring"
        "php-mysql"
        "php-xml"
        "php-zip"
        "php-bcmath"
        "php-bz2"
        "php-intl"
        "php-soap"
        "php-xsl"
        "php-xmlrpc"
        "php-pgsql"
        "php-sqlite3"
        "php-ldap"
        "php-imap"
        "php-redis"
        "php-memcached"
        "php-imagick"
        "php-xdebug"
        "php-dev"
        "php-pear"
        "composer"
    )
    
    for package in "${php_packages[@]}"; do
        if install_package_with_check "$package" "PHP: $package"; then
            COMPONENTS_INSTALLED+=("PHP: $package")
        else
            COMPONENTS_FAILED+=("PHP: $package")
        fi
    done
    
    # Configure PHP
    configure_php
}

# Install basic PHP
install_php_basic() {
    log_info "Installing basic PHP..."
    
    local basic_php=(
        "php"
        "libapache2-mod-php"
        "php-mysql"
        "php-curl"
        "php-gd"
        "php-mbstring"
        "php-xml"
        "php-zip"
    )
    
    for package in "${basic_php[@]}"; do
        if install_package_with_check "$package" "PHP: $package"; then
            COMPONENTS_INSTALLED+=("PHP: $package")
        else
            COMPONENTS_FAILED+=("PHP: $package")
        fi
    done
}

# Install Node.js and related tools
install_nodejs_complete() {
    log_info "Installing Node.js and related tools..."
    
    # Install Node.js
    if install_package_with_check "nodejs" "Node.js Runtime"; then
        COMPONENTS_INSTALLED+=("Node.js Runtime")
    else
        COMPONENTS_FAILED+=("Node.js Runtime")
    fi
    
    if install_package_with_check "npm" "NPM Package Manager"; then
        COMPONENTS_INSTALLED+=("NPM Package Manager")
    else
        COMPONENTS_FAILED+=("NPM Package Manager")
    fi
    
    # Install global Node.js tools
    local npm_globals=(
        "yarn"
        "pm2"
        "nodemon"
        "express-generator"
        "create-react-app"
        "vue-cli"
        "angular-cli"
        "@nestjs/cli"
        "typescript"
        "ts-node"
        "webpack"
        "gulp-cli"
        "grunt-cli"
    )
    
    for tool in "${npm_globals[@]}"; do
        if npm install -g "$tool" >/dev/null 2>&1; then
            log_ok "Installed Node.js tool: $tool"
            COMPONENTS_INSTALLED+=("Node.js: $tool")
        else
            log_warn "Failed to install Node.js tool: $tool"
            COMPONENTS_FAILED+=("Node.js: $tool")
        fi
    done
}

# Install Python frameworks
install_python_frameworks() {
    log_info "Installing Python web frameworks..."
    
    local python_packages=(
        "python3"
        "python3-pip"
        "python3-dev"
        "python3-venv"
        "python3-setuptools"
        "python3-wheel"
    )
    
    for package in "${python_packages[@]}"; do
        if install_package_with_check "$package" "Python: $package"; then
            COMPONENTS_INSTALLED+=("Python: $package")
        else
            COMPONENTS_FAILED+=("Python: $package")
        fi
    done
    
    # Install Python web frameworks via pip
    local python_frameworks=(
        "django"
        "flask"
        "fastapi"
        "tornado"
        "pyramid"
        "bottle"
        "cherrypy"
        "aiohttp"
        "sanic"
        "starlette"
        "uvicorn"
        "gunicorn"
        "celery"
        "redis"
        "psycopg2-binary"
        "mysql-connector-python"
    )
    
    for framework in "${python_frameworks[@]}"; do
        if pip3 install "$framework" >/dev/null 2>&1; then
            log_ok "Installed Python framework: $framework"
            COMPONENTS_INSTALLED+=("Python: $framework")
        else
            log_warn "Failed to install Python framework: $framework"
            COMPONENTS_FAILED+=("Python: $framework")
        fi
    done
}

# Install database components
install_database_components() {
    log_info "Installing database components..."
    
    local db_packages=(
        "mysql-server"
        "mysql-client"
        "postgresql"
        "postgresql-contrib"
        "sqlite3"
        "redis-server"
        "memcached"
        "mongodb-clients"
        "phpmyadmin"
        "adminer"
    )
    
    for package in "${db_packages[@]}"; do
        if install_package_with_check "$package" "Database: $package"; then
            COMPONENTS_INSTALLED+=("Database: $package")
        else
            COMPONENTS_FAILED+=("Database: $package")
        fi
    done
}

# Install SSL/TLS components
install_ssl_components() {
    log_info "Installing SSL/TLS components..."
    
    local ssl_packages=(
        "certbot"
        "python3-certbot-apache"
        "python3-certbot-nginx"
        "openssl"
        "ca-certificates"
        "ssl-cert"
    )
    
    for package in "${ssl_packages[@]}"; do
        if install_package_with_check "$package" "SSL: $package"; then
            COMPONENTS_INSTALLED+=("SSL: $package")
        else
            COMPONENTS_FAILED+=("SSL: $package")
        fi
    done
}

# Install security components
install_security_components() {
    log_info "Installing security components..."
    
    local security_packages=(
        "ufw"
        "fail2ban"
        "clamav"
        "clamav-daemon"
        "rkhunter"
        "chkrootkit"
        "aide"
        "logwatch"
        "psad"
        "portsentry"
        "ossec-hids"
    )
    
    for package in "${security_packages[@]}"; do
        if install_package_with_check "$package" "Security: $package"; then
            COMPONENTS_INSTALLED+=("Security: $package")
        else
            COMPONENTS_FAILED+=("Security: $package")
        fi
    done
    
    # Configure basic security
    configure_security
}

# Install monitoring tools
install_monitoring_tools() {
    log_info "Installing monitoring tools..."
    
    local monitoring_packages=(
        "htop"
        "iotop"
        "nload"
        "iftop"
        "nethogs"
        "ss"
        "netstat-nat"
        "tcpdump"
        "wireshark-common"
        "nagios-nrpe-server"
        "zabbix-agent"
        "collectd"
        "munin-node"
        "awstats"
        "goaccess"
    )
    
    for package in "${monitoring_packages[@]}"; do
        if install_package_with_check "$package" "Monitoring: $package"; then
            COMPONENTS_INSTALLED+=("Monitoring: $package")
        else
            COMPONENTS_FAILED+=("Monitoring: $package")
        fi
    done
}

# Install development tools
install_development_tools() {
    log_info "Installing development tools..."
    
    local dev_packages=(
        "git"
        "curl"
        "wget"
        "unzip"
        "zip"
        "build-essential"
        "gcc"
        "g++"
        "make"
        "cmake"
        "vim"
        "nano"
        "tree"
        "jq"
        "xmlstarlet"
        "ruby"
        "perl"
        "golang-go"
        "openjdk-11-jdk"
        "maven"
        "gradle"
    )
    
    for package in "${dev_packages[@]}"; do
        if install_package_with_check "$package" "Dev Tools: $package"; then
            COMPONENTS_INSTALLED+=("Dev Tools: $package")
        else
            COMPONENTS_FAILED+=("Dev Tools: $package")
        fi
    done
}

# Install performance tools
install_performance_tools() {
    log_info "Installing performance optimization tools..."
    
    local perf_packages=(
        "varnish"
        "memcached"
        "redis-server"
        "nginx-pagespeed"
        "apache2-mod-pagespeed-stable"
        "imagemagick"
        "optipng"
        "jpegoptim"
        "gifsicle"
        "svgo"
    )
    
    for package in "${perf_packages[@]}"; do
        if install_package_with_check "$package" "Performance: $package"; then
            COMPONENTS_INSTALLED+=("Performance: $package")
        else
            COMPONENTS_FAILED+=("Performance: $package")
        fi
    done
}

# Install additional technologies
install_additional_technologies() {
    log_info "Installing additional web technologies..."
    
    local additional_packages=(
        "docker.io"
        "docker-compose"
        "elasticsearch"
        "kibana"
        "logstash"
        "grafana"
        "prometheus"
        "jenkins"
        "gitlab-ce"
        "sonarqube"
        "ansible"
        "terraform"
    )
    
    for package in "${additional_packages[@]}"; do
        if install_package_with_check "$package" "Additional: $package"; then
            COMPONENTS_INSTALLED+=("Additional: $package")
        else
            COMPONENTS_FAILED+=("Additional: $package")
        fi
    done
}

#===========================================
# CONFIGURATION FUNCTIONS
#===========================================

# Configure Apache
configure_apache() {
    log_info "Configuring Apache web server..."
    
    # Backup original configuration
    cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.backup
    
    # Optimize Apache configuration
    cat >> /etc/apache2/conf-available/performance.conf << 'EOF'
# Performance optimization
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 15

# Security headers
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection "1; mode=block"
Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
Header always set Content-Security-Policy "default-src 'self'"

# Hide Apache version
ServerTokens Prod
ServerSignature Off

# Compression
LoadModule deflate_module modules/mod_deflate.so
<Location />
    SetOutputFilter DEFLATE
    SetEnvIfNoCase Request_URI \
        \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    SetEnvIfNoCase Request_URI \
        \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
</Location>
EOF
    
    a2enconf performance
    
    # Create default virtual host template
    create_default_vhost_template
    
    systemctl enable apache2
    log_ok "Apache configuration completed"
}

# Configure Nginx
configure_nginx() {
    log_info "Configuring Nginx web server..."
    
    # Backup original configuration
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    
    # Create optimized Nginx configuration
    cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 10240;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/x-javascript
        application/xml+rss
        application/javascript
        application/json;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
    
    # Create default server block
    create_nginx_default_site
    
    systemctl enable nginx
    log_ok "Nginx configuration completed"
}

# Configure PHP
configure_php() {
    log_info "Configuring PHP..."
    
    local php_version=$(php -v | head -1 | awk '{print $2}' | cut -d. -f1,2)
    local php_ini="/etc/php/$php_version/apache2/php.ini"
    
    if [[ -f "$php_ini" ]]; then
        # Backup original
        cp "$php_ini" "$php_ini.backup"
        
        # Optimize PHP configuration
        sed -i 's/memory_limit = .*/memory_limit = 512M/' "$php_ini"
        sed -i 's/upload_max_filesize = .*/upload_max_filesize = 100M/' "$php_ini"
        sed -i 's/post_max_size = .*/post_max_size = 100M/' "$php_ini"
        sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$php_ini"
        sed -i 's/max_input_vars = .*/max_input_vars = 3000/' "$php_ini"
        sed -i 's/;date.timezone =.*/date.timezone = UTC/' "$php_ini"
        sed -i 's/expose_php = .*/expose_php = Off/' "$php_ini"
        
        log_ok "PHP configuration optimized"
    fi
    
    # Configure PHP-FPM if installed
    if systemctl is-enabled php*-fpm >/dev/null 2>&1; then
        configure_php_fpm
    fi
}

# Configure PHP-FPM
configure_php_fpm() {
    log_info "Configuring PHP-FPM..."
    
    local php_version=$(php -v | head -1 | awk '{print $2}' | cut -d. -f1,2)
    local fpm_conf="/etc/php/$php_version/fpm/pool.d/www.conf"
    
    if [[ -f "$fpm_conf" ]]; then
        # Backup original
        cp "$fpm_conf" "$fpm_conf.backup"
        
        # Optimize FPM pool
        sed -i 's/pm = .*/pm = dynamic/' "$fpm_conf"
        sed -i 's/pm.max_children = .*/pm.max_children = 50/' "$fpm_conf"
        sed -i 's/pm.start_servers = .*/pm.start_servers = 5/' "$fpm_conf"
        sed -i 's/pm.min_spare_servers = .*/pm.min_spare_servers = 5/' "$fpm_conf"
        sed -i 's/pm.max_spare_servers = .*/pm.max_spare_servers = 35/' "$fpm_conf"
        
        systemctl enable php*-fpm
        log_ok "PHP-FPM configuration optimized"
    fi
}

# Configure basic security
configure_security() {
    log_info "Configuring basic security settings..."
    
    # Configure UFW firewall
    if command -v ufw >/dev/null 2>&1; then
        ufw --force reset
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw --force enable
        log_ok "UFW firewall configured"
    fi
    
    # Configure Fail2Ban
    if command -v fail2ban-server >/dev/null 2>&1; then
        configure_fail2ban
    fi
}

# Configure Fail2Ban
configure_fail2ban() {
    log_info "Configuring Fail2Ban..."
    
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
backend = systemd

[sshd]
enabled = true

[apache-auth]
enabled = true

[apache-badbots]
enabled = true

[apache-noscript]
enabled = true

[apache-overflows]
enabled = true

[nginx-http-auth]
enabled = true

[nginx-noscript]
enabled = true

[nginx-badbots]
enabled = true
EOF
    
    systemctl enable fail2ban
    systemctl restart fail2ban
    log_ok "Fail2Ban configured"
}

# Create default virtual host template
create_default_vhost_template() {
    cat > /etc/apache2/sites-available/000-default.conf << 'EOF'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    
    # Disable server signature
    ServerSignature Off
    
    # Directory security
    <Directory /var/www/html>
        Options -Indexes
        AllowOverride All
        Require all granted
    </Directory>
    
    # Hide sensitive files
    <FilesMatch "^\.">
        Require all denied
    </FilesMatch>
</VirtualHost>
EOF
}

# Create Nginx default site
create_nginx_default_site() {
    cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html index.php;
    
    server_name _;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Disable logging for favicon and robots
    location ~ ^/(favicon\.ico|robots\.txt)$ {
        access_log off;
        log_not_found off;
    }
}
EOF
}

#===========================================
# SERVICE CONFIGURATION FUNCTIONS
#===========================================

# Configure web services for different environments
configure_web_services() {
    log_info "Configuring web services..."
    
    # Start and enable services
    systemctl enable apache2 >/dev/null 2>&1
    systemctl start apache2 >/dev/null 2>&1
    
    # Note: Nginx and Apache on same server - stop nginx by default
    systemctl stop nginx >/dev/null 2>&1
    systemctl disable nginx >/dev/null 2>&1
    
    # Start PHP-FPM if available
    systemctl enable php*-fpm >/dev/null 2>&1
    systemctl start php*-fpm >/dev/null 2>&1
    
    # Create default web page
    create_default_webpage
    
    log_ok "Web services configured"
}

configure_basic_services() {
    configure_web_services
}

configure_development_services() {
    configure_web_services
    
    # Enable development tools
    systemctl enable mysql >/dev/null 2>&1
    systemctl start mysql >/dev/null 2>&1
    
    systemctl enable redis-server >/dev/null 2>&1
    systemctl start redis-server >/dev/null 2>&1
    
    log_ok "Development services configured"
}

configure_production_services() {
    configure_web_services
    configure_security
    
    # Enable monitoring services
    systemctl enable fail2ban >/dev/null 2>&1
    systemctl start fail2ban >/dev/null 2>&1
    
    log_ok "Production services configured"
}

configure_minimal_services() {
    systemctl enable apache2 >/dev/null 2>&1
    systemctl start apache2 >/dev/null 2>&1
    
    create_default_webpage
    log_ok "Minimal services configured"
}

# Create default webpage
create_default_webpage() {
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Web Server Installed Successfully</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f4f4f4; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; text-align: center; }
        .success { color: #27ae60; text-align: center; font-size: 1.2em; margin: 20px 0; }
        .info { background: #ecf0f1; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .feature { margin: 10px 0; padding: 10px; background: #e8f6f3; border-left: 4px solid #27ae60; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Web Server Installation Complete!</h1>
        <div class="success">Your web server is now running successfully!</div>
        
        <div class="info">
            <h3>🚀 What's Installed:</h3>
            <div class="feature">✅ Apache Web Server with security modules</div>
            <div class="feature">✅ PHP with essential extensions</div>
            <div class="feature">✅ SSL/TLS support ready</div>
            <div class="feature">✅ Security configurations applied</div>
            <div class="feature">✅ Performance optimizations enabled</div>
        </div>
        
        <div class="info">
            <h3>📋 Next Steps:</h3>
            <ul>
                <li>Add your websites using the web management menu</li>
                <li>Configure virtual hosts for multiple domains</li>
                <li>Install SSL certificates for HTTPS</li>
                <li>Monitor server performance and security</li>
            </ul>
        </div>
        
        <div class="info">
            <h3>🔧 Management Commands:</h3>
            <ul>
                <li><code>./manage.sh web</code> - Access web management menu</li>
                <li><code>./modules/web/maintain.sh</code> - Server maintenance</li>
                <li><code>./system-status-checker.sh</code> - Check installation status</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF
    
    # Create PHP info page
    cat > /var/www/html/info.php << 'EOF'
<?php
// Remove this file in production
phpinfo();
?>
EOF
    
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
}

#===========================================
# WEBSITE MANAGEMENT FUNCTIONS
#===========================================

# Add website with advanced options
add_website() {
    local domain="$1"
    local php_version="${2:-8.1}"
    local ssl_enabled="${3:-false}"
    
    if [[ -z "$domain" ]]; then
        log_error "Domain parameter required"
        return 1
    fi
    
    log_info "Adding website: $domain"
    
    # Create document root structure
    mkdir -p "/var/www/$domain"/{public_html,logs,backups,ssl}
    
    # Create default website content
    create_website_content "$domain"
    
    # Create Apache virtual host
    create_apache_vhost "$domain" "$php_version" "$ssl_enabled"
    
    # Create Nginx virtual host
    create_nginx_vhost "$domain" "$php_version" "$ssl_enabled"
    
    # Set proper permissions
    chown -R www-data:www-data "/var/www/$domain"
    chmod -R 755 "/var/www/$domain"
    
    # Enable the site
    a2ensite "$domain.conf" >/dev/null 2>&1
    systemctl reload apache2 >/dev/null 2>&1
    
    log_ok "Website $domain created successfully"
    log_info "Document root: /var/www/$domain/public_html"
    
    # Enable SSL if requested
    if [[ "$ssl_enabled" == "true" ]]; then
        enable_ssl "$domain"
    fi
}

# Create website content
create_website_content() {
    local domain="$1"
    
    # Create HTML index
    cat > "/var/www/$domain/public_html/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to $domain</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
        .container { text-align: center; background: rgba(255,255,255,0.1); padding: 40px; border-radius: 15px; backdrop-filter: blur(10px); }
        h1 { font-size: 3em; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
        p { font-size: 1.2em; margin-bottom: 30px; }
        .info { background: rgba(255,255,255,0.2); padding: 20px; border-radius: 10px; margin: 20px 0; }
        .features { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-top: 30px; }
        .feature { background: rgba(255,255,255,0.1); padding: 15px; border-radius: 8px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌟 Welcome to $domain</h1>
        <p>Your website has been successfully created and is now online!</p>
        
        <div class="info">
            <h3>📋 Website Information</h3>
            <p><strong>Domain:</strong> $domain</p>
            <p><strong>Created:</strong> $(date)</p>
            <p><strong>Server:</strong> Apache/Nginx with PHP</p>
        </div>
        
        <div class="features">
            <div class="feature">
                <h4>🚀 Ready to Use</h4>
                <p>Upload your content to get started</p>
            </div>
            <div class="feature">
                <h4>🔒 SSL Ready</h4>
                <p>HTTPS can be enabled easily</p>
            </div>
            <div class="feature">
                <h4>📊 PHP Enabled</h4>
                <p>Dynamic content supported</p>
            </div>
        </div>
    </div>
</body>
</html>
EOF
    
    # Create PHP test file
    cat > "/var/www/$domain/public_html/phpinfo.php" << EOF
<?php
// PHP Information Page for $domain
// Remove this file in production

echo "<h1>PHP Information for $domain</h1>";
echo "<p>Created: " . date('Y-m-d H:i:s') . "</p>";
echo "<hr>";

phpinfo();
?>
EOF
    
    # Create robots.txt
    cat > "/var/www/$domain/public_html/robots.txt" << EOF
User-agent: *
Allow: /

Sitemap: https://$domain/sitemap.xml
EOF
    
    # Create .htaccess for security and performance
    cat > "/var/www/$domain/public_html/.htaccess" << EOF
# Security headers
<IfModule mod_headers.c>
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
</IfModule>

# Performance optimization
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>

# Browser caching
<IfModule mod_expires.c>
    ExpiresActive on
    ExpiresByType image/jpg "access plus 1 month"
    ExpiresByType image/jpeg "access plus 1 month"
    ExpiresByType image/gif "access plus 1 month"
    ExpiresByType image/png "access plus 1 month"
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/pdf "access plus 1 month"
    ExpiresByType text/javascript "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
    ExpiresByType application/x-shockwave-flash "access plus 1 month"
    ExpiresByType image/x-icon "access plus 1 year"
    ExpiresDefault "access plus 2 days"
</IfModule>

# Hide sensitive files
<FilesMatch "^\.">
    Require all denied
</FilesMatch>

<Files "*.log">
    Require all denied
</Files>
EOF
}

# Create Apache virtual host
create_apache_vhost() {
    local domain="$1"
    local php_version="$2"
    local ssl_enabled="$3"
    
    cat > "/etc/apache2/sites-available/$domain.conf" << EOF
# Virtual Host for $domain
# Created: $(date)

<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot /var/www/$domain/public_html
    
    # Logging
    ErrorLog /var/www/$domain/logs/error.log
    CustomLog /var/www/$domain/logs/access.log combined
    LogLevel warn
    
    # Directory configuration
    <Directory /var/www/$domain/public_html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
        
        # PHP configuration
        <IfModule mod_php.c>
            php_admin_value upload_tmp_dir /var/www/$domain/tmp
            php_admin_value session.save_path /var/www/$domain/tmp
        </IfModule>
    </Directory>
    
    # Security headers
    <IfModule mod_headers.c>
        Header always set X-Content-Type-Options nosniff
        Header always set X-Frame-Options SAMEORIGIN
        Header always set X-XSS-Protection "1; mode=block"
        Header always set Referrer-Policy "strict-origin-when-cross-origin"
    </IfModule>
    
    # Hide server information
    ServerSignature Off
    
    # Deny access to sensitive files
    <FilesMatch "^\.">
        Require all denied
    </FilesMatch>
    
    <Files "*.log">
        Require all denied
    </Files>
    
    # Redirect to HTTPS if SSL is enabled
EOF

    if [[ "$ssl_enabled" == "true" ]]; then
        cat >> "/etc/apache2/sites-available/$domain.conf" << EOF
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
EOF
    fi
    
    echo "</VirtualHost>" >> "/etc/apache2/sites-available/$domain.conf"
    
    # Create SSL virtual host if enabled
    if [[ "$ssl_enabled" == "true" ]]; then
        cat >> "/etc/apache2/sites-available/$domain.conf" << EOF

<VirtualHost *:443>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot /var/www/$domain/public_html
    
    # SSL Configuration
    SSLEngine on
    SSLCertificateFile /var/www/$domain/ssl/$domain.crt
    SSLCertificateKeyFile /var/www/$domain/ssl/$domain.key
    
    # Modern SSL configuration
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE+AESGCM:ECDHE+AES256:ECDHE+AES128:!DHE:!RSA:!3DES:!MD5
    SSLHonorCipherOrder on
    
    # HSTS
    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    
    # Logging
    ErrorLog /var/www/$domain/logs/ssl_error.log
    CustomLog /var/www/$domain/logs/ssl_access.log combined
    
    # Directory configuration
    <Directory /var/www/$domain/public_html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
    fi
}

# Create Nginx virtual host
create_nginx_vhost() {
    local domain="$1"
    local php_version="$2"
    local ssl_enabled="$3"
    
    cat > "/etc/nginx/sites-available/$domain" << EOF
# Nginx configuration for $domain
# Created: $(date)

server {
    listen 80;
    server_name $domain www.$domain;
    root /var/www/$domain/public_html;
    index index.html index.htm index.php;
    
    # Logging
    access_log /var/www/$domain/logs/nginx_access.log;
    error_log /var/www/$domain/logs/nginx_error.log;
    
    # Security headers
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Main location
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$php_version-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to log files
    location ~ \.log$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Static file caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Favicon and robots
    location ~ ^/(favicon\.ico|robots\.txt)$ {
        access_log off;
        log_not_found off;
    }
EOF

    if [[ "$ssl_enabled" == "true" ]]; then
        cat >> "/etc/nginx/sites-available/$domain" << EOF
    
    # Redirect to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain www.$domain;
    root /var/www/$domain/public_html;
    index index.html index.htm index.php;
    
    # SSL Configuration
    ssl_certificate /var/www/$domain/ssl/$domain.crt;
    ssl_certificate_key /var/www/$domain/ssl/$domain.key;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE+AESGCM:ECDHE+AES256:ECDHE+AES128:!DHE:!RSA:!3DES:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    
    # Security headers
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Logging
    access_log /var/www/$domain/logs/nginx_ssl_access.log;
    error_log /var/www/$domain/logs/nginx_ssl_error.log;
    
    # Main location
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$php_version-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to log files
    location ~ \.log$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Static file caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Favicon and robots
    location ~ ^/(favicon\.ico|robots\.txt)$ {
        access_log off;
        log_not_found off;
    }
EOF
    fi
    
    echo "}" >> "/etc/nginx/sites-available/$domain"
}

# Remove website with complete cleanup
remove_website() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        log_error "Domain parameter required"
        return 1
    fi
    
    log_info "Removing website: $domain"
    
    # Confirm removal
    if ! confirm_action "Are you sure you want to remove $domain? This will delete all files!"; then
        log_info "Website removal cancelled"
        return 0
    fi
    
    # Create backup before removal
    if [[ -d "/var/www/$domain" ]]; then
        log_info "Creating backup before removal..."
        tar -czf "/var/backups/${domain}_$(date +%Y%m%d_%H%M%S).tar.gz" -C "/var/www" "$domain" 2>/dev/null
        log_ok "Backup created in /var/backups/"
    fi
    
    # Disable Apache site
    a2dissite "$domain.conf" >/dev/null 2>&1
    rm -f "/etc/apache2/sites-available/$domain.conf"
    
    # Remove Nginx site
    rm -f "/etc/nginx/sites-available/$domain"
    rm -f "/etc/nginx/sites-enabled/$domain"
    
    # Remove website directory
    rm -rf "/var/www/$domain"
    
    # Reload web servers
    systemctl reload apache2 >/dev/null 2>&1
    systemctl reload nginx >/dev/null 2>&1
    
    log_ok "Website $domain removed successfully"
}

# List all websites with detailed information
list_websites() {
    log_info "Websites on this server:"
    echo ""
    
    local count=0
    
    # Check Apache sites
    if [[ -d "/etc/apache2/sites-available" ]]; then
        echo -e "${WHITE}Apache Virtual Hosts:${NC}"
        for site in /etc/apache2/sites-available/*.conf; do
            if [[ -f "$site" ]]; then
                local domain=$(basename "$site" .conf)
                if [[ "$domain" != "000-default" ]] && [[ "$domain" != "default-ssl" ]]; then
                    local enabled="❌"
                    if [[ -f "/etc/apache2/sites-enabled/$domain.conf" ]]; then
                        enabled="✅"
                    fi
                    
                    local ssl_status="HTTP"
                    if grep -q "VirtualHost.*:443" "$site"; then
                        ssl_status="HTTPS"
                    fi
                    
                    echo -e "  $enabled ${GREEN}$domain${NC} [$ssl_status]"
                    
                    # Show document root
                    local docroot=$(grep "DocumentRoot" "$site" | head -1 | awk '{print $2}')
                    if [[ -n "$docroot" ]]; then
                        echo -e "      📁 $docroot"
                    fi
                    
                    # Show site size
                    if [[ -d "$docroot" ]]; then
                        local size=$(du -sh "$docroot" 2>/dev/null | awk '{print $1}')
                        echo -e "      📊 Size: $size"
                    fi
                    
                    count=$((count + 1))
                fi
            fi
        done
    fi
    
    echo ""
    
    # Check Nginx sites
    if [[ -d "/etc/nginx/sites-available" ]]; then
        echo -e "${WHITE}Nginx Virtual Hosts:${NC}"
        for site in /etc/nginx/sites-available/*; do
            if [[ -f "$site" ]]; then
                local domain=$(basename "$site")
                if [[ "$domain" != "default" ]]; then
                    local enabled="❌"
                    if [[ -f "/etc/nginx/sites-enabled/$domain" ]]; then
                        enabled="✅"
                    fi
                    
                    local ssl_status="HTTP"
                    if grep -q "listen.*443.*ssl" "$site"; then
                        ssl_status="HTTPS"
                    fi
                    
                    echo -e "  $enabled ${GREEN}$domain${NC} [$ssl_status]"
                    count=$((count + 1))
                fi
            fi
        done
    fi
    
    echo ""
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}No custom websites found${NC}"
        echo "Use the web management menu to add websites"
    else
        echo -e "${WHITE}Total websites: $count${NC}"
    fi
    
    # Show disk usage
    echo ""
    echo -e "${WHITE}Web Directory Usage:${NC}"
    if [[ -d "/var/www" ]]; then
        du -sh /var/www/* 2>/dev/null | sort -hr | head -10
    fi
}

# Enable SSL for website
enable_ssl() {
    local domain="$1"
    local force="${2:-false}"
    
    if [[ -z "$domain" ]]; then
        log_error "Domain parameter required"
        return 1
    fi
    
    log_info "Enabling SSL for: $domain"
    
    # Check if Certbot is available
    if ! command -v certbot >/dev/null 2>&1; then
        log_error "Certbot not installed. Installing SSL components..."
        install_ssl_components
        
        if ! command -v certbot >/dev/null 2>&1; then
            log_error "Failed to install Certbot"
            return 1
        fi
    fi
    
    # Check if domain is accessible
    if ! ping -c 1 "$domain" >/dev/null 2>&1 && [[ "$force" != "true" ]]; then
        log_warn "Domain $domain is not accessible from this server"
        if ! confirm_action "Continue with SSL setup anyway?"; then
            log_info "SSL setup cancelled"
            return 0
        fi
    fi
    
    # Determine web server
    local webserver="apache"
    if systemctl is-active --quiet nginx && ! systemctl is-active --quiet apache2; then
        webserver="nginx"
    fi
    
    # Obtain SSL certificate
    log_info "Obtaining SSL certificate for $domain..."
    
    if [[ "$webserver" == "apache" ]]; then
        certbot --apache -d "$domain" -d "www.$domain" \
            --non-interactive --agree-tos \
            --email "admin@$domain" \
            --redirect
    else
        certbot --nginx -d "$domain" -d "www.$domain" \
            --non-interactive --agree-tos \
            --email "admin@$domain" \
            --redirect
    fi
    
    if [[ $? -eq 0 ]]; then
        log_ok "SSL certificate obtained and configured for $domain"
        
        # Test SSL configuration
        log_info "Testing SSL configuration..."
        if curl -I "https://$domain" >/dev/null 2>&1; then
            log_ok "SSL is working correctly"
        else
            log_warn "SSL certificate installed but HTTPS test failed"
        fi
        
        # Setup auto-renewal if not already configured
        setup_ssl_autorenewal
        
    else
        log_error "Failed to obtain SSL certificate for $domain"
        return 1
    fi
}

# Setup SSL auto-renewal
setup_ssl_autorenewal() {
    log_info "Setting up SSL certificate auto-renewal..."
    
    # Add cron job for auto-renewal
    if ! crontab -l 2>/dev/null | grep -q "certbot.*renew"; then
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
        log_ok "SSL auto-renewal configured"
    else
        log_info "SSL auto-renewal already configured"
    fi
}

# Clone website
clone_website() {
    local source_domain="$1"
    local target_domain="$2"
    
    if [[ -z "$source_domain" ]] || [[ -z "$target_domain" ]]; then
        log_error "Source and target domain parameters required"
        return 1
    fi
    
    if [[ ! -d "/var/www/$source_domain" ]]; then
        log_error "Source website $source_domain does not exist"
        return 1
    fi
    
    log_info "Cloning website from $source_domain to $target_domain..."
    
    # Copy website files
    cp -r "/var/www/$source_domain" "/var/www/$target_domain"
    
    # Update content references
    find "/var/www/$target_domain" -type f -name "*.html" -o -name "*.php" -o -name "*.css" -o -name "*.js" | \
        xargs sed -i "s/$source_domain/$target_domain/g" 2>/dev/null
    
    # Create new virtual host
    add_website "$target_domain"
    
    log_ok "Website cloned from $source_domain to $target_domain"
}

#===========================================
# SERVICE MANAGEMENT FUNCTIONS
#===========================================

# Restart web services with health checks
restart_web() {
    log_info "Restarting web services..."
    
    local services_restarted=()
    local services_failed=()
    
    # Restart Apache
    if systemctl is-enabled apache2 >/dev/null 2>&1; then
        if systemctl restart apache2; then
            log_ok "Apache2 restarted successfully"
            services_restarted+=("Apache2")
        else
            log_error "Failed to restart Apache2"
            services_failed+=("Apache2")
        fi
    fi
    
    # Restart Nginx if it was running
    if systemctl is-active --quiet nginx; then
        if systemctl restart nginx; then
            log_ok "Nginx restarted successfully"
            services_restarted+=("Nginx")
        else
            log_error "Failed to restart Nginx"
            services_failed+=("Nginx")
        fi
    fi
    
    # Restart PHP-FPM
    if systemctl is-enabled php*-fpm >/dev/null 2>&1; then
        if systemctl restart php*-fpm; then
            log_ok "PHP-FPM restarted successfully"
            services_restarted+=("PHP-FPM")
        else
            log_error "Failed to restart PHP-FPM"
            services_failed+=("PHP-FPM")
        fi
    fi
    
    # Report results
    if [[ ${#services_restarted[@]} -gt 0 ]]; then
        echo -e "${GREEN}Successfully restarted:${NC} ${services_restarted[*]}"
    fi
    
    if [[ ${#services_failed[@]} -gt 0 ]]; then
        echo -e "${RED}Failed to restart:${NC} ${services_failed[*]}"
        return 1
    fi
    
    # Verify services are responding
    verify_web_services
    
    log_ok "Web services restart completed"
}

# Reload web configurations
reload_web() {
    log_info "Reloading web configurations..."
    
    # Test configurations first
    if ! test_web_config; then
        log_error "Configuration test failed. Aborting reload."
        return 1
    fi
    
    # Reload Apache
    if systemctl is-active --quiet apache2; then
        if systemctl reload apache2; then
            log_ok "Apache2 configuration reloaded"
        else
            log_error "Failed to reload Apache2 configuration"
        fi
    fi
    
    # Reload Nginx
    if systemctl is-active --quiet nginx; then
        if systemctl reload nginx; then
            log_ok "Nginx configuration reloaded"
        else
            log_error "Failed to reload Nginx configuration"
        fi
    fi
    
    # Reload PHP-FPM
    if systemctl is-active --quiet php*-fpm; then
        if systemctl reload php*-fpm; then
            log_ok "PHP-FPM configuration reloaded"
        else
            log_error "Failed to reload PHP-FPM configuration"
        fi
    fi
    
    log_ok "Web configurations reloaded"
}

# Stop web services
stop_web() {
    log_info "Stopping web services..."
    
    # Stop services gracefully
    systemctl stop apache2 >/dev/null 2>&1 && log_ok "Apache2 stopped"
    systemctl stop nginx >/dev/null 2>&1 && log_ok "Nginx stopped"
    systemctl stop php*-fpm >/dev/null 2>&1 && log_ok "PHP-FPM stopped"
    
    log_ok "Web services stopped"
}

# Start web services
start_web() {
    log_info "Starting web services..."
    
    # Start Apache (primary web server)
    if systemctl start apache2; then
        log_ok "Apache2 started successfully"
    else
        log_error "Failed to start Apache2"
    fi
    
    # Start PHP-FPM if available
    if systemctl start php*-fpm >/dev/null 2>&1; then
        log_ok "PHP-FPM started successfully"
    fi
    
    # Note: Don't start Nginx by default to avoid port conflicts
    log_info "Nginx kept stopped to avoid port conflicts with Apache"
    log_info "Use 'switch_webserver nginx' to use Nginx instead"
    
    # Verify services
    verify_web_services
    
    log_ok "Web services started"
}

# Get comprehensive web services status
status_web() {
    clear
    show_header "WEB SERVICES STATUS"
    
    # Apache status
    echo -e "${WHITE}Apache Web Server:${NC}"
    if systemctl is-active --quiet apache2; then
        echo -e "  Status: ${GREEN}✓ Running${NC}"
        local apache_version=$(apache2 -v 2>/dev/null | head -1 | awk '{print $3}')
        echo -e "  Version: $apache_version"
        local apache_pid=$(systemctl show apache2 --property MainPID --value)
        echo -e "  PID: $apache_pid"
        local apache_memory=$(ps -o pid,pcpu,pmem,vsz,rss -p "$apache_pid" 2>/dev/null | tail -1 | awk '{print $5}')
        if [[ -n "$apache_memory" ]]; then
            echo -e "  Memory: ${apache_memory}KB"
        fi
    elif systemctl is-enabled apache2 >/dev/null 2>&1; then
        echo -e "  Status: ${RED}✗ Stopped${NC}"
    else
        echo -e "  Status: ${YELLOW}○ Not Installed${NC}"
    fi
    
    echo ""
    
    # Nginx status
    echo -e "${WHITE}Nginx Web Server:${NC}"
    if systemctl is-active --quiet nginx; then
        echo -e "  Status: ${GREEN}✓ Running${NC}"
        local nginx_version=$(nginx -v 2>&1 | awk '{print $3}')
        echo -e "  Version: $nginx_version"
        local nginx_pid=$(systemctl show nginx --property MainPID --value)
        echo -e "  PID: $nginx_pid"
    elif systemctl is-enabled nginx >/dev/null 2>&1; then
        echo -e "  Status: ${RED}✗ Stopped${NC}"
    else
        echo -e "  Status: ${YELLOW}○ Not Installed${NC}"
    fi
    
    echo ""
    
    # PHP status
    echo -e "${WHITE}PHP Runtime:${NC}"
    if command -v php >/dev/null 2>&1; then
        local php_version=$(php -v | head -1 | awk '{print $2}')
        echo -e "  Version: ${GREEN}$php_version${NC}"
        
        # PHP-FPM status
        if systemctl is-active --quiet php*-fpm; then
            echo -e "  PHP-FPM: ${GREEN}✓ Running${NC}"
        elif systemctl is-enabled php*-fpm >/dev/null 2>&1; then
            echo -e "  PHP-FPM: ${RED}✗ Stopped${NC}"
        else
            echo -e "  PHP-FPM: ${YELLOW}○ Not Configured${NC}"
        fi
        
        # PHP modules
        local php_modules=$(php -m | wc -l)
        echo -e "  Loaded Modules: $php_modules"
    else
        echo -e "  Status: ${YELLOW}○ Not Installed${NC}"
    fi
    
    echo ""
    
    # Port status
    echo -e "${WHITE}Port Status:${NC}"
    check_port_status 80 "HTTP"
    check_port_status 443 "HTTPS"
    check_port_status 9000 "PHP-FPM"
    
    echo ""
    
    # Website count
    echo -e "${WHITE}Websites:${NC}"
    local website_count=0
    if [[ -d "/etc/apache2/sites-available" ]]; then
        website_count=$(find /etc/apache2/sites-available -name "*.conf" -not -name "000-default.conf" -not -name "default-ssl.conf" | wc -l)
    fi
    echo -e "  Configured: $website_count websites"
    
    # Disk usage
    echo -e "${WHITE}Disk Usage:${NC}"
    if [[ -d "/var/www" ]]; then
        local web_size=$(du -sh /var/www 2>/dev/null | awk '{print $1}')
        echo -e "  Web Directory: $web_size"
    fi
    
    # Log files size
    local log_size=$(du -sh /var/log/apache2 /var/log/nginx 2>/dev/null | awk '{sum+=$1} END {print sum"KB"}')
    echo -e "  Log Files: $log_size"
    
    echo ""
}

# Check port status
check_port_status() {
    local port="$1"
    local service="$2"
    
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "  Port $port ($service): ${GREEN}✓ Open${NC}"
    else
        echo -e "  Port $port ($service): ${RED}✗ Closed${NC}"
    fi
}

# Verify web services are responding
verify_web_services() {
    log_info "Verifying web services are responding..."
    
    # Test Apache
    if systemctl is-active --quiet apache2; then
        if curl -I "http://localhost" >/dev/null 2>&1; then
            log_ok "Apache is responding to HTTP requests"
        else
            log_warn "Apache is running but not responding to HTTP requests"
        fi
    fi
    
    # Test Nginx
    if systemctl is-active --quiet nginx; then
        if curl -I "http://localhost:8080" >/dev/null 2>&1; then
            log_ok "Nginx is responding to HTTP requests"
        else
            log_warn "Nginx is running but not responding to HTTP requests"
        fi
    fi
    
    # Test PHP
    if systemctl is-active --quiet apache2 && command -v php >/dev/null 2>&1; then
        echo "<?php echo 'PHP is working'; ?>" > /tmp/test.php
        if curl -s "http://localhost/test.php" | grep -q "PHP is working"; then
            log_ok "PHP is processing requests correctly"
        else
            log_warn "PHP may not be processing requests correctly"
        fi
        rm -f /tmp/test.php /var/www/html/test.php
    fi
}

# Switch between web servers
switch_webserver() {
    local target="$1"
    
    if [[ -z "$target" ]]; then
        log_error "Target web server (apache/nginx) required"
        return 1
    fi
    
    case "$target" in
        "apache")
            log_info "Switching to Apache web server..."
            systemctl stop nginx >/dev/null 2>&1
            systemctl disable nginx >/dev/null 2>&1
            systemctl enable apache2
            systemctl start apache2
            log_ok "Switched to Apache web server"
            ;;
        "nginx")
            log_info "Switching to Nginx web server..."
            systemctl stop apache2 >/dev/null 2>&1
            systemctl disable apache2 >/dev/null 2>&1
            systemctl enable nginx
            systemctl start nginx
            log_ok "Switched to Nginx web server"
            ;;
        *)
            log_error "Invalid web server. Use 'apache' or 'nginx'"
            return 1
            ;;
    esac
    
    verify_web_services
}

#===========================================
# UTILITY FUNCTIONS
#===========================================

# Install package with error checking and logging
install_package_with_check() {
    local package="$1"
    local description="$2"
    
    log_info "Installing $description..."
    
    if apt-get update >/dev/null 2>&1 && apt-get install -y "$package" >/dev/null 2>&1; then
        log_ok "$description installed successfully"
        echo "$(date): SUCCESS - $description ($package)" >> "$WEB_INSTALL_LOG"
        return 0
    else
        log_error "Failed to install $description"
        echo "$(date): FAILED - $description ($package)" >> "$WEB_INSTALL_LOG"
        return 1
    fi
}

# Test web server configurations
test_web_config() {
    log_info "Testing web server configurations..."
    
    local config_valid=true
    
    # Test Apache configuration
    if systemctl is-enabled apache2 >/dev/null 2>&1; then
        if apache2ctl configtest >/dev/null 2>&1; then
            log_ok "Apache configuration is valid"
        else
            log_error "Apache configuration has errors"
            config_valid=false
        fi
    fi
    
    # Test Nginx configuration
    if systemctl is-enabled nginx >/dev/null 2>&1; then
        if nginx -t >/dev/null 2>&1; then
            log_ok "Nginx configuration is valid"
        else
            log_error "Nginx configuration has errors"
            config_valid=false
        fi
    fi
    
    # Test PHP configuration
    if command -v php >/dev/null 2>&1; then
        if php -m >/dev/null 2>&1; then
            log_ok "PHP configuration is valid"
        else
            log_error "PHP configuration has errors"
            config_valid=false
        fi
    fi
    
    return $config_valid
}

# Confirm action with user
confirm_action() {
    local message="$1"
    
    echo -e "${YELLOW}$message${NC}"
    read -p "Continue? [y/N]: " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

#===========================================
# MONITORING AND MAINTENANCE FUNCTIONS
#===========================================

# Perform comprehensive health check
check_web_health() {
    log_info "Performing comprehensive web server health check..."
    
    local health_issues=()
    local warnings=()
    
    # Check disk space
    local disk_usage=$(df /var/www 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 90 ]]; then
        health_issues+=("Critical: Disk usage is ${disk_usage}% - free up space immediately")
    elif [[ $disk_usage -gt 80 ]]; then
        warnings+=("Warning: Disk usage is ${disk_usage}% - consider cleaning up")
    fi
    
    # Check memory usage
    local memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    if [[ $memory_usage -gt 95 ]]; then
        health_issues+=("Critical: Memory usage is ${memory_usage}% - restart services")
    elif [[ $memory_usage -gt 85 ]]; then
        warnings+=("Warning: Memory usage is ${memory_usage}% - monitor closely")
    fi
    
    # Check web server processes
    if systemctl is-enabled apache2 >/dev/null 2>&1; then
        if ! systemctl is-active --quiet apache2; then
            health_issues+=("Critical: Apache web server is not running")
        fi
    fi
    
    # Report results
    if [[ ${#health_issues[@]} -eq 0 ]] && [[ ${#warnings[@]} -eq 0 ]]; then
        log_ok "All health checks passed - system is healthy"
    else
        if [[ ${#health_issues[@]} -gt 0 ]]; then
            echo -e "${RED}Critical Issues Found:${NC}"
            for issue in "${health_issues[@]}"; do
                echo -e "  ❌ $issue"
            done
        fi
        
        if [[ ${#warnings[@]} -gt 0 ]]; then
            echo -e "${YELLOW}Warnings:${NC}"
            for warning in "${warnings[@]}"; do
                echo -e "  ⚠️  $warning"
            done
        fi
    fi
}

# Security hardening
harden_web_security() {
    log_info "Hardening web server security..."
    
    # Secure file permissions
    chown -R www-data:www-data /var/www
    find /var/www -type d -exec chmod 755 {} \;
    find /var/www -type f -exec chmod 644 {} \;
    
    # Configure firewall
    if command -v ufw >/dev/null 2>&1; then
        ufw limit 22/tcp comment 'SSH with rate limiting'
        ufw allow 80/tcp comment 'HTTP'
        ufw allow 443/tcp comment 'HTTPS'
        ufw logging on
    fi
    
    log_ok "Security hardening completed"
}

# Cleanup and optimization
optimize_web_performance() {
    log_info "Optimizing web server performance..."
    
    # Clean temporary files
    find /tmp -type f -atime +7 -delete 2>/dev/null
    find /var/tmp -type f -atime +7 -delete 2>/dev/null
    
    # Clear package cache
    apt-get clean >/dev/null 2>&1
    
    log_ok "Performance optimization completed"
}

# Backup websites
backup_websites() {
    local backup_dir="/var/backups/websites"
    local date_stamp=$(date +%Y%m%d_%H%M%S)
    
    log_info "Creating website backups..."
    
    mkdir -p "$backup_dir"
    
    # Backup each website
    for site_dir in /var/www/*/; do
        if [[ -d "$site_dir" ]] && [[ "$site_dir" != "/var/www/html/" ]]; then
            local site_name=$(basename "$site_dir")
            local backup_file="$backup_dir/${site_name}_${date_stamp}.tar.gz"
            
            if tar -czf "$backup_file" -C "/var/www" "$site_name" 2>/dev/null; then
                log_ok "Backed up website: $site_name"
            else
                log_error "Failed to backup website: $site_name"
            fi
        fi
    done
    
    log_ok "Website backups completed"
}

# Check SSL certificates expiry
check_ssl_expiry_all() {
    log_info "Checking SSL certificate expiry..."
    
    # Find all SSL certificates
    find /etc/letsencrypt/live -name "cert.pem" 2>/dev/null | while read cert; do
        local domain=$(basename $(dirname "$cert"))
        local expiry_date=$(openssl x509 -enddate -noout -in "$cert" 2>/dev/null | cut -d= -f2)
        
        if [[ -n "$expiry_date" ]]; then
            local expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null)
            local current_epoch=$(date +%s)
            local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
            
            if [[ $days_until_expiry -lt 7 ]]; then
                log_error "SSL certificate for $domain expires in $days_until_expiry days"
            elif [[ $days_until_expiry -lt 30 ]]; then
                log_warn "SSL certificate for $domain expires in $days_until_expiry days"
            fi
        fi
    done
}

# Update web components
update_web_components() {
    log_info "Updating web server components..."
    
    # Update package list
    apt-get update >/dev/null 2>&1
    
    # Update web packages
    local web_packages=("apache2" "nginx" "php" "php-fpm" "mysql-server" "ssl-cert")
    local updated_packages=()
    
    for package in "${web_packages[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            if apt-get install -y --only-upgrade "$package" >/dev/null 2>&1; then
                updated_packages+=("$package")
            fi
        fi
    done
    
    # Update SSL certificates
    if command -v certbot >/dev/null 2>&1; then
        certbot renew --quiet && log_ok "SSL certificates renewed"
    fi
    
    log_ok "Web component updates completed"
}

#===========================================
# EXPORT ALL FUNCTIONS
#===========================================

# Make all functions available for sourcing
export -f install_core_packages install_apache_complete install_apache_basic
export -f install_nginx_complete install_php_complete install_php_basic
export -f install_nodejs_complete install_python_frameworks install_database_components
export -f install_ssl_components install_security_components install_monitoring_tools
export -f install_development_tools install_performance_tools install_additional_technologies
export -f configure_apache configure_nginx configure_php configure_php_fpm
export -f configure_security configure_fail2ban configure_web_services
export -f configure_basic_services configure_development_services configure_production_services
export -f configure_minimal_services create_default_webpage add_website create_website_content
export -f create_apache_vhost create_nginx_vhost remove_website list_websites
export -f enable_ssl setup_ssl_autorenewal clone_website restart_web reload_web
export -f stop_web start_web status_web verify_web_services switch_webserver
export -f install_package_with_check test_web_config confirm_action check_web_health
export -f harden_web_security optimize_web_performance backup_websites
export -f check_ssl_expiry_all update_web_components check_port_status

log_info "Complete web server functions library loaded successfully - All ${#BASH_LINENO[@]} functions exported"
}
