#!/bin/bash
# Complete Web Server Management Menu System

# Get base directory and source functions
BASE_DIR="$(dirname "$0")"
source "$BASE_DIR/functions.sh"
source "$(dirname "$BASE_DIR")/common.sh"

# Initialize web module variables
WEB_MODULE_DIR="$BASE_DIR"
WEB_INSTALL_LOG="/var/log/web-install.log"

# Main menu function
main() {
    while true; do
        clear
        show_header "COMPLETE WEB SERVER MANAGEMENT"
        
        # Show comprehensive system status
        echo -e "${WHITE}System Status Overview:${NC}"
        
        # Web servers status
        if systemctl is-active --quiet apache2; then
            echo -e "  ${GREEN}✓${NC} Apache2: Running ($(apache2 -v 2>/dev/null | head -1 | awk '{print $3}'))"
        elif check_service_installed "apache2"; then
            echo -e "  ${RED}✗${NC} Apache2: Stopped"
        else
            echo -e "  ${YELLOW}○${NC} Apache2: Not Installed"
        fi
        
        if systemctl is-active --quiet nginx; then
            echo -e "  ${GREEN}✓${NC} Nginx: Running ($(nginx -v 2>&1 | awk '{print $3}'))"
        elif check_service_installed "nginx"; then
            echo -e "  ${RED}✗${NC} Nginx: Stopped"
        else
            echo -e "  ${YELLOW}○${NC} Nginx: Not Installed"
        fi
        
        # PHP status
        if command -v php >/dev/null 2>&1; then
            local php_version=$(php -v 2>/dev/null | head -1 | awk '{print $2}' | cut -d. -f1,2)
            if systemctl is-active --quiet php*-fpm; then
                echo -e "  ${GREEN}✓${NC} PHP: Running (v$php_version with FPM)"
            else
                echo -e "  ${YELLOW}△${NC} PHP: Installed (v$php_version) - FPM stopped"
            fi
        else
            echo -e "  ${YELLOW}○${NC} PHP: Not Installed"
        fi
        
        # Quick stats
        local website_count=0
        if [[ -d "/etc/apache2/sites-available" ]]; then
            website_count=$(find /etc/apache2/sites-available -name "*.conf" -not -name "000-default.conf" -not -name "default-ssl.conf" | wc -l)
        fi
        echo -e "  ${BLUE}📋${NC} Websites: $website_count configured"
        
        # Port status
        if netstat -tuln 2>/dev/null | grep -q ":80 "; then
            echo -e "  ${GREEN}✓${NC} Port 80: Open"
        else
            echo -e "  ${RED}✗${NC} Port 80: Closed"
        fi
        
        if netstat -tuln 2>/dev/null | grep -q ":443 "; then
            echo -e "  ${GREEN}✓${NC} Port 443: Open (SSL)"
        else
            echo -e "  ${YELLOW}○${NC} Port 443: Closed"
        fi
        
        echo ""
        echo -e "${WHITE}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                    MANAGEMENT MENU${NC}"
        echo -e "${WHITE}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        
        echo -e "${CYAN}🚀 INSTALLATION & SETUP${NC}"
        echo "   1) Complete Web Server Installation (All Components)"
        echo "   2) Basic Web Server Setup (Apache + PHP)"
        echo "   3) Development Environment Setup"
        echo "   4) Production Environment Setup"
        echo "   5) Custom Component Installation"
        echo ""
        
        echo -e "${GREEN}🌐 WEBSITE MANAGEMENT${NC}"
        echo "   11) Add New Website (with SSL options)"
        echo "   12) Remove Website (with backup)"
        echo "   13) Clone Website"
        echo "   14) List All Websites"
        echo "   15) Website Content Manager"
        echo ""
        
        echo -e "${YELLOW}🔒 SSL & SECURITY${NC}"
        echo "   21) Enable SSL Certificate"
        echo "   22) Security Hardening"
        echo "   23) Check SSL Certificate Status"
        echo "   24) Configure Firewall"
        echo "   25) Setup Auto SSL Renewal"
        echo ""
        
        echo -e "${BLUE}⚙️  SERVICE MANAGEMENT${NC}"
        echo "   31) Start Web Services"
        echo "   32) Stop Web Services"
        echo "   33) Restart Web Services"
        echo "   34) Reload Configurations"
        echo "   35) Switch Web Server (Apache/Nginx)"
        echo "   36) Service Status Details"
        echo ""
        
        echo -e "${PURPLE}🔧 ADVANCED TOOLS${NC}"
        echo "   41) Performance Optimization"
        echo "   42) Health Check & Diagnostics"
        echo "   43) Backup All Websites"
        echo "   44) Update Components"
        echo "   45) Configuration Testing"
        echo "   46) Log Management"
        echo ""
        
        echo -e "${WHITE}📋 MONITORING & MAINTENANCE${NC}"
        echo "   51) Real-time Performance Monitor"
        echo "   52) View Access Logs"
        echo "   53) View Error Logs"
        echo "   54) Cleanup & Optimization"
        echo "   55) Setup Automated Maintenance"
        echo ""
        
        echo -e "${RED}🎯 QUICK ACTIONS${NC}"
        echo "   91) Quick PHP Info"
        echo "   92) Quick Apache Status"
        echo "   93) Quick Website Test"
        echo "   94) Emergency Services Restart"
        echo ""
        
        echo "0) Return to Main Menu"
        echo ""
        echo -n "Select option: "
        
        read choice
        
        case $choice in
            # Installation & Setup
            1) complete_installation_menu ;;
            2) basic_installation ;;
            3) development_installation ;;
            4) production_installation ;;
            5) custom_installation_menu ;;
            
            # Website Management
            11) add_website_wizard ;;
            12) remove_website_wizard ;;
            13) clone_website_wizard ;;
            14) list_websites_detailed ;;
            15) website_content_manager ;;
            
            # SSL & Security
            21) ssl_certificate_wizard ;;
            22) security_hardening_wizard ;;
            23) check_ssl_status ;;
            24) firewall_configuration ;;
            25) setup_auto_ssl_renewal ;;
            
            # Service Management
            31) start_web ;;
            32) stop_web ;;
            33) restart_web ;;
            34) reload_web ;;
            35) webserver_switch_menu ;;
            36) status_web ;;
            
            # Advanced Tools
            41) optimize_web_performance ;;
            42) check_web_health ;;
            43) backup_websites ;;
            44) update_web_components ;;
            45) test_web_config ;;
            46) log_management_menu ;;
            
            # Monitoring & Maintenance
            51) real_time_monitor ;;
            52) view_access_logs_menu ;;
            53) view_error_logs_menu ;;
            54) cleanup_optimization ;;
            55) automated_maintenance_setup ;;
            
            # Quick Actions
            91) quick_php_info ;;
            92) quick_apache_status ;;
            93) quick_website_test ;;
            94) emergency_restart ;;
            
            0) break ;;
            *) 
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

#===========================================
# INSTALLATION MENUS
#===========================================

# Complete installation menu
complete_installation_menu() {
    clear
    show_header "COMPLETE WEB SERVER INSTALLATION"
    
    echo -e "${WHITE}Select installation type:${NC}"
    echo ""
    echo "1) Full Installation (Everything included)"
    echo "2) Basic Installation (Apache + PHP + MySQL)"
    echo "3) Development Installation (Full + Dev tools)"
    echo "4) Production Installation (Full + Security)"
    echo "5) Custom Installation (Choose components)"
    echo "6) Minimal Installation (Core only)"
    echo ""
    echo "0) Back to main menu"
    echo ""
    echo -n "Select installation type: "
    
    read install_type
    
    case $install_type in
        1) full_installation ;;
        2) basic_installation ;;
        3) development_installation ;;
        4) production_installation ;;
        5) custom_installation_menu ;;
        6) minimal_installation ;;
        0) return ;;
        *) 
            echo -e "${RED}Invalid option${NC}"
            sleep 2
            complete_installation_menu
            ;;
    esac
}

# Full installation
full_installation() {
    clear
    show_header "FULL WEB SERVER INSTALLATION"
    
    log_info "Starting complete web server installation..."
    
    # Initialize component arrays
    COMPONENTS_INSTALLED=()
    COMPONENTS_FAILED=()
    
    echo -e "${WHITE}Installing all web server components...${NC}"
    echo ""
    
    # Install all components
    install_apache_complete
    install_nginx_complete  
    install_php_complete
    install_nodejs_complete
    install_python_frameworks
    install_database_components
    install_ssl_components
    install_security_components
    install_monitoring_tools
    install_development_tools
    install_performance_tools
    install_additional_technologies
    
    # Configure services
    configure_production_services
    
    # Show installation summary
    show_installation_summary
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Basic installation
basic_installation() {
    clear
    show_header "BASIC WEB SERVER INSTALLATION"
    
    log_info "Starting basic web server installation..."
    
    COMPONENTS_INSTALLED=()
    COMPONENTS_FAILED=()
    
    echo -e "${WHITE}Installing basic web server components...${NC}"
    echo ""
    
    install_apache_basic
    install_php_basic
    install_ssl_components
    
    configure_basic_services
    
    show_installation_summary
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Development installation
development_installation() {
    clear
    show_header "DEVELOPMENT ENVIRONMENT INSTALLATION"
    
    log_info "Starting development environment installation..."
    
    COMPONENTS_INSTALLED=()
    COMPONENTS_FAILED=()
    
    echo -e "${WHITE}Installing development environment...${NC}"
    echo ""
    
    install_apache_complete
    install_php_complete
    install_nodejs_complete
    install_python_frameworks
    install_database_components
    install_development_tools
    install_ssl_components
    
    configure_development_services
    
    show_installation_summary
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Production installation
production_installation() {
    clear
    show_header "PRODUCTION ENVIRONMENT INSTALLATION"
    
    log_info "Starting production environment installation..."
    
    COMPONENTS_INSTALLED=()
    COMPONENTS_FAILED=()
    
    echo -e "${WHITE}Installing production environment...${NC}"
    echo ""
    
    install_apache_complete
    install_php_complete
    install_database_components
    install_ssl_components
    install_security_components
    install_monitoring_tools
    install_performance_tools
    
    configure_production_services
    harden_web_security
    
    show_installation_summary
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Minimal installation
minimal_installation() {
    clear
    show_header "MINIMAL WEB SERVER INSTALLATION"
    
    log_info "Starting minimal web server installation..."
    
    COMPONENTS_INSTALLED=()
    COMPONENTS_FAILED=()
    
    echo -e "${WHITE}Installing minimal web server...${NC}"
    echo ""
    
    install_core_packages
    configure_minimal_services
    
    show_installation_summary
    
# Custom installation menu
custom_installation_menu() {
    clear
    show_header "CUSTOM COMPONENT INSTALLATION"
    
    echo -e "${WHITE}Select components to install:${NC}"
    echo ""
    
    local components=()
    local choices=()
    
    echo "Available Components:"
    echo ""
    echo "1) Apache Web Server (Complete)"
    echo "2) Nginx Web Server"
    echo "3) PHP (All Extensions)"
    echo "4) Node.js & NPM Tools"
    echo "5) Python Frameworks"
    echo "6) Database Components"
    echo "7) SSL/TLS Tools"
    echo "8) Security Tools"
    echo "9) Monitoring Tools"
    echo "10) Development Tools"
    echo "11) Performance Tools"
    echo "12) Additional Technologies"
    echo ""
    echo "Enter component numbers separated by spaces (e.g., 1 3 7):"
    echo "Or enter 'all' for everything:"
    echo ""
    echo -n "Selection: "
    
    read selection
    
    if [[ "$selection" == "all" ]]; then
        full_installation
        return
    fi
    
    COMPONENTS_INSTALLED=()
    COMPONENTS_FAILED=()
    
    echo ""
    echo -e "${WHITE}Installing selected components...${NC}"
    echo ""
    
    for choice in $selection; do
        case $choice in
            1) install_apache_complete ;;
            2) install_nginx_complete ;;
            3) install_php_complete ;;
            4) install_nodejs_complete ;;
            5) install_python_frameworks ;;
            6) install_database_components ;;
            7) install_ssl_components ;;
            8) install_security_components ;;
            9) install_monitoring_tools ;;
            10) install_development_tools ;;
            11) install_performance_tools ;;
            12) install_additional_technologies ;;
            *) log_warn "Invalid selection: $choice" ;;
        esac
    done
    
    configure_web_services
    show_installation_summary
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Show installation summary
show_installation_summary() {
    echo ""
    echo -e "${WHITE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                 INSTALLATION SUMMARY${NC}"
    echo -e "${WHITE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ ${#COMPONENTS_INSTALLED[@]} -gt 0 ]]; then
        echo -e "${GREEN}✓ Successfully Installed (${#COMPONENTS_INSTALLED[@]} components):${NC}"
        for component in "${COMPONENTS_INSTALLED[@]}"; do
            echo -e "  ${GREEN}✓${NC} $component"
        done
        echo ""
    fi
    
    if [[ ${#COMPONENTS_FAILED[@]} -gt 0 ]]; then
        echo -e "${RED}✗ Failed to Install (${#COMPONENTS_FAILED[@]} components):${NC}"
        for component in "${COMPONENTS_FAILED[@]}"; do
            echo -e "  ${RED}✗${NC} $component"
        done
        echo ""
    fi
    
    # Show next steps
    echo -e "${WHITE}Next Steps:${NC}"
    echo "• Visit http://localhost to test your web server"
    echo "• Use menu option 11 to add websites"
    echo "• Use menu option 21 to enable SSL certificates"
    echo "• Use menu option 42 to run health checks"
    
    if [[ -f "$WEB_INSTALL_LOG" ]]; then
        echo ""
        echo -e "${BLUE}Installation log: $WEB_INSTALL_LOG${NC}"
    fi
}

#===========================================
# WEBSITE MANAGEMENT WIZARDS
#===========================================

# Add website wizard
add_website_wizard() {
    clear
    show_header "ADD NEW WEBSITE WIZARD"
    
    echo -e "${WHITE}Website Configuration:${NC}"
    echo ""
    
    echo -n "Enter domain name (e.g., example.com): "
    read domain
    
    if [[ -z "$domain" ]]; then
        echo -e "${RED}Domain name is required${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo -n "PHP Version (default: 8.1): "
    read php_version
    php_version=${php_version:-8.1}
    
    echo ""
    echo "Enable SSL certificate? [y/N]: "
    read -n 1 ssl_choice
    echo ""
    
    local ssl_enabled="false"
    if [[ "$ssl_choice" =~ ^[Yy]$ ]]; then
        ssl_enabled="true"
    fi
    
    echo ""
    echo -e "${WHITE}Configuration Summary:${NC}"
    echo "  Domain: $domain"
    echo "  PHP Version: $php_version"
    echo "  SSL Enabled: $ssl_enabled"
    echo ""
    
    if confirm_action "Create website with these settings?"; then
        add_website "$domain" "$php_version" "$ssl_enabled"
        echo ""
        echo "Press any key to continue..."
        read -n 1
    fi
}

# Remove website wizard
remove_website_wizard() {
    clear
    show_header "REMOVE WEBSITE WIZARD"
    
    # List current websites
    list_websites
    
    echo ""
    echo -n "Enter domain name to remove: "
    read domain
    
    if [[ -z "$domain" ]]; then
        echo -e "${RED}Domain name is required${NC}"
        sleep 2
        return
    fi
    
    if [[ ! -d "/var/www/$domain" ]]; then
        echo -e "${RED}Website $domain does not exist${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo -e "${YELLOW}WARNING: This will permanently delete all files for $domain${NC}"
    echo "A backup will be created before removal."
    echo ""
    
    if confirm_action "Are you sure you want to remove $domain?"; then
        remove_website "$domain"
        echo ""
        echo "Press any key to continue..."
        read -n 1
    fi
}

# Clone website wizard
clone_website_wizard() {
    clear
    show_header "CLONE WEBSITE WIZARD"
    
    # List current websites
    list_websites
    
    echo ""
    echo -n "Enter source domain to clone FROM: "
    read source_domain
    
    if [[ -z "$source_domain" ]] || [[ ! -d "/var/www/$source_domain" ]]; then
        echo -e "${RED}Source domain does not exist${NC}"
        sleep 2
        return
    fi
    
    echo -n "Enter target domain to clone TO: "
    read target_domain
    
    if [[ -z "$target_domain" ]]; then
        echo -e "${RED}Target domain is required${NC}"
        sleep 2
        return
    fi
    
    if [[ -d "/var/www/$target_domain" ]]; then
        echo -e "${RED}Target domain already exists${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo -e "${WHITE}Clone Configuration:${NC}"
    echo "  From: $source_domain"
    echo "  To: $target_domain"
    echo ""
    
    if confirm_action "Clone website?"; then
        clone_website "$source_domain" "$target_domain"
        echo ""
        echo "Press any key to continue..."
        read -n 1
    fi
}

# List websites with detailed information
list_websites_detailed() {
    clear
    show_header "WEBSITE LISTING"
    
    list_websites
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Website content manager
website_content_manager() {
    clear
    show_header "WEBSITE CONTENT MANAGER"
    
    # List websites first
    list_websites
    
    echo ""
    echo -n "Enter domain name to manage: "
    read domain
    
    if [[ -z "$domain" ]] || [[ ! -d "/var/www/$domain" ]]; then
        echo -e "${RED}Website does not exist${NC}"
        sleep 2
        return
    fi
    
    while true; do
        clear
        show_header "CONTENT MANAGER - $domain"
        
        echo -e "${WHITE}Document Root:${NC} /var/www/$domain/public_html"
        echo ""
        echo "1) View current files"
        echo "2) Edit index.html"
        echo "3) Upload files (manual)"
        echo "4) Set permissions"
        echo "5) View logs"
        echo "0) Back"
        echo ""
        echo -n "Select option: "
        
        read content_choice
        
        case $content_choice in
            1)
                echo ""
                echo -e "${WHITE}Files in /var/www/$domain/public_html:${NC}"
                ls -la "/var/www/$domain/public_html" 2>/dev/null || echo "Directory not found"
                echo ""
                echo "Press any key to continue..."
                read -n 1
                ;;
            2)
                if command -v nano >/dev/null 2>&1; then
                    nano "/var/www/$domain/public_html/index.html"
                else
                    echo "Editor not available"
                    sleep 2
                fi
                ;;
            3)
                echo ""
                echo "To upload files:"
                echo "1. Use SCP: scp file.html user@server:/var/www/$domain/public_html/"
                echo "2. Use FTP client"
                echo "3. Copy files directly to /var/www/$domain/public_html/"
                echo ""
                echo "Press any key to continue..."
                read -n 1
                ;;
            4)
                chown -R www-data:www-data "/var/www/$domain"
                chmod -R 755 "/var/www/$domain"
                echo "Permissions set correctly"
                sleep 2
                ;;
            5)
                echo ""
                echo -e "${WHITE}Recent access log entries:${NC}"
                tail -10 "/var/www/$domain/logs/access.log" 2>/dev/null || echo "No logs found"
                echo ""
                echo "Press any key to continue..."
                read -n 1
                ;;
            0) break ;;
            *) 
                echo "Invalid option"
                sleep 1
                ;;
        esac
    done
}

#===========================================
# SSL & SECURITY WIZARDS
#===========================================

# SSL certificate wizard
ssl_certificate_wizard() {
    clear
    show_header "SSL CERTIFICATE WIZARD"
    
    # List websites
    list_websites
    
    echo ""
    echo -n "Enter domain name for SSL certificate: "
    read domain
    
    if [[ -z "$domain" ]]; then
        echo -e "${RED}Domain name is required${NC}"
        sleep 2
        return
    fi
    
    if [[ ! -d "/var/www/$domain" ]]; then
        echo -e "${RED}Website $domain does not exist${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo -e "${WHITE}SSL Certificate Options:${NC}"
    echo "1) Automatic certificate (Let's Encrypt)"
    echo "2) Manual certificate installation"
    echo ""
    echo -n "Select option: "
    read ssl_option
    
    case $ssl_option in
        1)
            echo ""
            echo "Force certificate installation (skip domain verification)? [y/N]: "
            read -n 1 force_choice
            echo ""
            
            local force="false"
            if [[ "$force_choice" =~ ^[Yy]$ ]]; then
                force="true"
            fi
            
            enable_ssl "$domain" "$force"
            ;;
        2)
            echo ""
            echo "Manual SSL certificate installation:"
            echo "1. Place certificate files in /var/www/$domain/ssl/"
            echo "2. Update virtual host configuration"
            echo "3. Restart web server"
            echo ""
            echo "Press any key to continue..."
            read -n 1
            ;;
        *)
            echo "Invalid option"
            sleep 2
            ;;
    esac
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Security hardening wizard
security_hardening_wizard() {
    clear
    show_header "SECURITY HARDENING WIZARD"
    
    echo -e "${WHITE}Security Hardening Options:${NC}"
    echo ""
    echo "This will apply comprehensive security settings:"
    echo "• Secure file permissions"
    echo "• Firewall configuration"
    echo "• Security headers"
    echo "• PHP security settings"
    echo "• Fail2Ban protection"
    echo ""
    
    if confirm_action "Apply security hardening?"; then
        harden_web_security
        echo ""
        echo "Press any key to continue..."
        read -n 1
    fi
}

# Check SSL status
check_ssl_status() {
    clear
    show_header "SSL CERTIFICATE STATUS"
    
    check_ssl_expiry_all
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Firewall configuration
firewall_configuration() {
    clear
    show_header "FIREWALL CONFIGURATION"
    
    if ! command -v ufw >/dev/null 2>&1; then
        echo "Installing UFW firewall..."
        apt-get update >/dev/null 2>&1
        apt-get install -y ufw >/dev/null 2>&1
    fi
    
    echo -e "${WHITE}Current firewall status:${NC}"
    ufw status verbose
    
    echo ""
    echo -e "${WHITE}Firewall Options:${NC}"
    echo "1) Enable basic web server rules"
    echo "2) View current rules"
    echo "3) Add custom rule"
    echo "4) Reset firewall"
    echo "0) Back"
    echo ""
    echo -n "Select option: "
    
    read fw_choice
    
    case $fw_choice in
        1)
            echo "Configuring basic firewall rules..."
            ufw --force reset
            ufw default deny incoming
            ufw default allow outgoing
            ufw allow ssh
            ufw allow 80/tcp comment 'HTTP'
            ufw allow 443/tcp comment 'HTTPS'
            ufw --force enable
            echo "Basic rules configured"
            ;;
        2)
            ufw status numbered
            ;;
        3)
            echo -n "Enter rule (e.g., 'allow 8080/tcp'): "
            read rule
            if [[ -n "$rule" ]]; then
                ufw $rule
            fi
            ;;
        4)
            if confirm_action "Reset all firewall rules?"; then
                ufw --force reset
                echo "Firewall reset"
            fi
            ;;
        0) return ;;
    esac
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

#===========================================
# QUICK ACTION FUNCTIONS
#===========================================

# Quick PHP info
quick_php_info() {
    clear
    show_header "PHP INFORMATION"
    
    if command -v php >/dev/null 2>&1; then
        php -v
        echo ""
        echo "Loaded modules:"
        php -m | head -20
        echo ""
        if [[ $(php -m | wc -l) -gt 20 ]]; then
            echo "... and $(($(php -m | wc -l) - 20)) more modules"
        fi
    else
        echo "PHP is not installed"
    fi
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Quick Apache status
quick_apache_status() {
    clear
    show_header "APACHE STATUS"
    
    if systemctl is-active --quiet apache2; then
        echo -e "${GREEN}Apache is running${NC}"
        echo ""
        apache2ctl status 2>/dev/null || systemctl status apache2 --no-pager
    else
        echo -e "${RED}Apache is not running${NC}"
        echo ""
        systemctl status apache2 --no-pager
    fi
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Quick website test
quick_website_test() {
    clear
    show_header "QUICK WEBSITE TEST"
    
    echo -n "Enter domain to test (or press Enter for localhost): "
    read test_domain
    test_domain=${test_domain:-localhost}
    
    echo ""
    echo "Testing $test_domain..."
    echo ""
    
    # Test HTTP
    if curl -I "http://$test_domain" 2>/dev/null | head -1; then
        echo -e "${GREEN}✓ HTTP response received${NC}"
    else
        echo -e "${RED}✗ HTTP test failed${NC}"
    fi
    
    # Test HTTPS if available
    if curl -I "https://$test_domain" 2>/dev/null | head -1; then
        echo -e "${GREEN}✓ HTTPS response received${NC}"
    else
        echo -e "${YELLOW}○ HTTPS not available${NC}"
    fi
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Emergency restart
emergency_restart() {
    clear
    show_header "EMERGENCY SERVICES RESTART"
    
    echo -e "${YELLOW}This will restart all web services${NC}"
    echo ""
    
    if confirm_action "Proceed with emergency restart?"; then
        echo "Restarting services..."
        systemctl restart apache2 2>/dev/null && echo "✓ Apache restarted"
        systemctl restart nginx 2>/dev/null && echo "✓ Nginx restarted"
        systemctl restart php*-fpm 2>/dev/null && echo "✓ PHP-FPM restarted"
        echo ""
        echo "Emergency restart completed"
    fi
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

#===========================================
# SERVICE MANAGEMENT FUNCTIONS
#===========================================

# Web server switch menu
webserver_switch_menu() {
    clear
    show_header "WEB SERVER SWITCH"
    
    echo -e "${WHITE}Current Status:${NC}"
    if systemctl is-active --quiet apache2; then
        echo -e "  Apache: ${GREEN}Running${NC}"
    else
        echo -e "  Apache: ${RED}Stopped${NC}"
    fi
    
    if systemctl is-active --quiet nginx; then
        echo -e "  Nginx: ${GREEN}Running${NC}"
    else
        echo -e "  Nginx: ${RED}Stopped${NC}"
    fi
    
    echo ""
    echo "1) Switch to Apache"
    echo "2) Switch to Nginx"
    echo "0) Back"
    echo ""
    echo -n "Select option: "
    
    read switch_choice
    
    case $switch_choice in
        1) switch_webserver "apache" ;;
        2) switch_webserver "nginx" ;;
        0) return ;;
        *) 
            echo "Invalid option"
            sleep 2
            ;;
    esac
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

#===========================================
# MONITORING FUNCTIONS
#===========================================

# Real-time monitor
real_time_monitor() {
    clear
    show_header "REAL-TIME PERFORMANCE MONITOR"
    
    echo "Press Ctrl+C to exit monitoring"
    echo ""
    
    while true; do
        clear
        show_header "REAL-TIME PERFORMANCE MONITOR"
        
        monitor_web_performance
        
        echo ""
        echo "Refreshing in 5 seconds... (Ctrl+C to exit)"
        sleep 5
    done
}

# Log management menu
log_management_menu() {
    clear
    show_header "LOG MANAGEMENT"
    
    echo "1) View Apache access logs"
    echo "2) View Apache error logs"
    echo "3) View Nginx logs"
    echo "4) View PHP logs"
    echo "5) Clear old logs"
    echo "6) Setup log rotation"
    echo "0) Back"
    echo ""
    echo -n "Select option: "
    
    read log_choice
    
    case $log_choice in
        1) view_apache_access_logs ;;
        2) view_apache_error_logs ;;
        3) view_nginx_logs ;;
        4) view_php_logs ;;
        5) clear_old_logs ;;
        6) setup_log_rotation ;;
        0) return ;;
        *) 
            echo "Invalid option"
            sleep 2
            log_management_menu
            ;;
    esac
}

# View access logs menu
view_access_logs_menu() {
    view_apache_access_logs
}

# View error logs menu  
view_error_logs_menu() {
    view_apache_error_logs
}

# Cleanup optimization
cleanup_optimization() {
    clear
    show_header "CLEANUP & OPTIMIZATION"
    
    echo "Performing cleanup and optimization..."
    echo ""
    
    optimize_web_performance
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Automated maintenance setup
automated_maintenance_setup() {
    clear
    show_header "AUTOMATED MAINTENANCE SETUP"
    
    echo "Setting up automated maintenance..."
    echo ""
    
    # Create maintenance script
    create_maintenance_script
    
    echo "Automated maintenance has been configured to run weekly"
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

#===========================================
# LOG VIEWING FUNCTIONS
#===========================================

# View Apache access logs
view_apache_access_logs() {
    clear
    show_header "APACHE ACCESS LOGS"
    
    echo "Recent Apache access log entries:"
    echo ""
    
    if [[ -f "/var/log/apache2/access.log" ]]; then
        tail -20 /var/log/apache2/access.log
    else
        echo "No Apache access logs found"
    fi
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# View Apache error logs
view_apache_error_logs() {
    clear
    show_header "APACHE ERROR LOGS"
    
    echo "Recent Apache error log entries:"
    echo ""
    
    if [[ -f "/var/log/apache2/error.log" ]]; then
        tail -20 /var/log/apache2/error.log
    else
        echo "No Apache error logs found"
    fi
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# View Nginx logs
view_nginx_logs() {
    clear
    show_header "NGINX LOGS"
    
    echo "Recent Nginx log entries:"
    echo ""
    
    if [[ -f "/var/log/nginx/access.log" ]]; then
        echo "Access logs:"
        tail -10 /var/log/nginx/access.log
        echo ""
    fi
    
    if [[ -f "/var/log/nginx/error.log" ]]; then
        echo "Error logs:"
        tail -10 /var/log/nginx/error.log
    fi
    
    if [[ ! -f "/var/log/nginx/access.log" ]] && [[ ! -f "/var/log/nginx/error.log" ]]; then
        echo "No Nginx logs found"
    fi
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# View PHP logs
view_php_logs() {
    clear
    show_header "PHP LOGS"
    
    echo "Recent PHP log entries:"
    echo ""
    
    local php_log="/var/log/php_errors.log"
    local fpm_log="/var/log/php*-fpm.log"
    
    if [[ -f "$php_log" ]]; then
        tail -10 "$php_log"
    elif ls $fpm_log >/dev/null 2>&1; then
        tail -10 $fpm_log
    else
        echo "No PHP logs found"
        echo "Check /var/log/ for PHP-related log files"
    fi
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Clear old logs
clear_old_logs() {
    clear
    show_header "CLEAR OLD LOGS"
    
    if confirm_action "Clear log files older than 30 days?"; then
        echo "Clearing old log files..."
        
        find /var/log -name "*.log.*" -atime +30 -delete 2>/dev/null
        find /var/log -name "*.gz" -atime +30 -delete 2>/dev/null
        
        echo "Old log files cleared"
    fi
    
    echo ""
    echo "Press any key to continue..."
    read -n 1
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
                install_php_extensions_interactive
                ;;
            7)
                install_nodejs_interactive
                ;;
            8)
                bash "$BASE_DIR/maintain.sh"
                ;;
            9)
                bash "$BASE_DIR/update.sh"
                ;;
            10)
                advanced_config_menu
                ;;
            0)
                break
                ;;
        esac
    done
}

# Interactive website addition
add_website_interactive() {
    clear
    show_header "ADD NEW WEBSITE"
    
    echo "This will create a new virtual host for your domain."
    echo ""
    
    local domain=$(ask_domain)
    if [[ $? -ne 0 ]]; then
        pause "Press Enter to continue..."
        return
    fi
    
    if ! validate_domain "$domain"; then
        log_error "Invalid domain format"
        pause "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo "Available web servers:"
    local servers=()
    if check_service_installed "apache2"; then
        servers+=("apache")
        echo "1) Apache2"
    fi
    if check_service_installed "nginx"; then
        servers+=("nginx")
        echo "${#servers[@]}) Nginx"
    fi
    
    if [[ ${#servers[@]} -eq 0 ]]; then
        log_error "No web server installed. Please install Apache or Nginx first."
        pause "Press Enter to continue..."
        return
    fi
    
    echo ""
    local server_choice=$(get_menu_choice ${#servers[@]})
    if [[ $server_choice -eq 0 ]]; then
        return
    fi
    
    local selected_server=${servers[$((server_choice-1))]}
    
    log_info "Creating website: $domain using $selected_server"
    add_website "$domain" "$selected_server"
    
    pause "Press Enter to continue..."
}

# Interactive website removal
remove_website_interactive() {
    clear
    show_header "REMOVE WEBSITE"
    
    local domain=$(ask_domain)
    if [[ $? -ne 0 ]]; then
        pause "Press Enter to continue..."
        return
    fi
    
    if confirm_action "This will remove the virtual host for $domain. Continue?"; then
        remove_website "$domain"
    else
        log_info "Website removal cancelled"
    fi
    
    pause "Press Enter to continue..."
}

# Interactive SSL enablement
enable_ssl_interactive() {
    clear
    show_header "ENABLE SSL FOR WEBSITE"
    
    local domain=$(ask_domain)
    if [[ $? -ne 0 ]]; then
        pause "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo "SSL Certificate Options:"
    echo "1) Let's Encrypt (Free, Automatic)"
    echo "2) Self-Signed Certificate"
    echo "0) Cancel"
    echo ""
    
    local ssl_choice=$(get_menu_choice 2)
    
    case $ssl_choice in
        1)
            local email=$(ask_email)
            if [[ $? -eq 0 ]]; then
                log_info "Setting up Let's Encrypt SSL for $domain"
                enable_ssl "$domain" "letsencrypt" "$email"
            fi
            ;;
        2)
            log_info "Creating self-signed certificate for $domain"
            enable_ssl "$domain" "selfsigned"
            ;;
        0)
            log_info "SSL setup cancelled"
            ;;
    esac
    
    pause "Press Enter to continue..."
}

# List websites
list_websites_interactive() {
    clear
    show_header "ACTIVE WEBSITES"
    
    echo "=== Apache Virtual Hosts ==="
    if check_service_installed "apache2"; then
        if [[ -d /etc/apache2/sites-available ]]; then
            ls -1 /etc/apache2/sites-available/*.conf 2>/dev/null | sed 's/.*\///' | sed 's/\.conf$//' || echo "No Apache sites found"
        fi
    else
        echo "Apache not installed"
    fi
    
    echo ""
    echo "=== Nginx Server Blocks ==="
    if check_service_installed "nginx"; then
        if [[ -d /etc/nginx/sites-available ]]; then
            ls -1 /etc/nginx/sites-available/ 2>/dev/null | grep -v default || echo "No Nginx sites found"
        fi
    else
        echo "Nginx not installed"
    fi
    
    echo ""
    echo "=== SSL Certificates ==="
    if command_exists certbot; then
        certbot certificates 2>/dev/null | grep "Certificate Name" | awk '{print $3}' || echo "No certificates found"
    else
        echo "Certbot not installed"
    fi
    
    pause "Press Enter to continue..."
}

# Install PHP extensions
install_php_extensions_interactive() {
    clear
    show_header "INSTALL PHP EXTENSIONS"
    
    if ! check_package_installed "php"; then
        log_error "PHP is not installed. Please install the web server stack first."
        pause "Press Enter to continue..."
        return
    fi
    
    echo "Common PHP Extensions:"
    echo "1) MySQL/MariaDB (php-mysql)"
    echo "2) PostgreSQL (php-pgsql)"
    echo "3) cURL (php-curl)"
    echo "4) GD Graphics (php-gd)"
    echo "5) XML (php-xml)"
    echo "6) Zip (php-zip)"
    echo "7) Mbstring (php-mbstring)"
    echo "8) JSON (php-json)"
    echo "9) Install All Common Extensions"
    echo "0) Cancel"
    echo ""
    
    local choice=$(get_menu_choice 9)
    
    case $choice in
        1) install_php_extension "php-mysql" ;;
        2) install_php_extension "php-pgsql" ;;
        3) install_php_extension "php-curl" ;;
        4) install_php_extension "php-gd" ;;
        5) install_php_extension "php-xml" ;;
        6) install_php_extension "php-zip" ;;
        7) install_php_extension "php-mbstring" ;;
        8) install_php_extension "php-json" ;;
        9) 
            log_info "Installing all common PHP extensions..."
            for ext in "php-mysql" "php-curl" "php-gd" "php-xml" "php-zip" "php-mbstring" "php-json"; do
                install_php_extension "$ext"
            done
            ;;
        0) log_info "Installation cancelled" ;;
    esac
    
    pause "Press Enter to continue..."
}

# Install Node.js
install_nodejs_interactive() {
    clear
    show_header "INSTALL NODE.JS & NPM"
    
    if command_exists node; then
        local node_version=$(node -v)
        log_info "Node.js is already installed: $node_version"
        if ! confirm_action "Do you want to update/reinstall Node.js?"; then
            return
        fi
    fi
    
    log_info "Installing Node.js and NPM..."
    install_nodejs
    
    if command_exists node && command_exists npm; then
        echo ""
        log_ok "Node.js and NPM installed successfully!"
        echo "Node.js version: $(node -v)"
        echo "NPM version: $(npm -v)"
    else
        log_error "Node.js installation failed"
    fi
    
    pause "Press Enter to continue..."
}

# Advanced configuration menu
advanced_config_menu() {
    while true; do
        clear
        show_header "ADVANCED WEB CONFIGURATION"
        
        echo "1) Configure Apache Security"
        echo "2) Configure Nginx Security"
        echo "3) Setup Load Balancing"
        echo "4) Configure Caching"
        echo "5) Backup Web Configurations"
        echo "6) Restore Web Configurations"
        echo "7) View Configuration Files"
        echo "0) Back"
        echo ""
        
        local choice=$(get_menu_choice 7)
        
        case $choice in
            1) configure_apache_security ;;
            2) configure_nginx_security ;;
            3) configure_load_balancing ;;
            4) configure_caching ;;
            5) backup_web_configs ;;
            6) restore_web_configs ;;
            7) view_config_files ;;
            0) break ;;
        esac
        
        pause "Press Enter to continue..."
    done
}

# Helper functions for advanced config
configure_apache_security() {
    log_info "Configuring Apache security settings..."
    # Implementation would go here
    log_warn "Feature not yet implemented"
}

configure_nginx_security() {
    log_info "Configuring Nginx security settings..."
    # Implementation would go here
    log_warn "Feature not yet implemented"
}

configure_load_balancing() {
    log_info "Setting up load balancing..."
    # Implementation would go here
    log_warn "Feature not yet implemented"
}

configure_caching() {
    log_info "Configuring web caching..."
    # Implementation would go here
    log_warn "Feature not yet implemented"
}

view_config_files() {
    echo "=== Apache Configuration Files ==="
    if [[ -f /etc/apache2/apache2.conf ]]; then
        echo "/etc/apache2/apache2.conf"
        echo "/etc/apache2/sites-available/"
        echo "/etc/apache2/sites-enabled/"
    fi
    
    echo ""
    echo "=== Nginx Configuration Files ==="
    if [[ -f /etc/nginx/nginx.conf ]]; then
        echo "/etc/nginx/nginx.conf"
        echo "/etc/nginx/sites-available/"
        echo "/etc/nginx/sites-enabled/"
    fi
}

# Helper functions that work with existing functions.sh
install_php_extension() {
    local extension="$1"
    log_info "Installing PHP extension: $extension"
    apt update -y >/dev/null 2>&1
    apt install -y "$extension"
    
    if check_package_installed "${extension#php-}"; then
        log_ok "PHP extension $extension installed"
        # Restart web services to load new extension
        restart_web
    else
        log_error "Failed to install PHP extension $extension"
    fi
}

# Run main function
main "$@"
