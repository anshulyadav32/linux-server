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

# Function to check SSL certificates
check_ssl_certs() {
    echo -e "${YELLOW}Checking SSL certificates...${NC}"
    local errors=0
    
    # Check Let's Encrypt certificates
    if [ -d "/etc/letsencrypt/live" ]; then
        for domain in /etc/letsencrypt/live/*; do
            if [ -d "$domain" ]; then
                domain=$(basename "$domain")
                expiry=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$domain/cert.pem" | cut -d= -f2)
                expiry_epoch=$(date -d "$expiry" +%s)
                current_epoch=$(date +%s)
                days_left=$(( ($expiry_epoch - $current_epoch) / 86400 ))
                
                if [ $days_left -lt 30 ]; then
                    echo -e "${RED}✗ Certificate for $domain expires in $days_left days${NC}"
                    errors=$((errors + 1))
                else
                    echo -e "${GREEN}✓ Certificate for $domain valid for $days_left days${NC}"
                fi
            fi
        done
    fi
    
    # Check self-signed certificates
    for cert in /etc/ssl/certs/*.crt; do
        if [ -f "$cert" ]; then
            expiry=$(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2)
            expiry_epoch=$(date -d "$expiry" +%s)
            current_epoch=$(date +%s)
            days_left=$(( ($expiry_epoch - $current_epoch) / 86400 ))
            
            if [ $days_left -lt 30 ]; then
                echo -e "${RED}✗ Self-signed certificate $(basename "$cert") expires in $days_left days${NC}"
                errors=$((errors + 1))
            else
                echo -e "${GREEN}✓ Self-signed certificate $(basename "$cert") valid for $days_left days${NC}"
            fi
        fi
    done
    
    return $errors
}

# Function to renew certificates
renew_certificates() {
    echo -e "${YELLOW}Renewing certificates...${NC}"
    
    # Try to renew Let's Encrypt certificates
    certbot renew --non-interactive
    
    # Check renewal status
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Certificate renewal completed${NC}"
    else
        echo -e "${RED}✗ Certificate renewal failed${NC}"
        return 1
    fi
}

# Function to check SSL configuration
check_ssl_config() {
    echo -e "${YELLOW}Checking SSL configuration...${NC}"
    local errors=0
    
    # Check SSL directories
    for dir in "/etc/ssl/private" "/etc/ssl/certs" "/etc/letsencrypt"; do
        if [ ! -d "$dir" ]; then
            echo -e "${RED}✗ $dir directory is missing${NC}"
            errors=$((errors + 1))
        fi
    done
    
    # Check directory permissions
    if [ "$(stat -c %a /etc/ssl/private)" != "700" ]; then
        echo -e "${RED}✗ /etc/ssl/private has incorrect permissions${NC}"
        errors=$((errors + 1))
    fi
    
    # Check renewal cron job
    if ! crontab -l | grep -q "certbot renew"; then
        echo -e "${RED}✗ Certificate renewal cron job is missing${NC}"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# Function to repair SSL configuration
repair_ssl_config() {
    echo -e "${YELLOW}Repairing SSL configuration...${NC}"
    
    # Recreate missing directories
    for dir in "/etc/ssl/private" "/etc/ssl/certs" "/etc/letsencrypt"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo -e "${GREEN}✓ Recreated $dir${NC}"
        fi
    done
    
    # Fix permissions
    chmod 700 /etc/ssl/private
    chmod 755 /etc/ssl/certs
    chmod 755 /etc/letsencrypt
    
    # Restore renewal cron job if missing
    if ! crontab -l | grep -q "certbot renew"; then
        setup_cert_renewal
    fi
    
    echo -e "${GREEN}✓ SSL configuration repaired${NC}"
}

# Function to show SSL status
show_ssl_status() {
    echo -e "${YELLOW}SSL System Status${NC}"
    echo "----------------------------------------"
    
    # Show Let's Encrypt certificates
    echo "Let's Encrypt Certificates:"
    if [ -d "/etc/letsencrypt/live" ]; then
        for domain in /etc/letsencrypt/live/*; do
            if [ -d "$domain" ]; then
                domain=$(basename "$domain")
                echo "Domain: $domain"
                openssl x509 -in "/etc/letsencrypt/live/$domain/cert.pem" -noout -text | grep -E "Not Before|Not After|Subject:"
                echo
            fi
        done
    fi
    
    # Show self-signed certificates
    echo "Self-signed Certificates:"
    for cert in /etc/ssl/certs/*.crt; do
        if [ -f "$cert" ]; then
            echo "Certificate: $(basename "$cert")"
            openssl x509 -in "$cert" -noout -text | grep -E "Not Before|Not After|Subject:"
            echo
        fi
    done
    
    # Show renewal status
    echo "Let's Encrypt Renewal Status:"
    certbot certificates
}

# Main menu
while true; do
    echo -e "\n${YELLOW}SSL System Maintenance${NC}"
    echo "1. Check SSL certificates"
    echo "2. Renew certificates"
    echo "3. Check SSL configuration"
    echo "4. Repair SSL configuration"
    echo "5. Show SSL status"
    echo "6. Exit"
    
    read -p "Select an option: " choice
    
    case $choice in
        1)
            check_ssl_certs
            ;;
        2)
            renew_certificates
            ;;
        3)
            check_ssl_config
            ;;
        4)
            repair_ssl_config
            ;;
        5)
            show_ssl_status
            ;;
        6)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
done

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
