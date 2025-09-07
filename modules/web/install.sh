#!/bin/bash
# Complete Web Server Installation Script
# Installs all possible web server dependencies and components

# Get base directory and source functions
BASE_DIR="$(dirname "$0")"
source "$BASE_DIR/functions.sh"
source "$(dirname "$BASE_DIR")/common.sh"

# Installation configuration
WEB_INSTALL_LOG="/var/log/web-install.log"
COMPONENTS_INSTALLED=()
COMPONENTS_FAILED=()

# Main installation function
main() {
    clear
    show_header "COMPLETE WEB SERVER INSTALLATION"
    
    log_info "Starting comprehensive web server installation..."
    echo ""
    
    # Create log file
    touch "$WEB_INSTALL_LOG"
    echo "$(date): Starting web server installation" >> "$WEB_INSTALL_LOG"
    
    # Show installation options
    show_installation_menu
    
    # Final report
    show_installation_report
    
    log_ok "Web server installation completed!"
    echo ""
    log_info "You can now:"
    echo "  - Manage websites using the web management menu"
    echo "  - Configure virtual hosts and SSL certificates"
    echo "  - Use development tools and frameworks"
    echo "  - Monitor server performance and security"
    echo ""
    
    pause "Press Enter to return to web management menu..."
}

# Show installation menu with all possible components
show_installation_menu() {
    while true; do
        clear
        show_header "WEB INSTALLATION COMPONENTS"
        
        echo -e "${WHITE}Choose installation type:${NC}"
        echo ""
        echo "1) Full Installation (All Components)"
        echo "2) Basic Web Server (Apache/Nginx + PHP)"
        echo "3) Development Stack (Full + Dev Tools)"
        echo "4) Production Stack (Full + Security + Monitoring)"
        echo "5) Custom Installation (Choose Components)"
        echo "6) Minimal Installation (Essential Only)"
        echo "0) Cancel Installation"
        echo ""
        
        local choice=$(get_menu_choice 6)
        
        case $choice in
            1)
                install_full_stack
                break
                ;;
            2)
                install_basic_web
                break
                ;;
            3)
                install_development_stack
                break
                ;;
            4)
                install_production_stack
                break
                ;;
            5)
                install_custom_components
                break
                ;;
            6)
                install_minimal_stack
                break
                ;;
            0)
                log_info "Installation cancelled"
                exit 0
                ;;
            *)
                log_error "Invalid choice. Please try again."
                pause
                ;;
        esac
    done
}

# Install full stack with all possible components
install_full_stack() {
    log_info "Installing complete web server stack with all components..."
    
    # Core web servers
    install_apache_complete
    install_nginx_complete
    
    # PHP and extensions
    install_php_complete
    
    # Databases
    install_database_components
    
    # Development tools
    install_development_tools
    
    # Security components
    install_security_components
    
    # Monitoring and performance
    install_monitoring_tools
    
    # Additional web technologies
    install_additional_technologies
    
    # Configure services
    configure_web_services
}

# Install basic web server
install_basic_web() {
    log_info "Installing basic web server stack..."
    
    install_apache_basic
    install_php_basic
    configure_basic_services
}

# Install development stack
install_development_stack() {
    log_info "Installing development stack..."
    
    install_apache_complete
    install_nginx_complete
    install_php_complete
    install_development_tools
    install_database_components
    configure_development_services
}

# Install production stack
install_production_stack() {
    log_info "Installing production stack..."
    
    install_apache_complete
    install_nginx_complete
    install_php_complete
    install_security_components
    install_monitoring_tools
    install_performance_tools
    configure_production_services
}

# Install minimal stack
install_minimal_stack() {
    log_info "Installing minimal web server stack..."
    
    install_core_packages
    configure_minimal_services
}

# Custom component installation
install_custom_components() {
    while true; do
        clear
        show_header "CUSTOM COMPONENT INSTALLATION"
        
        echo -e "${WHITE}Available Components:${NC}"
        echo ""
        echo "1) Apache Web Server"
        echo "2) Nginx Web Server"
        echo "3) PHP & Extensions"
        echo "4) Node.js & NPM"
        echo "5) Python & Frameworks"
        echo "6) Database Servers"
        echo "7) SSL/TLS Components"
        echo "8) Security Tools"
        echo "9) Monitoring Tools"
        echo "10) Development Tools"
        echo "11) Performance Tools"
        echo "12) Additional Technologies"
        echo "0) Finish Custom Installation"
        echo ""
        
        local choice=$(get_menu_choice 12)
        
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
            0) 
                configure_web_services
                break 
                ;;
            *) 
                log_error "Invalid choice. Please try again."
                pause 
                ;;
        esac
    done
}

# Show installation report
show_installation_report() {
    clear
    show_header "INSTALLATION REPORT"
    
    echo -e "${GREEN}Successfully Installed Components:${NC}"
    if [[ ${#COMPONENTS_INSTALLED[@]} -eq 0 ]]; then
        echo "  No components were installed"
    else
        for component in "${COMPONENTS_INSTALLED[@]}"; do
            echo -e "  ${GREEN}✓${NC} $component"
        done
    fi
    
    echo ""
    if [[ ${#COMPONENTS_FAILED[@]} -gt 0 ]]; then
        echo -e "${RED}Failed Components:${NC}"
        for component in "${COMPONENTS_FAILED[@]}"; do
            echo -e "  ${RED}✗${NC} $component"
        done
        echo ""
    fi
    
    echo "Installation log saved to: $WEB_INSTALL_LOG"
    echo ""
    pause
}

# Run main function
main "$@"
