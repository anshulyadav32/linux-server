#!/bin/bash
# Mail System Maintenance
# Purpose: Daily operational checks and maintenance for mail system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Source functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}      MAIL SYSTEM MAINTENANCE          ${NC}"
echo -e "${BLUE}========================================${NC}"

# Function to show maintenance menu
show_maintenance_menu() {
    clear
    echo -e "${BLUE}Mail System Maintenance Options:${NC}"
    echo -e "${GREEN}1)${NC} Check service status"
    echo -e "${GREEN}2)${NC} Restart mail services"
    echo -e "${GREEN}3)${NC} View mail logs"
    echo -e "${GREEN}4)${NC} Check mail queue"
    echo -e "${GREEN}5)${NC} Test mail delivery"
    echo -e "${GREEN}6)${NC} Backup configurations"
    echo -e "${GREEN}7)${NC} Backup mail data"
    echo -e "${GREEN}8)${NC} Check disk usage"
    echo -e "${GREEN}9)${NC} Full system check"
    echo -e "${YELLOW}0)${NC} Return to main menu"
    echo
}

# Function to check service status
check_status() {
    echo -e "${YELLOW}Checking mail service status...${NC}"
    echo
    check_all_mail_services
    echo
    echo -e "${BLUE}Port status:${NC}"
    check_mail_ports
    echo
    read -p "Press Enter to continue..."
}

# Function to restart services
restart_services() {
    echo -e "${YELLOW}Restarting mail services...${NC}"
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required to restart services${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    restart_mail_services
    echo
    echo -e "${GREEN}Services restarted successfully${NC}"
    echo
    check_all_mail_services
    echo
    read -p "Press Enter to continue..."
}

# Function to view logs
view_logs() {
    clear
    echo -e "${BLUE}Mail System Logs${NC}"
    echo -e "${CYAN}1)${NC} View general mail logs"
    echo -e "${CYAN}2)${NC} View Postfix logs"
    echo -e "${CYAN}3)${NC} View Dovecot logs"
    echo -e "${CYAN}4)${NC} Back to maintenance menu"
    echo
    read -p "Select option [1-4]: " log_choice
    
    case $log_choice in
        1)
            echo -e "${YELLOW}General mail logs:${NC}"
            view_mail_logs
            ;;
        2)
            echo -e "${YELLOW}Postfix logs:${NC}"
            view_postfix_logs
            ;;
        3)
            echo -e "${YELLOW}Dovecot logs:${NC}"
            view_dovecot_logs
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    echo
    read -p "Press Enter to continue..."
}

# Function to check mail queue
check_queue() {
    echo -e "${YELLOW}Checking mail queue...${NC}"
    echo
    get_mail_queue_status
    echo
    
    read -p "Do you want to flush the mail queue? (y/N): " flush_choice
    if [[ "$flush_choice" =~ ^[Yy]$ ]]; then
        if [[ $EUID -ne 0 ]]; then
            echo -e "${RED}Root privileges required to flush queue${NC}"
        else
            flush_mail_queue
        fi
    fi
    echo
    read -p "Press Enter to continue..."
}

# Function to test mail delivery
test_delivery() {
    echo -e "${YELLOW}Testing mail delivery...${NC}"
    echo
    read -p "Enter email address to test: " test_email
    read -p "Enter domain to test SMTP connection (optional): " test_domain
    
    if [[ -n "$test_email" ]]; then
        test_mail_delivery "$test_email"
    fi
    
    if [[ -n "$test_domain" ]]; then
        test_smtp_connection "$test_domain"
    fi
    echo
    read -p "Press Enter to continue..."
}

# Function to backup configurations
backup_configs() {
    echo -e "${YELLOW}Backing up mail configurations...${NC}"
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required for backup${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    backup_mail_configs
    echo
    read -p "Press Enter to continue..."
}

# Function to backup mail data
backup_data() {
    echo -e "${YELLOW}Backing up mail data...${NC}"
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required for backup${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    backup_mail_data
    echo
    read -p "Press Enter to continue..."
}

# Function to check disk usage
check_disk() {
    echo -e "${YELLOW}Checking disk usage...${NC}"
    echo
    check_disk_usage
    echo
    
    echo -e "${BLUE}System disk usage:${NC}"
    df -h
    echo
    read -p "Press Enter to continue..."
}

# Function for full system check
full_check() {
    echo -e "${YELLOW}Performing full mail system check...${NC}"
    echo
    
    echo -e "${BLUE}=== Service Status ===${NC}"
    check_all_mail_services
    echo
    
    echo -e "${BLUE}=== Port Status ===${NC}"
    check_mail_ports
    echo
    
    echo -e "${BLUE}=== Mail Queue ===${NC}"
    get_mail_queue_status
    echo
    
    echo -e "${BLUE}=== Disk Usage ===${NC}"
    check_disk_usage
    echo
    
    echo -e "${BLUE}=== Recent Logs ===${NC}"
    view_mail_logs | tail -10
    echo
    
    echo -e "${GREEN}Full system check completed${NC}"
    echo
    read -p "Press Enter to continue..."
}

# Main maintenance loop
while true; do
    show_maintenance_menu
    read -p "Select an option [0-9]: " choice
    
    case $choice in
        1)
            check_status
            ;;
        2)
            restart_services
            ;;
        3)
            view_logs
            ;;
        4)
            check_queue
            ;;
        5)
            test_delivery
            ;;
        6)
            backup_configs
            ;;
        7)
            backup_data
            ;;
        8)
            check_disk
            ;;
        9)
            full_check
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
