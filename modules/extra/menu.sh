#!/bin/bash
# Mail System Management Menu
# Purpose: Interactive CLI for comprehensive mail system management

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

# Function to display main header
show_header() {
    clear
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}           MAIL SYSTEM MANAGEMENT              ${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
}

# Function to display main menu
show_main_menu() {
    show_header
    echo -e "${GREEN}Installation & Setup:${NC}"
    echo -e "  ${CYAN}1)${NC} Install mail system"
    echo -e "  ${CYAN}2)${NC} Update mail system"
    echo
    echo -e "${GREEN}Service Management:${NC}"
    echo -e "  ${CYAN}3)${NC} Check service status"
    echo -e "  ${CYAN}4)${NC} Start/Stop services"
    echo -e "  ${CYAN}5)${NC} Restart all services"
    echo
    echo -e "${GREEN}Configuration:${NC}"
    echo -e "  ${CYAN}6)${NC} Configure domains"
    echo -e "  ${CYAN}7)${NC} Manage users"
    echo -e "  ${CYAN}8)${NC} Configure DKIM/SPF/DMARC"
    echo -e "  ${CYAN}9)${NC} Configure security settings"
    echo
    echo -e "${GREEN}Monitoring & Maintenance:${NC}"
    echo -e "  ${CYAN}10)${NC} View logs"
    echo -e "  ${CYAN}11)${NC} Check mail queue"
    echo -e "  ${CYAN}12)${NC} Test mail delivery"
    echo -e "  ${CYAN}13)${NC} System maintenance"
    echo
    echo -e "${GREEN}Backup & Recovery:${NC}"
    echo -e "  ${CYAN}14)${NC} Backup system"
    echo -e "  ${CYAN}15)${NC} Restore backup"
    echo
    echo -e "${YELLOW}0)${NC} Exit"
    echo
}

# Function to show service control menu
show_service_menu() {
    clear
    echo -e "${BLUE}Service Management${NC}"
    echo -e "${GREEN}1)${NC} Start all services"
    echo -e "${GREEN}2)${NC} Stop all services"
    echo -e "${GREEN}3)${NC} Start Postfix"
    echo -e "${GREEN}4)${NC} Stop Postfix"
    echo -e "${GREEN}5)${NC} Start Dovecot"
    echo -e "${GREEN}6)${NC} Stop Dovecot"
    echo -e "${GREEN}7)${NC} Start Apache/Nginx"
    echo -e "${GREEN}8)${NC} Stop Apache/Nginx"
    echo -e "${YELLOW}0)${NC} Back to main menu"
    echo
}

# Function to manage services
manage_services() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required for service management${NC}"
        sleep 2
        return
    fi

    while true; do
        show_service_menu
        read -p "Select an option [0-8]: " service_choice
        
        case $service_choice in
            1)
                echo -e "${YELLOW}Starting all mail services...${NC}"
                start_mail_services
                echo -e "${GREEN}All services started${NC}"
                sleep 2
                ;;
            2)
                echo -e "${YELLOW}Stopping all mail services...${NC}"
                stop_mail_services
                echo -e "${YELLOW}All services stopped${NC}"
                sleep 2
                ;;
            3)
                echo -e "${YELLOW}Starting Postfix...${NC}"
                systemctl start postfix
                echo -e "${GREEN}Postfix started${NC}"
                sleep 2
                ;;
            4)
                echo -e "${YELLOW}Stopping Postfix...${NC}"
                systemctl stop postfix
                echo -e "${YELLOW}Postfix stopped${NC}"
                sleep 2
                ;;
            5)
                echo -e "${YELLOW}Starting Dovecot...${NC}"
                systemctl start dovecot
                echo -e "${GREEN}Dovecot started${NC}"
                sleep 2
                ;;
            6)
                echo -e "${YELLOW}Stopping Dovecot...${NC}"
                systemctl stop dovecot
                echo -e "${YELLOW}Dovecot stopped${NC}"
                sleep 2
                ;;
            7)
                echo -e "${YELLOW}Starting web server...${NC}"
                if command -v apache2 >/dev/null 2>&1; then
                    systemctl start apache2
                elif command -v nginx >/dev/null 2>&1; then
                    systemctl start nginx
                fi
                echo -e "${GREEN}Web server started${NC}"
                sleep 2
                ;;
            8)
                echo -e "${YELLOW}Stopping web server...${NC}"
                if command -v apache2 >/dev/null 2>&1; then
                    systemctl stop apache2
                elif command -v nginx >/dev/null 2>&1; then
                    systemctl stop nginx
                fi
                echo -e "${YELLOW}Web server stopped${NC}"
                sleep 2
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Function to configure domains
configure_domains() {
    clear
    echo -e "${BLUE}Domain Configuration${NC}"
    echo
    echo -e "${YELLOW}Current domains:${NC}"
    list_mail_domains
    echo
    
    echo -e "${GREEN}Options:${NC}"
    echo -e "1) Add new domain"
    echo -e "2) Remove domain"
    echo -e "3) Configure domain settings"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select option [0-3]: " domain_choice
    
    case $domain_choice in
        1)
            read -p "Enter domain name: " new_domain
            if [[ -n "$new_domain" ]]; then
                add_mail_domain "$new_domain"
            fi
            ;;
        2)
            read -p "Enter domain to remove: " remove_domain
            if [[ -n "$remove_domain" ]]; then
                remove_mail_domain "$remove_domain"
            fi
            ;;
        3)
            read -p "Enter domain to configure: " config_domain
            if [[ -n "$config_domain" ]]; then
                configure_domain_settings "$config_domain"
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

# Function to manage users
manage_users() {
    clear
    echo -e "${BLUE}User Management${NC}"
    echo
    echo -e "${YELLOW}Current mail users:${NC}"
    list_mail_users
    echo
    
    echo -e "${GREEN}Options:${NC}"
    echo -e "1) Add new user"
    echo -e "2) Delete user"
    echo -e "3) Change password"
    echo -e "4) View user details"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select option [0-4]: " user_choice
    
    case $user_choice in
        1)
            read -p "Enter email address: " new_user
            read -p "Enter domain: " user_domain
            if [[ -n "$new_user" && -n "$user_domain" ]]; then
                add_mail_user "$new_user" "$user_domain"
            fi
            ;;
        2)
            read -p "Enter email address to delete: " del_user
            if [[ -n "$del_user" ]]; then
                delete_mail_user "$del_user"
            fi
            ;;
        3)
            read -p "Enter email address: " change_user
            if [[ -n "$change_user" ]]; then
                change_user_password "$change_user"
            fi
            ;;
        4)
            read -p "Enter email address: " view_user
            if [[ -n "$view_user" ]]; then
                get_user_details "$view_user"
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

# Function for DKIM/SPF/DMARC configuration
configure_security_records() {
    clear
    echo -e "${BLUE}DKIM/SPF/DMARC Configuration${NC}"
    echo
    
    echo -e "${GREEN}Options:${NC}"
    echo -e "1) Setup DKIM"
    echo -e "2) Configure SPF record"
    echo -e "3) Configure DMARC record"
    echo -e "4) View current records"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select option [0-4]: " security_choice
    
    case $security_choice in
        1)
            read -p "Enter domain for DKIM setup: " dkim_domain
            if [[ -n "$dkim_domain" ]]; then
                setup_dkim "$dkim_domain"
            fi
            ;;
        2)
            read -p "Enter domain for SPF: " spf_domain
            if [[ -n "$spf_domain" ]]; then
                configure_spf "$spf_domain"
            fi
            ;;
        3)
            read -p "Enter domain for DMARC: " dmarc_domain
            if [[ -n "$dmarc_domain" ]]; then
                configure_dmarc "$dmarc_domain"
            fi
            ;;
        4)
            read -p "Enter domain to check: " check_domain
            if [[ -n "$check_domain" ]]; then
                check_dns_records "$check_domain"
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

# Function to show logs menu
show_logs_menu() {
    clear
    echo -e "${BLUE}Log Viewer${NC}"
    echo -e "${GREEN}1)${NC} View general mail logs"
    echo -e "${GREEN}2)${NC} View Postfix logs"
    echo -e "${GREEN}3)${NC} View Dovecot logs"
    echo -e "${GREEN}4)${NC} View error logs"
    echo -e "${GREEN}5)${NC} View live logs (tail)"
    echo -e "${YELLOW}0)${NC} Back to main menu"
    echo
    
    read -p "Select option [0-5]: " log_choice
    
    case $log_choice in
        1)
            view_mail_logs
            ;;
        2)
            view_postfix_logs
            ;;
        3)
            view_dovecot_logs
            ;;
        4)
            view_error_logs
            ;;
        5)
            echo -e "${YELLOW}Showing live logs (Ctrl+C to exit):${NC}"
            tail_mail_logs
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

# Main menu loop
while true; do
    show_main_menu
    read -p "Select an option [0-15]: " choice
    
    case $choice in
        1)
            echo -e "${YELLOW}Starting mail system installation...${NC}"
            bash "$SCRIPT_DIR/install.sh"
            read -p "Press Enter to continue..."
            ;;
        2)
            echo -e "${YELLOW}Starting mail system update...${NC}"
            bash "$SCRIPT_DIR/update.sh"
            read -p "Press Enter to continue..."
            ;;
        3)
            clear
            echo -e "${BLUE}Service Status${NC}"
            check_all_mail_services
            read -p "Press Enter to continue..."
            ;;
        4)
            manage_services
            ;;
        5)
            if [[ $EUID -ne 0 ]]; then
                echo -e "${RED}Root privileges required${NC}"
                sleep 2
            else
                echo -e "${YELLOW}Restarting all services...${NC}"
                restart_mail_services
                echo -e "${GREEN}Services restarted${NC}"
                sleep 2
            fi
            ;;
        6)
            configure_domains
            ;;
        7)
            manage_users
            ;;
        8)
            configure_security_records
            ;;
        9)
            clear
            echo -e "${BLUE}Security Configuration${NC}"
            configure_security
            read -p "Press Enter to continue..."
            ;;
        10)
            show_logs_menu
            ;;
        11)
            clear
            echo -e "${BLUE}Mail Queue Status${NC}"
            get_mail_queue_status
            read -p "Press Enter to continue..."
            ;;
        12)
            clear
            echo -e "${BLUE}Mail Delivery Test${NC}"
            read -p "Enter email address to test: " test_email
            if [[ -n "$test_email" ]]; then
                test_mail_delivery "$test_email"
            fi
            read -p "Press Enter to continue..."
            ;;
        13)
            bash "$SCRIPT_DIR/maintain.sh"
            ;;
        14)
            clear
            echo -e "${BLUE}Backup System${NC}"
            if [[ $EUID -ne 0 ]]; then
                echo -e "${RED}Root privileges required${NC}"
            else
                backup_mail_system
            fi
            read -p "Press Enter to continue..."
            ;;
        15)
            clear
            echo -e "${BLUE}Restore Backup${NC}"
            if [[ $EUID -ne 0 ]]; then
                echo -e "${RED}Root privileges required${NC}"
            else
                restore_mail_system
            fi
            read -p "Press Enter to continue..."
            ;;
        0)
            echo -e "${YELLOW}Exiting mail system management...${NC}"
            break
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 2
            ;;
    esac
done

echo -e "${GREEN}Thank you for using Mail System Management!${NC}"
