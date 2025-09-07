#!/bin/bash
# Web Server Management Menu

# Get base directory and source functions
BASE_DIR="$(dirname "$0")"
source "$BASE_DIR/functions.sh"
source "$(dirname "$BASE_DIR")/common.sh"

# Main menu function
main() {
    while true; do
        clear
        show_header "WEB SERVER MANAGEMENT"
        
        # Show current status
        echo -e "${WHITE}Current Status:${NC}"
        if systemctl is-active --quiet apache2; then
            echo -e "  ${GREEN}✓${NC} Apache2: Running"
        elif check_service_installed "apache2"; then
            echo -e "  ${RED}✗${NC} Apache2: Stopped"
        else
            echo -e "  ${YELLOW}○${NC} Apache2: Not Installed"
        fi
        
        if systemctl is-active --quiet nginx; then
            echo -e "  ${GREEN}✓${NC} Nginx: Running"
        elif check_service_installed "nginx"; then
            echo -e "  ${RED}✗${NC} Nginx: Stopped"
        else
            echo -e "  ${YELLOW}○${NC} Nginx: Not Installed"
        fi
        
        if check_package_installed "php"; then
            local php_version=$(php -v 2>/dev/null | head -1 | awk '{print $2}' | cut -d. -f1,2)
            echo -e "  ${GREEN}✓${NC} PHP: Installed (v$php_version)"
        else
            echo -e "  ${YELLOW}○${NC} PHP: Not Installed"
        fi
        
        echo ""
        echo -e "${WHITE}Management Options:${NC}"
        echo ""
        echo "1) Install Web Server Stack"
        echo "2) Add New Website/Virtual Host"
        echo "3) Remove Website"
        echo "4) Enable SSL for Website"
        echo "5) List Websites"
        echo "6) Install PHP Extensions"
        echo "7) Install Node.js & NPM"
        echo "8) Website Maintenance"
        echo "9) Update Web Components"
        echo "10) Advanced Configuration"
        echo "0) Back to Main Menu"
        echo ""
        
        local choice=$(get_menu_choice 10)
        
        case $choice in
            1)
                bash "$BASE_DIR/install.sh"
                ;;
            2)
                add_website_interactive
                ;;
            3)
                remove_website_interactive
                ;;
            4)
                enable_ssl_interactive
                ;;
            5)
                list_websites_interactive
                ;;
            6)
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
