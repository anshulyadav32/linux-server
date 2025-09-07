#!/bin/bash
# Quick Backup Module Installer
# curl -sSL ls.r-u.live/sh/backup.sh | sudo bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}           💾 BACKUP SYSTEM MODULE INSTALLER                 ${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Quick install: curl -sSL ls.r-u.live/sh/backup.sh | sudo bash${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo -e "${YELLOW}[1/4] Downloading repository...${NC}"

if command -v git >/dev/null 2>&1; then
    git clone https://github.com/anshulyadav32/linux-setup.git >/dev/null 2>&1
    cd linux-setup
else
    curl -sSL https://github.com/anshulyadav32/linux-setup/archive/main.zip -o repo.zip
    unzip -q repo.zip
    cd linux-setup-main
fi

echo -e "${YELLOW}[2/4] Setting permissions...${NC}"
chmod +x *.sh 2>/dev/null || true
chmod +x modules/**/*.sh 2>/dev/null || true

echo -e "${YELLOW}[3/4] Installing Backup System Module...${NC}"
echo -e "${GREEN}💾 Backup System - Automated backups with encryption and remote sync${NC}"

if bash modules/backup/install.sh; then
    echo -e "${GREEN}✓ Backup System module installed successfully${NC}"
else
    echo -e "${RED}✗ Backup System module installation failed${NC}"
    exit 1
fi

echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   💾 BACKUP SYSTEM MODULE INSTALLATION COMPLETE             ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"

if [[ ! -d "/opt/server-management" ]]; then
    mkdir -p /opt/server-management
    cp -r . /opt/server-management/
fi

cd /
rm -rf "$TEMP_DIR"
echo -e "${GREEN}Backup System installation completed!${NC}"
