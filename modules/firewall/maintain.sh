#!/bin/bash
# Firewall System Maintenance
# Purpose: Daily operational checks and maintenance for firewall and security

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
echo -e "${BLUE}      FIREWALL SYSTEM MAINTENANCE      ${NC}"
echo -e "${BLUE}========================================${NC}"

# Function to show maintenance menu
show_maintenance_menu() {
    clear
    echo -e "${BLUE}Firewall System Maintenance Options:${NC}"
    echo -e "${GREEN}1)${NC} Check firewall status"
    echo -e "${GREEN}2)${NC} View firewall rules"
    echo -e "${GREEN}3)${NC} Check fail2ban status"
    echo -e "${GREEN}4)${NC} View blocked IPs"
    echo -e "${GREEN}5)${NC} Add/Remove firewall rules"
    echo -e "${GREEN}6)${NC} Block/Unblock IP addresses"
    echo -e "${GREEN}7)${NC} Test port connectivity"
    echo -e "${GREEN}8)${NC} View security logs"
    echo -e "${GREEN}9)${NC} Restart firewall services"
    echo -e "${GREEN}10)${NC} Security health check"
    echo -e "${GREEN}11)${NC} Backup/Restore configuration"
    echo -e "${YELLOW}0)${NC} Return to main menu"
    echo
}

# Function to check firewall status
check_status() {
    echo -e "${YELLOW}Checking firewall status...${NC}"
    echo
    check_firewall_status
    echo
    get_security_summary
    echo
    read -p "Press Enter to continue..."
}

# Function to view firewall rules
view_rules() {
    clear
    echo -e "${BLUE}Current Firewall Rules${NC}"
    echo
    
    if command -v ufw >/dev/null 2>&1; then
        echo -e "${CYAN}UFW Rules:${NC}"
        ufw status numbered
        echo
    fi
    
    echo -e "${CYAN}iptables Rules:${NC}"
    iptables -L -n --line-numbers
    echo
    
    read -p "Press Enter to continue..."
}

# Function to check fail2ban status
check_fail2ban() {
    echo -e "${YELLOW}Checking fail2ban status...${NC}"
    echo
    show_fail2ban_status
    echo
    read -p "Press Enter to continue..."
}

# Function to view blocked IPs
view_blocked_ips() {
    clear
    echo -e "${BLUE}Blocked IP Addresses${NC}"
    echo
    
    if systemctl is-active --quiet fail2ban; then
        echo -e "${CYAN}IPs blocked by fail2ban:${NC}"
        local jails=$(fail2ban-client status | grep "Jail list" | cut -d: -f2 | tr ',' ' ')
        for jail in $jails; do
            jail=$(echo $jail | xargs) # trim whitespace
            if [[ -n "$jail" ]]; then
                echo -e "${YELLOW}Jail: $jail${NC}"
                fail2ban-client status "$jail" | grep "Banned IP"
                echo
            fi
        done
    else
        echo -e "${RED}fail2ban is not running${NC}"
    fi
    
    echo -e "${CYAN}IPs blocked by UFW:${NC}"
    if command -v ufw >/dev/null 2>&1; then
        ufw status | grep DENY || echo "No IPs explicitly denied by UFW"
    fi
    echo
    
    read -p "Press Enter to continue..."
}

# Function to manage firewall rules
manage_rules() {
    clear
    echo -e "${BLUE}Firewall Rule Management${NC}"
    echo
    echo -e "${GREEN}Options:${NC}"
    echo -e "1) Add rule"
    echo -e "2) Remove rule"
    echo -e "3) List current rules"
    echo -e "0) Back to maintenance menu"
    echo
    
    read -p "Select option [0-3]: " rule_choice
    
    case $rule_choice in
        1)
            echo -e "${CYAN}Add Firewall Rule${NC}"
            read -p "Enter port number: " port
            read -p "Enter protocol (tcp/udp) [tcp]: " protocol
            protocol=${protocol:-tcp}
            read -p "Enter description: " description
            
            if [[ -n "$port" ]]; then
                add_firewall_rule "$port" "$protocol" "$description"
                echo -e "${GREEN}Rule added successfully${NC}"
            else
                echo -e "${RED}Port number is required${NC}"
            fi
            ;;
        2)
            echo -e "${CYAN}Remove Firewall Rule${NC}"
            if command -v ufw >/dev/null 2>&1; then
                echo "Current rules:"
                ufw status numbered
                echo
                read -p "Enter rule number to delete: " rule_num
                if [[ -n "$rule_num" ]]; then
                    ufw delete "$rule_num"
                    echo -e "${GREEN}Rule removed successfully${NC}"
                fi
            else
                read -p "Enter port number: " port
                read -p "Enter protocol (tcp/udp) [tcp]: " protocol
                protocol=${protocol:-tcp}
                
                if [[ -n "$port" ]]; then
                    remove_firewall_rule "$port" "$protocol"
                    echo -e "${GREEN}Rule removed successfully${NC}"
                fi
            fi
            ;;
        3)
            view_rules
            return
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to manage IP blocking
manage_ip_blocking() {
    clear
    echo -e "${BLUE}IP Address Management${NC}"
    echo
    echo -e "${GREEN}Options:${NC}"
    echo -e "1) Block IP address"
    echo -e "2) Unblock IP address"
    echo -e "3) View blocked IPs"
    echo -e "4) Unban IP from fail2ban"
    echo -e "0) Back to maintenance menu"
    echo
    
    read -p "Select option [0-4]: " ip_choice
    
    case $ip_choice in
        1)
            echo -e "${CYAN}Block IP Address${NC}"
            read -p "Enter IP address to block: " ip_addr
            
            if [[ -n "$ip_addr" ]]; then
                block_ip "$ip_addr"
                echo -e "${GREEN}IP address blocked successfully${NC}"
            else
                echo -e "${RED}IP address is required${NC}"
            fi
            ;;
        2)
            echo -e "${CYAN}Unblock IP Address${NC}"
            read -p "Enter IP address to unblock: " ip_addr
            
            if [[ -n "$ip_addr" ]]; then
                unblock_ip "$ip_addr"
                echo -e "${GREEN}IP address unblocked successfully${NC}"
            else
                echo -e "${RED}IP address is required${NC}"
            fi
            ;;
        3)
            view_blocked_ips
            return
            ;;
        4)
            echo -e "${CYAN}Unban IP from fail2ban${NC}"
            if systemctl is-active --quiet fail2ban; then
                echo "Active jails:"
                fail2ban-client status | grep "Jail list"
                echo
                read -p "Enter jail name: " jail_name
                read -p "Enter IP address to unban: " ip_addr
                
                if [[ -n "$jail_name" && -n "$ip_addr" ]]; then
                    fail2ban-client set "$jail_name" unbanip "$ip_addr"
                    echo -e "${GREEN}IP unbanned from jail successfully${NC}"
                fi
            else
                echo -e "${RED}fail2ban is not running${NC}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to test port connectivity
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

# Function to view security logs
view_security_logs() {
    clear
    echo -e "${BLUE}Security Logs${NC}"
    echo -e "${CYAN}1)${NC} UFW firewall logs"
    echo -e "${CYAN}2)${NC} fail2ban logs"
    echo -e "${CYAN}3)${NC} System security logs"
    echo -e "${CYAN}4)${NC} All security logs"
    echo -e "${CYAN}5)${NC} Back to maintenance menu"
    echo
    
    read -p "Select option [1-5]: " log_choice
    
    case $log_choice in
        1)
            echo -e "${YELLOW}UFW firewall logs:${NC}"
            if [[ -f /var/log/ufw.log ]]; then
                tail -50 /var/log/ufw.log
            else
                echo "No UFW log file found"
            fi
            ;;
        2)
            echo -e "${YELLOW}fail2ban logs:${NC}"
            if [[ -f /var/log/fail2ban.log ]]; then
                tail -50 /var/log/fail2ban.log
            else
                echo "No fail2ban log file found"
            fi
            ;;
        3)
            echo -e "${YELLOW}System security logs:${NC}"
            journalctl -u ssh -n 20 --no-pager
            ;;
        4)
            echo -e "${YELLOW}All security logs (recent):${NC}"
            show_firewall_logs 20
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
}

# Function to restart services
restart_services() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required to restart services${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}Restarting firewall services...${NC}"
    echo
    
    # Restart fail2ban
    echo -e "${CYAN}Restarting fail2ban...${NC}"
    systemctl restart fail2ban
    sleep 3
    
    if systemctl is-active --quiet fail2ban; then
        echo -e "${GREEN}✓ fail2ban restarted successfully${NC}"
    else
        echo -e "${RED}✗ fail2ban restart failed${NC}"
    fi
    
    # Reload UFW
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
        echo -e "${CYAN}Reloading UFW rules...${NC}"
        ufw reload
        echo -e "${GREEN}✓ UFW rules reloaded${NC}"
    fi
    
    # Restart iptables service if available
    if systemctl list-unit-files | grep -q iptables; then
        echo -e "${CYAN}Restarting iptables...${NC}"
        systemctl restart iptables
        echo -e "${GREEN}✓ iptables restarted${NC}"
    fi
    
    echo
    echo -e "${GREEN}Firewall services restart completed${NC}"
    echo
    read -p "Press Enter to continue..."
}

# Function for security health check
security_health_check() {
    echo -e "${YELLOW}Performing security health check...${NC}"
    echo
    
    echo -e "${BLUE}=== Security Health Report ===${NC}"
    
    # Check firewall status
    echo -e "${CYAN}Firewall Status:${NC}"
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
        echo -e "${GREEN}✓ UFW Firewall is active${NC}"
    else
        echo -e "${RED}✗ UFW Firewall is not active${NC}"
    fi
    
    # Check fail2ban status
    echo -e "${CYAN}Intrusion Prevention:${NC}"
    if systemctl is-active --quiet fail2ban; then
        echo -e "${GREEN}✓ fail2ban is running${NC}"
        local banned_count=$(fail2ban-client status | grep -o "Currently banned:.*" | grep -o "[0-9]*" || echo "0")
        echo -e "${CYAN}  Currently banned IPs: $banned_count${NC}"
    else
        echo -e "${RED}✗ fail2ban is not running${NC}"
    fi
    
    # Check SSH configuration
    echo -e "${CYAN}SSH Security:${NC}"
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
        echo -e "${GREEN}✓ Root login disabled${NC}"
    else
        echo -e "${YELLOW}⚠ Root login may be enabled${NC}"
    fi
    
    if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
        echo -e "${GREEN}✓ Password authentication disabled${NC}"
    else
        echo -e "${YELLOW}⚠ Password authentication may be enabled${NC}"
    fi
    
    # Check open ports
    echo -e "${CYAN}Network Exposure:${NC}"
    if command -v ss >/dev/null 2>&1; then
        local open_ports=$(ss -tlnp | grep LISTEN | wc -l)
        echo -e "${CYAN}  Open listening ports: $open_ports${NC}"
        
        # Check for potentially risky open ports
        ss -tlnp | grep LISTEN | while read line; do
            port=$(echo "$line" | awk '{print $4}' | cut -d: -f2)
            case $port in
                21) echo -e "${YELLOW}  ⚠ FTP (21) is open - consider SFTP${NC}" ;;
                23) echo -e "${RED}  ⚠ Telnet (23) is open - use SSH instead${NC}" ;;
                3306) echo -e "${YELLOW}  ⚠ MySQL (3306) is open - ensure access control${NC}" ;;
                5432) echo -e "${YELLOW}  ⚠ PostgreSQL (5432) is open - ensure access control${NC}" ;;
                27017) echo -e "${YELLOW}  ⚠ MongoDB (27017) is open - ensure access control${NC}" ;;
            esac
        done
    fi
    
    # Check recent security events
    echo -e "${CYAN}Recent Security Events:${NC}"
    if [[ -f /var/log/fail2ban.log ]]; then
        local recent_bans=$(tail -100 /var/log/fail2ban.log | grep "Ban " | wc -l)
        echo -e "${CYAN}  Recent IP bans: $recent_bans${NC}"
    fi
    
    # Check system updates
    echo -e "${CYAN}System Updates:${NC}"
    if command -v apt >/dev/null 2>&1; then
        local updates=$(apt list --upgradable 2>/dev/null | wc -l)
        if [[ $updates -gt 1 ]]; then
            echo -e "${YELLOW}  ⚠ $((updates-1)) package updates available${NC}"
        else
            echo -e "${GREEN}✓ System is up to date${NC}"
        fi
    fi
    
    echo
    echo -e "${GREEN}Security health check completed${NC}"
    echo
    read -p "Press Enter to continue..."
}

# Function to backup/restore configuration
backup_restore_config() {
    clear
    echo -e "${BLUE}Backup/Restore Configuration${NC}"
    echo
    echo -e "${GREEN}Options:${NC}"
    echo -e "1) Backup current configuration"
    echo -e "2) List available backups"
    echo -e "3) Restore from backup"
    echo -e "0) Back to maintenance menu"
    echo
    
    read -p "Select option [0-3]: " backup_choice
    
    case $backup_choice in
        1)
            if [[ $EUID -ne 0 ]]; then
                echo -e "${RED}Root privileges required for backup${NC}"
            else
                backup_firewall_config
                echo -e "${GREEN}Configuration backup completed${NC}"
            fi
            ;;
        2)
            echo -e "${CYAN}Available backups:${NC}"
            ls -la /var/backups/firewall/ 2>/dev/null || echo "No backups found"
            ;;
        3)
            if [[ $EUID -ne 0 ]]; then
                echo -e "${RED}Root privileges required for restore${NC}"
            else
                echo "Available backups:"
                ls -la /var/backups/firewall/ 2>/dev/null || echo "No backups found"
                echo
                read -p "Enter backup file path: " backup_file
                if [[ -n "$backup_file" ]]; then
                    restore_firewall_config "$backup_file"
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
    
    read -p "Press Enter to continue..."
}

# Main maintenance loop
while true; do
    show_maintenance_menu
    read -p "Select an option [0-11]: " choice
    
    case $choice in
        1)
            check_status
            ;;
        2)
            view_rules
            ;;
        3)
            check_fail2ban
            ;;
        4)
            view_blocked_ips
            ;;
        5)
            manage_rules
            ;;
        6)
            manage_ip_blocking
            ;;
        7)
            test_connectivity
            ;;
        8)
            view_security_logs
            ;;
        9)
            restart_services
            ;;
        10)
            security_health_check
            ;;
        11)
            backup_restore_config
            ;;
        0)
            echo -e "${YELLOW}Returning to main menu...${NC}"
            break
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 2
            ;;
    esac
done
