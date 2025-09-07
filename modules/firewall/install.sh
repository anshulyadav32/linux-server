#!/bin/bash
# Firewall System Installation
# Purpose: Automated setup of firewall and security infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Source functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}      FIREWALL SYSTEM INSTALLATION     ${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting firewall and security system installation...${NC}"
echo

# Step 1: System Update
echo -e "${BLUE}Step 1/7: Updating system packages...${NC}"
update_system_packages
echo -e "${GREEN}✓ System packages updated${NC}"
echo

# Step 2: Install firewall and security tools
echo -e "${BLUE}Step 2/7: Installing firewall and security tools...${NC}"
install_firewall_tools
echo -e "${GREEN}✓ Firewall tools installed${NC}"
echo

# Step 3: Configure UFW firewall
echo -e "${BLUE}Step 3/7: Configuring UFW firewall...${NC}"
enable_ufw
echo -e "${GREEN}✓ UFW firewall configured${NC}"
echo

# Step 4: Setup fail2ban intrusion prevention
echo -e "${BLUE}Step 4/7: Setting up fail2ban...${NC}"
setup_fail2ban
echo -e "${GREEN}✓ fail2ban configured${NC}"
echo

# Step 5: Configure additional security rules
echo -e "${BLUE}Step 5/7: Configuring security rules...${NC}"

# Ask user for additional ports to open
echo -e "${CYAN}Would you like to configure additional ports? (y/N):${NC}"
read -r configure_ports

if [[ "$configure_ports" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Common services:${NC}"
    echo -e "1) Mail server (SMTP: 25, IMAP: 993, POP3: 995)"
    echo -e "2) Database (MySQL: 3306, PostgreSQL: 5432, MongoDB: 27017)"
    echo -e "3) FTP (21, 22)"
    echo -e "4) Custom ports"
    echo -e "5) Skip additional configuration"
    echo
    
    read -p "Select option [1-5]: " port_choice
    
    case $port_choice in
        1)
            echo -e "${YELLOW}Configuring mail server ports...${NC}"
            add_firewall_rule 25 tcp "SMTP"
            add_firewall_rule 587 tcp "SMTP Submission"
            add_firewall_rule 993 tcp "IMAP SSL"
            add_firewall_rule 995 tcp "POP3 SSL"
            echo -e "${GREEN}✓ Mail server ports configured${NC}"
            ;;
        2)
            echo -e "${YELLOW}Configuring database ports...${NC}"
            echo -e "${CYAN}Which databases? (mysql/postgresql/mongodb/all):${NC}"
            read -r db_choice
            case $db_choice in
                mysql)
                    add_firewall_rule 3306 tcp "MySQL/MariaDB"
                    ;;
                postgresql)
                    add_firewall_rule 5432 tcp "PostgreSQL"
                    ;;
                mongodb)
                    add_firewall_rule 27017 tcp "MongoDB"
                    ;;
                all)
                    add_firewall_rule 3306 tcp "MySQL/MariaDB"
                    add_firewall_rule 5432 tcp "PostgreSQL"
                    add_firewall_rule 27017 tcp "MongoDB"
                    ;;
            esac
            echo -e "${GREEN}✓ Database ports configured${NC}"
            ;;
        3)
            echo -e "${YELLOW}Configuring FTP ports...${NC}"
            add_firewall_rule 21 tcp "FTP"
            add_firewall_rule 22 tcp "SFTP"
            echo -e "${GREEN}✓ FTP ports configured${NC}"
            ;;
        4)
            echo -e "${CYAN}Enter custom port (format: port/protocol):${NC}"
            read -r custom_port
            echo -e "${CYAN}Enter description:${NC}"
            read -r description
            
            if [[ -n "$custom_port" ]]; then
                # Parse port and protocol
                port=$(echo "$custom_port" | cut -d'/' -f1)
                protocol=$(echo "$custom_port" | cut -d'/' -f2)
                [[ -z "$protocol" ]] && protocol="tcp"
                
                add_firewall_rule "$port" "$protocol" "$description"
                echo -e "${GREEN}✓ Custom port $custom_port configured${NC}"
            fi
            ;;
        5)
            echo -e "${YELLOW}Skipping additional port configuration${NC}"
            ;;
    esac
fi

echo -e "${GREEN}✓ Security rules configured${NC}"
echo

# Step 6: Start and enable services
echo -e "${BLUE}Step 6/7: Starting security services...${NC}"
start_firewall_services
echo -e "${GREEN}✓ Security services started${NC}"
echo

# Step 7: Verify installation and show status
echo -e "${BLUE}Step 7/7: Verifying installation...${NC}"

# Check firewall status
check_firewall_status

# Test basic connectivity
echo -e "${CYAN}Testing basic connectivity...${NC}"
test_port localhost 22 && echo -e "${GREEN}✓ SSH access verified${NC}" || echo -e "${RED}✗ SSH access issue${NC}"

if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet apache2 || systemctl is-active --quiet nginx; then
        test_port localhost 80 && echo -e "${GREEN}✓ HTTP access verified${NC}" || echo -e "${YELLOW}! HTTP not accessible (normal if no web server)${NC}"
        test_port localhost 443 && echo -e "${GREEN}✓ HTTPS access verified${NC}" || echo -e "${YELLOW}! HTTPS not accessible (normal if no SSL)${NC}"
    fi
fi

echo -e "${GREEN}✓ Installation verification completed${NC}"
echo

# Installation summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}      INSTALLATION COMPLETED           ${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo -e "${GREEN}Firewall system installed successfully!${NC}"
echo

echo -e "${CYAN}Security Summary:${NC}"
get_security_summary

echo -e "${CYAN}Firewall Configuration:${NC}"
if command -v ufw >/dev/null 2>&1; then
    ufw status numbered
fi

echo
echo -e "${YELLOW}Important Security Notes:${NC}"
echo -e "1. SSH access is allowed - ensure strong passwords/keys"
echo -e "2. fail2ban is protecting against brute force attacks"
echo -e "3. Default policy denies all incoming connections except allowed ports"
echo -e "4. Monitor logs regularly: /var/log/ufw.log and /var/log/fail2ban.log"
echo -e "5. Use 'ufw status' to check current firewall rules"
echo

echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Configure SSH key authentication (disable password auth)"
echo -e "2. Review and customize fail2ban jail configurations"
echo -e "3. Set up log monitoring and alerting"
echo -e "4. Regular security updates and rule reviews"
echo

echo -e "${GREEN}Firewall installation completed successfully!${NC}"
echo -e "${CYAN}Your server is now protected with a basic security configuration.${NC}"
