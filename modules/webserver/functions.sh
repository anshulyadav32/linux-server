#!/bin/bash
# =============================================================================
# Linux Setup - Webserver Module Functions
# =============================================================================
# Author: Anshul Yadav
# Description: Core functions for webserver module management
# =============================================================================

# ==========================================
# APACHE FUNCTIONS
# ==========================================

enable_apache_module() {
    local module="$1"
    print_substep "Enabling Apache module: $module"
    
    if command -v a2enmod >/dev/null 2>&1; then
        a2enmod "$module" >/dev/null 2>&1 || log_warning "Failed to enable module: $module"
    else
        log_warning "a2enmod command not found"
    fi
}

disable_apache_module() {
    local module="$1"
    print_substep "Disabling Apache module: $module"
    
    if command -v a2dismod >/dev/null 2>&1; then
        a2dismod "$module" >/dev/null 2>&1 || log_warning "Failed to disable module: $module"
    else
        log_warning "a2dismod command not found"
    fi
}

create_apache_virtual_host() {
    local domain="$1"
    local document_root="$2"
    local config_file="/etc/apache2/sites-available/${domain}.conf"
    
    print_substep "Creating Apache virtual host for: $domain"
    
    cat > "$config_file" << EOF
<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot $document_root
    
    <Directory $document_root>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/${domain}_error.log
    CustomLog \${APACHE_LOG_DIR}/${domain}_access.log combined
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # Compression
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
</VirtualHost>
EOF
    
    # Enable the site
    if command -v a2ensite >/dev/null 2>&1; then
        a2ensite "$domain" >/dev/null 2>&1
        log_success "Apache virtual host created: $domain"
    fi
}

configure_apache_security() {
    print_substep "Configuring Apache security..."
    
    local security_conf="/etc/apache2/conf-available/security.conf"
    
    # Create security configuration
    cat > "$security_conf" << 'EOF'
# Security Configuration for Apache

# Hide Apache version information
ServerTokens Prod
ServerSignature Off

# Prevent access to .htaccess files
<FilesMatch "^\.ht">
    Require all denied
</FilesMatch>

# Prevent access to sensitive files
<FilesMatch "\.(bak|config|sql|fla|psd|ini|log|sh|inc|swp|dist)$">
    Require all denied
</FilesMatch>

# Disable TRACE method
TraceEnable Off

# Timeout settings
Timeout 60
KeepAliveTimeout 5

# Limit request size (100MB)
LimitRequestBody 104857600
EOF
    
    # Enable security configuration
    if command -v a2enconf >/dev/null 2>&1; then
        a2enconf security >/dev/null 2>&1
    fi
    
    log_info "Apache security configuration applied"
}

# ==========================================
# NGINX FUNCTIONS
# ==========================================

create_nginx_virtual_host() {
    local domain="$1"
    local document_root="$2"
    local config_file="/etc/nginx/sites-available/$domain"
    
    print_substep "Creating Nginx virtual host for: $domain"
    
    cat > "$config_file" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    root $document_root;
    index index.php index.html index.htm;
    
    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
    
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
}
EOF
    
    # Enable the site
    ln -sf "$config_file" "/etc/nginx/sites-enabled/$domain" 2>/dev/null
    log_success "Nginx virtual host created: $domain"
}

setup_nginx_reverse_proxy() {
    print_substep "Setting up Nginx reverse proxy..."
    
    local proxy_conf="/etc/nginx/conf.d/reverse-proxy.conf"
    
    cat > "$proxy_conf" << 'EOF'
# Reverse Proxy Configuration

# Proxy headers
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;

# Proxy timeouts
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;

# Buffer settings
proxy_buffering on;
proxy_buffer_size 8k;
proxy_buffers 16 8k;
proxy_busy_buffers_size 16k;

# Hide proxy headers
proxy_hide_header X-Powered-By;
EOF
    
    log_info "Nginx reverse proxy configuration created"
}

configure_nginx_security() {
    print_substep "Configuring Nginx security..."
    
    local security_conf="/etc/nginx/conf.d/security.conf"
    
    cat > "$security_conf" << 'EOF'
# Security Configuration for Nginx

# Hide Nginx version
server_tokens off;

# File upload limit (100MB)
client_max_body_size 100M;

# Rate limiting
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

# Block common attacks
location ~* \.(php|jsp|cgi)$ {
    limit_req zone=api burst=5 nodelay;
}

# Block access to sensitive files
location ~* \.(bak|config|sql|fla|psd|ini|log|sh|inc|swp|dist)$ {
    deny all;
}

# Block access to hidden files
location ~ /\. {
    deny all;
}
EOF
    
    log_info "Nginx security configuration applied"
}

# ==========================================
# VIRTUAL HOST MANAGEMENT
# ==========================================

setup_virtual_hosts() {
    print_step "Setting up virtual hosts..."
    
    # Create default document root
    mkdir -p /var/www/html
    
    # Create default index page
    create_default_index_page
    
    # Set proper permissions
    chown -R www-data:www-data /var/www/html 2>/dev/null || \
    chown -R apache:apache /var/www/html 2>/dev/null || \
    chown -R nginx:nginx /var/www/html 2>/dev/null
    
    chmod -R 755 /var/www/html
    
    log_info "Virtual hosts setup completed"
}

create_default_index_page() {
    local index_file="/var/www/html/index.html"
    
    cat > "$index_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Linux Setup - Web Server</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            text-align: center;
            max-width: 600px;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        h1 {
            font-size: 3rem;
            margin-bottom: 1rem;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        .emoji {
            font-size: 4rem;
            margin-bottom: 1rem;
        }
        p {
            font-size: 1.2rem;
            line-height: 1.6;
            margin-bottom: 2rem;
        }
        .feature {
            background: rgba(255, 255, 255, 0.1);
            padding: 1rem;
            margin: 1rem 0;
            border-radius: 10px;
            border-left: 4px solid #4CAF50;
        }
        .status {
            display: inline-block;
            padding: 0.5rem 1rem;
            background: #4CAF50;
            border-radius: 20px;
            font-weight: bold;
            margin-top: 1rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="emoji">🌐</div>
        <h1>Web Server Active</h1>
        <p>Your Linux Setup web server is now running successfully!</p>
        
        <div class="feature">
            <strong>✅ Apache Web Server</strong><br>
            High-performance web server with SSL support
        </div>
        
        <div class="feature">
            <strong>✅ Nginx Reverse Proxy</strong><br>
            Load balancing and caching capabilities
        </div>
        
        <div class="feature">
            <strong>✅ PHP Support</strong><br>
            Latest PHP with essential extensions
        </div>
        
        <div class="feature">
            <strong>✅ Security Configured</strong><br>
            Firewall, SSL/TLS, and security headers
        </div>
        
        <div class="status">🚀 Server Status: Online</div>
        
        <p style="margin-top: 2rem; font-size: 0.9rem; opacity: 0.8;">
            Linux Setup - Professional Server Management System<br>
            <a href="https://ls.r-u.live" style="color: #FFD700;">ls.r-u.live</a>
        </p>
    </div>
</body>
</html>
EOF
    
    log_info "Default index page created"
}

# ==========================================
# SSL/TLS FUNCTIONS
# ==========================================

configure_webserver_ssl() {
    print_step "Configuring SSL/TLS for webserver..."
    
    # Check if SSL module is available
    if systemctl is-active ssl 2>/dev/null; then
        log_info "SSL certificates already configured"
        return 0
    fi
    
    # Generate self-signed certificate for testing
    generate_self_signed_cert
    
    # Configure SSL virtual hosts
    configure_ssl_virtual_hosts
    
    log_info "SSL/TLS configuration completed"
}

generate_self_signed_cert() {
    print_substep "Generating self-signed SSL certificate..."
    
    local ssl_dir="/etc/ssl/certs"
    local key_dir="/etc/ssl/private"
    
    mkdir -p "$ssl_dir" "$key_dir"
    
    # Generate certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$key_dir/apache-selfsigned.key" \
        -out "$ssl_dir/apache-selfsigned.crt" \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=localhost" \
        >/dev/null 2>&1
    
    log_info "Self-signed SSL certificate generated"
}

configure_ssl_virtual_hosts() {
    print_substep "Configuring SSL virtual hosts..."
    
    # Configure Apache SSL
    configure_apache_ssl
    
    # Configure Nginx SSL
    configure_nginx_ssl
    
    log_info "SSL virtual hosts configured"
}

configure_apache_ssl() {
    local ssl_conf="/etc/apache2/sites-available/default-ssl.conf"
    
    cat > "$ssl_conf" << 'EOF'
<VirtualHost _default_:443>
    DocumentRoot /var/www/html
    
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
    
    # Modern SSL configuration
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder off
    SSLSessionTickets off
    
    # Security headers
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    
    ErrorLog ${APACHE_LOG_DIR}/ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/ssl_access.log combined
</VirtualHost>
EOF
    
    # Enable SSL site
    a2ensite default-ssl >/dev/null 2>&1 || true
}

configure_nginx_ssl() {
    local ssl_conf="/etc/nginx/sites-available/default-ssl"
    
    cat > "$ssl_conf" << 'EOF'
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name _;
    
    root /var/www/html;
    index index.html index.php;
    
    ssl_certificate /etc/ssl/certs/apache-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/apache-selfsigned.key;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }
}
EOF
    
    # Enable SSL site
    ln -sf "$ssl_conf" "/etc/nginx/sites-enabled/default-ssl" 2>/dev/null
}

# ==========================================
# SECURITY FUNCTIONS
# ==========================================

configure_webserver_security() {
    print_step "Configuring webserver security..."
    
    # Configure fail2ban for web server
    configure_webserver_fail2ban
    
    # Set up log rotation
    configure_webserver_logrotate
    
    # Configure file permissions
    secure_webserver_permissions
    
    log_info "Webserver security configuration completed"
}

configure_webserver_fail2ban() {
    print_substep "Configuring Fail2Ban for webserver..."
    
    # Check if fail2ban is installed
    if ! command -v fail2ban-server >/dev/null 2>&1; then
        log_warning "Fail2Ban not installed, skipping configuration"
        return 0
    fi
    
    local jail_conf="/etc/fail2ban/jail.d/webserver.conf"
    
    cat > "$jail_conf" << 'EOF'
[apache-auth]
enabled = true
port = http,https
filter = apache-auth
logpath = /var/log/apache2/*error.log
maxretry = 3
bantime = 3600

[apache-badbots]
enabled = true
port = http,https
filter = apache-badbots
logpath = /var/log/apache2/*access.log
maxretry = 2
bantime = 86400

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/*error.log
maxretry = 3
bantime = 3600
EOF
    
    # Restart fail2ban
    systemctl restart fail2ban >/dev/null 2>&1 || true
    
    log_info "Fail2Ban configured for webserver"
}

configure_webserver_logrotate() {
    print_substep "Configuring log rotation..."
    
    local logrotate_conf="/etc/logrotate.d/webserver"
    
    cat > "$logrotate_conf" << 'EOF'
/var/log/apache2/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 root adm
    postrotate
        systemctl reload apache2 > /dev/null 2>&1 || true
    endscript
}

/var/log/nginx/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data adm
    postrotate
        systemctl reload nginx > /dev/null 2>&1 || true
    endscript
}
EOF
    
    log_info "Log rotation configured"
}

secure_webserver_permissions() {
    print_substep "Securing file permissions..."
    
    # Set secure permissions for web directories
    find /var/www -type d -exec chmod 755 {} \; 2>/dev/null || true
    find /var/www -type f -exec chmod 644 {} \; 2>/dev/null || true
    
    # Set ownership
    chown -R www-data:www-data /var/www 2>/dev/null || \
    chown -R apache:apache /var/www 2>/dev/null || \
    chown -R nginx:nginx /var/www 2>/dev/null || true
    
    log_info "File permissions secured"
}

# ==========================================
# FIREWALL FUNCTIONS
# ==========================================

configure_webserver_firewall() {
    print_step "Configuring firewall for webserver..."
    
    # Allow HTTP and HTTPS traffic
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 80/tcp >/dev/null 2>&1 || true
        ufw allow 443/tcp >/dev/null 2>&1 || true
        log_info "UFW rules added for HTTP/HTTPS"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-service=http >/dev/null 2>&1 || true
        firewall-cmd --permanent --add-service=https >/dev/null 2>&1 || true
        firewall-cmd --reload >/dev/null 2>&1 || true
        log_info "Firewalld rules added for HTTP/HTTPS"
    else
        log_warning "No supported firewall found"
    fi
}

# ==========================================
# MONITORING FUNCTIONS
# ==========================================

install_web_tools() {
    print_step "Installing additional web tools..."
    
    case $OS in
        "ubuntu"|"debian")
            apt_install "curl wget htop iotop"
            apt_install "apache2-utils" # For ab (Apache Bench)
            ;;
        "centos"|"rhel"|"rocky"|"alma")
            dnf_install "curl wget htop iotop"
            dnf_install "httpd-tools" # For ab (Apache Bench)
            ;;
        "arch")
            pacman_install "curl wget htop iotop"
            pacman_install "apache-tools"
            ;;
    esac
    
    log_info "Additional web tools installed"
}

# ==========================================
# UTILITY FUNCTIONS
# ==========================================

get_webserver_status() {
    echo "=== Web Server Status ==="
    
    # Apache status
    if systemctl is-active apache2 >/dev/null 2>&1 || systemctl is-active httpd >/dev/null 2>&1; then
        echo "Apache: ✅ Running"
    else
        echo "Apache: ❌ Not running"
    fi
    
    # Nginx status
    if systemctl is-active nginx >/dev/null 2>&1; then
        echo "Nginx: ✅ Running"
    else
        echo "Nginx: ❌ Not running"
    fi
    
    # PHP-FPM status
    if systemctl is-active php-fpm >/dev/null 2>&1; then
        echo "PHP-FPM: ✅ Running"
    else
        echo "PHP-FPM: ❌ Not running"
    fi
    
    # Port status
    echo ""
    echo "=== Port Status ==="
    ss -tlnp | grep -E ':80 |:443 ' || echo "No web server ports listening"
}

restart_webserver() {
    print_step "Restarting web server services..."
    
    systemctl restart apache2 2>/dev/null || systemctl restart httpd 2>/dev/null || true
    systemctl restart nginx 2>/dev/null || true
    systemctl restart php-fpm 2>/dev/null || true
    
    log_info "Web server services restarted"
}

check_webserver_config() {
    print_step "Checking web server configuration..."
    
    # Check Apache configuration
    if command -v apache2ctl >/dev/null 2>&1; then
        if apache2ctl configtest >/dev/null 2>&1; then
            log_success "Apache configuration: OK"
        else
            log_error "Apache configuration: ERROR"
        fi
    elif command -v httpd >/dev/null 2>&1; then
        if httpd -t >/dev/null 2>&1; then
            log_success "Apache configuration: OK"
        else
            log_error "Apache configuration: ERROR"
        fi
    fi
    
    # Check Nginx configuration
    if command -v nginx >/dev/null 2>&1; then
        if nginx -t >/dev/null 2>&1; then
            log_success "Nginx configuration: OK"
        else
            log_error "Nginx configuration: ERROR"
        fi
    fi
}
