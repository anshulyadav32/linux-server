#!/bin/bash
# Mail System Installer
# Purpose: Complete mail server setup with Postfix, Dovecot, Roundcube, and security

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

# Configure basic settings
echo -e "\n${YELLOW}[7/8] Basic configuration...${NC}"

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
    
    echo -e "${GREEN}Basic Postfix configuration completed${NC}"
    
    # Restart Postfix to apply changes
    systemctl restart postfix
fi

# Test installation
echo -e "\n${YELLOW}[8/8] Testing mail server installation...${NC}"

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
echo -e "${GREEN}Webmail: http://your-server/roundcube${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${YELLOW}1. Configure DNS records (MX, A, SPF, DKIM)${NC}"
echo -e "${YELLOW}2. Set up SSL certificates${NC}"
echo -e "${YELLOW}3. Configure user accounts${NC}"
echo -e "${YELLOW}4. Test email sending and receiving${NC}"
