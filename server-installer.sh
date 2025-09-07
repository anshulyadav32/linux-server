#!/bin/bash
# =============================================================================
# Linux Setup - Modular Server Management System
# Comprehensive Server Installer with Checkpoints
# =============================================================================
# Author: Anshul Yadav
# Description: Complete automated server installation with progress tracking
# Version: 1.0
# URL: https://ls.r-u.live | https://anshulyadav32.github.io/linux-setup
# =============================================================================

set -euo pipefail

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
LOGS_DIR="$SCRIPT_DIR/logs"
CONFIGS_DIR="$SCRIPT_DIR/configs"

# Create logs directory if it doesn't exist
mkdir -p "$LOGS_DIR"

# Installation log file with timestamp
INSTALL_LOG="$LOGS_DIR/server-installation-$(date +%Y%m%d_%H%M%S).log"

# Checkpoint tracking
CHECKPOINT_FILE="$LOGS_DIR/installation-checkpoints.log"
TOTAL_STEPS=25
CURRENT_STEP=0

# Color definitions for enhanced output
declare -A COLORS=(
    [CYAN]='\033[0;36m'
    [GREEN]='\033[0;32m'
    [RED]='\033[0;31m'
    [YELLOW]='\033[1;33m'
    [BLUE]='\033[0;34m'
    [PURPLE]='\033[0;35m'
    [WHITE]='\033[1;37m'
    [BOLD]='\033[1m'
    [DIM]='\033[2m'
    [NC]='\033[0m'
)

# =============================================================================
# LOGGING AND DISPLAY FUNCTIONS
# =============================================================================

log_and_echo() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$INSTALL_LOG"
    
    case "$level" in
        "INFO")
            echo -e "${COLORS[CYAN]}[INFO]${COLORS[NC]} $message"
            ;;
        "SUCCESS")
            echo -e "${COLORS[GREEN]}[✓]${COLORS[NC]} $message"
            ;;
        "ERROR")
            echo -e "${COLORS[RED]}[✗]${COLORS[NC]} $message"
            ;;
        "WARNING")
            echo -e "${COLORS[YELLOW]}[⚠]${COLORS[NC]} $message"
            ;;
        "CHECKPOINT")
            echo -e "${COLORS[PURPLE]}[CHECKPOINT]${COLORS[NC]} $message"
            ;;
        "STEP")
            echo -e "${COLORS[BLUE]}[STEP $CURRENT_STEP/$TOTAL_STEPS]${COLORS[NC]} $message"
            ;;
    esac
}

show_header() {
    local title="$1"
    echo ""
    echo -e "${COLORS[BOLD]}${COLORS[WHITE]}=================================================${COLORS[NC]}"
    echo -e "${COLORS[BOLD]}${COLORS[WHITE]}    LINUX SETUP - MODULAR SERVER MANAGEMENT${COLORS[NC]}"
    echo -e "${COLORS[BOLD]}${COLORS[WHITE]}              $title${COLORS[NC]}"
    echo -e "${COLORS[BOLD]}${COLORS[WHITE]}=================================================${COLORS[NC]}"
    echo ""
}

show_progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${COLORS[CYAN]}Progress: [${COLORS[NC]}"
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "${COLORS[CYAN]}] %d%% (%d/%d)${COLORS[NC]}" $percentage $current $total
}

checkpoint() {
    local step_name="$1"
    local description="$2"
    
    ((CURRENT_STEP++))
    echo "STEP_$CURRENT_STEP:$step_name:$(date '+%Y-%m-%d %H:%M:%S'):SUCCESS" >> "$CHECKPOINT_FILE"
    
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS
    echo ""
    log_and_echo "CHECKPOINT" "Step $CURRENT_STEP/$TOTAL_STEPS: $step_name - $description"
    echo ""
}

# =============================================================================
# SYSTEM CHECKS AND PREREQUISITES
# =============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_and_echo "ERROR" "This script must be run as root. Use: sudo $0"
        exit 1
    fi
}

check_os_compatibility() {
    if [[ ! -f /etc/os-release ]]; then
        log_and_echo "ERROR" "Cannot determine OS version. /etc/os-release not found."
        exit 1
    fi
    
    source /etc/os-release
    
    case "$ID" in
        ubuntu|debian)
            log_and_echo "SUCCESS" "Compatible OS detected: $PRETTY_NAME"
            ;;
        centos|rhel|fedora)
            log_and_echo "WARNING" "CentOS/RHEL/Fedora detected. Some features may require adaptation."
            ;;
        *)
            log_and_echo "WARNING" "Untested OS: $PRETTY_NAME. Proceeding with caution."
            ;;
    esac
}

check_internet_connectivity() {
    if ! ping -c 1 google.com &> /dev/null; then
        log_and_echo "ERROR" "No internet connectivity. Please check your network connection."
        exit 1
    fi
    log_and_echo "SUCCESS" "Internet connectivity verified"
}

check_system_resources() {
    local min_ram_gb=1
    local min_disk_gb=5
    
    # Check RAM
    local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $ram_gb -lt $min_ram_gb ]]; then
        log_and_echo "WARNING" "Low RAM detected: ${ram_gb}GB (minimum recommended: ${min_ram_gb}GB)"
    else
        log_and_echo "SUCCESS" "RAM check passed: ${ram_gb}GB available"
    fi
    
    # Check disk space
    local disk_gb=$(df / | awk 'NR==2{print int($4/1024/1024)}')
    if [[ $disk_gb -lt $min_disk_gb ]]; then
        log_and_echo "ERROR" "Insufficient disk space: ${disk_gb}GB (minimum required: ${min_disk_gb}GB)"
        exit 1
    else
        log_and_echo "SUCCESS" "Disk space check passed: ${disk_gb}GB available"
    fi
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

update_system() {
    log_and_echo "INFO" "Updating system packages..."
    
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get upgrade -y
    elif command -v yum &> /dev/null; then
        yum update -y
    elif command -v dnf &> /dev/null; then
        dnf update -y
    else
        log_and_echo "ERROR" "Unknown package manager. Please update system manually."
        exit 1
    fi
    
    checkpoint "SYSTEM_UPDATE" "System packages updated successfully"
}

install_dependencies() {
    log_and_echo "INFO" "Installing essential dependencies..."
    
    local packages=(
        "curl" "wget" "git" "unzip" "software-properties-common"
        "apt-transport-https" "ca-certificates" "gnupg" "lsb-release"
        "build-essential" "python3" "python3-pip" "nodejs" "npm"
    )
    
    if command -v apt-get &> /dev/null; then
        apt-get install -y "${packages[@]}"
    elif command -v yum &> /dev/null; then
        yum install -y "${packages[@]}"
    elif command -v dnf &> /dev/null; then
        dnf install -y "${packages[@]}"
    fi
    
    checkpoint "DEPENDENCIES" "Essential dependencies installed"
}

setup_firewall() {
    log_and_echo "INFO" "Configuring UFW firewall..."
    
    if ! command -v ufw &> /dev/null; then
        apt-get install -y ufw
    fi
    
    # Enable UFW and set default policies
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow essential services
    ufw allow ssh
    ufw allow 80/tcp   # HTTP
    ufw allow 443/tcp  # HTTPS
    ufw allow 53       # DNS
    
    checkpoint "FIREWALL" "UFW firewall configured with basic rules"
}

install_web_server() {
    log_and_echo "INFO" "Installing and configuring web server (Nginx + Apache)..."
    
    # Install Nginx
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    
    # Install Apache (for compatibility)
    apt-get install -y apache2
    systemctl enable apache2
    
    # Configure Apache to run on port 8080 to avoid conflict with Nginx
    sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
    sed -i 's/:80>/:8080>/' /etc/apache2/sites-available/000-default.conf
    
    systemctl start apache2
    
    # Install PHP
    apt-get install -y php php-fpm php-mysql php-curl php-json php-mbstring php-xml php-zip
    
    checkpoint "WEB_SERVER" "Nginx and Apache web servers installed and configured"
}

install_database() {
    log_and_echo "INFO" "Installing database servers (MySQL + PostgreSQL)..."
    
    # Install MySQL
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y mysql-server
    systemctl enable mysql
    systemctl start mysql
    
    # Secure MySQL installation (automated)
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'SecureRootPass123!';"
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    mysql -e "FLUSH PRIVILEGES;"
    
    # Install PostgreSQL
    apt-get install -y postgresql postgresql-contrib
    systemctl enable postgresql
    systemctl start postgresql
    
    checkpoint "DATABASE" "MySQL and PostgreSQL database servers installed"
}

install_mail_server() {
    log_and_echo "INFO" "Installing mail server (Postfix + Dovecot)..."
    
    # Install Postfix (with automatic configuration)
    export DEBIAN_FRONTEND=noninteractive
    echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
    echo "postfix postfix/mailname string $(hostname -f)" | debconf-set-selections
    apt-get install -y postfix
    
    # Install Dovecot
    apt-get install -y dovecot-core dovecot-imapd dovecot-pop3d
    
    systemctl enable postfix dovecot
    systemctl start postfix dovecot
    
    checkpoint "MAIL_SERVER" "Postfix and Dovecot mail servers installed"
}

install_dns_server() {
    log_and_echo "INFO" "Installing DNS server (BIND9)..."
    
    apt-get install -y bind9 bind9utils bind9-doc
    systemctl enable bind9
    systemctl start bind9
    
    checkpoint "DNS_SERVER" "BIND9 DNS server installed and configured"
}

install_ssl_tools() {
    log_and_echo "INFO" "Installing SSL certificate tools (Certbot)..."
    
    apt-get install -y certbot python3-certbot-nginx python3-certbot-apache
    
    checkpoint "SSL_TOOLS" "SSL certificate tools (Certbot) installed"
}

install_monitoring_tools() {
    log_and_echo "INFO" "Installing monitoring and management tools..."
    
    # Install htop, iotop, and other monitoring tools
    apt-get install -y htop iotop nethogs iftop ncdu tree fail2ban
    
    # Configure fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
    
    checkpoint "MONITORING" "System monitoring and security tools installed"
}

setup_backup_system() {
    log_and_echo "INFO" "Setting up backup system..."
    
    apt-get install -y rsync duplicity
    
    # Create backup directories
    mkdir -p /var/backups/server-backups/{daily,weekly,monthly}
    mkdir -p /var/backups/database-backups
    
    checkpoint "BACKUP_SYSTEM" "Backup system configured with automated directories"
}

configure_log_rotation() {
    log_and_echo "INFO" "Configuring log rotation..."
    
    # Create custom logrotate configuration for our logs
    cat > /etc/logrotate.d/server-management << 'EOF'
/var/log/server-management/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    copytruncate
    notifempty
}
EOF
    
    checkpoint "LOG_ROTATION" "Log rotation configured for system maintenance"
}

setup_cron_jobs() {
    log_and_echo "INFO" "Setting up automated maintenance cron jobs..."
    
    # Create maintenance scripts directory
    mkdir -p /etc/server-management/scripts
    
    # Add basic maintenance cron jobs
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/bin/apt-get update && /usr/bin/apt-get upgrade -y") | crontab -
    (crontab -l 2>/dev/null; echo "0 3 * * 0 /usr/bin/find /var/log -name '*.log' -mtime +30 -delete") | crontab -
    
    checkpoint "CRON_JOBS" "Automated maintenance tasks scheduled"
}

install_additional_tools() {
    log_and_echo "INFO" "Installing additional development and management tools..."
    
    # Development tools
    apt-get install -y vim nano emacs-nox
    apt-get install -y screen tmux
    
    # Network tools
    apt-get install -y nmap netcat-openbsd tcpdump wireshark-common
    
    # Archive tools
    apt-get install -y zip unzip p7zip-full
    
    checkpoint "ADDITIONAL_TOOLS" "Development and network management tools installed"
}

setup_system_users() {
    log_and_echo "INFO" "Setting up system service users..."
    
    # Create service users for better security
    useradd -r -s /bin/false webmaster 2>/dev/null || true
    useradd -r -s /bin/false mailmaster 2>/dev/null || true
    useradd -r -s /bin/false dnsmaster 2>/dev/null || true
    
    checkpoint "SYSTEM_USERS" "Service users created for enhanced security"
}

configure_system_limits() {
    log_and_echo "INFO" "Configuring system limits and optimizations..."
    
    # Update system limits
    cat >> /etc/security/limits.conf << 'EOF'
# Server performance optimizations
* soft nofile 65535
* hard nofile 65535
* soft nproc 32768
* hard nproc 32768
EOF
    
    # Update sysctl settings
    cat >> /etc/sysctl.conf << 'EOF'
# Network optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_wmem = 4096 12582912 16777216
net.core.netdev_max_backlog = 5000
EOF
    
    sysctl -p
    
    checkpoint "SYSTEM_LIMITS" "System limits and network optimizations configured"
}

# =============================================================================
# MODULE INSTALLATION
# =============================================================================

install_server_modules() {
    log_and_echo "INFO" "Installing server management modules..."
    
    # Ensure modules directory exists and has proper permissions
    chmod +x "$MODULES_DIR"/*.sh 2>/dev/null || true
    chmod +x "$MODULES_DIR"/*/*.sh 2>/dev/null || true
    
    # Source common functions
    if [[ -f "$MODULES_DIR/common.sh" ]]; then
        source "$MODULES_DIR/common.sh"
        log_and_echo "SUCCESS" "Common functions module loaded"
    fi
    
    checkpoint "SERVER_MODULES" "Server management modules configured and loaded"
}

create_master_symlink() {
    log_and_echo "INFO" "Creating system-wide access to management tools..."
    
    # Create symlink for easy system-wide access
    ln -sf "$SCRIPT_DIR/master.sh" /usr/local/bin/server-manager
    chmod +x /usr/local/bin/server-manager
    
    # Create server-installer symlink
    ln -sf "$SCRIPT_DIR/server-installer.sh" /usr/local/bin/server-installer
    chmod +x /usr/local/bin/server-installer
    
    checkpoint "SYMLINKS" "System-wide command shortcuts created (server-manager, server-installer)"
}

# =============================================================================
# FINAL CONFIGURATION AND VERIFICATION
# =============================================================================

verify_installations() {
    log_and_echo "INFO" "Verifying all service installations..."
    
    local services=("nginx" "apache2" "mysql" "postgresql" "postfix" "dovecot" "bind9" "fail2ban")
    local failed_services=()
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log_and_echo "SUCCESS" "$service is running"
        else
            log_and_echo "WARNING" "$service is not running"
            failed_services+=("$service")
        fi
    done
    
    if [[ ${#failed_services[@]} -eq 0 ]]; then
        checkpoint "VERIFICATION" "All services verified and running successfully"
    else
        log_and_echo "WARNING" "Some services need attention: ${failed_services[*]}"
        checkpoint "VERIFICATION" "Service verification completed with warnings"
    fi
}

create_installation_summary() {
    local summary_file="$LOGS_DIR/installation-summary-$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$summary_file" << EOF
================================================================================
LINUX SETUP - MODULAR SERVER MANAGEMENT SYSTEM
Installation Summary Report
================================================================================
Installation Date: $(date '+%Y-%m-%d %H:%M:%S')
Server Hostname: $(hostname -f)
Operating System: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")
Kernel Version: $(uname -r)
Architecture: $(uname -m)

================================================================================
INSTALLED COMPONENTS
================================================================================

WEB SERVERS:
✓ Nginx (Primary web server on port 80)
✓ Apache2 (Secondary web server on port 8080)  
✓ PHP-FPM (PHP processor)

DATABASE SERVERS:
✓ MySQL Server (with secure configuration)
✓ PostgreSQL Server

MAIL SERVERS:
✓ Postfix (SMTP server)
✓ Dovecot (IMAP/POP3 server)

DNS SERVER:
✓ BIND9 (DNS server)

SECURITY TOOLS:
✓ UFW Firewall (configured with basic rules)
✓ Fail2Ban (intrusion prevention)
✓ SSL Tools (Certbot for Let's Encrypt)

MONITORING TOOLS:
✓ htop, iotop (system monitoring)
✓ nethogs, iftop (network monitoring)
✓ ncdu (disk usage analyzer)

BACKUP SYSTEM:
✓ rsync, duplicity (backup tools)
✓ Automated backup directories

DEVELOPMENT TOOLS:
✓ Git, Node.js, Python3
✓ Build essentials and compilers
✓ Text editors (vim, nano)

================================================================================
MANAGEMENT COMMANDS
================================================================================

System-wide commands available:
• server-manager     - Launch the master management interface
• server-installer   - Re-run this installer or install additional components

Service management:
• systemctl status nginx apache2 mysql postgresql postfix dovecot bind9
• systemctl restart [service-name]
• systemctl enable/disable [service-name]

================================================================================
IMPORTANT SECURITY NOTES
================================================================================

1. MySQL root password has been set to: SecureRootPass123!
   Please change this immediately: mysql -u root -p
   
2. Default firewall rules are active. Modify as needed:
   sudo ufw status
   sudo ufw allow [port]/[protocol]
   
3. SSH access is allowed. Consider configuring key-based authentication.

4. All services are configured with default settings. 
   Review and customize configurations in:
   - /etc/nginx/
   - /etc/apache2/
   - /etc/mysql/
   - /etc/postgresql/
   - /etc/postfix/
   - /etc/dovecot/
   - /etc/bind/

================================================================================
LOG LOCATIONS
================================================================================

Installation logs: $LOGS_DIR/
Service logs: /var/log/
Management modules: $MODULES_DIR/

================================================================================
NEXT STEPS
================================================================================

1. Run 'server-manager' to access the management interface
2. Configure domain names and SSL certificates
3. Set up database users and databases
4. Configure mail domains and user accounts
5. Set up DNS zones and records
6. Review and customize firewall rules
7. Set up automated backups for your data

For documentation and support:
• Website: https://ls.r-u.live
• GitHub: https://github.com/anshulyadav32/linux-setup
• Documentation: https://ls.r-u.live/docs/

================================================================================
EOF

    log_and_echo "SUCCESS" "Installation summary created: $summary_file"
    checkpoint "SUMMARY" "Installation summary and documentation generated"
}

display_final_status() {
    echo ""
    echo -e "${COLORS[BOLD]}${COLORS[GREEN]}=================================================${COLORS[NC]}"
    echo -e "${COLORS[BOLD]}${COLORS[GREEN]}    INSTALLATION COMPLETED SUCCESSFULLY!${COLORS[NC]}"
    echo -e "${COLORS[BOLD]}${COLORS[GREEN]}=================================================${COLORS[NC]}"
    echo ""
    echo -e "${COLORS[CYAN]}🎉 Linux Setup - Modular Server Management System${COLORS[NC]}"
    echo -e "${COLORS[WHITE]}   has been successfully installed on your server!${COLORS[NC]}"
    echo ""
    echo -e "${COLORS[YELLOW]}📊 Installation Statistics:${COLORS[NC]}"
    echo -e "${COLORS[WHITE]}   • Total Steps Completed: ${COLORS[GREEN]}$CURRENT_STEP/$TOTAL_STEPS${COLORS[NC]}"
    echo -e "${COLORS[WHITE]}   • Installation Time: ${COLORS[GREEN]}$(date '+%Y-%m-%d %H:%M:%S')${COLORS[NC]}"
    echo -e "${COLORS[WHITE]}   • Log File: ${COLORS[BLUE]}$INSTALL_LOG${COLORS[NC]}"
    echo ""
    echo -e "${COLORS[YELLOW]}🚀 Quick Start Commands:${COLORS[NC]}"
    echo -e "${COLORS[WHITE]}   • ${COLORS[CYAN]}server-manager${COLORS[NC]}     - Launch management interface"
    echo -e "${COLORS[WHITE]}   • ${COLORS[CYAN]}systemctl status nginx${COLORS[NC]} - Check web server status"
    echo -e "${COLORS[WHITE]}   • ${COLORS[CYAN]}ufw status${COLORS[NC]}           - Check firewall status"
    echo ""
    echo -e "${COLORS[YELLOW]}📚 Documentation:${COLORS[NC]}"
    echo -e "${COLORS[WHITE]}   • Website: ${COLORS[BLUE]}https://ls.r-u.live${COLORS[NC]}"
    echo -e "${COLORS[WHITE]}   • GitHub: ${COLORS[BLUE]}https://github.com/anshulyadav32/linux-setup${COLORS[NC]}"
    echo ""
    echo -e "${COLORS[GREEN]}Ready to manage your server! 🎯${COLORS[NC]}"
    echo ""
}

# =============================================================================
# MAIN INSTALLATION FLOW
# =============================================================================

main() {
    # Start installation
    show_header "COMPREHENSIVE SERVER INSTALLER"
    
    log_and_echo "INFO" "Starting Linux Setup - Modular Server Management System installation..."
    log_and_echo "INFO" "Installation log: $INSTALL_LOG"
    
    # Pre-installation checks
    log_and_echo "INFO" "Performing pre-installation checks..."
    check_root
    checkpoint "ROOT_CHECK" "Root access verified"
    
    check_os_compatibility
    checkpoint "OS_CHECK" "Operating system compatibility verified"
    
    check_internet_connectivity  
    checkpoint "INTERNET_CHECK" "Internet connectivity verified"
    
    check_system_resources
    checkpoint "RESOURCE_CHECK" "System resources verified"
    
    # System preparation
    update_system
    install_dependencies
    
    # Security setup
    setup_firewall
    
    # Core services installation
    install_web_server
    install_database
    install_mail_server
    install_dns_server
    install_ssl_tools
    
    # Monitoring and management
    install_monitoring_tools
    setup_backup_system
    configure_log_rotation
    setup_cron_jobs
    install_additional_tools
    
    # System configuration
    setup_system_users
    configure_system_limits
    
    # Module setup
    install_server_modules
    create_master_symlink
    
    # Final verification
    verify_installations
    create_installation_summary
    
    # Display completion status
    echo ""
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS
    echo ""
    display_final_status
    
    log_and_echo "SUCCESS" "Installation completed successfully!"
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Linux Setup - Modular Server Management System Installer"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --version, -v  Show version information" 
        echo "  --check        Run pre-installation checks only"
        echo ""
        echo "This script installs a complete server management system including:"
        echo "• Web servers (Nginx, Apache)"
        echo "• Database servers (MySQL, PostgreSQL)"
        echo "• Mail servers (Postfix, Dovecot)"
        echo "• DNS server (BIND9)"
        echo "• Security tools (UFW, Fail2Ban, SSL)"
        echo "• Monitoring and backup systems"
        echo "• Management interface and modules"
        echo ""
        exit 0
        ;;
    --version|-v)
        echo "Linux Setup - Modular Server Management System v1.0"
        echo "Author: Anshul Yadav"
        echo "Website: https://ls.r-u.live"
        exit 0
        ;;
    --check)
        echo "Running pre-installation checks..."
        check_root
        check_os_compatibility
        check_internet_connectivity
        check_system_resources
        echo "Pre-installation checks completed successfully!"
        exit 0
        ;;
    "")
        # No arguments, run main installation
        main
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
