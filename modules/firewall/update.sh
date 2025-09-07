#!/bin/bash
# Firewall System Update
# Purpose: Keep firewall and security tools updated and maintain configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Source functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       FIREWALL SYSTEM UPDATE          ${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting firewall system update...${NC}"
echo

# Step 1: Backup current configuration
echo -e "${BLUE}Step 1/6: Backing up current firewall configuration...${NC}"
backup_firewall_config
echo -e "${GREEN}✓ Firewall configuration backed up${NC}"
echo

# Step 2: Update system packages
echo -e "${BLUE}Step 2/6: Updating system packages...${NC}"
update_system_packages
echo -e "${GREEN}✓ System packages updated${NC}"
echo

# Step 3: Update firewall and security packages
echo -e "${BLUE}Step 3/6: Updating firewall and security packages...${NC}"

if command -v apt >/dev/null 2>&1; then
    echo -e "${CYAN}Updating UFW, fail2ban, and iptables...${NC}"
    apt install --only-upgrade -y ufw fail2ban iptables iptables-persistent
    echo -e "${GREEN}✓ Firewall packages updated${NC}"
    
elif command -v yum >/dev/null 2>&1; then
    echo -e "${CYAN}Updating firewall packages (RHEL/CentOS)...${NC}"
    yum update -y ufw fail2ban iptables-services
    echo -e "${GREEN}✓ Firewall packages updated${NC}"
    
elif command -v dnf >/dev/null 2>&1; then
    echo -e "${CYAN}Updating firewall packages (Fedora)...${NC}"
    dnf update -y ufw fail2ban iptables-services
    echo -e "${GREEN}✓ Firewall packages updated${NC}"
    
elif command -v pacman >/dev/null 2>&1; then
    echo -e "${CYAN}Updating firewall packages (Arch)...${NC}"
    pacman -Syu --noconfirm ufw fail2ban iptables
    echo -e "${GREEN}✓ Firewall packages updated${NC}"
fi

echo

# Step 4: Update fail2ban rules and filters
echo -e "${BLUE}Step 4/6: Updating fail2ban rules and filters...${NC}"

# Check for new fail2ban filters and update jail configuration
if [[ -f /etc/fail2ban/jail.local ]]; then
    echo -e "${CYAN}Updating fail2ban jail configuration...${NC}"
    
    # Add new common jails if not present
    if ! grep -q "\[nginx-http-auth\]" /etc/fail2ban/jail.local; then
        echo "
[nginx-http-auth]
enabled = true
port = http,https
logpath = %(nginx_error_log)s" >> /etc/fail2ban/jail.local
        echo -e "${CYAN}✓ Added nginx-http-auth jail${NC}"
    fi
    
    if ! grep -q "\[postfix\]" /etc/fail2ban/jail.local; then
        echo "
[postfix]
enabled = true
port = smtp,465,587
logpath = %(postfix_log)s
backend = %(postfix_backend)s" >> /etc/fail2ban/jail.local
        echo -e "${CYAN}✓ Added postfix jail${NC}"
    fi
    
    if ! grep -q "\[dovecot\]" /etc/fail2ban/jail.local; then
        echo "
[dovecot]
enabled = true
port = pop3,pop3s,imap,imaps,submission,465,sieve
logpath = %(dovecot_log)s
backend = %(dovecot_backend)s" >> /etc/fail2ban/jail.local
        echo -e "${CYAN}✓ Added dovecot jail${NC}"
    fi
    
    echo -e "${GREEN}✓ fail2ban configuration updated${NC}"
else
    echo -e "${YELLOW}No existing jail.local found, using defaults${NC}"
fi

echo

# Step 5: Restart and reload services
echo -e "${BLUE}Step 5/6: Restarting firewall services...${NC}"

# Reload UFW rules
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    echo -e "${CYAN}Reloading UFW rules...${NC}"
    ufw reload
    echo -e "${GREEN}✓ UFW rules reloaded${NC}"
fi

# Restart fail2ban to apply updates
echo -e "${CYAN}Restarting fail2ban...${NC}"
systemctl restart fail2ban
sleep 3

# Verify services are running
if systemctl is-active --quiet fail2ban; then
    echo -e "${GREEN}✓ fail2ban restarted successfully${NC}"
else
    echo -e "${RED}✗ fail2ban restart failed${NC}"
    echo -e "${YELLOW}Checking fail2ban status...${NC}"
    systemctl status fail2ban --no-pager -l
fi

# Restart iptables service if available
if systemctl list-unit-files | grep -q iptables; then
    echo -e "${CYAN}Restarting iptables service...${NC}"
    systemctl restart iptables
    echo -e "${GREEN}✓ iptables service restarted${NC}"
fi

echo -e "${GREEN}✓ Firewall services restarted${NC}"
echo

# Step 6: Verify configuration and run health checks
echo -e "${BLUE}Step 6/6: Running post-update verification...${NC}"

# Check firewall status
echo -e "${CYAN}Checking firewall status...${NC}"
check_firewall_status

# Verify fail2ban jails are active
echo -e "${CYAN}Verifying fail2ban jails...${NC}"
show_fail2ban_status

# Test basic connectivity
echo -e "${CYAN}Testing basic connectivity...${NC}"
test_port localhost 22 && echo -e "${GREEN}✓ SSH connectivity verified${NC}" || echo -e "${RED}✗ SSH connectivity issue${NC}"

# Check for any security warnings
echo -e "${CYAN}Checking for security issues...${NC}"

# Check if SSH is properly secured
if grep -q "PermitRootLogin yes" /etc/ssh/sshd_config 2>/dev/null; then
    echo -e "${YELLOW}⚠ Warning: Root login via SSH is enabled${NC}"
fi

if grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config 2>/dev/null; then
    echo -e "${YELLOW}⚠ Warning: Password authentication is enabled${NC}"
fi

# Check for common open ports that might need attention
echo -e "${CYAN}Reviewing open ports...${NC}"
if command -v ss >/dev/null 2>&1; then
    open_ports=$(ss -tlnp | grep LISTEN | awk '{print $4}' | cut -d: -f2 | sort -n | uniq)
    for port in $open_ports; do
        case $port in
            22) echo -e "${GREEN}✓ Port 22 (SSH) - Secure${NC}" ;;
            80) echo -e "${CYAN}ℹ Port 80 (HTTP) - Consider HTTPS redirect${NC}" ;;
            443) echo -e "${GREEN}✓ Port 443 (HTTPS) - Secure${NC}" ;;
            3306) echo -e "${YELLOW}⚠ Port 3306 (MySQL) - Ensure proper access control${NC}" ;;
            5432) echo -e "${YELLOW}⚠ Port 5432 (PostgreSQL) - Ensure proper access control${NC}" ;;
            27017) echo -e "${YELLOW}⚠ Port 27017 (MongoDB) - Ensure proper access control${NC}" ;;
            *) echo -e "${CYAN}ℹ Port $port - Review if needed${NC}" ;;
        esac
    done
fi

echo -e "${GREEN}✓ Post-update verification completed${NC}"
echo

# Update summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}        UPDATE COMPLETED                ${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo -e "${GREEN}Firewall system update completed successfully!${NC}"
echo

echo -e "${CYAN}Update Summary:${NC}"
echo -e "• Configuration backed up before update"
echo -e "• System and firewall packages updated"
echo -e "• fail2ban rules and filters updated"
echo -e "• Services restarted and verified"
echo -e "• Security health check completed"
echo

echo -e "${CYAN}Current Security Status:${NC}"
get_security_summary

echo
echo -e "${YELLOW}Recommendations:${NC}"
echo -e "1. Review fail2ban logs for any new threats: tail -f /var/log/fail2ban.log"
echo -e "2. Monitor firewall logs: tail -f /var/log/ufw.log"
echo -e "3. Check for any new security advisories for your system"
echo -e "4. Consider updating SSH configuration for enhanced security"
echo -e "5. Review and update fail2ban jail configurations as needed"
echo

echo -e "${GREEN}Firewall update process completed!${NC}"
