#!/usr/bin/env bash
# =============================================================================
# Linux Setup - Domain Management Interface
# =============================================================================

set -Eeuo pipefail

# ---------- Script Setup ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions
if [[ -f "$BASE_DIR/modules/common.sh" ]]; then
    source "$BASE_DIR/modules/common.sh"
else
    echo "Error: common.sh not found"
    exit 1
fi

# ---------- Configuration ----------
DOMAIN_CONFIG="/etc/domain-manager/config"
ZONE_DIR="/etc/bind/zones"
NAMED_CONF="/etc/bind/named.conf.local"
TEMPLATES_DIR="/etc/domain-manager/templates"

# Load configuration if it exists
if [[ -f "$DOMAIN_CONFIG" ]]; then
    source "$DOMAIN_CONFIG"
fi

# ---------- Domain Management Functions ----------

add_domain() {
    local domain="$1"
    local ip="${2:-$(get_server_ip)}"
    
    log_info "Adding domain: $domain"
    
    # Validate domain format
    if ! validate_domain "$domain"; then
        log_error "Invalid domain format: $domain"
        return 1
    fi
    
    # Check if domain already exists
    if [[ -f "$ZONE_DIR/db.$domain" ]]; then
        log_warning "Domain $domain already exists"
        return 1
    fi
    
    # Create zone file from template
    create_zone_file "$domain" "$ip"
    
    # Add to named.conf.local
    add_to_named_conf "$domain"
    
    # Create web server configuration
    create_web_config "$domain"
    
    # Reload DNS service
    reload_dns_service
    
    log_success "Domain $domain added successfully"
}

create_zone_file() {
    local domain="$1"
    local ip="$2"
    local zone_file="$ZONE_DIR/db.$domain"
    
    log_info "Creating zone file for $domain"
    
    # Ensure zone directory exists
    mkdir -p "$ZONE_DIR"
    
    # Generate zone file from template
    sed -e "s/DOMAIN/$domain/g" \
        -e "s/SERVER_IP/$ip/g" \
        -e "s/\$(date +%Y%m%d%H)/$(date +%Y%m%d%H)/g" \
        "$TEMPLATES_DIR/a-record.template" > "$zone_file"
    
    # Set proper permissions
    chown bind:bind "$zone_file" 2>/dev/null || true
    chmod 644 "$zone_file"
    
    # Validate zone file
    if command -v named-checkzone >/dev/null; then
        if named-checkzone "$domain" "$zone_file" >/dev/null 2>&1; then
            log_success "Zone file for $domain is valid"
        else
            log_error "Zone file for $domain has errors"
            return 1
        fi
    fi
}

add_to_named_conf() {
    local domain="$1"
    
    log_info "Adding $domain to named configuration"
    
    # Backup existing configuration
    cp "$NAMED_CONF" "$NAMED_CONF.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Add zone configuration
    cat >> "$NAMED_CONF" <<EOF

zone "$domain" {
    type master;
    file "$ZONE_DIR/db.$domain";
    allow-update { none; };
};
EOF
    
    # Validate configuration
    if command -v named-checkconf >/dev/null; then
        if named-checkconf >/dev/null 2>&1; then
            log_success "BIND configuration is valid"
        else
            log_error "BIND configuration has errors"
            # Restore backup
            mv "$NAMED_CONF.backup.$(date +%Y%m%d_%H%M%S)" "$NAMED_CONF"
            return 1
        fi
    fi
}

create_web_config() {
    local domain="$1"
    local doc_root="/var/www/$domain"
    
    log_info "Creating web server configuration for $domain"
    
    # Create document root
    mkdir -p "$doc_root"
    
    # Create basic index file
    cat > "$doc_root/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to $domain</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
        h1 { color: #333; }
        p { color: #666; }
    </style>
</head>
<body>
    <h1>Welcome to $domain</h1>
    <p>This domain has been successfully configured.</p>
    <p>Domain added on: $(date)</p>
</body>
</html>
EOF
    
    # Set proper permissions
    chown -R www-data:www-data "$doc_root" 2>/dev/null || \
    chown -R apache:apache "$doc_root" 2>/dev/null || \
    chown -R nginx:nginx "$doc_root" 2>/dev/null || true
    
    # Create Apache virtual host if Apache is installed
    if command -v apache2 >/dev/null || command -v httpd >/dev/null; then
        create_apache_vhost "$domain" "$doc_root"
    fi
    
    # Create Nginx virtual host if Nginx is installed
    if command -v nginx >/dev/null; then
        create_nginx_vhost "$domain" "$doc_root"
    fi
}

create_apache_vhost() {
    local domain="$1"
    local doc_root="$2"
    local config_file="/etc/apache2/sites-available/$domain.conf"
    
    # Handle different Apache configurations
    if [[ -d "/etc/httpd/conf.d" ]]; then
        config_file="/etc/httpd/conf.d/$domain.conf"
    fi
    
    cat > "$config_file" <<EOF
<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot $doc_root
    
    <Directory $doc_root>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/$domain-error.log
    CustomLog \${APACHE_LOG_DIR}/$domain-access.log combined
</VirtualHost>
EOF
    
    # Enable site if using Debian/Ubuntu Apache
    if command -v a2ensite >/dev/null; then
        a2ensite "$domain" >/dev/null 2>&1 || true
    fi
    
    log_success "Apache virtual host created for $domain"
}

create_nginx_vhost() {
    local domain="$1"
    local doc_root="$2"
    local config_file="/etc/nginx/sites-available/$domain"
    
    cat > "$config_file" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    root $doc_root;
    index index.html index.htm index.php;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # PHP processing (if PHP-FPM is available)
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }
    
    # Deny access to .htaccess files
    location ~ /\.ht {
        deny all;
    }
    
    access_log /var/log/nginx/$domain-access.log;
    error_log /var/log/nginx/$domain-error.log;
}
EOF
    
    # Enable site
    ln -sf "$config_file" "/etc/nginx/sites-enabled/$domain" 2>/dev/null || true
    
    log_success "Nginx virtual host created for $domain"
}

remove_domain() {
    local domain="$1"
    
    log_info "Removing domain: $domain"
    
    # Remove zone file
    if [[ -f "$ZONE_DIR/db.$domain" ]]; then
        rm -f "$ZONE_DIR/db.$domain"
        log_success "Zone file removed for $domain"
    fi
    
    # Remove from named.conf.local
    remove_from_named_conf "$domain"
    
    # Remove web server configs
    remove_web_config "$domain"
    
    # Reload DNS service
    reload_dns_service
    
    log_success "Domain $domain removed successfully"
}

remove_from_named_conf() {
    local domain="$1"
    
    # Backup configuration
    cp "$NAMED_CONF" "$NAMED_CONF.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Remove zone configuration
    sed -i "/^zone \"$domain\" {/,/^};$/d" "$NAMED_CONF"
    
    log_success "Removed $domain from BIND configuration"
}

remove_web_config() {
    local domain="$1"
    
    # Remove Apache configuration
    if [[ -f "/etc/apache2/sites-available/$domain.conf" ]]; then
        a2dissite "$domain" >/dev/null 2>&1 || true
        rm -f "/etc/apache2/sites-available/$domain.conf"
    fi
    
    if [[ -f "/etc/httpd/conf.d/$domain.conf" ]]; then
        rm -f "/etc/httpd/conf.d/$domain.conf"
    fi
    
    # Remove Nginx configuration
    if [[ -f "/etc/nginx/sites-available/$domain" ]]; then
        rm -f "/etc/nginx/sites-enabled/$domain"
        rm -f "/etc/nginx/sites-available/$domain"
    fi
    
    log_success "Web server configuration removed for $domain"
}

list_domains() {
    log_info "Configured domains:"
    echo ""
    
    if [[ -d "$ZONE_DIR" ]]; then
        local count=0
        for zone_file in "$ZONE_DIR"/db.*; do
            if [[ -f "$zone_file" ]]; then
                local domain=$(basename "$zone_file" | sed 's/^db\.//')
                echo "  • $domain"
                ((count++))
            fi
        done
        
        if [[ $count -eq 0 ]]; then
            echo "  No domains configured"
        else
            echo ""
            log_success "Total domains: $count"
        fi
    else
        echo "  Zone directory not found"
    fi
}

check_domain() {
    local domain="$1"
    
    log_info "Checking domain: $domain"
    echo ""
    
    # DNS Resolution check
    if command -v dig >/dev/null; then
        echo "DNS Resolution:"
        dig +short "$domain" || echo "  DNS resolution failed"
        echo ""
    fi
    
    # Web server check
    echo "Web Server:"
    if curl -s -I "http://$domain" >/dev/null 2>&1; then
        echo "  ✓ HTTP accessible"
    else
        echo "  ✗ HTTP not accessible"
    fi
    
    # Zone file check
    echo ""
    echo "Zone File:"
    if [[ -f "$ZONE_DIR/db.$domain" ]]; then
        echo "  ✓ Zone file exists"
        if command -v named-checkzone >/dev/null; then
            if named-checkzone "$domain" "$ZONE_DIR/db.$domain" >/dev/null 2>&1; then
                echo "  ✓ Zone file is valid"
            else
                echo "  ✗ Zone file has errors"
            fi
        fi
    else
        echo "  ✗ Zone file not found"
    fi
}

reload_dns_service() {
    log_info "Reloading DNS service..."
    
    if systemctl is-active --quiet bind9; then
        systemctl reload bind9
    elif systemctl is-active --quiet named; then
        systemctl reload named
    else
        log_warning "No DNS service found to reload"
        return 1
    fi
    
    log_success "DNS service reloaded"
}

# ---------- Menu System ----------

show_main_menu() {
    while true; do
        clear
        show_header "Domain Management"
        echo ""
        echo "1) Add Domain"
        echo "2) Remove Domain"
        echo "3) List Domains"
        echo "4) Check Domain"
        echo "5) DNS Management"
        echo "6) Domain Tools"
        echo "0) Exit"
        echo ""
        
        read -p "Choose an option [0-6]: " choice
        
        case $choice in
            1) handle_add_domain ;;
            2) handle_remove_domain ;;
            3) list_domains; pause ;;
            4) handle_check_domain ;;
            5) show_dns_menu ;;
            6) show_tools_menu ;;
            0) exit 0 ;;
            *) log_error "Invalid choice"; sleep 2 ;;
        esac
    done
}

handle_add_domain() {
    clear
    show_header "Add Domain"
    echo ""
    
    read -p "Enter domain name: " domain
    if [[ -z "$domain" ]]; then
        log_error "Domain name cannot be empty"
        pause
        return
    fi
    
    read -p "Enter IP address (default: auto-detect): " ip
    if [[ -z "$ip" ]]; then
        ip=$(get_server_ip)
        log_info "Using detected IP: $ip"
    fi
    
    echo ""
    if add_domain "$domain" "$ip"; then
        echo ""
        log_success "Domain $domain added successfully!"
        echo ""
        echo "Next steps:"
        echo "1. Update your DNS provider to point $domain to $ip"
        echo "2. Access http://$domain to verify configuration"
    fi
    
    pause
}

handle_remove_domain() {
    clear
    show_header "Remove Domain"
    echo ""
    
    list_domains
    echo ""
    
    read -p "Enter domain name to remove: " domain
    if [[ -z "$domain" ]]; then
        log_error "Domain name cannot be empty"
        pause
        return
    fi
    
    echo ""
    if confirm_action "Remove domain $domain?"; then
        remove_domain "$domain"
    else
        log_info "Domain removal cancelled"
    fi
    
    pause
}

handle_check_domain() {
    clear
    show_header "Check Domain"
    echo ""
    
    read -p "Enter domain name to check: " domain
    if [[ -z "$domain" ]]; then
        log_error "Domain name cannot be empty"
        pause
        return
    fi
    
    echo ""
    check_domain "$domain"
    
    pause
}

show_dns_menu() {
    while true; do
        clear
        show_header "DNS Management"
        echo ""
        echo "1) Reload DNS Service"
        echo "2) Check DNS Configuration"
        echo "3) View DNS Logs"
        echo "4) DNS Service Status"
        echo "0) Back"
        echo ""
        
        read -p "Choose an option [0-4]: " choice
        
        case $choice in
            1) reload_dns_service; pause ;;
            2) check_dns_config; pause ;;
            3) view_dns_logs; pause ;;
            4) dns_service_status; pause ;;
            0) return ;;
            *) log_error "Invalid choice"; sleep 2 ;;
        esac
    done
}

show_tools_menu() {
    while true; do
        clear
        show_header "Domain Tools"
        echo ""
        echo "1) Domain Whois Lookup"
        echo "2) DNS Propagation Check"
        echo "3) SSL Certificate Check"
        echo "4) Bulk Domain Import"
        echo "0) Back"
        echo ""
        
        read -p "Choose an option [0-4]: " choice
        
        case $choice in
            1) handle_whois_lookup ;;
            2) handle_dns_propagation ;;
            3) handle_ssl_check ;;
            4) handle_bulk_import ;;
            0) return ;;
            *) log_error "Invalid choice"; sleep 2 ;;
        esac
    done
}

# ---------- Additional Tools ----------

check_dns_config() {
    log_info "Checking DNS configuration..."
    
    if command -v named-checkconf >/dev/null; then
        if named-checkconf; then
            log_success "BIND configuration is valid"
        else
            log_error "BIND configuration has errors"
        fi
    else
        log_warning "named-checkconf not available"
    fi
}

view_dns_logs() {
    log_info "Recent DNS logs:"
    echo ""
    
    if [[ -f /var/log/syslog ]]; then
        grep 'named\|bind' /var/log/syslog | tail -n 20
    elif [[ -f /var/log/messages ]]; then
        grep 'named\|bind' /var/log/messages | tail -n 20
    else
        log_warning "DNS logs not found"
    fi
}

dns_service_status() {
    log_info "DNS service status:"
    echo ""
    
    if systemctl is-active --quiet bind9; then
        systemctl status bind9 --no-pager -l
    elif systemctl is-active --quiet named; then
        systemctl status named --no-pager -l
    else
        log_warning "No DNS service found"
    fi
}

handle_whois_lookup() {
    clear
    show_header "Whois Lookup"
    echo ""
    
    read -p "Enter domain name: " domain
    if [[ -n "$domain" ]] && command -v whois >/dev/null; then
        echo ""
        whois "$domain"
    else
        log_error "Invalid domain or whois command not available"
    fi
    
    pause
}

handle_dns_propagation() {
    clear
    show_header "DNS Propagation Check"
    echo ""
    
    read -p "Enter domain name: " domain
    if [[ -n "$domain" ]] && command -v dig >/dev/null; then
        echo ""
        log_info "Checking DNS propagation for $domain..."
        
        # Check against multiple public DNS servers
        local dns_servers=("8.8.8.8" "1.1.1.1" "208.67.222.222" "4.2.2.1")
        
        for server in "${dns_servers[@]}"; do
            echo "DNS Server: $server"
            dig +short "@$server" "$domain" || echo "No response"
            echo ""
        done
    else
        log_error "Invalid domain or dig command not available"
    fi
    
    pause
}

handle_ssl_check() {
    clear
    show_header "SSL Certificate Check"
    echo ""
    
    read -p "Enter domain name: " domain
    if [[ -n "$domain" ]]; then
        echo ""
        log_info "Checking SSL certificate for $domain..."
        
        if command -v openssl >/dev/null; then
            echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | \
            openssl x509 -noout -dates 2>/dev/null || \
            log_warning "SSL certificate not found or invalid"
        else
            log_error "OpenSSL command not available"
        fi
    fi
    
    pause
}

handle_bulk_import() {
    clear
    show_header "Bulk Domain Import"
    echo ""
    
    read -p "Enter file path with domain list (one per line): " file_path
    if [[ -f "$file_path" ]]; then
        echo ""
        log_info "Importing domains from $file_path..."
        
        local count=0
        while IFS= read -r domain; do
            # Skip empty lines and comments
            if [[ -n "$domain" && ! "$domain" =~ ^[[:space:]]*# ]]; then
                echo "Adding: $domain"
                if add_domain "$domain"; then
                    ((count++))
                fi
            fi
        done < "$file_path"
        
        log_success "Imported $count domains"
    else
        log_error "File not found: $file_path"
    fi
    
    pause
}

# ---------- Main Entry Point ----------
main() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
    
    # Handle command line arguments
    case "${1:-}" in
        add)
            if [[ -n "${2:-}" ]]; then
                add_domain "$2" "${3:-}"
            else
                log_error "Usage: $0 add <domain> [ip]"
                exit 1
            fi
            ;;
        remove)
            if [[ -n "${2:-}" ]]; then
                remove_domain "$2"
            else
                log_error "Usage: $0 remove <domain>"
                exit 1
            fi
            ;;
        list)
            list_domains
            ;;
        check)
            if [[ -n "${2:-}" ]]; then
                check_domain "$2"
            else
                log_error "Usage: $0 check <domain>"
                exit 1
            fi
            ;;
        *)
            show_main_menu
            ;;
    esac
}

main "$@"