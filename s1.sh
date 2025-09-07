#!/bin/bash
# Quick SSL Module Installer
# curl -sSL ls.r-u.live/s1.sh | sudo bash

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
echo -e "${WHITE}           🔐 SSL CERTIFICATE MODULE INSTALLER               ${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Quick install: curl -sSL ls.r-u.live/s1.sh | sudo bash${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   echo -e "${YELLOW}Please run: curl -sSL ls.r-u.live/s1.sh | sudo bash${NC}"
   exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo -e "${YELLOW}[1/4] Downloading Complete Server Management System...${NC}"

# Download the complete repository
if command -v git >/dev/null 2>&1; then
    echo -e "${CYAN}Using git to clone repository...${NC}"
    git clone https://github.com/anshulyadav32/linux-setup.git >/dev/null 2>&1
    cd linux-setup
else
    echo -e "${CYAN}Downloading repository archive...${NC}"
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
chmod +x *.sh
chmod +x modules/**/*.sh 2>/dev/null || true

echo -e "${YELLOW}[3/4] Installing SSL Certificate Module...${NC}"

# Check if SSL module exists
if [[ -f "modules/ssl/install.sh" ]]; then
    echo -e "${GREEN}🔐 SSL Certificates - Let's Encrypt automation with multi-domain support${NC}"
    
    # Run SSL module installer
    if bash modules/ssl/install.sh; then
        echo -e "${GREEN}✓ SSL Certificate module installed successfully${NC}"
    else
        echo -e "${RED}✗ SSL Certificate module installation failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: SSL module not found${NC}"
    exit 1
fi

echo -e "${YELLOW}[4/4] Installation complete${NC}"

echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   🔐 SSL CERTIFICATE MODULE INSTALLATION COMPLETE           ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}Available Management Commands:${NC}"
echo -e "  ${CYAN}./modules/ssl/menu.sh${NC}           - SSL Certificate management"
echo -e "  ${CYAN}./master.sh${NC}                    - Main management interface"
echo ""
echo -e "${WHITE}Complete System Installation:${NC}"
echo -e "  ${CYAN}./install.sh${NC}                   - Install all 5 modules"
echo ""
echo -e "${WHITE}Individual Module Installation:${NC}"
echo -e "  ${CYAN}./modules/mail/install.sh${NC}       - Mail system"
echo -e "  ${CYAN}./modules/database/install.sh${NC}   - Database systems"
echo -e "  ${CYAN}./modules/firewall/install.sh${NC}   - Firewall & Security"
echo -e "  ${CYAN}./modules/backup/install.sh${NC}     - Backup system"
echo ""
echo -e "${BLUE}Quick reinstall: curl -sSL ls.r-u.live/s1.sh | sudo bash${NC}"
echo -e "${GREEN}Thank you for using the SSL Certificate Module!${NC}"

# Copy files to a permanent location (optional)
echo -e "${YELLOW}Copying files to /opt/server-management for permanent access...${NC}"
if [[ ! -d "/opt/server-management" ]]; then
    mkdir -p /opt/server-management
    cp -r . /opt/server-management/
    echo -e "${GREEN}Files copied to /opt/server-management${NC}"
    echo -e "${CYAN}You can access the system from: cd /opt/server-management${NC}"
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Installation completed successfully!${NC}"
