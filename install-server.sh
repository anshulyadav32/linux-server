#!/bin/bash
# Server Dependencies Installation Script
# Comprehensive installation with checkpoint error handling and testing

# Set strict error handling
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_LOG="$SCRIPT_DIR/logs/install-$(date +%Y%m%d-%H%M%S).log"

# Create logs directory
mkdir -p "$SCRIPT_DIR/logs"

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
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $message" | tee -a "$INSTALL_LOG"
}

log_ok() {
    local message="$1"
    echo -e "${GREEN}[OK]${NC} $message" | tee -a "$INSTALL_LOG"
}

log_warn() {
    local message="$1"
    echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$INSTALL_LOG"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message" | tee -a "$INSTALL_LOG"
}

log_checkpoint() {
    local checkpoint="$1"
    echo -e "${CYAN}[CHECKPOINT]${NC} $checkpoint" | tee -a "$INSTALL_LOG"
}

# Error handler
error_exit() {
    local line_number="$1"
    local error_code="$2"
    log_error "Script failed at line $line_number with exit code $error_code"
    log_error "Check the log file: $INSTALL_LOG"
    exit "$error_code"
}

# Set trap for error handling
trap 'error_exit ${LINENO} $?' ERR

# Checkpoint tracking
CHECKPOINT_FILE="$SCRIPT_DIR/logs/install-checkpoints.txt"
touch "$CHECKPOINT_FILE"

# Mark checkpoint as completed
mark_checkpoint() {
    local checkpoint="$1"
    echo "$checkpoint" >> "$CHECKPOINT_FILE"
    log_checkpoint "Completed: $checkpoint"
}

# Check if checkpoint was completed
check_checkpoint() {
    local checkpoint="$1"
    grep -q "^$checkpoint$" "$CHECKPOINT_FILE" 2>/dev/null
}

# Test functions for each component
test_package() {
    local package_name="$1"
    if dpkg -l | grep -q "^ii.*$package_name "; then
        log_ok "Package $package_name is installed and verified"
        return 0
    else
        log_error "Package $package_name is not properly installed"
        return 1
    fi
}

test_service() {
    local service_name="$1"
    if systemctl is-active --quiet "$service_name"; then
        log_ok "Service $service_name is active and running"
        return 0
    else
        log_warn "Service $service_name is not running (may be normal for some services)"
        return 1
    fi
}

test_command() {
    local command_name="$1"
    if command -v "$command_name" >/dev/null 2>&1; then
        log_ok "Command $command_name is available"
        return 0
    else
        log_error "Command $command_name is not available"
        return 1
    fi
}

test_port() {
    local port="$1"
    local service_name="$2"
    if netstat -tuln | grep -q ":$port "; then
        log_ok "Port $port is open for $service_name"
        return 0
    else
        log_warn "Port $port is not open for $service_name (may be normal if service is not configured)"
        return 1
    fi
}

test_file_exists() {
    local file_path="$1"
    local description="$2"
    if [[ -f "$file_path" ]]; then
        log_ok "$description exists at $file_path"
        return 0
    else
        log_warn "$description not found at $file_path"
        return 1
    fi
}

# System requirements check
check_system_requirements() {
    log_checkpoint "SYSTEM_REQUIREMENTS_CHECK"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root!"
        log_info "Run as a regular user with sudo privileges."
        exit 1
    fi
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        log_error "Unable to detect Linux distribution"
        exit 1
    fi
    
    source /etc/os-release
    log_info "Detected OS: $PRETTY_NAME"
    
    if [[ "$ID" != "ubuntu" ]] && [[ "$ID" != "debian" ]]; then
        log_warn "This system is optimized for Ubuntu/Debian"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check sudo privileges
    if ! sudo -n true 2>/dev/null; then
        log_error "User must have sudo privileges"
        exit 1
    fi
    
    # Check internet connectivity
    log_info "Testing internet connectivity..."
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_error "No internet connectivity detected"
        exit 1
    fi
    
    # Check available disk space (at least 2GB)
    local available_space=$(df / | tail -1 | awk '{print $4}')
    local required_space=2097152  # 2GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        log_error "Insufficient disk space. Required: 2GB, Available: $((available_space/1024/1024))GB"
        exit 1
    fi
    
    mark_checkpoint "SYSTEM_REQUIREMENTS_CHECK"
}

# Update system packages
update_system() {
    if check_checkpoint "SYSTEM_UPDATE"; then
        log_info "System update already completed, skipping..."
        return 0
    fi
    
    log_checkpoint "SYSTEM_UPDATE"
    log_info "Updating system packages..."
    
    # Update package lists
    sudo apt update 2>&1 | tee -a "$INSTALL_LOG"
    
    # Upgrade existing packages
    sudo apt upgrade -y 2>&1 | tee -a "$INSTALL_LOG"
    
    # Test: Check if apt is working
    if ! apt list --installed >/dev/null 2>&1; then
        log_error "APT package manager is not functioning properly"
        exit 1
    fi
    
    mark_checkpoint "SYSTEM_UPDATE"
}

# Install essential packages
install_essential_packages() {
    if check_checkpoint "ESSENTIAL_PACKAGES"; then
        log_info "Essential packages already installed, skipping..."
        return 0
    fi
    
    log_checkpoint "ESSENTIAL_PACKAGES"
    log_info "Installing essential packages..."
    
    local essential_packages=(
        "curl"
        "wget"
        "git"
        "htop"
        "tree"
        "unzip"
        "zip"
        "nano"
        "vim"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "net-tools"
        "dnsutils"
        "telnet"
        "tcpdump"
        "iotop"
        "iftop"
        "nmap"
    )
    
    for package in "${essential_packages[@]}"; do
        log_info "Installing $package..."
        if sudo apt install -y "$package" 2>&1 | tee -a "$INSTALL_LOG"; then
            test_package "$package"
        else
            log_error "Failed to install $package"
            exit 1
        fi
    done
    
    # Test essential commands
    local essential_commands=("curl" "wget" "git" "htop" "tree" "nano" "dig" "nmap")
    for cmd in "${essential_commands[@]}"; do
        test_command "$cmd"
    done
    
    mark_checkpoint "ESSENTIAL_PACKAGES"
}

# Install web server dependencies
install_web_dependencies() {
    if check_checkpoint "WEB_DEPENDENCIES"; then
        log_info "Web dependencies already installed, skipping..."
        return 0
    fi
    
    log_checkpoint "WEB_DEPENDENCIES"
    log_info "Installing web server dependencies..."
    
    local web_packages=(
        "apache2"
        "nginx"
        "php"
        "php-fpm"
        "php-mysql"
        "php-pgsql"
        "php-curl"
        "php-gd"
        "php-mbstring"
        "php-xml"
        "php-zip"
        "php-json"
        "nodejs"
        "npm"
        "python3"
        "python3-pip"
        "python3-venv"
    )
    
    for package in "${web_packages[@]}"; do
        log_info "Installing $package..."
        if sudo apt install -y "$package" 2>&1 | tee -a "$INSTALL_LOG"; then
            test_package "$package"
        else
            log_warn "Failed to install $package (may not be available in this distribution)"
        fi
    done
    
    # Test web server commands
    test_command "apache2"
    test_command "nginx"
    test_command "php"
    test_command "node"
    test_command "npm"
    test_command "python3"
    test_command "pip3"
    
    # Test configuration files
    test_file_exists "/etc/apache2/apache2.conf" "Apache configuration"
    test_file_exists "/etc/nginx/nginx.conf" "Nginx configuration"
    
    mark_checkpoint "WEB_DEPENDENCIES"
}

# Install database dependencies
install_database_dependencies() {
    if check_checkpoint "DATABASE_DEPENDENCIES"; then
        log_info "Database dependencies already installed, skipping..."
        return 0
    fi
    
    log_checkpoint "DATABASE_DEPENDENCIES"
    log_info "Installing database dependencies..."
    
    local db_packages=(
        "mysql-server"
        "mysql-client"
        "postgresql"
        "postgresql-contrib"
        "redis-server"
        "sqlite3"
    )
    
    for package in "${db_packages[@]}"; do
        log_info "Installing $package..."
        if sudo apt install -y "$package" 2>&1 | tee -a "$INSTALL_LOG"; then
            test_package "$package"
        else
            log_warn "Failed to install $package"
        fi
    done
    
    # Test database commands
    test_command "mysql"
    test_command "psql"
    test_command "redis-cli"
    test_command "sqlite3"
    
    # Test database services
    test_service "mysql"
    test_service "postgresql"
    test_service "redis-server"
    
    mark_checkpoint "DATABASE_DEPENDENCIES"
}

# Install mail server dependencies
install_mail_dependencies() {
    if check_checkpoint "MAIL_DEPENDENCIES"; then
        log_info "Mail dependencies already installed, skipping..."
        return 0
    fi
    
    log_checkpoint "MAIL_DEPENDENCIES"
    log_info "Installing mail server dependencies..."
    
    local mail_packages=(
        "postfix"
        "dovecot-core"
        "dovecot-imapd"
        "dovecot-pop3d"
        "opendkim"
        "opendkim-tools"
        "spamassassin"
        "clamav"
        "clamav-daemon"
    )
    
    # Configure postfix non-interactively
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | sudo debconf-set-selections
    echo "postfix postfix/mailname string $(hostname -f)" | sudo debconf-set-selections
    
    for package in "${mail_packages[@]}"; do
        log_info "Installing $package..."
        if sudo apt install -y "$package" 2>&1 | tee -a "$INSTALL_LOG"; then
            test_package "$package"
        else
            log_warn "Failed to install $package"
        fi
    done
    
    # Test mail commands
    test_command "postfix"
    test_command "dovecot"
    test_command "opendkim"
    
    # Test mail configuration files
    test_file_exists "/etc/postfix/main.cf" "Postfix main configuration"
    test_file_exists "/etc/dovecot/dovecot.conf" "Dovecot configuration"
    
    mark_checkpoint "MAIL_DEPENDENCIES"
}

# Install DNS server dependencies
install_dns_dependencies() {
    if check_checkpoint "DNS_DEPENDENCIES"; then
        log_info "DNS dependencies already installed, skipping..."
        return 0
    fi
    
    log_checkpoint "DNS_DEPENDENCIES"
    log_info "Installing DNS server dependencies..."
    
    local dns_packages=(
        "bind9"
        "bind9utils"
        "bind9-doc"
        "dnsutils"
    )
    
    for package in "${dns_packages[@]}"; do
        log_info "Installing $package..."
        if sudo apt install -y "$package" 2>&1 | tee -a "$INSTALL_LOG"; then
            test_package "$package"
        else
            log_error "Failed to install $package"
            exit 1
        fi
    done
    
    # Test DNS commands
    test_command "named"
    test_command "dig"
    test_command "nslookup"
    test_command "host"
    
    # Test DNS configuration files
    test_file_exists "/etc/bind/named.conf" "BIND main configuration"
    test_file_exists "/etc/bind/named.conf.options" "BIND options configuration"
    
    mark_checkpoint "DNS_DEPENDENCIES"
}

# Install SSL/Security dependencies
install_ssl_dependencies() {
    if check_checkpoint "SSL_DEPENDENCIES"; then
        log_info "SSL dependencies already installed, skipping..."
        return 0
    fi
    
    log_checkpoint "SSL_DEPENDENCIES"
    log_info "Installing SSL and security dependencies..."
    
    local ssl_packages=(
        "certbot"
        "python3-certbot-apache"
        "python3-certbot-nginx"
        "ufw"
        "fail2ban"
        "openssl"
        "ssl-cert"
    )
    
    for package in "${ssl_packages[@]}"; do
        log_info "Installing $package..."
        if sudo apt install -y "$package" 2>&1 | tee -a "$INSTALL_LOG"; then
            test_package "$package"
        else
            log_warn "Failed to install $package"
        fi
    done
    
    # Test SSL/Security commands
    test_command "certbot"
    test_command "ufw"
    test_command "fail2ban-client"
    test_command "openssl"
    
    # Test security configuration files
    test_file_exists "/etc/ufw/ufw.conf" "UFW configuration"
    test_file_exists "/etc/fail2ban/fail2ban.conf" "Fail2Ban configuration"
    
    mark_checkpoint "SSL_DEPENDENCIES"
}

# Install backup dependencies
install_backup_dependencies() {
    if check_checkpoint "BACKUP_DEPENDENCIES"; then
        log_info "Backup dependencies already installed, skipping..."
        return 0
    fi
    
    log_checkpoint "BACKUP_DEPENDENCIES"
    log_info "Installing backup and monitoring dependencies..."
    
    local backup_packages=(
        "rsync"
        "duplicity"
        "borgbackup"
        "cron"
        "logrotate"
        "monit"
        "nagios-nrpe-server"
        "nagios-plugins-basic"
    )
    
    for package in "${backup_packages[@]}"; do
        log_info "Installing $package..."
        if sudo apt install -y "$package" 2>&1 | tee -a "$INSTALL_LOG"; then
            test_package "$package"
        else
            log_warn "Failed to install $package"
        fi
    done
    
    # Test backup commands
    test_command "rsync"
    test_command "duplicity"
    test_command "borg"
    test_command "crontab"
    
    # Test service
    test_service "cron"
    
    mark_checkpoint "BACKUP_DEPENDENCIES"
}

# Install system monitoring dependencies
install_monitoring_dependencies() {
    if check_checkpoint "MONITORING_DEPENDENCIES"; then
        log_info "Monitoring dependencies already installed, skipping..."
        return 0
    fi
    
    log_checkpoint "MONITORING_DEPENDENCIES"
    log_info "Installing system monitoring dependencies..."
    
    local monitoring_packages=(
        "htop"
        "iotop"
        "iftop"
        "nethogs"
        "sysstat"
        "psmisc"
        "lsof"
        "strace"
        "tcpdump"
        "wireshark-common"
    )
    
    for package in "${monitoring_packages[@]}"; do
        log_info "Installing $package..."
        if sudo apt install -y "$package" 2>&1 | tee -a "$INSTALL_LOG"; then
            test_package "$package"
        else
            log_warn "Failed to install $package"
        fi
    done
    
    # Test monitoring commands
    test_command "htop"
    test_command "iotop"
    test_command "iftop"
    test_command "nethogs"
    test_command "sar"
    test_command "lsof"
    
    mark_checkpoint "MONITORING_DEPENDENCIES"
}

# Perform comprehensive system test
perform_system_test() {
    log_checkpoint "SYSTEM_TEST"
    log_info "Performing comprehensive system test..."
    
    local test_results=()
    local failed_tests=0
    
    # Test network connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        test_results+=("✓ Network connectivity: PASS")
    else
        test_results+=("✗ Network connectivity: FAIL")
        ((failed_tests++))
    fi
    
    # Test DNS resolution
    if dig google.com >/dev/null 2>&1; then
        test_results+=("✓ DNS resolution: PASS")
    else
        test_results+=("✗ DNS resolution: FAIL")
        ((failed_tests++))
    fi
    
    # Test package manager
    if apt list --installed >/dev/null 2>&1; then
        test_results+=("✓ Package manager: PASS")
    else
        test_results+=("✗ Package manager: FAIL")
        ((failed_tests++))
    fi
    
    # Test sudo access
    if sudo -n true 2>/dev/null; then
        test_results+=("✓ Sudo access: PASS")
    else
        test_results+=("✗ Sudo access: FAIL")
        ((failed_tests++))
    fi
    
    # Test filesystem
    if touch /tmp/test_file && rm /tmp/test_file; then
        test_results+=("✓ Filesystem write: PASS")
    else
        test_results+=("✗ Filesystem write: FAIL")
        ((failed_tests++))
    fi
    
    # Display test results
    echo ""
    log_info "=== SYSTEM TEST RESULTS ==="
    for result in "${test_results[@]}"; do
        if [[ $result == *"PASS"* ]]; then
            echo -e "${GREEN}$result${NC}"
        else
            echo -e "${RED}$result${NC}"
        fi
    done
    
    if [[ $failed_tests -eq 0 ]]; then
        log_ok "All system tests passed!"
        mark_checkpoint "SYSTEM_TEST"
        return 0
    else
        log_error "$failed_tests system tests failed!"
        return 1
    fi
}

# Display installation summary
display_summary() {
    log_checkpoint "INSTALLATION_SUMMARY"
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    INSTALLATION SUMMARY                     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Count completed checkpoints
    local total_checkpoints=$(grep -c "mark_checkpoint" "$0")
    local completed_checkpoints=$(wc -l < "$CHECKPOINT_FILE")
    
    echo -e "${WHITE}Installation Progress:${NC} $completed_checkpoints/$total_checkpoints checkpoints completed"
    echo ""
    
    echo -e "${WHITE}Completed Components:${NC}"
    while IFS= read -r checkpoint; do
        echo -e "  ${GREEN}✓${NC} $checkpoint"
    done < "$CHECKPOINT_FILE"
    
    echo ""
    echo -e "${WHITE}Installation Log:${NC} $INSTALL_LOG"
    echo -e "${WHITE}Checkpoint File:${NC} $CHECKPOINT_FILE"
    echo ""
    
    if [[ $completed_checkpoints -eq $total_checkpoints ]]; then
        echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
        echo ""
        echo -e "${WHITE}Next Steps:${NC}"
        echo "1. Run ./master.sh to access the main menu"
        echo "2. Configure individual services as needed"
        echo "3. Use ./modules/interdependent.sh for automated workflows"
    else
        echo -e "${YELLOW}⚠️  Installation incomplete. Check the log for errors.${NC}"
    fi
    
    mark_checkpoint "INSTALLATION_SUMMARY"
}

# Main installation function
main() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               SERVER DEPENDENCIES INSTALLER                 ║${NC}"
    echo -e "${CYAN}║            Comprehensive Installation with Testing          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log_info "Starting server dependencies installation..."
    log_info "Installation log: $INSTALL_LOG"
    echo ""
    
    # Installation steps with error handling and testing
    check_system_requirements
    update_system
    install_essential_packages
    install_web_dependencies
    install_database_dependencies
    install_mail_dependencies
    install_dns_dependencies
    install_ssl_dependencies
    install_backup_dependencies
    install_monitoring_dependencies
    perform_system_test
    display_summary
    
    echo ""
    log_ok "Server dependencies installation completed!"
}

# Run main function with error handling
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
