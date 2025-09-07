#!/bin/bash
# =============================================================================
# Linux Setup - Modular Server Management System
# Installation Status Checker and Verification Tool
# =============================================================================
# Author: Anshul Yadav
# Description: Comprehensive system checker to verify what's installed and what's not
# Version: 1.0
# URL: https://ls.r-u.live | https://anshulyadav32.github.io/linux-setup
# =============================================================================

set -euo pipefail

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="$SCRIPT_DIR/logs"

# Create logs directory if it doesn't exist
mkdir -p "$LOGS_DIR"

# Status check log file with timestamp
STATUS_LOG="$LOGS_DIR/system-status-$(date +%Y%m%d_%H%M%S).log"

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

# Status counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# =============================================================================
# LOGGING AND DISPLAY FUNCTIONS
# =============================================================================

log_and_echo() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$STATUS_LOG"
    
    case "$level" in
        "INFO")
            echo -e "${COLORS[CYAN]}[INFO]${COLORS[NC]} $message"
            ;;
        "PASS")
            echo -e "${COLORS[GREEN]}[✓ INSTALLED]${COLORS[NC]} $message"
            ((PASSED_CHECKS++))
            ;;
        "FAIL")
            echo -e "${COLORS[RED]}[✗ NOT INSTALLED]${COLORS[NC]} $message"
            ((FAILED_CHECKS++))
            ;;
        "WARNING")
            echo -e "${COLORS[YELLOW]}[⚠ PARTIAL]${COLORS[NC]} $message"
            ((WARNING_CHECKS++))
            ;;
        "SECTION")
            echo -e "${COLORS[BOLD]}${COLORS[BLUE]}=== $message ===${COLORS[NC]}"
            ;;
    esac
    ((TOTAL_CHECKS++))
}

show_header() {
    local title="$1"
    echo ""
    echo -e "${COLORS[BOLD]}${COLORS[WHITE]}=================================================${COLORS[NC]}"
    echo -e "${COLORS[BOLD]}${COLORS[WHITE]}    LINUX SETUP - SYSTEM STATUS CHECKER${COLORS[NC]}"
    echo -e "${COLORS[BOLD]}${COLORS[WHITE]}              $title${COLORS[NC]}"
    echo -e "${COLORS[BOLD]}${COLORS[WHITE]}=================================================${COLORS[NC]}"
    echo ""
}

show_progress_summary() {
    local installed=$PASSED_CHECKS
    local not_installed=$FAILED_CHECKS
    local partial=$WARNING_CHECKS
    local total=$((installed + not_installed + partial))
    
    echo ""
    echo -e "${COLORS[BOLD]}${COLORS[WHITE]}=== INSTALLATION STATUS SUMMARY ===${COLORS[NC]}"
    echo -e "${COLORS[GREEN]}✓ Fully Installed: $installed${COLORS[NC]}"
    echo -e "${COLORS[YELLOW]}⚠ Partially Installed: $partial${COLORS[NC]}"
    echo -e "${COLORS[RED]}✗ Not Installed: $not_installed${COLORS[NC]}"
    echo -e "${COLORS[CYAN]}📊 Total Components Checked: $total${COLORS[NC]}"
    
    if [[ $total -gt 0 ]]; then
        local percentage=$((installed * 100 / total))
        echo -e "${COLORS[BLUE]}📈 Installation Completeness: $percentage%${COLORS[NC]}"
    fi
    echo ""
}

# =============================================================================
# SYSTEM CHECK FUNCTIONS
# =============================================================================

check_system_info() {
    log_and_echo "SECTION" "SYSTEM INFORMATION"
    
    echo -e "${COLORS[CYAN]}Hostname:${COLORS[NC]} $(hostname -f)"
    echo -e "${COLORS[CYAN]}OS:${COLORS[NC]} $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo -e "${COLORS[CYAN]}Kernel:${COLORS[NC]} $(uname -r)"
    echo -e "${COLORS[CYAN]}Architecture:${COLORS[NC]} $(uname -m)"
    echo -e "${COLORS[CYAN]}Uptime:${COLORS[NC]} $(uptime -p)"
    echo ""
}

check_package() {
    local package="$1"
    local description="$2"
    
    if command -v "$package" &> /dev/null; then
        local version=""
        case "$package" in
            "nginx") version=$(nginx -v 2>&1 | cut -d'/' -f2) ;;
            "apache2") version=$(apache2 -v 2>&1 | head -1 | cut -d'/' -f2 | cut -d' ' -f1) ;;
            "mysql") version=$(mysql --version | cut -d' ' -f3 | cut -d',' -f1) ;;
            "psql") version=$(psql --version | cut -d' ' -f3) ;;
            "php") version=$(php -v | head -1 | cut -d' ' -f2) ;;
            "node") version=$(node --version) ;;
            "git") version=$(git --version | cut -d' ' -f3) ;;
            *) version=$(${package} --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+[0-9.]*' | head -1 || echo "unknown") ;;
        esac
        log_and_echo "PASS" "$description (version: $version)"
        return 0
    else
        log_and_echo "FAIL" "$description"
        return 1
    fi
}

check_service() {
    local service="$1"
    local description="$2"
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        local status=$(systemctl is-enabled "$service" 2>/dev/null || echo "disabled")
        log_and_echo "PASS" "$description (active, $status)"
        return 0
    elif systemctl list-unit-files | grep -q "^$service.service"; then
        local status=$(systemctl is-active "$service" 2>/dev/null || echo "inactive")
        log_and_echo "WARNING" "$description (installed but $status)"
        return 1
    else
        log_and_echo "FAIL" "$description"
        return 1
    fi
}

check_port() {
    local port="$1"
    local service="$2"
    
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        log_and_echo "PASS" "$service listening on port $port"
        return 0
    else
        log_and_echo "FAIL" "$service not listening on port $port"
        return 1
    fi
}

check_file_exists() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        log_and_echo "PASS" "$description"
        return 0
    else
        log_and_echo "FAIL" "$description"
        return 1
    fi
}

check_directory_exists() {
    local directory="$1"
    local description="$2"
    
    if [[ -d "$directory" ]]; then
        log_and_echo "PASS" "$description"
        return 0
    else
        log_and_echo "FAIL" "$description"
        return 1
    fi
}

# =============================================================================
# COMPONENT CHECKS
# =============================================================================

check_web_servers() {
    log_and_echo "SECTION" "WEB SERVERS"
    
    check_package "nginx" "Nginx Web Server"
    check_package "apache2" "Apache Web Server"
    check_package "php" "PHP Processor"
    
    check_service "nginx" "Nginx Service"
    check_service "apache2" "Apache Service"
    check_service "php8.1-fpm" "PHP-FPM Service (8.1)" || check_service "php8.0-fpm" "PHP-FPM Service (8.0)" || check_service "php7.4-fpm" "PHP-FPM Service (7.4)"
    
    check_port "80" "HTTP (Nginx)"
    check_port "8080" "HTTP (Apache alternate)"
    check_port "443" "HTTPS"
    
    check_directory_exists "/etc/nginx" "Nginx Configuration Directory"
    check_directory_exists "/etc/apache2" "Apache Configuration Directory"
    
    echo ""
}

check_database_servers() {
    log_and_echo "SECTION" "DATABASE SERVERS"
    
    check_package "mysql" "MySQL Client"
    check_package "mysqld" "MySQL Server" || check_service "mysql" "MySQL Service"
    check_package "psql" "PostgreSQL Client"
    
    check_service "mysql" "MySQL Service"
    check_service "postgresql" "PostgreSQL Service"
    
    check_port "3306" "MySQL Database"
    check_port "5432" "PostgreSQL Database"
    
    check_directory_exists "/etc/mysql" "MySQL Configuration Directory"
    check_directory_exists "/etc/postgresql" "PostgreSQL Configuration Directory"
    
    echo ""
}

check_mail_servers() {
    log_and_echo "SECTION" "MAIL SERVERS"
    
    check_package "postfix" "Postfix SMTP Server"
    check_package "dovecot" "Dovecot IMAP/POP3 Server"
    
    check_service "postfix" "Postfix Service"
    check_service "dovecot" "Dovecot Service"
    
    check_port "25" "SMTP"
    check_port "587" "SMTP Submission"
    check_port "993" "IMAPS"
    check_port "995" "POP3S"
    
    check_directory_exists "/etc/postfix" "Postfix Configuration Directory"
    check_directory_exists "/etc/dovecot" "Dovecot Configuration Directory"
    
    echo ""
}

check_dns_server() {
    log_and_echo "SECTION" "DNS SERVER"
    
    check_package "named" "BIND9 DNS Server" || check_package "bind9" "BIND9 DNS Server"
    
    check_service "bind9" "BIND9 Service" || check_service "named" "BIND9 Service"
    
    check_port "53" "DNS"
    
    check_directory_exists "/etc/bind" "BIND Configuration Directory"
    check_file_exists "/etc/bind/named.conf" "BIND Main Configuration"
    
    echo ""
}

check_security_tools() {
    log_and_echo "SECTION" "SECURITY TOOLS"
    
    check_package "ufw" "UFW Firewall"
    check_package "fail2ban-client" "Fail2Ban Intrusion Prevention"
    check_package "certbot" "Certbot SSL Certificate Tool"
    
    check_service "ufw" "UFW Firewall Service"
    check_service "fail2ban" "Fail2Ban Service"
    
    # Check UFW status
    if command -v ufw &> /dev/null; then
        local ufw_status=$(ufw status | head -1 | cut -d':' -f2 | xargs)
        if [[ "$ufw_status" == "active" ]]; then
            log_and_echo "PASS" "UFW Firewall Status: Active"
        else
            log_and_echo "WARNING" "UFW Firewall Status: $ufw_status"
        fi
    fi
    
    check_directory_exists "/etc/ufw" "UFW Configuration Directory"
    check_directory_exists "/etc/fail2ban" "Fail2Ban Configuration Directory"
    
    echo ""
}

check_monitoring_tools() {
    log_and_echo "SECTION" "MONITORING & SYSTEM TOOLS"
    
    check_package "htop" "htop System Monitor"
    check_package "iotop" "iotop I/O Monitor"
    check_package "nethogs" "nethogs Network Monitor"
    check_package "iftop" "iftop Network Bandwidth Monitor"
    check_package "ncdu" "ncdu Disk Usage Analyzer"
    check_package "tree" "tree Directory Listing"
    
    echo ""
}

check_development_tools() {
    log_and_echo "SECTION" "DEVELOPMENT TOOLS"
    
    check_package "git" "Git Version Control"
    check_package "node" "Node.js Runtime"
    check_package "npm" "NPM Package Manager"
    check_package "python3" "Python 3"
    check_package "pip3" "Python Package Manager"
    check_package "curl" "cURL HTTP Client"
    check_package "wget" "wget Downloader"
    check_package "vim" "Vim Text Editor"
    check_package "nano" "Nano Text Editor"
    
    echo ""
}

check_backup_tools() {
    log_and_echo "SECTION" "BACKUP & ARCHIVE TOOLS"
    
    check_package "rsync" "rsync Backup Tool"
    check_package "duplicity" "Duplicity Encrypted Backup"
    check_package "zip" "zip Archive Tool"
    check_package "unzip" "unzip Extract Tool"
    check_package "p7zip" "7-Zip Archive Tool"
    
    check_directory_exists "/var/backups" "System Backup Directory"
    check_directory_exists "/var/backups/server-backups" "Server Backup Directory"
    
    echo ""
}

check_system_configuration() {
    log_and_echo "SECTION" "SYSTEM CONFIGURATION"
    
    check_file_exists "/etc/security/limits.conf" "System Limits Configuration"
    check_file_exists "/etc/sysctl.conf" "Kernel Parameters Configuration"
    check_file_exists "/etc/cron.d" "Cron Jobs Directory" || check_directory_exists "/etc/cron.d" "Cron Jobs Directory"
    
    # Check if server-manager command exists
    if command -v server-manager &> /dev/null; then
        log_and_echo "PASS" "System-wide server-manager command"
    else
        log_and_echo "FAIL" "System-wide server-manager command"
    fi
    
    # Check if server-installer command exists
    if command -v server-installer &> /dev/null; then
        log_and_echo "PASS" "System-wide server-installer command"
    else
        log_and_echo "FAIL" "System-wide server-installer command"
    fi
    
    echo ""
}

check_server_modules() {
    log_and_echo "SECTION" "SERVER MANAGEMENT MODULES"
    
    local modules_dir="$SCRIPT_DIR/modules"
    
    check_directory_exists "$modules_dir" "Modules Directory"
    check_file_exists "$modules_dir/common.sh" "Common Functions Module"
    check_file_exists "$modules_dir/interdependent.sh" "Interdependent Workflows Module"
    
    # Check individual modules
    local module_dirs=("web" "dns" "mail" "db" "firewall" "ssl" "system" "backup")
    for module in "${module_dirs[@]}"; do
        check_directory_exists "$modules_dir/$module" "$module Module Directory"
    done
    
    echo ""
}

# =============================================================================
# RECOMMENDATIONS AND FIXES
# =============================================================================

generate_recommendations() {
    echo -e "${COLORS[BOLD]}${COLORS[YELLOW]}=== RECOMMENDATIONS ===${COLORS[NC]}"
    
    if [[ $FAILED_CHECKS -gt 0 ]]; then
        echo -e "${COLORS[YELLOW]}To install missing components, run:${COLORS[NC]}"
        echo -e "${COLORS[CYAN]}sudo ./server-installer.sh${COLORS[NC]}"
        echo ""
        
        echo -e "${COLORS[YELLOW]}To check system compatibility first:${COLORS[NC]}"
        echo -e "${COLORS[CYAN]}sudo ./server-installer.sh --check${COLORS[NC]}"
        echo ""
    fi
    
    if [[ $WARNING_CHECKS -gt 0 ]]; then
        echo -e "${COLORS[YELLOW]}Some services are installed but not running. To start them:${COLORS[NC]}"
        echo -e "${COLORS[CYAN]}sudo systemctl start [service-name]${COLORS[NC]}"
        echo -e "${COLORS[CYAN]}sudo systemctl enable [service-name]${COLORS[NC]}"
        echo ""
    fi
    
    if [[ $PASSED_CHECKS -eq $TOTAL_CHECKS ]]; then
        echo -e "${COLORS[GREEN]}🎉 Congratulations! All components are fully installed and running.${COLORS[NC]}"
        echo -e "${COLORS[GREEN]}Your server is ready for management. Run: ${COLORS[CYAN]}server-manager${COLORS[NC]}"
        echo ""
    fi
    
    echo -e "${COLORS[BLUE]}For detailed system management, run:${COLORS[NC]}"
    echo -e "${COLORS[CYAN]}./master.sh${COLORS[NC]} or ${COLORS[CYAN]}server-manager${COLORS[NC]}"
    echo ""
}

# =============================================================================
# MAIN CHECKING FLOW
# =============================================================================

main() {
    # Show header
    show_header "INSTALLATION STATUS VERIFICATION"
    
    log_and_echo "INFO" "Starting comprehensive system status check..."
    log_and_echo "INFO" "Status log: $STATUS_LOG"
    
    # System information
    check_system_info
    
    # Reset counters for actual component checks
    TOTAL_CHECKS=0
    PASSED_CHECKS=0
    FAILED_CHECKS=0
    WARNING_CHECKS=0
    
    # Run all component checks
    check_web_servers
    check_database_servers
    check_mail_servers
    check_dns_server
    check_security_tools
    check_monitoring_tools
    check_development_tools
    check_backup_tools
    check_system_configuration
    check_server_modules
    
    # Show summary
    show_progress_summary
    
    # Generate recommendations
    generate_recommendations
    
    # Final status
    echo -e "${COLORS[CYAN]}📋 Detailed log saved to: $STATUS_LOG${COLORS[NC]}"
    echo ""
    
    log_and_echo "INFO" "System status check completed."
    
    # Exit with appropriate code
    if [[ $FAILED_CHECKS -eq 0 && $WARNING_CHECKS -eq 0 ]]; then
        exit 0  # All good
    elif [[ $FAILED_CHECKS -eq 0 ]]; then
        exit 1  # Warnings only
    else
        exit 2  # Failed checks
    fi
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Linux Setup - System Status Checker"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --version, -v  Show version information"
        echo "  --quick        Run quick check (essential services only)"
        echo "  --services     Check only service status"
        echo "  --packages     Check only package installation"
        echo ""
        echo "This script checks the installation status of all server components including:"
        echo "• Web servers (Nginx, Apache, PHP)"
        echo "• Database servers (MySQL, PostgreSQL)"
        echo "• Mail servers (Postfix, Dovecot)"
        echo "• DNS server (BIND9)"
        echo "• Security tools (UFW, Fail2Ban, SSL)"
        echo "• Monitoring and development tools"
        echo "• System configuration and modules"
        echo ""
        exit 0
        ;;
    --version|-v)
        echo "Linux Setup - System Status Checker v1.0"
        echo "Author: Anshul Yadav"
        echo "Website: https://ls.r-u.live"
        exit 0
        ;;
    --quick)
        echo "Quick check mode not implemented yet. Running full check..."
        main
        ;;
    --services)
        echo "Services-only mode not implemented yet. Running full check..."
        main
        ;;
    --packages)
        echo "Packages-only mode not implemented yet. Running full check..."
        main
        ;;
    "")
        # No arguments, run main check
        main
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
