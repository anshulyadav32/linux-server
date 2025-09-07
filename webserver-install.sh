#!/bin/bash
# =============================================================================
# Quick Webserver Module Installer
# =============================================================================
# Usage: curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-setup/main/webserver-install.sh | sudo bash
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}         🌐 WEBSERVER MODULE DIRECT INSTALLER                 ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}" 
   echo -e "${YELLOW}Please run: curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-setup/main/webserver-install.sh | sudo bash${NC}"
   exit 1
fi

echo -e "${YELLOW}[1/4] Creating temporary directory...${NC}"
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo -e "${YELLOW}[2/4] Downloading Linux Setup repository...${NC}"
if command -v git >/dev/null 2>&1; then
    git clone https://github.com/anshulyadav32/linux-setup.git >/dev/null 2>&1
    cd linux-setup
else
    echo -e "${RED}❌ Git not found. Installing git...${NC}"
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq && apt-get install -y git >/dev/null 2>&1
    elif command -v yum >/dev/null 2>&1; then
        yum install -y git >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y git >/dev/null 2>&1
    else
        echo -e "${RED}❌ Unable to install git. Please install manually.${NC}"
        exit 1
    fi
    git clone https://github.com/anshulyadav32/linux-setup.git >/dev/null 2>&1
    cd linux-setup
fi

echo -e "${YELLOW}[3/4] Installing webserver module...${NC}"
if [[ -f "modules/webserver/install.sh" ]]; then
    chmod +x modules/webserver/install.sh
    chmod +x modules/common.sh 2>/dev/null || true
    
    echo ""
    echo -e "${CYAN}🚀 Starting webserver installation...${NC}"
    echo ""
    
    if bash modules/webserver/install.sh; then
        echo ""
        echo -e "${GREEN}✅ Webserver module installed successfully!${NC}"
    else
        echo ""
        echo -e "${RED}❌ Webserver module installation failed!${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Webserver module not found!${NC}"
    exit 1
fi

echo -e "${YELLOW}[4/4] Setting up system integration...${NC}"
# Copy to system directory
INSTALL_DIR="/opt/linux-setup"
mkdir -p "$INSTALL_DIR"
cp -r . "$INSTALL_DIR/"
find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Create symlink for easy access
ln -sf "$INSTALL_DIR/modules/webserver/menu.sh" "/usr/local/bin/webserver-menu" 2>/dev/null || true

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 WEBSERVER MODULE INSTALLATION COMPLETED!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}🚀 Management Commands:${NC}"
echo "  • Interactive menu: webserver-menu"
echo "  • Direct access: /opt/linux-setup/modules/webserver/menu.sh"
echo "  • Full system: /opt/linux-setup/master.sh"
echo ""
echo -e "${CYAN}🌐 Webserver Features Installed:${NC}"
echo "  • Apache HTTP Server"
echo "  • Nginx Reverse Proxy"
echo "  • PHP 8.x with Extensions"
echo "  • SSL/TLS Certificate Support"
echo "  • Virtual Host Management"
echo "  • Security Hardening"
echo "  • Performance Optimization"
echo ""
echo -e "${YELLOW}📚 Documentation: https://github.com/anshulyadav32/linux-setup${NC}"
echo ""

# Cleanup
cd /
rm -rf "$TEMP_DIR" 2>/dev/null || true

echo -e "${GREEN}Installation completed! Run 'webserver-menu' to start managing your web server.${NC}"
