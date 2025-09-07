#!/bin/bash
# =============================================================================
# Linux Setup - Webserver Module Menu
# =============================================================================
# Author: Anshul Yadav
# Description: Interactive menu for webserver module management
# =============================================================================

set -e

# Script directory and base directory detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions
if [[ -f "$BASE_DIR/modules/common.sh" ]]; then
    source "$BASE_DIR/modules/common.sh"
else
    echo "Error: common.sh not found"
    exit 1
fi

# Source webserver functions
if [[ -f "$SCRIPT_DIR/functions.sh" ]]; then
    source "$SCRIPT_DIR/functions.sh"
fi

# ==========================================
# WEBSERVER MENU FUNCTIONS
# ==========================================

show_webserver_menu() {
    while true; do
        clear
        print_section_header "🌐 WEBSERVER MODULE MANAGEMENT"
        
        echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│                    🌐 WEBSERVER MENU                       │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}│  ${CYAN}1)${NC} Install Webserver Module                          │${NC}"
        echo -e "${BLUE}│  ${CYAN}2)${NC} Update Webserver                                  │${NC}"
        echo -e "${BLUE}│  ${CYAN}3)${NC} Maintain Webserver                                │${NC}"
        echo -e "${BLUE}│  ${CYAN}4)${NC} View Status                                       │${NC}"
        echo -e "${BLUE}│  ${CYAN}5)${NC} Restart Services                                  │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│  ${CYAN}6)${NC} Manage Virtual Hosts                              │${NC}"
        echo -e "${BLUE}│  ${CYAN}7)${NC} SSL Certificate Management                        │${NC}"
        echo -e "${BLUE}│  ${CYAN}8)${NC} Security Settings                                 │${NC}"
        echo -e "${BLUE}│  ${CYAN}9)${NC} Performance Tuning                                │${NC}"
        echo -e "${BLUE}│  ${CYAN}10)${NC} View Logs                                         │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│  ${CYAN}11)${NC} Backup Configuration                              │${NC}"
        echo -e "${BLUE}│  ${CYAN}12)${NC} Restore Configuration                             │${NC}"
        echo -e "${BLUE}│  ${CYAN}13)${NC} Configuration Test                                │${NC}"
        echo -e "${BLUE}│  ${CYAN}14)${NC} Usage Analytics                                   │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│  ${CYAN}0)${NC} Return to Main Menu                               │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo ""
        echo -ne "${CYAN}Enter your choice (0-14): ${NC}"
        read -r choice
        
        case $choice in
            1) handle_install_webserver ;;
            2) handle_update_webserver ;;
            3) handle_maintain_webserver ;;
            4) handle_view_status ;;
            5) handle_restart_services ;;
            6) handle_virtual_hosts ;;
            7) handle_ssl_management ;;
            8) handle_security_settings ;;
            9) handle_performance_tuning ;;
            10) handle_view_logs ;;
            11) handle_backup_config ;;
            12) handle_restore_config ;;
            13) handle_config_test ;;
            14) handle_usage_analytics ;;
            0) return 0 ;;
            *) 
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# ==========================================
# MAIN MENU HANDLERS
# ==========================================

handle_install_webserver() {
    clear
    print_section_header "🌐 WEBSERVER INSTALLATION"
    
    echo -e "${YELLOW}Installing webserver module...${NC}"
    echo ""
    
    if bash "$SCRIPT_DIR/install.sh"; then
        echo ""
        echo -e "${GREEN}✓ Webserver installation completed successfully!${NC}"
    else
        echo ""
        echo -e "${RED}✗ Webserver installation failed!${NC}"
    fi
    
    pause "Press Enter to continue..."
}

handle_update_webserver() {
    clear
    print_section_header "🔄 WEBSERVER UPDATE"
    
    echo -e "${YELLOW}Updating webserver module...${NC}"
    echo ""
    
    if bash "$SCRIPT_DIR/update.sh"; then
        echo ""
        echo -e "${GREEN}✓ Webserver update completed successfully!${NC}"
    else
        echo ""
        echo -e "${RED}✗ Webserver update failed!${NC}"
    fi
    
    pause "Press Enter to continue..."
}

handle_maintain_webserver() {
    clear
    print_section_header "🔧 WEBSERVER MAINTENANCE"
    
    echo -e "${YELLOW}Running webserver maintenance...${NC}"
    echo ""
    
    if bash "$SCRIPT_DIR/maintain.sh"; then
        echo ""
        echo -e "${GREEN}✓ Webserver maintenance completed successfully!${NC}"
    else
        echo ""
        echo -e "${RED}✗ Webserver maintenance failed!${NC}"
    fi
    
    pause "Press Enter to continue..."
}

handle_view_status() {
    clear
    print_section_header "📊 WEBSERVER STATUS"
    
    echo ""
    get_webserver_status
    echo ""
    
    # Show additional status information
    show_detailed_status
    
    pause "Press Enter to continue..."
}

handle_restart_services() {
    clear
    print_section_header "🔄 RESTART WEBSERVER SERVICES"
    
    echo -e "${YELLOW}Restarting webserver services...${NC}"
    echo ""
    
    restart_webserver
    
    echo ""
    echo -e "${GREEN}✓ Webserver services restarted successfully!${NC}"
    
    pause "Press Enter to continue..."
}

# ==========================================
# ADVANCED MENU HANDLERS
# ==========================================

handle_virtual_hosts() {
    while true; do
        clear
        print_section_header "🏠 VIRTUAL HOST MANAGEMENT"
        
        echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│                 🏠 VIRTUAL HOST MENU                       │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}│  ${CYAN}1)${NC} Create New Virtual Host                           │${NC}"
        echo -e "${BLUE}│  ${CYAN}2)${NC} List Virtual Hosts                                │${NC}"
        echo -e "${BLUE}│  ${CYAN}3)${NC} Enable Virtual Host                               │${NC}"
        echo -e "${BLUE}│  ${CYAN}4)${NC} Disable Virtual Host                              │${NC}"
        echo -e "${BLUE}│  ${CYAN}5)${NC} Delete Virtual Host                               │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│  ${CYAN}0)${NC} Back to Webserver Menu                           │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo ""
        echo -ne "${CYAN}Enter your choice (0-5): ${NC}"
        read -r choice
        
        case $choice in
            1) create_new_virtual_host ;;
            2) list_virtual_hosts ;;
            3) enable_virtual_host ;;
            4) disable_virtual_host ;;
            5) delete_virtual_host ;;
            0) break ;;
            *) 
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

handle_ssl_management() {
    while true; do
        clear
        print_section_header "🔐 SSL CERTIFICATE MANAGEMENT"
        
        echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│                 🔐 SSL CERTIFICATE MENU                    │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}│  ${CYAN}1)${NC} Install Let's Encrypt Certificate                 │${NC}"
        echo -e "${BLUE}│  ${CYAN}2)${NC} Renew SSL Certificates                            │${NC}"
        echo -e "${BLUE}│  ${CYAN}3)${NC} List SSL Certificates                             │${NC}"
        echo -e "${BLUE}│  ${CYAN}4)${NC} Generate Self-Signed Certificate                 │${NC}"
        echo -e "${BLUE}│  ${CYAN}5)${NC} Check Certificate Status                          │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│  ${CYAN}0)${NC} Back to Webserver Menu                           │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo ""
        echo -ne "${CYAN}Enter your choice (0-5): ${NC}"
        read -r choice
        
        case $choice in
            1) install_letsencrypt_cert ;;
            2) renew_ssl_certificates ;;
            3) list_ssl_certificates ;;
            4) generate_selfsigned_cert ;;
            5) check_certificate_status ;;
            0) break ;;
            *) 
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

handle_security_settings() {
    while true; do
        clear
        print_section_header "🔒 SECURITY SETTINGS"
        
        echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│                  🔒 SECURITY MENU                          │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}│  ${CYAN}1)${NC} Configure Security Headers                        │${NC}"
        echo -e "${BLUE}│  ${CYAN}2)${NC} Update Firewall Rules                             │${NC}"
        echo -e "${BLUE}│  ${CYAN}3)${NC} Configure Fail2Ban                               │${NC}"
        echo -e "${BLUE}│  ${CYAN}4)${NC} Security Scan                                     │${NC}"
        echo -e "${BLUE}│  ${CYAN}5)${NC} View Security Status                              │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│  ${CYAN}0)${NC} Back to Webserver Menu                           │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo ""
        echo -ne "${CYAN}Enter your choice (0-5): ${NC}"
        read -r choice
        
        case $choice in
            1) configure_security_headers ;;
            2) update_firewall_rules ;;
            3) configure_fail2ban ;;
            4) run_security_scan ;;
            5) view_security_status ;;
            0) break ;;
            *) 
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

handle_performance_tuning() {
    while true; do
        clear
        print_section_header "⚡ PERFORMANCE TUNING"
        
        echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│                ⚡ PERFORMANCE MENU                         │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}│  ${CYAN}1)${NC} Optimize Apache Performance                       │${NC}"
        echo -e "${BLUE}│  ${CYAN}2)${NC} Optimize Nginx Performance                        │${NC}"
        echo -e "${BLUE}│  ${CYAN}3)${NC} Optimize PHP Performance                          │${NC}"
        echo -e "${BLUE}│  ${CYAN}4)${NC} Enable Caching                                    │${NC}"
        echo -e "${BLUE}│  ${CYAN}5)${NC} Performance Monitoring                            │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│  ${CYAN}0)${NC} Back to Webserver Menu                           │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo ""
        echo -ne "${CYAN}Enter your choice (0-5): ${NC}"
        read -r choice
        
        case $choice in
            1) optimize_apache_performance ;;
            2) optimize_nginx_performance ;;
            3) optimize_php_performance ;;
            4) enable_caching ;;
            5) performance_monitoring ;;
            0) break ;;
            *) 
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

handle_view_logs() {
    while true; do
        clear
        print_section_header "📄 LOG VIEWER"
        
        echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│                   📄 LOG VIEWER MENU                       │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}│  ${CYAN}1)${NC} Apache Access Logs                                │${NC}"
        echo -e "${BLUE}│  ${CYAN}2)${NC} Apache Error Logs                                 │${NC}"
        echo -e "${BLUE}│  ${CYAN}3)${NC} Nginx Access Logs                                 │${NC}"
        echo -e "${BLUE}│  ${CYAN}4)${NC} Nginx Error Logs                                  │${NC}"
        echo -e "${BLUE}│  ${CYAN}5)${NC} PHP Error Logs                                    │${NC}"
        echo -e "${BLUE}│  ${CYAN}6)${NC} Live Log Monitoring                               │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│  ${CYAN}0)${NC} Back to Webserver Menu                           │${NC}"
        echo -e "${BLUE}│                                                             │${NC}"
        echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo ""
        echo -ne "${CYAN}Enter your choice (0-6): ${NC}"
        read -r choice
        
        case $choice in
            1) view_apache_access_logs ;;
            2) view_apache_error_logs ;;
            3) view_nginx_access_logs ;;
            4) view_nginx_error_logs ;;
            5) view_php_error_logs ;;
            6) live_log_monitoring ;;
            0) break ;;
            *) 
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

handle_backup_config() {
    clear
    print_section_header "💾 BACKUP CONFIGURATION"
    
    echo -e "${YELLOW}Creating configuration backup...${NC}"
    echo ""
    
    backup_webserver_configs
    
    echo ""
    echo -e "${GREEN}✓ Configuration backup completed!${NC}"
    
    pause "Press Enter to continue..."
}

handle_restore_config() {
    clear
    print_section_header "🔄 RESTORE CONFIGURATION"
    
    echo -e "${YELLOW}Available backups:${NC}"
    echo ""
    
    list_available_backups
    
    echo ""
    echo -ne "${CYAN}Enter backup directory to restore (or 'cancel'): ${NC}"
    read -r backup_dir
    
    if [[ "$backup_dir" != "cancel" && -d "$backup_dir" ]]; then
        echo ""
        echo -e "${YELLOW}Restoring configuration from: $backup_dir${NC}"
        restore_webserver_config "$backup_dir"
        echo ""
        echo -e "${GREEN}✓ Configuration restored successfully!${NC}"
    else
        echo ""
        echo -e "${YELLOW}Restore cancelled.${NC}"
    fi
    
    pause "Press Enter to continue..."
}

handle_config_test() {
    clear
    print_section_header "🧪 CONFIGURATION TEST"
    
    echo -e "${YELLOW}Testing webserver configuration...${NC}"
    echo ""
    
    check_webserver_config
    
    pause "Press Enter to continue..."
}

handle_usage_analytics() {
    clear
    print_section_header "📊 USAGE ANALYTICS"
    
    echo -e "${YELLOW}Generating usage analytics...${NC}"
    echo ""
    
    analyze_webserver_usage
    
    pause "Press Enter to continue..."
}

# ==========================================
# HELPER FUNCTIONS
# ==========================================

show_detailed_status() {
    echo "=== Service Details ==="
    
    # Apache version
    if command -v apache2 >/dev/null 2>&1; then
        echo "Apache version: $(apache2 -v 2>/dev/null | head -1 | awk '{print $3}')"
    elif command -v httpd >/dev/null 2>&1; then
        echo "Apache version: $(httpd -v 2>/dev/null | head -1 | awk '{print $3}')"
    fi
    
    # Nginx version
    if command -v nginx >/dev/null 2>&1; then
        echo "Nginx version: $(nginx -v 2>&1 | awk '{print $3}')"
    fi
    
    # PHP version
    if command -v php >/dev/null 2>&1; then
        echo "PHP version: $(php -v | head -1 | awk '{print $2}')"
    fi
    
    echo ""
    echo "=== Virtual Hosts ==="
    list_virtual_hosts
    
    echo ""
    echo "=== SSL Certificates ==="
    list_ssl_certificates
}

create_new_virtual_host() {
    clear
    print_section_header "🆕 CREATE VIRTUAL HOST"
    
    echo -ne "${CYAN}Enter domain name: ${NC}"
    read -r domain
    
    if [[ -z "$domain" ]]; then
        echo -e "${RED}Domain name cannot be empty!${NC}"
        pause "Press Enter to continue..."
        return
    fi
    
    echo -ne "${CYAN}Enter document root (default: /var/www/$domain): ${NC}"
    read -r doc_root
    
    if [[ -z "$doc_root" ]]; then
        doc_root="/var/www/$domain"
    fi
    
    echo ""
    echo -e "${YELLOW}Creating virtual host for: $domain${NC}"
    echo -e "${YELLOW}Document root: $doc_root${NC}"
    echo ""
    
    # Create document root
    mkdir -p "$doc_root"
    
    # Create Apache virtual host
    create_apache_virtual_host "$domain" "$doc_root"
    
    # Create Nginx virtual host
    create_nginx_virtual_host "$domain" "$doc_root"
    
    # Restart services
    systemctl reload apache2 2>/dev/null || systemctl reload httpd 2>/dev/null || true
    systemctl reload nginx 2>/dev/null || true
    
    echo -e "${GREEN}✓ Virtual host created successfully!${NC}"
    echo -e "${CYAN}Add the following to your /etc/hosts file for local testing:${NC}"
    echo -e "${YELLOW}127.0.0.1 $domain${NC}"
    
    pause "Press Enter to continue..."
}

list_virtual_hosts() {
    echo "Apache Virtual Hosts:"
    if [[ -d "/etc/apache2/sites-available" ]]; then
        ls -1 /etc/apache2/sites-available/*.conf 2>/dev/null | sed 's|.*/||; s|\.conf$||' | while read -r site; do
            if [[ -f "/etc/apache2/sites-enabled/${site}.conf" ]]; then
                echo "  ✓ $site (enabled)"
            else
                echo "  ✗ $site (disabled)"
            fi
        done
    fi
    
    echo ""
    echo "Nginx Virtual Hosts:"
    if [[ -d "/etc/nginx/sites-available" ]]; then
        ls -1 /etc/nginx/sites-available/ 2>/dev/null | while read -r site; do
            if [[ -f "/etc/nginx/sites-enabled/$site" ]]; then
                echo "  ✓ $site (enabled)"
            else
                echo "  ✗ $site (disabled)"
            fi
        done
    fi
}

list_ssl_certificates() {
    if [[ -d "/etc/letsencrypt/live" ]]; then
        echo "Let's Encrypt Certificates:"
        for cert_dir in /etc/letsencrypt/live/*/; do
            if [[ -d "$cert_dir" ]]; then
                local domain=$(basename "$cert_dir")
                local cert_file="$cert_dir/cert.pem"
                if [[ -f "$cert_file" ]]; then
                    local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
                    echo "  ✓ $domain (expires: $expiry_date)"
                fi
            fi
        done
    else
        echo "No Let's Encrypt certificates found"
    fi
}

list_available_backups() {
    if [[ -d "/root/backups" ]]; then
        ls -td /root/backups/webserver-* 2>/dev/null | head -10 | while read -r backup; do
            local backup_date=$(basename "$backup" | sed 's/webserver-//')
            echo "  $backup ($backup_date)"
        done
    else
        echo "No backups found"
    fi
}

# ==========================================
# STUB FUNCTIONS (TO BE IMPLEMENTED)
# ==========================================

enable_virtual_host() {
    echo "Enable virtual host functionality - To be implemented"
    pause "Press Enter to continue..."
}

disable_virtual_host() {
    echo "Disable virtual host functionality - To be implemented"
    pause "Press Enter to continue..."
}

delete_virtual_host() {
    echo "Delete virtual host functionality - To be implemented"
    pause "Press Enter to continue..."
}

install_letsencrypt_cert() {
    echo "Let's Encrypt certificate installation - To be implemented"
    pause "Press Enter to continue..."
}

renew_ssl_certificates() {
    echo "SSL certificate renewal - To be implemented"
    pause "Press Enter to continue..."
}

generate_selfsigned_cert() {
    echo "Self-signed certificate generation - To be implemented"
    pause "Press Enter to continue..."
}

check_certificate_status() {
    echo "Certificate status check - To be implemented"
    pause "Press Enter to continue..."
}

configure_security_headers() {
    echo "Security headers configuration - To be implemented"
    pause "Press Enter to continue..."
}

configure_fail2ban() {
    echo "Fail2Ban configuration - To be implemented"
    pause "Press Enter to continue..."
}

run_security_scan() {
    echo "Security scan - To be implemented"
    pause "Press Enter to continue..."
}

view_security_status() {
    echo "Security status view - To be implemented"
    pause "Press Enter to continue..."
}

enable_caching() {
    echo "Caching configuration - To be implemented"
    pause "Press Enter to continue..."
}

performance_monitoring() {
    echo "Performance monitoring - To be implemented"
    pause "Press Enter to continue..."
}

view_apache_access_logs() {
    clear
    print_section_header "📄 APACHE ACCESS LOGS"
    echo ""
    if [[ -f "/var/log/apache2/access.log" ]]; then
        tail -50 /var/log/apache2/access.log
    else
        echo "Apache access log not found"
    fi
    pause "Press Enter to continue..."
}

view_apache_error_logs() {
    clear
    print_section_header "📄 APACHE ERROR LOGS"
    echo ""
    if [[ -f "/var/log/apache2/error.log" ]]; then
        tail -50 /var/log/apache2/error.log
    else
        echo "Apache error log not found"
    fi
    pause "Press Enter to continue..."
}

view_nginx_access_logs() {
    clear
    print_section_header "📄 NGINX ACCESS LOGS"
    echo ""
    if [[ -f "/var/log/nginx/access.log" ]]; then
        tail -50 /var/log/nginx/access.log
    else
        echo "Nginx access log not found"
    fi
    pause "Press Enter to continue..."
}

view_nginx_error_logs() {
    clear
    print_section_header "📄 NGINX ERROR LOGS"
    echo ""
    if [[ -f "/var/log/nginx/error.log" ]]; then
        tail -50 /var/log/nginx/error.log
    else
        echo "Nginx error log not found"
    fi
    pause "Press Enter to continue..."
}

view_php_error_logs() {
    clear
    print_section_header "📄 PHP ERROR LOGS"
    echo ""
    if [[ -f "/var/log/php_errors.log" ]]; then
        tail -50 /var/log/php_errors.log
    else
        echo "PHP error log not found"
    fi
    pause "Press Enter to continue..."
}

live_log_monitoring() {
    clear
    print_section_header "📊 LIVE LOG MONITORING"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop monitoring${NC}"
    echo ""
    
    # Monitor multiple logs simultaneously
    if [[ -f "/var/log/apache2/access.log" ]] || [[ -f "/var/log/nginx/access.log" ]]; then
        tail -f /var/log/apache2/access.log /var/log/nginx/access.log 2>/dev/null
    else
        echo "No access logs found for monitoring"
        pause "Press Enter to continue..."
    fi
}

restore_webserver_config() {
    local backup_dir="$1"
    echo "Restoring from: $backup_dir"
    # Implementation for config restoration
}

# ==========================================
# MAIN EXECUTION
# ==========================================

main() {
    # Check if running as root
    check_root
    
    # Show webserver menu
    show_webserver_menu
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
