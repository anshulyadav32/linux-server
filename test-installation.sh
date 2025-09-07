#!/bin/bash
# Server Installation Test & Resume Script
# Advanced testing and checkpoint management for install-server.sh

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKPOINT_FILE="$SCRIPT_DIR/logs/install-checkpoints.txt"
INSTALL_LOG="$SCRIPT_DIR/logs/install-$(date +%Y%m%d-%H%M%S).log"

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

# Check if checkpoint was completed
check_checkpoint() {
    local checkpoint="$1"
    if [[ -f "$CHECKPOINT_FILE" ]]; then
        grep -q "^$checkpoint$" "$CHECKPOINT_FILE" 2>/dev/null
    else
        return 1
    fi
}

# Display installation status
show_installation_status() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  INSTALLATION STATUS                        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Define all checkpoints in order
    local checkpoints=(
        "SYSTEM_REQUIREMENTS_CHECK"
        "SYSTEM_UPDATE"
        "ESSENTIAL_PACKAGES"
        "WEB_DEPENDENCIES"
        "DATABASE_DEPENDENCIES"
        "MAIL_DEPENDENCIES"
        "DNS_DEPENDENCIES"
        "SSL_DEPENDENCIES"
        "BACKUP_DEPENDENCIES"
        "MONITORING_DEPENDENCIES"
        "SYSTEM_TEST"
        "INSTALLATION_SUMMARY"
    )
    
    local completed=0
    local total=${#checkpoints[@]}
    
    echo -e "${WHITE}Checkpoint Status:${NC}"
    echo ""
    
    for checkpoint in "${checkpoints[@]}"; do
        if check_checkpoint "$checkpoint"; then
            echo -e "  ${GREEN}✓${NC} $checkpoint"
            ((completed++))
        else
            echo -e "  ${RED}✗${NC} $checkpoint"
        fi
    done
    
    echo ""
    echo -e "${WHITE}Progress:${NC} $completed/$total checkpoints completed ($(( completed * 100 / total ))%)"
    
    if [[ -f "$CHECKPOINT_FILE" ]]; then
        echo -e "${WHITE}Checkpoint file:${NC} $CHECKPOINT_FILE"
        echo -e "${WHITE}Last completed:${NC} $(tail -1 "$CHECKPOINT_FILE" 2>/dev/null || echo "None")"
    else
        echo -e "${YELLOW}No checkpoint file found${NC}"
    fi
}

# Test specific components
test_web_stack() {
    echo -e "${CYAN}Testing Web Stack Components...${NC}"
    echo ""
    
    local tests_passed=0
    local tests_total=0
    
    # Test Apache
    ((tests_total++))
    if command -v apache2 >/dev/null 2>&1; then
        log_ok "Apache2 command available"
        ((tests_passed++))
    else
        log_error "Apache2 command not found"
    fi
    
    # Test Nginx
    ((tests_total++))
    if command -v nginx >/dev/null 2>&1; then
        log_ok "Nginx command available"
        ((tests_passed++))
    else
        log_error "Nginx command not found"
    fi
    
    # Test PHP
    ((tests_total++))
    if command -v php >/dev/null 2>&1; then
        local php_version=$(php -v | head -n1 | cut -d' ' -f2)
        log_ok "PHP available (version: $php_version)"
        ((tests_passed++))
    else
        log_error "PHP command not found"
    fi
    
    # Test Node.js
    ((tests_total++))
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version)
        log_ok "Node.js available (version: $node_version)"
        ((tests_passed++))
    else
        log_error "Node.js command not found"
    fi
    
    # Test Python
    ((tests_total++))
    if command -v python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version)
        log_ok "Python3 available ($python_version)"
        ((tests_passed++))
    else
        log_error "Python3 command not found"
    fi
    
    echo ""
    echo -e "${WHITE}Web Stack Test Results: $tests_passed/$tests_total passed${NC}"
    
    return $(( tests_total - tests_passed ))
}

test_database_stack() {
    echo -e "${CYAN}Testing Database Stack Components...${NC}"
    echo ""
    
    local tests_passed=0
    local tests_total=0
    
    # Test MySQL
    ((tests_total++))
    if command -v mysql >/dev/null 2>&1; then
        log_ok "MySQL client available"
        ((tests_passed++))
        
        # Test MySQL service
        if systemctl is-active --quiet mysql; then
            log_ok "MySQL service is running"
        else
            log_warn "MySQL service is not running"
        fi
    else
        log_error "MySQL client not found"
    fi
    
    # Test PostgreSQL
    ((tests_total++))
    if command -v psql >/dev/null 2>&1; then
        log_ok "PostgreSQL client available"
        ((tests_passed++))
        
        # Test PostgreSQL service
        if systemctl is-active --quiet postgresql; then
            log_ok "PostgreSQL service is running"
        else
            log_warn "PostgreSQL service is not running"
        fi
    else
        log_error "PostgreSQL client not found"
    fi
    
    # Test Redis
    ((tests_total++))
    if command -v redis-cli >/dev/null 2>&1; then
        log_ok "Redis client available"
        ((tests_passed++))
        
        # Test Redis service
        if systemctl is-active --quiet redis-server; then
            log_ok "Redis service is running"
        else
            log_warn "Redis service is not running"
        fi
    else
        log_error "Redis client not found"
    fi
    
    # Test SQLite
    ((tests_total++))
    if command -v sqlite3 >/dev/null 2>&1; then
        log_ok "SQLite3 available"
        ((tests_passed++))
    else
        log_error "SQLite3 not found"
    fi
    
    echo ""
    echo -e "${WHITE}Database Stack Test Results: $tests_passed/$tests_total passed${NC}"
    
    return $(( tests_total - tests_passed ))
}

test_mail_stack() {
    echo -e "${CYAN}Testing Mail Stack Components...${NC}"
    echo ""
    
    local tests_passed=0
    local tests_total=0
    
    # Test Postfix
    ((tests_total++))
    if command -v postfix >/dev/null 2>&1; then
        log_ok "Postfix available"
        ((tests_passed++))
        
        if systemctl is-active --quiet postfix; then
            log_ok "Postfix service is running"
        else
            log_warn "Postfix service is not running"
        fi
    else
        log_error "Postfix not found"
    fi
    
    # Test Dovecot
    ((tests_total++))
    if command -v dovecot >/dev/null 2>&1; then
        log_ok "Dovecot available"
        ((tests_passed++))
        
        if systemctl is-active --quiet dovecot; then
            log_ok "Dovecot service is running"
        else
            log_warn "Dovecot service is not running"
        fi
    else
        log_error "Dovecot not found"
    fi
    
    # Test OpenDKIM
    ((tests_total++))
    if command -v opendkim >/dev/null 2>&1; then
        log_ok "OpenDKIM available"
        ((tests_passed++))
    else
        log_error "OpenDKIM not found"
    fi
    
    # Test mail configuration files
    ((tests_total++))
    if [[ -f "/etc/postfix/main.cf" ]]; then
        log_ok "Postfix main configuration exists"
        ((tests_passed++))
    else
        log_error "Postfix main configuration not found"
    fi
    
    echo ""
    echo -e "${WHITE}Mail Stack Test Results: $tests_passed/$tests_total passed${NC}"
    
    return $(( tests_total - tests_passed ))
}

test_dns_stack() {
    echo -e "${CYAN}Testing DNS Stack Components...${NC}"
    echo ""
    
    local tests_passed=0
    local tests_total=0
    
    # Test BIND9
    ((tests_total++))
    if command -v named >/dev/null 2>&1; then
        log_ok "BIND9 named available"
        ((tests_passed++))
        
        if systemctl is-active --quiet bind9; then
            log_ok "BIND9 service is running"
        else
            log_warn "BIND9 service is not running"
        fi
    else
        log_error "BIND9 named not found"
    fi
    
    # Test DNS utilities
    ((tests_total++))
    if command -v dig >/dev/null 2>&1; then
        log_ok "dig utility available"
        ((tests_passed++))
    else
        log_error "dig utility not found"
    fi
    
    ((tests_total++))
    if command -v nslookup >/dev/null 2>&1; then
        log_ok "nslookup utility available"
        ((tests_passed++))
    else
        log_error "nslookup utility not found"
    fi
    
    # Test DNS configuration
    ((tests_total++))
    if [[ -f "/etc/bind/named.conf" ]]; then
        log_ok "BIND main configuration exists"
        ((tests_passed++))
    else
        log_error "BIND main configuration not found"
    fi
    
    # Test DNS resolution
    ((tests_total++))
    if dig google.com >/dev/null 2>&1; then
        log_ok "DNS resolution working"
        ((tests_passed++))
    else
        log_error "DNS resolution failed"
    fi
    
    echo ""
    echo -e "${WHITE}DNS Stack Test Results: $tests_passed/$tests_total passed${NC}"
    
    return $(( tests_total - tests_passed ))
}

test_ssl_security() {
    echo -e "${CYAN}Testing SSL and Security Components...${NC}"
    echo ""
    
    local tests_passed=0
    local tests_total=0
    
    # Test Certbot
    ((tests_total++))
    if command -v certbot >/dev/null 2>&1; then
        log_ok "Certbot available"
        ((tests_passed++))
    else
        log_error "Certbot not found"
    fi
    
    # Test UFW
    ((tests_total++))
    if command -v ufw >/dev/null 2>&1; then
        log_ok "UFW firewall available"
        ((tests_passed++))
        
        local ufw_status=$(sudo ufw status | head -1)
        log_info "UFW status: $ufw_status"
    else
        log_error "UFW firewall not found"
    fi
    
    # Test Fail2Ban
    ((tests_total++))
    if command -v fail2ban-client >/dev/null 2>&1; then
        log_ok "Fail2Ban available"
        ((tests_passed++))
        
        if systemctl is-active --quiet fail2ban; then
            log_ok "Fail2Ban service is running"
        else
            log_warn "Fail2Ban service is not running"
        fi
    else
        log_error "Fail2Ban not found"
    fi
    
    # Test OpenSSL
    ((tests_total++))
    if command -v openssl >/dev/null 2>&1; then
        local openssl_version=$(openssl version)
        log_ok "OpenSSL available ($openssl_version)"
        ((tests_passed++))
    else
        log_error "OpenSSL not found"
    fi
    
    echo ""
    echo -e "${WHITE}SSL/Security Test Results: $tests_passed/$tests_total passed${NC}"
    
    return $(( tests_total - tests_passed ))
}

# Run comprehensive tests
run_comprehensive_test() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  COMPREHENSIVE TESTING                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local total_failed=0
    
    # Run all component tests
    test_web_stack
    total_failed=$((total_failed + $?))
    echo ""
    
    test_database_stack
    total_failed=$((total_failed + $?))
    echo ""
    
    test_mail_stack
    total_failed=$((total_failed + $?))
    echo ""
    
    test_dns_stack
    total_failed=$((total_failed + $?))
    echo ""
    
    test_ssl_security
    total_failed=$((total_failed + $?))
    echo ""
    
    # Display final results
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    TEST SUMMARY                             ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ $total_failed -eq 0 ]]; then
        log_ok "All tests passed! System is ready for production use."
    else
        log_warn "$total_failed tests failed. Review the output above for details."
        echo ""
        echo -e "${WHITE}Recommended actions:${NC}"
        echo "1. Run ./install-server.sh to install missing components"
        echo "2. Check specific service configurations"
        echo "3. Review installation logs for errors"
    fi
}

# Reset installation (clear checkpoints)
reset_installation() {
    echo -e "${RED}WARNING: This will reset all installation checkpoints!${NC}"
    echo "This means the next run of install-server.sh will start from the beginning."
    echo ""
    read -p "Are you sure you want to reset? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -f "$CHECKPOINT_FILE" ]]; then
            rm "$CHECKPOINT_FILE"
            log_ok "Installation checkpoints reset"
        else
            log_info "No checkpoint file found"
        fi
    else
        log_info "Reset cancelled"
    fi
}

# Resume installation from last checkpoint
resume_installation() {
    if [[ ! -f "$CHECKPOINT_FILE" ]]; then
        log_error "No checkpoint file found. Run ./install-server.sh to start fresh installation."
        return 1
    fi
    
    log_info "Resuming installation from last checkpoint..."
    exec "$SCRIPT_DIR/install-server.sh"
}

# Main menu
main_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              INSTALLATION TEST & MANAGEMENT                 ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}Installation Management:${NC}"
        echo "1) Show installation status"
        echo "2) Resume installation"
        echo "3) Reset installation checkpoints"
        echo ""
        echo -e "${WHITE}Component Testing:${NC}"
        echo "4) Test web stack components"
        echo "5) Test database stack components"
        echo "6) Test mail stack components"
        echo "7) Test DNS stack components"
        echo "8) Test SSL/security components"
        echo ""
        echo -e "${WHITE}System Testing:${NC}"
        echo "9) Run comprehensive test"
        echo "10) View installation logs"
        echo ""
        echo -e "${RED}0) Exit${NC}"
        echo ""
        
        read -p "Select an option [0-10]: " choice
        
        case $choice in
            1) show_installation_status; read -p "Press Enter to continue..." ;;
            2) resume_installation ;;
            3) reset_installation; read -p "Press Enter to continue..." ;;
            4) test_web_stack; read -p "Press Enter to continue..." ;;
            5) test_database_stack; read -p "Press Enter to continue..." ;;
            6) test_mail_stack; read -p "Press Enter to continue..." ;;
            7) test_dns_stack; read -p "Press Enter to continue..." ;;
            8) test_ssl_security; read -p "Press Enter to continue..." ;;
            9) run_comprehensive_test; read -p "Press Enter to continue..." ;;
            10) 
                if [[ -f "$INSTALL_LOG" ]]; then
                    less "$INSTALL_LOG"
                else
                    log_warn "No installation log found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            0) log_info "Goodbye!"; exit 0 ;;
            *) log_error "Invalid option. Please try again."; sleep 2 ;;
        esac
    done
}

# Run main menu
main_menu
