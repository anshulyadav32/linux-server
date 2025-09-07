#!/bin/bash
# Interdependent Automation Script
# Orchestrates complex workflows across multiple service modules

# Get base directory and source functions
BASE_DIR="$(dirname "$0")"
source "$BASE_DIR/common.sh"

# Source all module functions
source "$BASE_DIR/web/functions.sh"
source "$BASE_DIR/dns/functions.sh"
source "$BASE_DIR/mail/functions.sh"
source "$BASE_DIR/ssl/functions.sh"
source "$BASE_DIR/firewall/functions.sh"
source "$BASE_DIR/db/functions.sh"
source "$BASE_DIR/system/functions.sh"
source "$BASE_DIR/backup/functions.sh"

# Main automation menu
main() {
    while true; do
        clear
        show_header "INTERDEPENDENT AUTOMATION"
        
        echo -e "${WHITE}Automated Workflows:${NC}"
        echo ""
        echo -e "${CYAN}Complete Server Setups:${NC}"
        echo "1) Full LAMP Stack Setup (Linux + Apache + MySQL + PHP)"
        echo "2) Full LEMP Stack Setup (Linux + Nginx + MySQL + PHP)"
        echo "3) Complete Mail Server Setup (Postfix + Dovecot + DNS)"
        echo "4) Full Website Deploy (Web + DNS + SSL + Firewall)"
        echo ""
        echo -e "${CYAN}Service Combinations:${NC}"
        echo "5) Website + DNS + SSL only"
        echo "6) Mail Domain Setup (DNS + Mail + Security)"
        echo "7) Database + Web + SSL"
        echo "8) Security Hardening (Firewall + SSL + System)"
        echo ""
        echo -e "${CYAN}Maintenance Workflows:${NC}"
        echo "9) Complete System Backup"
        echo "10) Security Audit & Hardening"
        echo "11) Performance Optimization"
        echo "12) Disaster Recovery Setup"
        echo ""
        echo -e "${RED}0) Back to Main Menu${NC}"
        echo ""
        
        local choice=$(get_menu_choice 12)
        
        case $choice in
            1) setup_lamp_stack ;;
            2) setup_lemp_stack ;;
            3) setup_complete_mail_server ;;
            4) setup_full_website ;;
            5) setup_website_dns_ssl ;;
            6) setup_mail_domain ;;
            7) setup_database_web_ssl ;;
            8) setup_security_hardening ;;
            9) perform_complete_backup ;;
            10) perform_security_audit ;;
            11) perform_optimization ;;
            12) setup_disaster_recovery ;;
            0) break ;;
        esac
    done
}

# LAMP Stack Setup (Apache + MySQL + PHP)
setup_lamp_stack() {
    clear
    show_header "FULL LAMP STACK SETUP"
    
    log_info "This will install and configure a complete LAMP stack:"
    echo "  ✓ Apache web server"
    echo "  ✓ MySQL database server"
    echo "  ✓ PHP with common extensions"
    echo "  ✓ Basic security configuration"
    echo "  ✓ Firewall rules"
    echo ""
    
    if ! confirm_action "Continue with LAMP stack installation?"; then
        return
    fi
    
    local domain=$(ask_domain)
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    local db_password=$(ask_password)
    echo ""
    
    log_info "Starting LAMP stack installation..."
    
    # Step 1: Install web server
    log_info "Step 1/6: Installing Apache web server..."
    install_web
    
    # Step 2: Install database
    log_info "Step 2/6: Installing MySQL database..."
    install_mysql
    
    # Step 3: Configure firewall
    log_info "Step 3/6: Configuring firewall..."
    if ! check_service_installed "ufw"; then
        install_firewall
    fi
    allow_service "web"
    
    # Step 4: Create website
    log_info "Step 4/6: Setting up website for $domain..."
    add_website "$domain" "apache"
    
    # Step 5: Create database
    log_info "Step 5/6: Creating database for $domain..."
    local db_name=$(echo "$domain" | sed 's/\./_/g')
    create_mysql_db "${db_name}_db" "${db_name}_user" "$db_password"
    
    # Step 6: Setup SSL
    log_info "Step 6/6: Setting up SSL certificate..."
    local email="admin@$domain"
    generate_letsencrypt_cert "$domain" "apache" "$email"
    
    log_ok "LAMP stack setup completed successfully!"
    echo ""
    echo "=== Setup Summary ==="
    echo "Domain: $domain"
    echo "Web Server: Apache"
    echo "Database: MySQL"
    echo "Database Name: ${db_name}_db"
    echo "Database User: ${db_name}_user"
    echo "SSL: Let's Encrypt"
    echo ""
    echo "You can now upload your website files to /var/www/$domain/"
    
    pause "Press Enter to continue..."
}

# LEMP Stack Setup (Nginx + MySQL + PHP)
setup_lemp_stack() {
    clear
    show_header "FULL LEMP STACK SETUP"
    
    log_info "This will install and configure a complete LEMP stack:"
    echo "  ✓ Nginx web server"
    echo "  ✓ MySQL database server"
    echo "  ✓ PHP-FPM with common extensions"
    echo "  ✓ Basic security configuration"
    echo "  ✓ Firewall rules"
    echo ""
    
    if ! confirm_action "Continue with LEMP stack installation?"; then
        return
    fi
    
    local domain=$(ask_domain)
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    local db_password=$(ask_password)
    echo ""
    
    log_info "Starting LEMP stack installation..."
    
    # Step 1: Install web server (Nginx)
    log_info "Step 1/6: Installing Nginx web server..."
    install_web
    
    # Step 2: Install database
    log_info "Step 2/6: Installing MySQL database..."
    install_mysql
    
    # Step 3: Configure firewall
    log_info "Step 3/6: Configuring firewall..."
    if ! check_service_installed "ufw"; then
        install_firewall
    fi
    allow_service "web"
    
    # Step 4: Create website
    log_info "Step 4/6: Setting up website for $domain..."
    add_website "$domain" "nginx"
    
    # Step 5: Create database
    log_info "Step 5/6: Creating database for $domain..."
    local db_name=$(echo "$domain" | sed 's/\./_/g')
    create_mysql_db "${db_name}_db" "${db_name}_user" "$db_password"
    
    # Step 6: Setup SSL
    log_info "Step 6/6: Setting up SSL certificate..."
    local email="admin@$domain"
    generate_letsencrypt_cert "$domain" "nginx" "$email"
    
    log_ok "LEMP stack setup completed successfully!"
    echo ""
    echo "=== Setup Summary ==="
    echo "Domain: $domain"
    echo "Web Server: Nginx"
    echo "Database: MySQL"
    echo "Database Name: ${db_name}_db"
    echo "Database User: ${db_name}_user"
    echo "SSL: Let's Encrypt"
    echo ""
    echo "You can now upload your website files to /var/www/$domain/"
    
    pause "Press Enter to continue..."
}

# Complete Mail Server Setup
setup_complete_mail_server() {
    clear
    show_header "COMPLETE MAIL SERVER SETUP"
    
    log_info "This will install and configure a complete mail server:"
    echo "  ✓ Postfix (SMTP server)"
    echo "  ✓ Dovecot (IMAP/POP3 server)"
    echo "  ✓ DNS records (MX, SPF, DKIM, DMARC)"
    echo "  ✓ SSL certificates for mail"
    echo "  ✓ Security configuration"
    echo "  ✓ Firewall rules"
    echo ""
    
    if ! confirm_action "Continue with mail server setup?"; then
        return
    fi
    
    local domain=$(ask_domain)
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    local server_ip=$(get_server_ip)
    echo "Using server IP: $server_ip"
    
    log_info "Starting complete mail server setup..."
    
    # Step 1: Install mail server
    log_info "Step 1/7: Installing mail server components..."
    install_mail
    
    # Step 2: Configure DNS if DNS server exists
    if check_service_installed "bind9"; then
        log_info "Step 2/7: Configuring DNS records..."
        # Add MX record
        add_record "$domain" "@" "MX" "10 mail.$domain."
        # Add mail subdomain
        add_record "$domain" "mail" "A" "$server_ip"
    else
        log_warn "Step 2/7: DNS server not installed - you'll need to manually configure DNS"
        echo "Required DNS records:"
        echo "  MX: @ IN MX 10 mail.$domain."
        echo "  A: mail IN A $server_ip"
    fi
    
    # Step 3: Configure firewall
    log_info "Step 3/7: Configuring firewall for mail services..."
    if ! check_service_installed "ufw"; then
        install_firewall
    fi
    allow_service "mail"
    
    # Step 4: Setup DKIM
    log_info "Step 4/7: Configuring DKIM..."
    configure_dkim "$domain"
    
    # Step 5: Generate SSL certificate for mail
    log_info "Step 5/7: Setting up SSL for mail server..."
    generate_letsencrypt_cert "mail.$domain" "standalone" "admin@$domain"
    
    # Step 6: Add mail domain
    log_info "Step 6/7: Adding mail domain..."
    add_mail_domain "$domain"
    
    # Step 7: Create first mail user
    log_info "Step 7/7: Creating administrator mail account..."
    local mail_password=$(ask_password)
    add_mail_user "admin" "$mail_password" "$domain"
    
    log_ok "Complete mail server setup finished!"
    echo ""
    echo "=== Mail Server Summary ==="
    echo "Domain: $domain"
    echo "Mail Server: mail.$domain"
    echo "Admin Email: admin@$domain"
    echo "IMAP Port: 993 (SSL)"
    echo "SMTP Port: 587 (STARTTLS)"
    echo ""
    echo "=== Important Next Steps ==="
    echo "1. Update DNS at your domain registrar with the displayed DKIM record"
    echo "2. Add SPF record: 'v=spf1 ip4:$server_ip ~all'"
    echo "3. Add DMARC record: 'v=DMARC1; p=quarantine; rua=mailto:dmarc@$domain'"
    echo "4. Test mail delivery and receiving"
    
    pause "Press Enter to continue..."
}

# Full Website Deploy
setup_full_website() {
    clear
    show_header "FULL WEBSITE DEPLOYMENT"
    
    log_info "This will deploy a complete website with:"
    echo "  ✓ Web server (Apache or Nginx)"
    echo "  ✓ DNS zone and records"
    echo "  ✓ SSL certificate"
    echo "  ✓ Firewall configuration"
    echo "  ✓ Security hardening"
    echo ""
    
    if ! confirm_action "Continue with full website deployment?"; then
        return
    fi
    
    local domain=$(ask_domain)
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    local email=$(ask_email)
    if [[ $? -ne 0 ]]; then
        email="admin@$domain"
    fi
    
    local server_ip=$(get_server_ip)
    
    log_info "Starting full website deployment..."
    
    # Step 1: Install web server if not installed
    if ! check_package_installed "apache2" && ! check_package_installed "nginx"; then
        log_info "Step 1/6: Installing web server..."
        install_web
    else
        log_info "Step 1/6: Web server already installed"
    fi
    
    # Step 2: Configure DNS
    log_info "Step 2/6: Configuring DNS..."
    if check_service_installed "bind9"; then
        add_zone "$domain" "$server_ip"
        add_record "$domain" "www" "CNAME" "$domain."
    else
        log_warn "DNS server not installed - you'll need to configure DNS manually"
        echo "Required DNS records:"
        echo "  A: @ IN A $server_ip"
        echo "  CNAME: www IN CNAME $domain."
    fi
    
    # Step 3: Configure firewall
    log_info "Step 3/6: Configuring firewall..."
    if ! check_service_installed "ufw"; then
        install_firewall
    fi
    allow_service "web"
    
    # Step 4: Create website
    log_info "Step 4/6: Creating website..."
    if check_package_installed "apache2"; then
        add_website "$domain" "apache"
    else
        add_website "$domain" "nginx"
    fi
    
    # Step 5: Setup SSL
    log_info "Step 5/6: Setting up SSL certificate..."
    local webserver="apache"
    if check_package_installed "nginx"; then
        webserver="nginx"
    fi
    generate_letsencrypt_cert "$domain" "$webserver" "$email"
    
    # Step 6: Security hardening
    log_info "Step 6/6: Applying security hardening..."
    harden_ssh
    
    log_ok "Full website deployment completed!"
    echo ""
    echo "=== Deployment Summary ==="
    echo "Domain: $domain"
    echo "Server IP: $server_ip"
    echo "Web Root: /var/www/$domain/"
    echo "SSL: Let's Encrypt"
    echo "Security: Hardened"
    echo ""
    echo "Your website is now live at: https://$domain"
    
    pause "Press Enter to continue..."
}

# Website + DNS + SSL only
setup_website_dns_ssl() {
    clear
    show_header "WEBSITE + DNS + SSL SETUP"
    
    local domain=$(ask_domain)
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    local email=$(ask_email)
    if [[ $? -ne 0 ]]; then
        email="admin@$domain"
    fi
    
    local server_ip=$(get_server_ip)
    
    log_info "Setting up website with DNS and SSL..."
    
    # Install web server if needed
    if ! check_package_installed "apache2" && ! check_package_installed "nginx"; then
        install_web
    fi
    
    # Configure DNS
    if check_service_installed "bind9"; then
        add_zone "$domain" "$server_ip"
    fi
    
    # Create website
    local webserver="apache"
    if check_package_installed "nginx"; then
        webserver="nginx"
    fi
    add_website "$domain" "$webserver"
    
    # Setup SSL
    generate_letsencrypt_cert "$domain" "$webserver" "$email"
    
    log_ok "Website + DNS + SSL setup complete for $domain"
    pause "Press Enter to continue..."
}

# Mail Domain Setup
setup_mail_domain() {
    clear
    show_header "MAIL DOMAIN SETUP"
    
    local domain=$(ask_domain)
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    local server_ip=$(get_server_ip)
    
    log_info "Setting up mail domain..."
    
    # Install mail server if needed
    if ! check_package_installed "postfix"; then
        install_mail
    fi
    
    # Configure DNS
    if check_service_installed "bind9"; then
        add_record "$domain" "@" "MX" "10 mail.$domain."
        add_record "$domain" "mail" "A" "$server_ip"
    fi
    
    # Add mail domain
    add_mail_domain "$domain"
    
    # Configure DKIM
    configure_dkim "$domain"
    
    # Create admin account
    local password=$(ask_password)
    add_mail_user "admin" "$password" "$domain"
    
    log_ok "Mail domain setup complete for $domain"
    pause "Press Enter to continue..."
}

# Database + Web + SSL
setup_database_web_ssl() {
    clear
    show_header "DATABASE + WEB + SSL SETUP"
    
    local domain=$(ask_domain)
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    log_info "Setting up database, web server, and SSL..."
    
    # Install components
    if ! check_package_installed "apache2" && ! check_package_installed "nginx"; then
        install_web
    fi
    
    if ! check_package_installed "mysql-server"; then
        install_mysql
    fi
    
    # Create website
    local webserver="apache"
    if check_package_installed "nginx"; then
        webserver="nginx"
    fi
    add_website "$domain" "$webserver"
    
    # Create database
    local db_name=$(echo "$domain" | sed 's/\./_/g')
    local db_password=$(ask_password)
    create_mysql_db "${db_name}_db" "${db_name}_user" "$db_password"
    
    # Setup SSL
    generate_letsencrypt_cert "$domain" "$webserver" "admin@$domain"
    
    log_ok "Database + Web + SSL setup complete!"
    echo "Database: ${db_name}_db"
    echo "DB User: ${db_name}_user"
    pause "Press Enter to continue..."
}

# Security Hardening
setup_security_hardening() {
    clear
    show_header "SECURITY HARDENING"
    
    log_info "Performing complete security hardening..."
    
    # Install and configure firewall
    if ! check_service_installed "ufw"; then
        install_firewall
    fi
    
    # System hardening
    harden_system
    harden_ssh
    
    # Configure automatic updates
    configure_automatic_updates
    
    log_ok "Security hardening completed!"
    pause "Press Enter to continue..."
}

# Complete System Backup
perform_complete_backup() {
    clear
    show_header "COMPLETE SYSTEM BACKUP"
    
    log_info "Performing complete system backup..."
    
    # Configure backup system if needed
    configure_backup_defaults
    
    # Run all backup types
    backup_system_configs
    
    if check_service_installed "apache2" || check_service_installed "nginx"; then
        backup_web_configs
    fi
    
    if check_service_installed "postfix"; then
        backup_mail_configs
    fi
    
    if check_service_installed "mysql"; then
        backup_mysql_all
    fi
    
    if check_service_installed "postgresql"; then
        backup_postgresql_all
    fi
    
    backup_ssl_certs
    
    log_ok "Complete system backup finished!"
    pause "Press Enter to continue..."
}

# Security Audit
perform_security_audit() {
    clear
    show_header "SECURITY AUDIT & HARDENING"
    
    log_info "Performing security audit..."
    
    check_system_health
    scan_security
    show_firewall_status
    
    pause "Press Enter to continue..."
}

# Performance Optimization
perform_optimization() {
    clear
    show_header "PERFORMANCE OPTIMIZATION"
    
    log_info "Performing system optimization..."
    
    cleanup_system
    optimize_system
    
    log_ok "System optimization completed!"
    pause "Press Enter to continue..."
}

# Disaster Recovery Setup
setup_disaster_recovery() {
    clear
    show_header "DISASTER RECOVERY SETUP"
    
    log_info "Setting up disaster recovery..."
    
    # Configure automated backups
    configure_backup_defaults
    set_backup_schedule "daily" "02:00"
    set_backup_schedule "weekly" "03:00"
    set_backup_schedule "monthly" "04:00"
    
    # Create system snapshot
    create_system_snapshot
    
    log_ok "Disaster recovery setup completed!"
    pause "Press Enter to continue..."
}

# Run main function
main "$@"
