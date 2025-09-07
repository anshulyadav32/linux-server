#!/bin/bash
# =============================================================================
# Linux Setup - Quick Installation Checker
# =============================================================================
# Simple status checker for quick verification
# =============================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Counters
INSTALLED=0
NOT_INSTALLED=0

check_service() {
    local service="$1"
    local name="$2"
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $name: ${GREEN}Running${NC}"
        ((INSTALLED++))
    elif systemctl list-unit-files | grep -q "^$service.service"; then
        echo -e "${YELLOW}⚠${NC} $name: ${YELLOW}Installed but not running${NC}"
        ((NOT_INSTALLED++))
    else
        echo -e "${RED}✗${NC} $name: ${RED}Not installed${NC}"
        ((NOT_INSTALLED++))
    fi
}

check_command() {
    local cmd="$1"
    local name="$2"
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $name: ${GREEN}Installed${NC}"
        ((INSTALLED++))
    else
        echo -e "${RED}✗${NC} $name: ${RED}Not installed${NC}"
        ((NOT_INSTALLED++))
    fi
}

echo -e "${WHITE}=== QUICK INSTALLATION STATUS CHECK ===${NC}"
echo ""

echo -e "${CYAN}Web Servers:${NC}"
check_service "nginx" "Nginx"
check_service "apache2" "Apache"
check_command "php" "PHP"

echo ""
echo -e "${CYAN}Database Servers:${NC}"
check_service "mysql" "MySQL"
check_service "postgresql" "PostgreSQL"

echo ""
echo -e "${CYAN}Mail Servers:${NC}"
check_service "postfix" "Postfix"
check_service "dovecot" "Dovecot"

echo ""
echo -e "${CYAN}DNS & Security:${NC}"
check_service "bind9" "BIND9 DNS"
check_service "fail2ban" "Fail2Ban"
check_command "ufw" "UFW Firewall"

echo ""
echo -e "${CYAN}Essential Tools:${NC}"
check_command "git" "Git"
check_command "node" "Node.js"
check_command "certbot" "Certbot SSL"

echo ""
echo -e "${WHITE}=== SUMMARY ===${NC}"
echo -e "${GREEN}✓ Installed/Running: $INSTALLED${NC}"
echo -e "${RED}✗ Not Installed/Running: $NOT_INSTALLED${NC}"

TOTAL=$((INSTALLED + NOT_INSTALLED))
if [[ $TOTAL -gt 0 ]]; then
    PERCENTAGE=$((INSTALLED * 100 / TOTAL))
    echo -e "${BLUE}📊 Completion: $PERCENTAGE%${NC}"
fi

echo ""
if [[ $NOT_INSTALLED -gt 0 ]]; then
    echo -e "${YELLOW}To install missing components:${NC}"
    echo -e "${CYAN}sudo ./server-installer.sh${NC}"
    echo ""
    echo -e "${YELLOW}For detailed status check:${NC}"
    echo -e "${CYAN}./system-status-checker.sh${NC}"
else
    echo -e "${GREEN}🎉 All essential components are installed!${NC}"
    echo -e "${GREEN}Run: ${CYAN}server-manager${NC} ${GREEN}to start managing your server${NC}"
fi
echo ""
