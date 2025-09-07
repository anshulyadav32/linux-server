#!/bin/bash
# SSL System Updater
# Purpose: Update SSL tools and renew certificates

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
echo -e "${BLUE}       SSL SYSTEM UPDATER              ${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

# Update system packages
echo -e "\n${YELLOW}[1/4] Updating system packages...${NC}"
apt update && apt upgrade -y

# Update Certbot
echo -e "\n${YELLOW}[2/4] Updating Certbot...${NC}"
if command -v certbot >/dev/null 2>&1; then
    apt install --only-upgrade -y certbot python3-certbot-apache python3-certbot-nginx
    echo -e "${GREEN}Certbot updated successfully${NC}"
else
    echo -e "${YELLOW}Certbot not installed, installing now...${NC}"
    install_ssl
fi

# Renew certificates
echo -e "\n${YELLOW}[3/4] Renewing SSL certificates...${NC}"
if certbot certificates 2>/dev/null | grep -q "Certificate Name:"; then
    if certbot renew --dry-run; then
        echo -e "${GREEN}Dry run successful, proceeding with renewal...${NC}"
        certbot renew --quiet
        echo -e "${GREEN}Certificates renewed successfully${NC}"
    else
        echo -e "${RED}Dry run failed, skipping renewal${NC}"
    fi
else
    echo -e "${YELLOW}No certificates found to renew${NC}"
fi

# Restart web servers
echo -e "\n${YELLOW}[4/4] Restarting web servers...${NC}"
if systemctl is-active --quiet apache2; then
    systemctl reload apache2
    echo -e "${GREEN}Apache reloaded${NC}"
fi

if systemctl is-active --quiet nginx; then
    systemctl reload nginx
    echo -e "${GREEN}Nginx reloaded${NC}"
fi

# Show certificate status
echo -e "\n${BLUE}Certificate Status:${NC}"
if command -v certbot >/dev/null 2>&1; then
    certbot certificates
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}     SSL SYSTEM UPDATE COMPLETE        ${NC}"
echo -e "${GREEN}========================================${NC}"
