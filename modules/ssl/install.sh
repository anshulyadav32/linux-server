enable_restart_webserver
#!/bin/bash
# SSL System Installer
# Purpose: Comprehensive SSL certificate management setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Source functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

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
