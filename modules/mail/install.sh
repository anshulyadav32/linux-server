#!/bin/bash
# Mail System Installer
# Purpose: Complete mail server setup with Postfix, Dovecot, Roundcube, and security

# Quick install from remote source
# curl -sSL ls.r-u.live/sh/mail.sh | sudo bash

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
echo -e "${BLUE}       MAIL SYSTEM INSTALLER           ${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

# Update system
echo -e "\n${YELLOW}[1/8] Updating system packages...${NC}"
update_system

# Install database
echo -e "\n${YELLOW}[2/8] Setting up database...${NC}"
install_database

# Install mail packages
echo -e "\n${YELLOW}[3/8] Installing mail server packages...${NC}"
install_mail_packages

# Configure firewall
echo -e "\n${YELLOW}[4/8] Configuring firewall...${NC}"
configure_mail_firewall

# Enable services
echo -e "\n${YELLOW}[5/8] Enabling mail services...${NC}"
enable_mail_services

# Start services
echo -e "\n${YELLOW}[6/8] Starting mail services...${NC}"
start_mail_services

# Configure SSL certificates
echo -e "\n${YELLOW}[7/10] Setting up SSL certificates...${NC}"

# Check if SSL module is available
if [[ -f "$SCRIPT_DIR/../ssl/functions.sh" ]]; then
    source "$SCRIPT_DIR/../ssl/functions.sh"
    echo -e "${GREEN}SSL module found, configuring certificates...${NC}"
else
    echo -e "${YELLOW}SSL module not found, you can install it later with:${NC}"
    echo -e "${YELLOW}curl -sSL ls.r-u.live/sh/s1.sh | sudo bash${NC}"
fi

# Configure basic settings
echo -e "\n${YELLOW}[8/10] Basic configuration...${NC}"

# Get domain information
read -p "Enter your mail server domain (e.g., mail.example.com): " mail_domain
read -p "Enter your primary domain (e.g., example.com): " primary_domain

if [[ -n "$mail_domain" && -n "$primary_domain" ]]; then
    # Basic Postfix configuration
    postconf -e "myhostname = $mail_domain"
    postconf -e "mydomain = $primary_domain"
    postconf -e "myorigin = \$mydomain"
    postconf -e "inet_interfaces = all"
    postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"
    
    # Basic security settings
    postconf -e "smtpd_banner = \$myhostname ESMTP"
    postconf -e "disable_vrfy_command = yes"
    postconf -e "smtpd_helo_required = yes"
    
    # SSL/TLS configuration for mail server
    postconf -e "smtpd_use_tls = yes"
    postconf -e "smtpd_tls_security_level = may"
    postconf -e "smtp_tls_security_level = may"
    postconf -e "smtpd_tls_cert_file = /etc/letsencrypt/live/$mail_domain/fullchain.pem"
    postconf -e "smtpd_tls_key_file = /etc/letsencrypt/live/$mail_domain/privkey.pem"
    postconf -e "smtpd_tls_protocols = !SSLv2, !SSLv3"
    
    echo -e "${GREEN}Basic Postfix configuration completed${NC}"
    
    # Check if SSL certificates exist, if not suggest installation
    if [[ ! -f "/etc/letsencrypt/live/$mail_domain/fullchain.pem" ]]; then
        echo -e "${YELLOW}SSL certificates not found for $mail_domain${NC}"
        echo -e "${YELLOW}To install SSL certificates, run:${NC}"
        echo -e "${BLUE}curl -sSL ls.r-u.live/sh/s1.sh | sudo bash${NC}"
        echo -e "${YELLOW}Then use the SSL module to generate certificates${NC}"
    else
        echo -e "${GREEN}SSL certificates found and configured${NC}"
    fi
    
    # Restart Postfix to apply changes
    systemctl restart postfix
fi

# Configure Dovecot SSL
echo -e "\n${YELLOW}[9/10] Configuring Dovecot SSL...${NC}"

if [[ -n "$mail_domain" ]]; then
    # Basic Dovecot SSL configuration
    if [[ -f "/etc/dovecot/conf.d/10-ssl.conf" ]]; then
        # Enable SSL in Dovecot
        sed -i 's/^#ssl = yes/ssl = yes/' /etc/dovecot/conf.d/10-ssl.conf
        sed -i "s|^#ssl_cert = .*|ssl_cert = </etc/letsencrypt/live/$mail_domain/fullchain.pem|" /etc/dovecot/conf.d/10-ssl.conf
        sed -i "s|^#ssl_key = .*|ssl_key = </etc/letsencrypt/live/$mail_domain/privkey.pem|" /etc/dovecot/conf.d/10-ssl.conf
        
        echo -e "${GREEN}Dovecot SSL configuration completed${NC}"
        systemctl restart dovecot
    else
        echo -e "${YELLOW}Dovecot SSL configuration file not found${NC}"
    fi
fi

# Test installation
echo -e "\n${YELLOW}[10/10] Testing mail server installation...${NC}"

echo -e "${BLUE}Checking service status:${NC}"
check_all_mail_services

echo -e "\n${BLUE}Checking mail ports:${NC}"
check_mail_ports

echo -e "\n${BLUE}Mail queue status:${NC}"
get_mail_queue_status

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   MAIL SYSTEM INSTALLATION COMPLETE   ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Mail server domain: $mail_domain${NC}"
echo -e "${GREEN}Primary domain: $primary_domain${NC}"
echo -e "${GREEN}Webmail: https://$mail_domain/roundcube${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${YELLOW}1. Install SSL certificates: ${BLUE}curl -sSL ls.r-u.live/sh/s1.sh | sudo bash${NC}"
echo -e "${YELLOW}2. Configure DNS records (MX, A, SPF, DKIM)${NC}"
echo -e "${YELLOW}3. Configure user accounts${NC}"
echo -e "${YELLOW}4. Test email sending and receiving${NC}"
echo -e "${YELLOW}5. Set up DKIM/SPF/DMARC for security${NC}"
