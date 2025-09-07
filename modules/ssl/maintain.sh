#!/bin/bash
# SSL System Maintenance
# Purpose: Daily SSL/certificate health checks and monitoring

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
echo -e "${BLUE}      SSL SYSTEM MAINTENANCE           ${NC}"
echo -e "${BLUE}========================================${NC}"

# Function to check certificate expiry
check_certificate_expiry() {
    local domain="$1"
    local cert_path="/etc/letsencrypt/live/$domain/fullchain.pem"
    
    if [[ -f "$cert_path" ]]; then
        local expiry_date=$(openssl x509 -enddate -noout -in "$cert_path" | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry_date" +%s)
        local current_epoch=$(date +%s)
        local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
        
        echo -e "${BLUE}Domain: $domain${NC}"
        echo -e "Certificate Path: $cert_path"
        echo -e "Expiry Date: $expiry_date"
        echo -e "Days Until Expiry: $days_until_expiry"
        
        if [[ $days_until_expiry -lt 30 ]]; then
            echo -e "${YELLOW}⚠️  Certificate expires in less than 30 days!${NC}"
        elif [[ $days_until_expiry -lt 7 ]]; then
            echo -e "${RED}🚨 Certificate expires in less than 7 days!${NC}"
        else
            echo -e "${GREEN}✅ Certificate is valid${NC}"
        fi
        echo
    else
        echo -e "${RED}❌ Certificate not found for $domain${NC}"
    fi
}

# Check web server status
echo -e "${YELLOW}[1/5] Checking web server status...${NC}"
if systemctl is-active --quiet apache2; then
    echo -e "${GREEN}✅ Apache is running${NC}"
    apache2ctl -t && echo -e "${GREEN}✅ Apache configuration is valid${NC}" || echo -e "${RED}❌ Apache configuration has errors${NC}"
elif systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ Nginx is running${NC}"
    nginx -t && echo -e "${GREEN}✅ Nginx configuration is valid${NC}" || echo -e "${RED}❌ Nginx configuration has errors${NC}"
else
    echo -e "${RED}❌ No web server is running${NC}"
fi

# Check Certbot status
echo -e "\n${YELLOW}[2/5] Checking Certbot installation...${NC}"
if command -v certbot >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Certbot is installed${NC}"
    certbot --version
else
    echo -e "${RED}❌ Certbot is not installed${NC}"
fi

# List and check all certificates
echo -e "\n${YELLOW}[3/5] Checking SSL certificates...${NC}"
if command -v certbot >/dev/null 2>&1; then
    if certbot certificates 2>/dev/null | grep -q "Certificate Name:"; then
        echo -e "${BLUE}Found certificates:${NC}"
        certbot certificates
        echo
        
        # Extract domain names and check each
        domains=$(certbot certificates 2>/dev/null | grep "Domains:" | sed 's/.*Domains: //' | tr ' ' '\n' | sort -u)
        for domain in $domains; do
            check_certificate_expiry "$domain"
        done
    else
        echo -e "${YELLOW}⚠️  No SSL certificates found${NC}"
    fi
fi

# Test HTTPS connectivity
echo -e "\n${YELLOW}[4/5] Testing HTTPS connectivity...${NC}"
read -p "Enter domain to test HTTPS (or press Enter to skip): " test_domain
if [[ -n "$test_domain" ]]; then
    echo -e "${BLUE}Testing HTTPS for $test_domain...${NC}"
    if curl -Is "https://$test_domain" --max-time 10 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ HTTPS is working for $test_domain${NC}"
        
        # Get SSL certificate info
        ssl_info=$(echo | openssl s_client -servername "$test_domain" -connect "$test_domain":443 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null)
        echo -e "${BLUE}SSL Certificate Info:${NC}"
        echo "$ssl_info"
    else
        echo -e "${RED}❌ HTTPS test failed for $test_domain${NC}"
    fi
fi

# Check auto-renewal setup
echo -e "\n${YELLOW}[5/5] Checking auto-renewal setup...${NC}"
if [[ -f /etc/cron.d/ssl_renew ]]; then
    echo -e "${GREEN}✅ Auto-renewal cron job exists${NC}"
    cat /etc/cron.d/ssl_renew
elif crontab -l 2>/dev/null | grep -q certbot; then
    echo -e "${GREEN}✅ Auto-renewal found in crontab${NC}"
    crontab -l | grep certbot
else
    echo -e "${YELLOW}⚠️  No auto-renewal setup found${NC}"
    echo -e "${YELLOW}Consider setting up auto-renewal with:${NC}"
    echo "echo '0 3 * * * root certbot renew --quiet && systemctl reload apache2 nginx' > /etc/cron.d/ssl_renew"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}    SSL MAINTENANCE CHECK COMPLETE     ${NC}"
echo -e "${GREEN}========================================${NC}"
