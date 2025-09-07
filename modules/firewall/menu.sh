#!/bin/bash
# Firewall System Interactive Menu
# Purpose: Main menu interface for firewall system management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Source functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

# Function to display banner
show_banner() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    FIREWALL SYSTEM MANAGER                  ║${NC}"
    echo -e "${BLUE}║                  Advanced Security Control                   ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Function to display system status
show_system_status() {
    echo -e "${CYAN}System Status:${NC}"
    
    # Check UFW status
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            echo -e "${GREEN}  ✓ UFW Firewall: Active${NC}"
        else
            echo -e "${RED}  ✗ UFW Firewall: Inactive${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠ UFW: Not installed${NC}"
    fi
    
    # Check fail2ban status
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        echo -e "${GREEN}  ✓ Fail2ban: Active${NC}"
        local banned_count=$(fail2ban-client status 2>/dev/null | grep -o "Currently banned:.*" | grep -o "[0-9]*" 2>/dev/null || echo "0")
        echo -e "${CYAN}    Currently banned IPs: $banned_count${NC}"
    else
        echo -e "${RED}  ✗ Fail2ban: Inactive${NC}"
    fi
    
    # Check iptables
    if command -v iptables >/dev/null 2>&1; then
        local rule_count=$(iptables -L 2>/dev/null | grep -c "^Chain " 2>/dev/null || echo "0")
        echo -e "${GREEN}  ✓ iptables: Available ($rule_count chains)${NC}"
    else
        echo -e "${YELLOW}  ⚠ iptables: Not available${NC}"
    fi
    
    echo
}

# Function to display main menu
show_main_menu() {
    show_banner
    show_system_status
    
    echo -e "${BLUE}Main Menu Options:${NC}"
    echo
    echo -e "${GREEN}INSTALLATION & SETUP${NC}"
    echo -e "  ${CYAN}1)${NC} Install firewall system"
    echo -e "  ${CYAN}2)${NC} Update firewall system"
    echo -e "  ${CYAN}3)${NC} Configure basic settings"
    echo
    echo -e "${GREEN}FIREWALL MANAGEMENT${NC}"
    echo -e "  ${CYAN}4)${NC} Quick firewall setup"
    echo -e "  ${CYAN}5)${NC} Manage firewall rules"
    echo -e "  ${CYAN}6)${NC} View current configuration"
    echo -e "  ${CYAN}7)${NC} Test port connectivity"
    echo
    echo -e "${GREEN}SECURITY & MONITORING${NC}"
    echo -e "  ${CYAN}8)${NC} Block/Unblock IP addresses"
    echo -e "  ${CYAN}9)${NC} View blocked IPs and logs"
    echo -e "  ${CYAN}10)${NC} Security health check"
    echo -e "  ${CYAN}11)${NC} Monitor security events"
    echo
    echo -e "${GREEN}SERVICE MANAGEMENT${NC}"
    echo -e "  ${CYAN}12)${NC} Start/Stop/Restart services"
    echo -e "  ${CYAN}13)${NC} Service status check"
    echo -e "  ${CYAN}14)${NC} Configure fail2ban jails"
    echo
    echo -e "${GREEN}MAINTENANCE & BACKUP${NC}"
    echo -e "  ${CYAN}15)${NC} System maintenance"
    echo -e "  ${CYAN}16)${NC} Backup/Restore configuration"
    echo -e "  ${CYAN}17)${NC} View system logs"
    echo
    echo -e "${GREEN}ADVANCED OPTIONS${NC}"
    echo -e "  ${CYAN}18)${NC} Custom rule configuration"
    echo -e "  ${CYAN}19)${NC} Emergency procedures"
    echo -e "  ${CYAN}20)${NC} System information"
    echo
    echo -e "${YELLOW}0) Exit${NC}"
    echo
}

# Function to install firewall system
install_system() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Installation requires root privileges${NC}"
        echo -e "${YELLOW}Please run: sudo $SCRIPT_DIR/install.sh${NC}"
        sleep 3
        return
    fi
    
    echo -e "${YELLOW}Starting firewall system installation...${NC}"
    "$SCRIPT_DIR/install.sh"
    echo
    read -p "Press Enter to continue..."
}

# Function to update system
update_system() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Update requires root privileges${NC}"
        echo -e "${YELLOW}Please run: sudo $SCRIPT_DIR/update.sh${NC}"
        sleep 3
        return
    fi
    
    echo -e "${YELLOW}Starting firewall system update...${NC}"
    "$SCRIPT_DIR/update.sh"
    echo
    read -p "Press Enter to continue..."
}

# Function to configure basic settings
configure_basic_settings() {
    clear
    echo -e "${BLUE}Basic Firewall Configuration${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Configuration requires root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}This will configure basic firewall settings:${NC}"
    echo -e "• Default policies"
    echo -e "• SSH access"
    echo -e "• Common services"
    echo
    
    read -p "Continue with basic configuration? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        configure_basic_firewall
        echo -e "${GREEN}Basic configuration completed${NC}"
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Function for quick firewall setup
quick_setup() {
    clear
    echo -e "${BLUE}Quick Firewall Setup${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Setup requires root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Quick setup options:${NC}"
    echo -e "1) Web server (HTTP/HTTPS)"
    echo -e "2) Mail server (SMTP/IMAP/POP3)"
    echo -e "3) Database server (MySQL/PostgreSQL)"
    echo -e "4) SSH only"
    echo -e "5) Custom configuration"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select setup type [0-5]: " setup_type
    
    case $setup_type in
        1)
            add_firewall_rule "80" "tcp" "HTTP"
            add_firewall_rule "443" "tcp" "HTTPS"
            echo -e "${GREEN}Web server rules added${NC}"
            ;;
        2)
            add_firewall_rule "25" "tcp" "SMTP"
            add_firewall_rule "587" "tcp" "SMTP Submission"
            add_firewall_rule "993" "tcp" "IMAPS"
            add_firewall_rule "995" "tcp" "POP3S"
            echo -e "${GREEN}Mail server rules added${NC}"
            ;;
        3)
            read -p "MySQL/MariaDB port (3306)? (y/N): " mysql_confirm
            if [[ $mysql_confirm =~ ^[Yy]$ ]]; then
                add_firewall_rule "3306" "tcp" "MySQL/MariaDB"
            fi
            
            read -p "PostgreSQL port (5432)? (y/N): " postgres_confirm
            if [[ $postgres_confirm =~ ^[Yy]$ ]]; then
                add_firewall_rule "5432" "tcp" "PostgreSQL"
            fi
            
            read -p "MongoDB port (27017)? (y/N): " mongo_confirm
            if [[ $mongo_confirm =~ ^[Yy]$ ]]; then
                add_firewall_rule "27017" "tcp" "MongoDB"
            fi
            echo -e "${GREEN}Database server rules added${NC}"
            ;;
        4)
            configure_ssh_firewall
            echo -e "${GREEN}SSH-only configuration completed${NC}"
            ;;
        5)
            "$SCRIPT_DIR/maintain.sh"
            return
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function to manage firewall rules
manage_rules() {
    "$SCRIPT_DIR/maintain.sh"
}

# Function to view current configuration
view_configuration() {
    clear
    echo -e "${BLUE}Current Firewall Configuration${NC}"
    echo
    
    # UFW status and rules
    if command -v ufw >/dev/null 2>&1; then
        echo -e "${CYAN}UFW Status and Rules:${NC}"
        ufw status verbose
        echo
    fi
    
    # Fail2ban status
    if systemctl is-active --quiet fail2ban; then
        echo -e "${CYAN}Fail2ban Status:${NC}"
        fail2ban-client status
        echo
    fi
    
    # iptables summary
    echo -e "${CYAN}iptables Rules Summary:${NC}"
    iptables -L -n | head -20
    echo
    
    read -p "Press Enter to continue..."
}

# Function to test connectivity
test_connectivity() {
    clear
    echo -e "${BLUE}Port Connectivity Test${NC}"
    echo
    
    read -p "Enter host to test [localhost]: " test_host
    test_host=${test_host:-localhost}
    
    read -p "Enter port to test: " test_port
    
    if [[ -n "$test_port" ]]; then
        test_port "$test_host" "$test_port"
    else
        echo -e "${RED}Port number is required${NC}"
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Function for IP management
manage_ips() {
    clear
    echo -e "${BLUE}IP Address Management${NC}"
    echo
    echo -e "${GREEN}Options:${NC}"
    echo -e "1) Block IP address"
    echo -e "2) Unblock IP address"
    echo -e "3) View blocked IPs"
    echo -e "4) Block IP range"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select option [0-4]: " ip_choice
    
    case $ip_choice in
        1)
            read -p "Enter IP address to block: " ip_addr
            if [[ -n "$ip_addr" ]]; then
                if [[ $EUID -eq 0 ]]; then
                    block_ip "$ip_addr"
                    echo -e "${GREEN}IP address blocked successfully${NC}"
                else
                    echo -e "${RED}Root privileges required to block IPs${NC}"
                fi
            fi
            ;;
        2)
            read -p "Enter IP address to unblock: " ip_addr
            if [[ -n "$ip_addr" ]]; then
                if [[ $EUID -eq 0 ]]; then
                    unblock_ip "$ip_addr"
                    echo -e "${GREEN}IP address unblocked successfully${NC}"
                else
                    echo -e "${RED}Root privileges required to unblock IPs${NC}"
                fi
            fi
            ;;
        3)
            echo -e "${CYAN}Blocked IP Addresses:${NC}"
            if command -v ufw >/dev/null 2>&1; then
                ufw status | grep DENY || echo "No IPs explicitly denied by UFW"
            fi
            if systemctl is-active --quiet fail2ban; then
                echo -e "${CYAN}IPs blocked by fail2ban:${NC}"
                fail2ban-client status | grep "Jail list"
            fi
            ;;
        4)
            read -p "Enter IP range to block (e.g., 192.168.1.0/24): " ip_range
            if [[ -n "$ip_range" ]]; then
                if [[ $EUID -eq 0 ]]; then
                    block_ip_range "$ip_range"
                    echo -e "${GREEN}IP range blocked successfully${NC}"
                else
                    echo -e "${RED}Root privileges required to block IP ranges${NC}"
                fi
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function to view logs and monitoring
view_monitoring() {
    clear
    echo -e "${BLUE}Security Monitoring${NC}"
    echo
    echo -e "${GREEN}Monitoring Options:${NC}"
    echo -e "1) Real-time log monitoring"
    echo -e "2) Recent security events"
    echo -e "3) Fail2ban activity"
    echo -e "4) UFW firewall logs"
    echo -e "5) Connection attempts"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select option [0-5]: " monitor_choice
    
    case $monitor_choice in
        1)
            echo -e "${YELLOW}Starting real-time log monitoring (Ctrl+C to stop)...${NC}"
            tail -f /var/log/fail2ban.log /var/log/ufw.log 2>/dev/null || echo "Log files not found"
            ;;
        2)
            echo -e "${CYAN}Recent Security Events:${NC}"
            show_firewall_logs 20
            ;;
        3)
            if systemctl is-active --quiet fail2ban; then
                echo -e "${CYAN}Fail2ban Activity:${NC}"
                tail -20 /var/log/fail2ban.log 2>/dev/null || echo "No fail2ban logs found"
            else
                echo -e "${RED}Fail2ban is not running${NC}"
            fi
            ;;
        4)
            echo -e "${CYAN}UFW Firewall Logs:${NC}"
            tail -20 /var/log/ufw.log 2>/dev/null || echo "No UFW logs found"
            ;;
        5)
            echo -e "${CYAN}Recent Connection Attempts:${NC}"
            journalctl -u ssh -n 20 --no-pager
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function for security health check
security_health() {
    echo -e "${YELLOW}Performing comprehensive security health check...${NC}"
    echo
    
    get_security_summary
    echo
    
    echo -e "${BLUE}Recommendations:${NC}"
    
    # Check for common issues
    if ! command -v ufw >/dev/null 2>&1; then
        echo -e "${YELLOW}• Install UFW for easier firewall management${NC}"
    elif ! ufw status | grep -q "Status: active"; then
        echo -e "${YELLOW}• Enable UFW firewall${NC}"
    fi
    
    if ! systemctl is-active --quiet fail2ban; then
        echo -e "${YELLOW}• Install and configure fail2ban for intrusion prevention${NC}"
    fi
    
    if grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config 2>/dev/null; then
        echo -e "${YELLOW}• Consider disabling SSH password authentication${NC}"
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Function for service management
manage_services() {
    clear
    echo -e "${BLUE}Service Management${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Service management requires root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${GREEN}Service Options:${NC}"
    echo -e "1) Start all firewall services"
    echo -e "2) Stop all firewall services"
    echo -e "3) Restart all firewall services"
    echo -e "4) Check service status"
    echo -e "5) Enable services at boot"
    echo -e "6) Disable services at boot"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select option [0-6]: " service_choice
    
    case $service_choice in
        1)
            echo -e "${YELLOW}Starting firewall services...${NC}"
            start_firewall_services
            ;;
        2)
            echo -e "${YELLOW}Stopping firewall services...${NC}"
            stop_firewall_services
            ;;
        3)
            echo -e "${YELLOW}Restarting firewall services...${NC}"
            restart_firewall_services
            ;;
        4)
            check_firewall_status
            ;;
        5)
            echo -e "${YELLOW}Enabling services at boot...${NC}"
            systemctl enable fail2ban
            echo -e "${GREEN}Services enabled at boot${NC}"
            ;;
        6)
            echo -e "${YELLOW}Disabling services at boot...${NC}"
            systemctl disable fail2ban
            echo -e "${GREEN}Services disabled at boot${NC}"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function for emergency procedures
emergency_procedures() {
    clear
    echo -e "${RED}EMERGENCY PROCEDURES${NC}"
    echo -e "${YELLOW}⚠ Use these options only in emergency situations ⚠${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Emergency procedures require root privileges${NC}"
        sleep 2
        return
    fi
    
    echo -e "${GREEN}Emergency Options:${NC}"
    echo -e "1) Disable all firewall rules (EMERGENCY ACCESS)"
    echo -e "2) Reset firewall to defaults"
    echo -e "3) Unban all IPs from fail2ban"
    echo -e "4) Create emergency SSH access"
    echo -e "5) Backup current config before changes"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select emergency option [0-5]: " emergency_choice
    
    case $emergency_choice in
        1)
            echo -e "${RED}WARNING: This will disable ALL firewall protection!${NC}"
            read -p "Are you absolutely sure? Type 'EMERGENCY' to confirm: " confirm
            if [[ "$confirm" == "EMERGENCY" ]]; then
                ufw --force reset
                ufw --force disable
                echo -e "${YELLOW}All firewall rules disabled${NC}"
            else
                echo -e "${GREEN}Emergency action cancelled${NC}"
            fi
            ;;
        2)
            read -p "Reset firewall to secure defaults? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                configure_basic_firewall
                echo -e "${GREEN}Firewall reset to defaults${NC}"
            fi
            ;;
        3)
            if systemctl is-active --quiet fail2ban; then
                fail2ban-client unban --all
                echo -e "${GREEN}All IPs unbanned from fail2ban${NC}"
            else
                echo -e "${RED}Fail2ban is not running${NC}"
            fi
            ;;
        4)
            echo -e "${YELLOW}Creating emergency SSH access...${NC}"
            ufw allow ssh
            echo -e "${GREEN}Emergency SSH access enabled${NC}"
            ;;
        5)
            backup_firewall_config
            echo -e "${GREEN}Emergency backup created${NC}"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function to show system information
show_system_info() {
    clear
    echo -e "${BLUE}System Information${NC}"
    echo
    
    echo -e "${CYAN}Firewall Components:${NC}"
    command -v ufw >/dev/null 2>&1 && echo -e "  UFW: $(ufw version 2>/dev/null | head -1)" || echo -e "  UFW: Not installed"
    command -v iptables >/dev/null 2>&1 && echo -e "  iptables: $(iptables --version 2>/dev/null | head -1)" || echo -e "  iptables: Not available"
    systemctl is-active --quiet fail2ban && echo -e "  fail2ban: Active" || echo -e "  fail2ban: Inactive"
    
    echo
    echo -e "${CYAN}Network Configuration:${NC}"
    echo -e "  Hostname: $(hostname)"
    echo -e "  IP Addresses:"
    ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print "    " $2}'
    
    echo
    echo -e "${CYAN}Security Status:${NC}"
    local open_ports=$(ss -tlnp 2>/dev/null | grep LISTEN | wc -l)
    echo -e "  Open listening ports: $open_ports"
    
    if systemctl is-active --quiet fail2ban; then
        local banned_ips=$(fail2ban-client status 2>/dev/null | grep -o "Currently banned:.*" | grep -o "[0-9]*" || echo "0")
        echo -e "  Currently banned IPs: $banned_ips"
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Main menu loop
while true; do
    show_main_menu
    read -p "Select an option [0-20]: " choice
    
    case $choice in
        1) install_system ;;
        2) update_system ;;
        3) configure_basic_settings ;;
        4) quick_setup ;;
        5) manage_rules ;;
        6) view_configuration ;;
        7) test_connectivity ;;
        8) manage_ips ;;
        9) view_monitoring ;;
        10) security_health ;;
        11) view_monitoring ;;
        12) manage_services ;;
        13) check_firewall_status; read -p "Press Enter to continue..." ;;
        14) configure_fail2ban_jails; read -p "Press Enter to continue..." ;;
        15) "$SCRIPT_DIR/maintain.sh" ;;
        16) 
            if [[ $EUID -eq 0 ]]; then
                backup_firewall_config
                echo -e "${GREEN}Configuration backup completed${NC}"
            else
                echo -e "${RED}Backup requires root privileges${NC}"
            fi
            read -p "Press Enter to continue..."
            ;;
        17) view_monitoring ;;
        18) manage_rules ;;
        19) emergency_procedures ;;
        20) show_system_info ;;
        0)
            echo -e "${YELLOW}Thank you for using Firewall System Manager!${NC}"
            echo -e "${CYAN}Remember to regularly check your security status.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 2
            ;;
    esac
done
