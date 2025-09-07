#!/bin/bash
# Master Server Management CLI
# Complete server administration system with modular architecture

# Get the base directory for modules
BASE_DIR="$(dirname "$0")/modules"

# Source common functions
source "$BASE_DIR/common.sh"

# Check if running as root
check_root

# Main menu loop
main_menu() {
    while true; do
        clear
        show_header "MASTER SERVER MANAGEMENT"
        echo ""
        echo -e "${WHITE}Select a service to manage:${NC}"
        echo ""
        echo -e "${CYAN}1)${NC} Web Server Management       ${BLUE}(Apache/Nginx, PHP, Node.js)${NC}"
        echo -e "${CYAN}2)${NC} DNS Management              ${BLUE}(BIND9, zones, records)${NC}"
        echo -e "${CYAN}3)${NC} Mail System Management      ${BLUE}(Postfix, Dovecot, DKIM)${NC}"
        echo -e "${CYAN}4)${NC} Database Management         ${BLUE}(MySQL, PostgreSQL)${NC}"
        echo -e "${CYAN}5)${NC} Firewall Management         ${BLUE}(UFW, Fail2Ban, security)${NC}"
        echo -e "${CYAN}6)${NC} SSL Certificate Management  ${BLUE}(Let's Encrypt, self-signed)${NC}"
        echo -e "${CYAN}7)${NC} System Administration       ${BLUE}(users, packages, monitoring)${NC}"
        echo -e "${CYAN}8)${NC} Backup & Restore            ${BLUE}(automated backups, recovery)${NC}"
        echo ""
        echo -e "${YELLOW}9)${NC} Interdependent Automation   ${PURPLE}(full workflows, orchestration)${NC}"
        echo ""
        echo -e "${RED}0)${NC} Exit"
        echo ""
        echo "=============================="
        
        local choice=$(get_menu_choice 9)
        
        case $choice in
            1) 
                log_info "Launching Web Server Management..."
                bash "$BASE_DIR/web/menu.sh" 
                ;;
            2) 
                log_info "Launching DNS Management..."
                bash "$BASE_DIR/dns/menu.sh" 
                ;;
            3) 
                log_info "Launching Mail System Management..."
                bash "$BASE_DIR/mail/menu.sh" 
                ;;
            4) 
                log_info "Launching Database Management..."
                bash "$BASE_DIR/db/menu.sh" 
                ;;
            5) 
                log_info "Launching Firewall Management..."
                bash "$BASE_DIR/firewall/menu.sh" 
                ;;
            6) 
                log_info "Launching SSL Certificate Management..."
                bash "$BASE_DIR/ssl/menu.sh" 
                ;;
            7) 
                log_info "Launching System Administration..."
                bash "$BASE_DIR/system/menu.sh" 
                ;;
            8) 
                log_info "Launching Backup & Restore..."
                bash "$BASE_DIR/backup/menu.sh" 
                ;;
            9) 
                log_info "Launching Interdependent Automation..."
                bash "$BASE_DIR/interdependent.sh" 
                ;;
            0) 
                log_info "Exiting Master Server Management"
                exit 0 
                ;;
        esac
    done
}

# Display welcome message
welcome_message() {
    clear
    echo -e "${CYAN}"
    echo "================================================================"
    echo "           WELCOME TO MASTER SERVER MANAGEMENT"
    echo "================================================================"
    echo -e "${NC}"
    echo ""
    echo -e "${WHITE}This comprehensive system helps you manage:${NC}"
    echo -e "${GREEN}✓${NC} Web servers (Apache, Nginx, PHP, Node.js)"
    echo -e "${GREEN}✓${NC} DNS services (BIND9, zone management)"
    echo -e "${GREEN}✓${NC} Mail systems (Postfix, Dovecot, security)"
    echo -e "${GREEN}✓${NC} Databases (MySQL, PostgreSQL)"
    echo -e "${GREEN}✓${NC} Firewall & security (UFW, Fail2Ban)"
    echo -e "${GREEN}✓${NC} SSL certificates (Let's Encrypt, custom)"
    echo -e "${GREEN}✓${NC} System administration & monitoring"
    echo -e "${GREEN}✓${NC} Automated backups & disaster recovery"
    echo -e "${GREEN}✓${NC} Interdependent automation workflows"
    echo ""
    echo -e "${YELLOW}Note: This system requires root privileges for most operations.${NC}"
    echo ""
    pause "Press Enter to continue to the main menu..."
}

# Check system prerequisites
check_prerequisites() {
    log_info "Checking system prerequisites..."
    
    # Check if we're on Ubuntu/Debian
    if ! command_exists apt; then
        log_error "This system is designed for Ubuntu/Debian systems with apt package manager"
        exit 1
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        log_warn "No internet connectivity detected. Some features may not work."
        pause
    fi
    
    # Update package list
    log_info "Updating package list..."
    apt update -y >/dev/null 2>&1
    
    log_ok "System prerequisites check completed"
}

# Main execution
main() {
    # Show welcome message
    welcome_message
    
    # Check prerequisites
    check_prerequisites
    
    # Start main menu
    main_menu
}

# Run the main function
main "$@"
