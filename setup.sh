#!/bin/bash
# Quick Setup Script for Modular Server Management System
# This script initializes all modules and prepares the system

# Set variables
BASE_DIR="$(dirname "$0")"
MODULES_DIR="$BASE_DIR/modules"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root!"
        log_info "Run as a regular user with sudo privileges."
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        log_error "Unable to detect Linux distribution"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]] && [[ "$ID" != "debian" ]]; then
        log_warn "This system is designed for Ubuntu/Debian"
        log_info "Detected: $PRETTY_NAME"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check sudo
    if ! sudo -n true 2>/dev/null; then
        log_error "User must have sudo privileges"
        exit 1
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "No internet connectivity detected"
        exit 1
    fi
    
    log_ok "System requirements check passed"
}

# Create directory structure
create_structure() {
    log_info "Creating modular directory structure..."
    
    # Make all scripts executable
    find "$BASE_DIR" -name "*.sh" -exec chmod +x {} \;
    
    # Create logs directory
    mkdir -p "$BASE_DIR/logs"
    
    # Create backups directory
    mkdir -p "$BASE_DIR/backups"
    
    # Create configs directory
    mkdir -p "$BASE_DIR/configs"
    
    log_ok "Directory structure created"
}

# Initialize system packages
init_system() {
    log_info "Initializing system packages..."
    
    # Update package lists
    sudo apt update &> /dev/null
    
    # Install essential packages
    local packages=(
        "curl"
        "wget"
        "git"
        "htop"
        "tree"
        "unzip"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$package "; then
            log_info "Installing $package..."
            sudo apt install -y "$package" &> /dev/null
        fi
    done
    
    log_ok "Essential packages installed"
}

# Test module functionality
test_modules() {
    log_info "Testing module functionality..."
    
    # Test common.sh functions
    if source "$MODULES_DIR/common.sh" 2>/dev/null; then
        log_ok "Common library loaded successfully"
    else
        log_error "Failed to load common library"
        exit 1
    fi
    
    # Test each module's functions.sh
    local modules=("web" "dns" "mail" "db" "firewall" "ssl" "system" "backup")
    
    for module in "${modules[@]}"; do
        if [[ -f "$MODULES_DIR/$module/functions.sh" ]]; then
            if source "$MODULES_DIR/$module/functions.sh" 2>/dev/null; then
                log_ok "$module module functions loaded"
            else
                log_warn "$module module functions failed to load"
            fi
        else
            log_warn "$module module functions.sh not found"
        fi
    done
}

# Display system information
show_system_info() {
    log_info "System Information:"
    echo "  OS: $(lsb_release -ds 2>/dev/null || cat /etc/issue | head -1)"
    echo "  Kernel: $(uname -r)"
    echo "  Architecture: $(uname -m)"
    echo "  CPU: $(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs)"
    echo "  Memory: $(free -h | grep Mem | awk '{print $2}')"
    echo "  Disk: $(df -h / | tail -1 | awk '{print $2}' | xargs)"
    echo "  IP: $(curl -s ifconfig.me 2>/dev/null || echo "Unable to detect")"
    echo ""
}

# Create quick-start guide
create_quick_start() {
    log_info "Creating quick-start guide..."
    
    cat > "$BASE_DIR/QUICK_START.md" << 'EOF'
# Modular Server Management System - Quick Start

## Getting Started

1. **Run the main menu:**
   ```bash
   ./master.sh
   ```

2. **Individual module access:**
   ```bash
   ./modules/web/menu.sh      # Web server management
   ./modules/dns/menu.sh      # DNS server management
   ./modules/mail/menu.sh     # Mail server management
   ./modules/db/menu.sh       # Database management
   ./modules/firewall/menu.sh # Firewall management
   ./modules/ssl/menu.sh      # SSL certificate management
   ./modules/system/menu.sh   # System administration
   ./modules/backup/menu.sh   # Backup management
   ```

3. **Automated workflows:**
   ```bash
   ./modules/interdependent.sh
   ```

## Common Tasks

### Setup LAMP Stack
1. Run `./master.sh`
2. Choose "Interdependent Automation"
3. Select "Full LAMP Stack Setup"

### Setup Mail Server
1. Run `./master.sh`
2. Choose "Interdependent Automation"
3. Select "Complete Mail Server Setup"

### Deploy Website with SSL
1. Run `./master.sh`
2. Choose "Interdependent Automation"
3. Select "Full Website Deploy"

## Module Overview

- **Web**: Apache/Nginx, PHP, Node.js, website management
- **DNS**: BIND9, zones, records, DNS testing
- **Mail**: Postfix, Dovecot, DKIM, user management
- **Database**: MySQL, PostgreSQL, database operations
- **Firewall**: UFW, Fail2Ban, security rules
- **SSL**: Let's Encrypt, certificate management
- **System**: Users, packages, monitoring, maintenance
- **Backup**: Automated backups, restore operations

## Support

- Check logs in `./logs/` directory
- Use the diagnostic tools in each module
- Review module documentation in respective directories

EOF

    log_ok "Quick-start guide created: $BASE_DIR/QUICK_START.md"
}

# Main setup function
main() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               Modular Server Management System               ║${NC}"
    echo -e "${CYAN}║                        Setup Script                         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log_info "Initializing Modular Server Management System..."
    echo ""
    
    # Run setup steps
    check_root
    check_requirements
    show_system_info
    create_structure
    init_system
    test_modules
    create_quick_start
    
    echo ""
    log_ok "Setup completed successfully!"
    echo ""
    echo -e "${WHITE}Next Steps:${NC}"
    echo "1. Review the quick-start guide: cat QUICK_START.md"
    echo "2. Run the main menu: ./master.sh"
    echo "3. Choose modules to install and configure"
    echo ""
    echo -e "${CYAN}Happy server management!${NC}"
}

# Run main function
main "$@"
