#!/bin/bash
# =============================================================================
# Linux Setup - Quick Module Installer
# =============================================================================
# Author: Anshul Yadav
# Description: Quick installer script for individual modules
# Usage: curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-setup/main/s1.sh | sudo bash -s [module_name]
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ==========================================
# HELPER FUNCTIONS
# ==========================================

print_header() {
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}           � LINUX SETUP - MODULE INSTALLER                ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Quick install: curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-setup/main/s1.sh | sudo bash -s [module]${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

print_usage() {
    echo ""
    echo -e "${YELLOW}📋 Available modules:${NC}"
    echo "  ssl         - 🔐 SSL Certificate Management"
    echo "  mail        - ✉️  Mail Server (Postfix, Dovecot, Roundcube)"
    echo "  database    - 🗄️  Database Systems (PostgreSQL, MariaDB, MongoDB)"
    echo "  firewall    - 🔒 Firewall & Security (UFW, Fail2Ban, ClamAV)"
    echo "  backup      - 💾 Backup System"
    echo "  webserver   - 🌐 Web Server (Apache, Nginx, PHP)"
    echo ""
    echo -e "${YELLOW}📝 Usage examples:${NC}"
    echo "  curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-setup/main/s1.sh | sudo bash -s ssl"
    echo "  curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-setup/main/s1.sh | sudo bash -s webserver"
    echo "  curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-setup/main/s1.sh | sudo bash -s mail"
    echo ""
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root${NC}" 
        echo -e "${YELLOW}Please run: curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-setup/main/s1.sh | sudo bash -s [module]${NC}"
        exit 1
    fi
}

install_dependencies() {
    echo -e "${YELLOW}[1/5] Installing dependencies...${NC}"
    
    # Detect OS and install git
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq >/dev/null 2>&1
        apt-get install -y git curl wget >/dev/null 2>&1
    elif command -v yum >/dev/null 2>&1; then
        yum install -y git curl wget >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y git curl wget >/dev/null 2>&1
    else
        echo -e "${RED}❌ Unsupported package manager${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Dependencies installed${NC}"
}

download_repository() {
    echo -e "${YELLOW}[2/5] Downloading Linux Setup repository...${NC}"
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Clone repository
    if git clone https://github.com/anshulyadav32/linux-setup.git >/dev/null 2>&1; then
        cd linux-setup
        echo -e "${GREEN}✓ Repository downloaded${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to download repository${NC}"
        exit 1
    fi
}

install_module() {
    local module="$1"
    
    echo -e "${YELLOW}[3/5] Validating module: $module${NC}"
    
    # Validate module
    case "$module" in
        ssl|mail|database|firewall|backup|webserver)
            echo -e "${GREEN}✓ Module '$module' is valid${NC}"
            ;;
        *)
            echo -e "${RED}❌ Unknown module: $module${NC}"
            print_usage
            exit 1
            ;;
    esac
    
    # Check if module exists
    if [[ ! -d "modules/$module" ]]; then
        echo -e "${RED}❌ Module directory not found: modules/$module${NC}"
        exit 1
    fi
    
    if [[ ! -f "modules/$module/install.sh" ]]; then
        echo -e "${RED}❌ Module install script not found: modules/$module/install.sh${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}[4/5] Installing $module module...${NC}"
    echo ""
    
    # Make scripts executable
    chmod +x modules/$module/*.sh >/dev/null 2>&1 || true
    chmod +x modules/common.sh >/dev/null 2>&1 || true
    
    # Run module installation
    if bash "modules/$module/install.sh"; then
        echo ""
        echo -e "${GREEN}✅ $module module installation completed successfully!${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ $module module installation failed!${NC}"
        return 1
    fi
}

copy_to_system() {
    local module="$1"
    
    echo -e "${YELLOW}[5/5] Setting up system integration...${NC}"
    
    # Create system directory
    INSTALL_DIR="/opt/linux-setup"
    mkdir -p "$INSTALL_DIR"
    
    # Copy the entire repository
    cp -r . "$INSTALL_DIR/"
    
    # Make all scripts executable
    find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \; >/dev/null 2>&1 || true
    
    # Create symlinks for easy access
    ln -sf "$INSTALL_DIR/modules/$module/menu.sh" "/usr/local/bin/${module}-menu" >/dev/null 2>&1 || true
    
    echo -e "${GREEN}✓ System integration completed${NC}"
    echo ""
    echo -e "${CYAN}💡 Module management:${NC}"
    echo "  • Run module menu: ${module}-menu"
    echo "  • Full menu system: $INSTALL_DIR/master.sh"
    echo "  • Module directory: $INSTALL_DIR/modules/$module/"
    echo ""
}

cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up temporary files...${NC}"
    cd /
    rm -rf "$TEMP_DIR" >/dev/null 2>&1 || true
    echo -e "${GREEN}✓ Cleanup completed${NC}"
}

# ==========================================
# MAIN EXECUTION
# ==========================================

main() {
    print_header
    
    # Check root privileges
    check_root
    
    # Get module parameter
    local module="$1"
    
    # If no module specified, default to SSL for backward compatibility
    if [[ -z "$module" ]]; then
        echo -e "${YELLOW}⚠️  No module specified, defaulting to SSL module${NC}"
        module="ssl"
    fi
    
    # Convert to lowercase
    module=$(echo "$module" | tr '[:upper:]' '[:lower:]')
    
    # Show help if requested
    if [[ "$module" == "help" || "$module" == "-h" || "$module" == "--help" ]]; then
        print_usage
        exit 0
    fi
    
    echo -e "${CYAN}🎯 Installing module: $module${NC}"
    echo ""
    
    # Execute installation steps
    install_dependencies
    download_repository
    install_module "$module"
    copy_to_system "$module"
    cleanup
    
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}🎉 $module MODULE INSTALLATION COMPLETED!${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo "  1. Run module menu: ${module}-menu"
    echo "  2. Configure settings: /opt/linux-setup/modules/$module/menu.sh"
    echo "  3. Check status: systemctl status ${module}* --no-pager"
    echo ""
    echo -e "${YELLOW}📚 Documentation: https://github.com/anshulyadav32/linux-setup${NC}"
    echo ""
}

# Execute main function with all arguments
main "$@"
}

copy_to_system() {
    local module="$1"
    
    echo -e "${YELLOW}[5/5] Setting up system integration...${NC}"
    
    # Create system directory
    INSTALL_DIR="/opt/linux-setup"
    mkdir -p "$INSTALL_DIR"
    
    # Copy the entire repository
    cp -r . "$INSTALL_DIR/"
    
    # Make all scripts executable
    find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \; >/dev/null 2>&1 || true
    
    # Create symlinks for easy access
    ln -sf "$INSTALL_DIR/modules/$module/menu.sh" "/usr/local/bin/${module}-menu" >/dev/null 2>&1 || true
    
    echo -e "${GREEN}✓ System integration completed${NC}"
    echo ""
    echo -e "${CYAN}💡 Module management:${NC}"
    echo "  • Run module menu: ${module}-menu"
    echo "  • Full menu system: $INSTALL_DIR/master.sh"
    echo "  • Module directory: $INSTALL_DIR/modules/$module/"
    echo ""
}

cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up temporary files...${NC}"
    cd /
    rm -rf "$TEMP_DIR" >/dev/null 2>&1 || true
    echo -e "${GREEN}✓ Cleanup completed${NC}"
}

# ==========================================
# MAIN EXECUTION
# ==========================================

main() {
    print_header
    
    # Check root privileges
    check_root
    
    # Get module parameter
    local module="$1"
    
    # If no module specified, default to SSL for backward compatibility
    if [[ -z "$module" ]]; then
        echo -e "${YELLOW}⚠️  No module specified, defaulting to SSL module${NC}"
        module="ssl"
    fi
    
    # Convert to lowercase
    module=$(echo "$module" | tr '[:upper:]' '[:lower:]')
    
    # Show help if requested
    if [[ "$module" == "help" || "$module" == "-h" || "$module" == "--help" ]]; then
        print_usage
        exit 0
    fi
    
    echo -e "${CYAN}🎯 Installing module: $module${NC}"
    echo ""
    
    # Execute installation steps
    install_dependencies
    download_repository
    install_module "$module"
    copy_to_system "$module"
    cleanup
    
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}🎉 $module MODULE INSTALLATION COMPLETED!${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo "  1. Run module menu: ${module}-menu"
    echo "  2. Configure settings: /opt/linux-setup/modules/$module/menu.sh"
    echo "  3. Check status: systemctl status ${module}* --no-pager"
    echo ""
    echo -e "${YELLOW}📚 Documentation: https://github.com/anshulyadav32/linux-setup${NC}"
    echo ""
}

# Execute main function with all arguments
main "$@"
    
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
echo -e "${BLUE}Quick reinstall: curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-setup/main/s1.sh | sudo bash${NC}"
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
