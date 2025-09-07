#!/bin/bash
# SSL Functions Library
# Reusable functions for SSL certificate management

#===========================================
# INSTALLATION FUNCTIONS
#===========================================

install_ssl() {
    echo "[INFO] Installing SSL certificate tools..."
    
    # Update package list
    apt update -y
    
    # Install Certbot and SSL tools
    apt install -y certbot python3-certbot-apache python3-certbot-nginx \
                   openssl ca-certificates
    
    # Install snapd for latest certbot (if available)
    if command -v snap &> /dev/null; then
        snap install core; snap refresh core
        snap install --classic certbot
        ln -sf /snap/bin/certbot /usr/bin/certbot
    fi
    
    configure_ssl_defaults
    echo "[SUCCESS] SSL tools installed"
}

configure_ssl_defaults() {
    echo "[INFO] Configuring SSL defaults..."
    
    # Create SSL directory structure
    mkdir -p /etc/ssl/private
    mkdir -p /etc/ssl/certs
    mkdir -p /etc/ssl/requests
    
    # Set proper permissions
    chmod 700 /etc/ssl/private
    chmod 755 /etc/ssl/certs
    
    # Create DH parameters for better security
    if [[ ! -f /etc/ssl/certs/dhparam.pem ]]; then
        echo "[INFO] Generating DH parameters (this may take a while)..."
        openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    fi
    
    echo "[SUCCESS] SSL defaults configured"
}

#===========================================
# CERTIFICATE GENERATION FUNCTIONS
#===========================================

generate_letsencrypt_cert() {
    local domain="$1"
    local webserver="${2:-apache}"
    local email="${3:-admin@$domain}"
    
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Generating Let's Encrypt certificate for: $domain"
    
    case "$webserver" in
        "apache")
            certbot --apache -d "$domain" --email "$email" --agree-tos --non-interactive
            ;;
        "nginx")
            certbot --nginx -d "$domain" --email "$email" --agree-tos --non-interactive
            ;;
        "standalone")
            certbot certonly --standalone -d "$domain" --email "$email" --agree-tos --non-interactive
            ;;
        "webroot")
            local webroot="${4:-/var/www/html}"
            certbot certonly --webroot -w "$webroot" -d "$domain" --email "$email" --agree-tos --non-interactive
            ;;
        *)
            echo "[ERROR] Supported webservers: apache, nginx, standalone, webroot"
            return 1
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        echo "[SUCCESS] Let's Encrypt certificate generated for $domain"
        configure_auto_renewal
    else
        echo "[ERROR] Certificate generation failed"
        return 1
    fi
}

generate_selfsigned_cert() {
    local domain="$1"
    local days="${2:-365}"
    local key_size="${3:-2048}"
    
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Generating self-signed certificate for: $domain"
    
    local cert_path="/etc/ssl/certs/$domain.crt"
    local key_path="/etc/ssl/private/$domain.key"
    local csr_path="/etc/ssl/requests/$domain.csr"
    
    # Generate private key
    openssl genrsa -out "$key_path" "$key_size"
    
    # Generate certificate signing request
    openssl req -new -key "$key_path" -out "$csr_path" -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"
    
    # Generate self-signed certificate
    openssl x509 -req -in "$csr_path" -signkey "$key_path" -out "$cert_path" -days "$days"
    
    # Set proper permissions
    chmod 600 "$key_path"
    chmod 644 "$cert_path"
    
    echo "[SUCCESS] Self-signed certificate generated for $domain"
    echo "Certificate: $cert_path"
    echo "Private Key: $key_path"
}

generate_csr() {
    local domain="$1"
    local key_size="${2:-2048}"
    
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Generating CSR for: $domain"
    
    local key_path="/etc/ssl/private/$domain.key"
    local csr_path="/etc/ssl/requests/$domain.csr"
    
    # Generate private key
    openssl genrsa -out "$key_path" "$key_size"
    
    # Generate CSR
    openssl req -new -key "$key_path" -out "$csr_path" -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"
    
    # Set proper permissions
    chmod 600 "$key_path"
    chmod 644 "$csr_path"
    
    echo "[SUCCESS] CSR generated for $domain"
    echo "CSR: $csr_path"
    echo "Private Key: $key_path"
    echo ""
    echo "CSR Content (submit this to your CA):"
    cat "$csr_path"
}

#===========================================
# CERTIFICATE MANAGEMENT FUNCTIONS
#===========================================

install_cert() {
    local domain="$1"
    local cert_file="$2"
    local key_file="$3"
    local chain_file="$4"
    
    if [[ -z "$domain" || -z "$cert_file" || -z "$key_file" ]]; then
        echo "[ERROR] Domain, certificate file, and key file parameters required"
        return 1
    fi
    
    echo "[INFO] Installing certificate for: $domain"
    
    local cert_path="/etc/ssl/certs/$domain.crt"
    local key_path="/etc/ssl/private/$domain.key"
    
    # Copy certificate files
    cp "$cert_file" "$cert_path"
    cp "$key_file" "$key_path"
    
    # Install chain certificate if provided
    if [[ -n "$chain_file" ]]; then
        cat "$chain_file" >> "$cert_path"
    fi
    
    # Set proper permissions
    chmod 644 "$cert_path"
    chmod 600 "$key_path"
    
    echo "[SUCCESS] Certificate installed for $domain"
}

renew_letsencrypt_cert() {
    local domain="$1"
    
    if [[ -n "$domain" ]]; then
        echo "[INFO] Renewing Let's Encrypt certificate for: $domain"
        certbot renew --cert-name "$domain"
    else
        echo "[INFO] Renewing all Let's Encrypt certificates"
        certbot renew
    fi
    
    if [[ $? -eq 0 ]]; then
        echo "[SUCCESS] Certificate(s) renewed successfully"
        reload_webserver
    else
        echo "[ERROR] Certificate renewal failed"
        return 1
    fi
}

revoke_letsencrypt_cert() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[WARNING] This will revoke the certificate for: $domain"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        certbot revoke --cert-name "$domain"
        certbot delete --cert-name "$domain"
        echo "[SUCCESS] Certificate revoked for $domain"
    else
        echo "[INFO] Operation cancelled"
    fi
}

remove_cert() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[WARNING] This will remove the certificate for: $domain"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -f "/etc/ssl/certs/$domain.crt"
        rm -f "/etc/ssl/private/$domain.key"
        rm -f "/etc/ssl/requests/$domain.csr"
        echo "[SUCCESS] Certificate files removed for $domain"
    else
        echo "[INFO] Operation cancelled"
    fi
}

list_certificates() {
    echo "[INFO] SSL certificates on system:"
    
    echo "=== Let's Encrypt Certificates ==="
    if command -v certbot &> /dev/null; then
        certbot certificates
    else
        echo "Certbot not available"
    fi
    
    echo ""
    echo "=== Local Certificate Files ==="
    if [[ -d /etc/ssl/certs ]]; then
        find /etc/ssl/certs -name "*.crt" -exec basename {} \; | grep -v "^ca-certificates" | sort
    fi
}

#===========================================
# CERTIFICATE VALIDATION FUNCTIONS
#===========================================

verify_cert() {
    local domain="$1"
    local cert_file="${2:-/etc/ssl/certs/$domain.crt}"
    
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Verifying certificate for: $domain"
    
    if [[ -f "$cert_file" ]]; then
        echo "=== Certificate Information ==="
        openssl x509 -in "$cert_file" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:)"
        
        echo ""
        echo "=== Certificate Validity ==="
        local expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
        echo "Expires: $expiry_date"
        
        # Check if certificate is expired
        if openssl x509 -in "$cert_file" -noout -checkend 0; then
            echo "Status: Valid"
        else
            echo "Status: EXPIRED"
        fi
        
        # Check if certificate expires in 30 days
        if openssl x509 -in "$cert_file" -noout -checkend 2592000; then
            echo "Warning: Certificate expires within 30 days"
        fi
    else
        echo "[ERROR] Certificate file not found: $cert_file"
        return 1
    fi
}

test_ssl_connection() {
    local domain="$1"
    local port="${2:-443}"
    
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Testing SSL connection to: $domain:$port"
    
    echo "" | openssl s_client -connect "$domain:$port" -servername "$domain" 2>/dev/null | \
    openssl x509 -noout -subject -dates -issuer
    
    # Test SSL configuration
    echo ""
    echo "=== SSL Configuration Test ==="
    curl -I "https://$domain" 2>/dev/null | head -1 || echo "Connection failed"
}

check_cert_expiry() {
    local days="${1:-30}"
    
    echo "[INFO] Checking certificates expiring within $days days:"
    
    # Check Let's Encrypt certificates
    if command -v certbot &> /dev/null; then
        certbot certificates 2>/dev/null | grep -E "(Certificate Name:|Expiry Date:)" | \
        while read line; do
            if [[ "$line" =~ "Certificate Name:" ]]; then
                cert_name=$(echo "$line" | cut -d: -f2 | tr -d ' ')
            elif [[ "$line" =~ "Expiry Date:" ]]; then
                expiry_date=$(echo "$line" | cut -d: -f2- | tr -d ' ')
                expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null)
                current_timestamp=$(date +%s)
                days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
                
                if [[ $days_until_expiry -le $days ]]; then
                    echo "WARNING: $cert_name expires in $days_until_expiry days ($expiry_date)"
                fi
            fi
        done
    fi
}

#===========================================
# WEBSERVER INTEGRATION FUNCTIONS
#===========================================

configure_apache_ssl() {
    local domain="$1"
    local cert_file="${2:-/etc/ssl/certs/$domain.crt}"
    local key_file="${3:-/etc/ssl/private/$domain.key}"
    
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Configuring Apache SSL for: $domain"
    
    # Enable SSL module
    a2enmod ssl
    
    # Create SSL virtual host
    cat > "/etc/apache2/sites-available/$domain-ssl.conf" << EOF
<VirtualHost *:443>
    ServerName $domain
    DocumentRoot /var/www/$domain
    
    SSLEngine on
    SSLCertificateFile $cert_file
    SSLCertificateKeyFile $key_file
    
    # Modern SSL configuration
    SSLProtocol -all +TLSv1.2 +TLSv1.3
    SSLCipherSuite ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder on
    
    # Security headers
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Frame-Options DENY
    Header always set X-Content-Type-Options nosniff
    
    ErrorLog \${APACHE_LOG_DIR}/$domain-ssl_error.log
    CustomLog \${APACHE_LOG_DIR}/$domain-ssl_access.log combined
</VirtualHost>
EOF
    
    # Enable site
    a2ensite "$domain-ssl"
    systemctl reload apache2
    
    echo "[SUCCESS] Apache SSL configured for $domain"
}

configure_nginx_ssl() {
    local domain="$1"
    local cert_file="${2:-/etc/ssl/certs/$domain.crt}"
    local key_file="${3:-/etc/ssl/private/$domain.key}"
    
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Configuring Nginx SSL for: $domain"
    
    # Create SSL server block
    cat > "/etc/nginx/sites-available/$domain-ssl" << EOF
server {
    listen 443 ssl http2;
    server_name $domain;
    root /var/www/$domain;
    
    # SSL configuration
    ssl_certificate $cert_file;
    ssl_certificate_key $key_file;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    access_log /var/log/nginx/$domain-ssl_access.log;
    error_log /var/log/nginx/$domain-ssl_error.log;
}
EOF
    
    # Enable site
    ln -sf "/etc/nginx/sites-available/$domain-ssl" "/etc/nginx/sites-enabled/"
    nginx -t && systemctl reload nginx
    
    echo "[SUCCESS] Nginx SSL configured for $domain"
}

reload_webserver() {
    echo "[INFO] Reloading web server..."
    
    if systemctl is-active --quiet apache2; then
        systemctl reload apache2
        echo "[SUCCESS] Apache reloaded"
    fi
    
    if systemctl is-active --quiet nginx; then
        nginx -t && systemctl reload nginx
        echo "[SUCCESS] Nginx reloaded"
    fi
}

#===========================================
# AUTOMATION FUNCTIONS
#===========================================

configure_auto_renewal() {
    echo "[INFO] Configuring automatic certificate renewal..."
    
    # Create renewal script
    cat > /usr/local/bin/ssl-auto-renew.sh << 'EOF'
#!/bin/bash
# Automatic SSL certificate renewal script

LOG_FILE="/var/log/ssl-renewal.log"

echo "$(date): Starting certificate renewal check" >> "$LOG_FILE"

# Renew Let's Encrypt certificates
if command -v certbot &> /dev/null; then
    certbot renew --quiet >> "$LOG_FILE" 2>&1
    
    if [[ $? -eq 0 ]]; then
        echo "$(date): Certificate renewal completed successfully" >> "$LOG_FILE"
        
        # Reload web servers
        if systemctl is-active --quiet apache2; then
            systemctl reload apache2
        fi
        
        if systemctl is-active --quiet nginx; then
            systemctl reload nginx
        fi
    else
        echo "$(date): Certificate renewal failed" >> "$LOG_FILE"
    fi
fi

echo "$(date): Certificate renewal check completed" >> "$LOG_FILE"
EOF
    
    chmod +x /usr/local/bin/ssl-auto-renew.sh
    
    # Add to crontab (run twice daily)
    (crontab -l 2>/dev/null; echo "0 */12 * * * /usr/local/bin/ssl-auto-renew.sh") | crontab -
    
    echo "[SUCCESS] Automatic renewal configured"
}

#===========================================
# UPDATE FUNCTIONS
#===========================================

update_ssl() {
    echo "[INFO] Updating SSL tools..."
    apt update -y
    apt upgrade -y certbot python3-certbot-apache python3-certbot-nginx openssl
    
    # Update snap certbot if available
    if command -v snap &> /dev/null && snap list certbot &>/dev/null; then
        snap refresh certbot
    fi
    
    echo "[SUCCESS] SSL tools updated"
}
