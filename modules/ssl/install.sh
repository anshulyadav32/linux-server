#!/bin/bash
# SSL System Installer
# Purpose: Comprehensive SSL certificate management setup

# Quick install from remote source
# curl -sSL ls.r-u.live/s1.sh | sudo bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Source functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Function to install SSL tools
install_ssl_tools() {
    echo -e "${YELLOW}Installing SSL tools...${NC}"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $ID in
            ubuntu|debian)
                apt-get update
                apt-get install -y certbot openssl apache2-utils
                ;;
            centos|rhel|fedora)
                yum install -y epel-release
                yum install -y certbot openssl httpd-tools
                ;;
            *)
                echo -e "${RED}Unsupported operating system${NC}"
                exit 1
                ;;
        esac
    fi
}

# Function to setup SSL directory structure
setup_ssl_dirs() {
    echo -e "${YELLOW}Setting up SSL directory structure...${NC}"
    
    # Create SSL directories
    mkdir -p /etc/ssl/private
    mkdir -p /etc/ssl/certs
    mkdir -p /etc/letsencrypt
    
    # Set proper permissions
    chmod 700 /etc/ssl/private
    chmod 755 /etc/ssl/certs
    chmod 755 /etc/letsencrypt
}

# Function to create self-signed certificate
create_self_signed_cert() {
    local domain=$1
    local email=$2
    
    echo -e "${YELLOW}Creating self-signed certificate for $domain...${NC}"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "/etc/ssl/private/$domain.key" \
        -out "/etc/ssl/certs/$domain.crt" \
        -subj "/CN=$domain/emailAddress=$email/O=Self Signed/C=US"
        
    chmod 600 "/etc/ssl/private/$domain.key"
    chmod 644 "/etc/ssl/certs/$domain.crt"
}

# Function to request Let's Encrypt certificate
request_letsencrypt_cert() {
    local domain=$1
    local email=$2
    
    echo -e "${YELLOW}Requesting Let's Encrypt certificate for $domain...${NC}"
    
    certbot certonly --standalone \
        --non-interactive \
        --agree-tos \
        --email "$email" \
        -d "$domain"
}

# Function to setup automatic renewal
setup_cert_renewal() {
    echo -e "${YELLOW}Setting up certificate renewal...${NC}"
    
    # Add renewal job to crontab
    (crontab -l 2>/dev/null || true; echo "0 0 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    # Create renewal hook directory
    mkdir -p /etc/letsencrypt/renewal-hooks/post
}

# Function to validate SSL setup
validate_ssl_setup() {
    echo -e "${YELLOW}Validating SSL setup...${NC}"
    local errors=0
    
    # Check SSL tools
    for tool in openssl certbot; do
        if ! command -v $tool &> /dev/null; then
            echo -e "${RED}✗ $tool is not installed${NC}"
            errors=$((errors + 1))
        else
            echo -e "${GREEN}✓ $tool is installed${NC}"
        fi
    done
    
    # Check SSL directories
    for dir in "/etc/ssl/private" "/etc/ssl/certs" "/etc/letsencrypt"; do
        if [ ! -d "$dir" ]; then
            echo -e "${RED}✗ $dir directory is missing${NC}"
            errors=$((errors + 1))
        else
            echo -e "${GREEN}✓ $dir directory exists${NC}"
        fi
    done
    
    # Check directory permissions
    if [ "$(stat -c %a /etc/ssl/private)" != "700" ]; then
        echo -e "${RED}✗ /etc/ssl/private has incorrect permissions${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ /etc/ssl/private has correct permissions${NC}"
    fi
    
    # Check renewal cron job
    if ! crontab -l | grep -q "certbot renew"; then
        echo -e "${RED}✗ Certificate renewal cron job is not configured${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ Certificate renewal cron job is configured${NC}"
    fi
    
    return $errors
}

# Main installation flow
echo -e "${YELLOW}Starting SSL system installation...${NC}"

# Install required tools
install_ssl_tools
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install SSL tools${NC}"
    exit 1
fi

# Setup SSL directories
setup_ssl_dirs
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to setup SSL directories${NC}"
    exit 1
fi

# Setup certificate renewal
setup_cert_renewal
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to setup certificate renewal${NC}"
    exit 1
fi

# Validate installation
validate_ssl_setup
if [ $? -ne 0 ]; then
    echo -e "${RED}SSL system validation failed${NC}"
    exit 1
fi

echo -e "${GREEN}SSL system installation completed successfully${NC}"
echo -e "${YELLOW}To create a self-signed certificate use: create_self_signed_cert domain.com email@domain.com${NC}"
echo -e "${YELLOW}To request a Let's Encrypt certificate use: request_letsencrypt_cert domain.com email@domain.com${NC}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       SSL SYSTEM INSTALLER            ${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

# Update system
echo -e "\n${YELLOW}[1/6] Updating system packages...${NC}"
apt update && apt upgrade -y

# Install SSL tools
echo -e "\n${YELLOW}[2/6] Installing SSL tools...${NC}"
install_ssl

# Install web server if not present
echo -e "\n${YELLOW}[3/6] Checking web server...${NC}"
if ! systemctl is-active --quiet apache2 && ! systemctl is-active --quiet nginx; then
    echo -e "${YELLOW}No web server found. Installing Apache...${NC}"
    apt install -y apache2
    systemctl enable apache2
    systemctl start apache2
fi

# Enable SSL modules
echo -e "\n${YELLOW}[4/6] Enabling SSL modules...${NC}"
if systemctl is-active --quiet apache2; then
    a2enmod ssl
    a2enmod rewrite
    systemctl restart apache2
elif systemctl is-active --quiet nginx; then
    systemctl restart nginx
fi

# Configure firewall
echo -e "\n${YELLOW}[5/6] Configuring firewall...${NC}"
if command -v ufw >/dev/null 2>&1; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    echo -e "${GREEN}Firewall configured for HTTP/HTTPS${NC}"
fi

# Request SSL certificate
echo -e "\n${YELLOW}[6/6] SSL Certificate Setup${NC}"
read -p "Enter domain for SSL certificate (e.g., example.com): " domain
read -p "Enter email for Let's Encrypt registration: " email

if [[ -n "$domain" && -n "$email" ]]; then
    echo -e "${YELLOW}Requesting SSL certificate for $domain...${NC}"
    
    # Create webroot if it doesn't exist
    mkdir -p /var/www/html
    
    # Request certificate
    if certbot certonly --webroot -w /var/www/html -d "$domain" --email "$email" --agree-tos --non-interactive; then
        echo -e "${GREEN}SSL certificate successfully installed for $domain${NC}"
        
        # Setup auto-renewal
        echo "0 3 * * * root certbot renew --quiet && systemctl reload apache2 nginx" > /etc/cron.d/ssl_renew
        echo -e "${GREEN}Auto-renewal configured${NC}"
        
        # Test certificate
        test_ssl_certificate "$domain"
    else
        echo -e "${RED}Failed to install SSL certificate${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Skipping certificate installation (no domain/email provided)${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   SSL SYSTEM INSTALLATION COMPLETE    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Certificate location: /etc/letsencrypt/live/$domain/${NC}"
echo -e "${GREEN}Auto-renewal: Configured via cron${NC}"
echo -e "${GREEN}Next steps: Configure your web server virtual hosts${NC}"
