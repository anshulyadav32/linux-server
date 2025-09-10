#!/bin/bash
# Mail System Updater
# Purpose: Update mail server packages and apply security patches

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
echo -e "${BLUE}       MAIL SYSTEM UPDATER             ${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

# Backup configurations before update
echo -e "\n${YELLOW}[1/6] Creating configuration backup...${NC}"
backup_mail_configs

# Update system packages
echo -e "\n${YELLOW}[2/6] Updating system packages...${NC}"
apt update && apt upgrade -y

# Update mail-specific packages
echo -e "\n${YELLOW}[3/6] Updating mail server packages...${NC}"
echo -e "${BLUE}Updating Postfix...${NC}"
apt install --only-upgrade -y postfix postfix-pcre

echo -e "${BLUE}Updating Dovecot...${NC}"
apt install --only-upgrade -y dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-sieve dovecot-managesieved

echo -e "${BLUE}Updating Roundcube...${NC}"
apt install --only-upgrade -y roundcube roundcube-core roundcube-mysql roundcube-plugins

echo -e "${BLUE}Updating security tools...${NC}"
apt install --only-upgrade -y spamassassin spamc clamav clamav-daemon opendkim opendkim-tools opendmarc

# Update ClamAV signatures
echo -e "\n${YELLOW}[4/6] Updating antivirus signatures...${NC}"
freshclam

# Restart services to apply updates
echo -e "\n${YELLOW}[5/6] Restarting mail services...${NC}"
restart_mail_services

# Verify services after update
echo -e "\n${YELLOW}[6/6] Verifying services after update...${NC}"

echo -e "${BLUE}Checking service status:${NC}"
check_all_mail_services

echo -e "\n${BLUE}Checking mail ports:${NC}"
check_mail_ports

echo -e "\n${BLUE}Testing mail queue:${NC}"
get_mail_queue_status

# Test mail functionality
read -p "Enter email address to test mail delivery (or press Enter to skip): " test_email
if [[ -n "$test_email" ]]; then
    test_mail_delivery "$test_email"
fi

echo -e "\n${BLUE}Recent mail logs:${NC}"
view_mail_logs | tail -10

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}     MAIL SYSTEM UPDATE COMPLETE       ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All mail services updated and verified${NC}"
echo -e "${GREEN}Configuration backup created${NC}"
echo -e "${GREEN}Antivirus signatures updated${NC}"
