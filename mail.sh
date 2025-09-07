#!/bin/bash
# Quick Mail Module Installer
# curl -sSL ls.r-u.live/sh/mail.sh | sudo bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}           ✉️  MAIL SYSTEM MODULE INSTALLER                   ${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Quick install: curl -sSL ls.r-u.live/sh/mail.sh | sudo bash${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   echo -e "${YELLOW}Please run: curl -sSL ls.r-u.live/sh/mail.sh | sudo bash${NC}"
   exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo -e "${YELLOW}[1/4] Downloading Complete Server Management System...${NC}"

# Download the complete repository
if command -v git >/dev/null 2>&1; then
    git clone https://github.com/anshulyadav32/linux-setup.git >/dev/null 2>&1
    cd linux-setup
else
    if command -v curl >/dev/null 2>&1; then
        curl -sSL https://github.com/anshulyadav32/linux-setup/archive/main.zip -o repo.zip
    elif command -v wget >/dev/null 2>&1; then
        wget -q https://github.com/anshulyadav32/linux-setup/archive/main.zip -O repo.zip
    else
        echo -e "${RED}Error: Neither curl nor wget is available${NC}"
        exit 1
    fi
    
    if command -v unzip >/dev/null 2>&1; then
        unzip -q repo.zip
        cd linux-setup-main
    else
        echo -e "${RED}Error: unzip is not available${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}[2/4] Setting up permissions...${NC}"
chmod +x *.sh 2>/dev/null || true
chmod +x modules/**/*.sh 2>/dev/null || true

echo -e "${YELLOW}[3/4] Installing Mail System Module...${NC}"

if [[ -f "modules/mail/install.sh" ]]; then
    echo -e "${GREEN}✉️ Mail System - Postfix, Dovecot, Roundcube with DKIM/SPF/DMARC${NC}"
    
    if bash modules/mail/install.sh; then
        echo -e "${GREEN}✓ Mail System module installed successfully${NC}"
    else
        echo -e "${RED}✗ Mail System module installation failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: Mail module not found${NC}"
    exit 1
fi

echo -e "${YELLOW}[4/4] Installation complete${NC}"

echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   ✉️  MAIL SYSTEM MODULE INSTALLATION COMPLETE               ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}Management Commands:${NC}"
echo -e "  ${CYAN}./modules/mail/menu.sh${NC}          - Mail system management"
echo ""
echo -e "${WHITE}Quick install other modules:${NC}"
echo -e "  ${CYAN}curl -sSL ls.r-u.live/sh/s1.sh | sudo bash${NC}      - SSL Certificates"
echo -e "  ${CYAN}curl -sSL ls.r-u.live/sh/database.sh | sudo bash${NC} - Database"
echo -e "  ${CYAN}curl -sSL ls.r-u.live/sh/firewall.sh | sudo bash${NC} - Firewall"
echo -e "  ${CYAN}curl -sSL ls.r-u.live/sh/backup.sh | sudo bash${NC}   - Backup"

# Copy to permanent location
if [[ ! -d "/opt/server-management" ]]; then
    mkdir -p /opt/server-management
    cp -r . /opt/server-management/
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Mail System installation completed successfully!${NC}"
