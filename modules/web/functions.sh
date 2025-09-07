#!/bin/bash
# Web-server Functions Library
# Reusable functions for web server management

#===========================================
# INSTALLATION FUNCTIONS
#===========================================

install_web() {
    # Install Apache, Nginx, PHP, Node.js stack
    echo "[INFO] Installing web server stack..."
    apt update -y
    apt install -y apache2 nginx php libapache2-mod-php nodejs npm php-mysql php-curl php-gd php-mbstring php-xml php-zip
    systemctl enable apache2 nginx
    systemctl start apache2
    # Stop nginx by default to avoid port conflicts
    systemctl stop nginx
    echo "[SUCCESS] Web server stack installed"
}

#===========================================
# WEBSITE MANAGEMENT FUNCTIONS
#===========================================

add_website() {
    local domain="$1"
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Adding website: $domain"
    
    # Create document root
    mkdir -p "/var/www/$domain/public_html"
    echo "<h1>Welcome to $domain</h1><p>Website successfully created!</p>" > "/var/www/$domain/public_html/index.html"
    
    # Create Apache virtual host
    cat > "/etc/apache2/sites-available/$domain.conf" << EOF
<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot /var/www/$domain/public_html
    ErrorLog \${APACHE_LOG_DIR}/${domain}_error.log
    CustomLog \${APACHE_LOG_DIR}/${domain}_access.log combined
</VirtualHost>
EOF
    
    # Enable the site
    a2ensite "$domain.conf"
    systemctl reload apache2
    
    echo "[SUCCESS] Website $domain created successfully"
    echo "[INFO] Document root: /var/www/$domain/public_html"
}

remove_website() {
    local domain="$1"
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Removing website: $domain"
    
    # Disable and remove site
    a2dissite "$domain.conf" 2>/dev/null
    rm -f "/etc/apache2/sites-available/$domain.conf"
    rm -rf "/var/www/$domain"
    systemctl reload apache2
    
    echo "[SUCCESS] Website $domain removed"
}

list_websites() {
    echo "[INFO] Active websites:"
    ls -la /var/www/ | grep -E '^d' | awk '{print $9}' | grep -v -E '^\.|^html$' | while read site; do
        if [[ -n "$site" ]]; then
            echo "  - $site"
        fi
    done
}

enable_ssl() {
    local domain="$1"
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    if command -v certbot >/dev/null 2>&1; then
        echo "[INFO] Enabling SSL for: $domain"
        certbot --apache -d "$domain" --non-interactive --agree-tos --email admin@"$domain"
        echo "[SUCCESS] SSL enabled for $domain"
    else
        echo "[ERROR] Certbot not installed. Install SSL module first."
        return 1
    fi
}

#===========================================
# SERVICE MANAGEMENT FUNCTIONS
#===========================================

restart_web() {
    echo "[INFO] Restarting web services..."
    systemctl restart apache2
    if systemctl is-active --quiet nginx; then
        systemctl restart nginx
    fi
    echo "[SUCCESS] Web services restarted"
}

reload_web() {
    echo "[INFO] Reloading web configurations..."
    systemctl reload apache2
    if systemctl is-active --quiet nginx; then
        systemctl reload nginx
    fi
    echo "[SUCCESS] Web configurations reloaded"
}

status_web() {
    echo "[INFO] Web services status:"
    echo "Apache2:"
    systemctl status apache2 --no-pager | head -3
    echo "Nginx:"
    systemctl status nginx --no-pager | head -3
}

#===========================================
# MAINTENANCE FUNCTIONS
#===========================================

clear_web_logs() {
    echo "[INFO] Clearing web server logs..."
    truncate -s 0 /var/log/apache2/error.log
    truncate -s 0 /var/log/apache2/access.log
    truncate -s 0 /var/log/nginx/error.log 2>/dev/null
    truncate -s 0 /var/log/nginx/access.log 2>/dev/null
    echo "[SUCCESS] Web server logs cleared"
}

view_web_logs() {
    echo "[INFO] Recent web server logs:"
    echo "=== Apache Error Log ==="
    tail -n 10 /var/log/apache2/error.log
    echo "=== Apache Access Log ==="
    tail -n 5 /var/log/apache2/access.log
}

test_web_config() {
    echo "[INFO] Testing web server configurations..."
    echo "Apache Configuration Test:"
    apache2ctl configtest
    echo "Nginx Configuration Test:"
    nginx -t 2>/dev/null || echo "Nginx not running"
}

#===========================================
# UPDATE FUNCTIONS
#===========================================

update_web() {
    echo "[INFO] Updating web server packages..."
    apt update -y
    apt upgrade -y apache2 nginx php libapache2-mod-php nodejs npm php-mysql php-curl php-gd php-mbstring php-xml php-zip
    npm update -g 2>/dev/null || echo "No global npm packages to update"
    echo "[SUCCESS] Web server stack updated"
}
