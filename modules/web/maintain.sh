#!/bin/bash
# Web Server Maintenance Script

# Get base directory and source functions
BASE_DIR="$(dirname "$0")"
source "$BASE_DIR/functions.sh"
source "$(dirname "$BASE_DIR")/common.sh"

# Main maintenance menu
main() {
    while true; do
        clear
        show_header "WEB SERVER MAINTENANCE"
        
        # Check service status
        if systemctl is-active --quiet apache2; then
            echo -e "${GREEN}Apache Status: Active${NC}"
        elif check_service_installed "apache2"; then
            echo -e "${RED}Apache Status: Inactive${NC}"
        else
            echo -e "${YELLOW}Apache Status: Not Installed${NC}"
        fi
        
        if systemctl is-active --quiet nginx; then
            echo -e "${GREEN}Nginx Status: Active${NC}"
        elif check_service_installed "nginx"; then
            echo -e "${RED}Nginx Status: Inactive${NC}"
        else
            echo -e "${YELLOW}Nginx Status: Not Installed${NC}"
        fi
        
        echo ""
        echo "1) Restart Web Services"
        echo "2) Reload Web Services"
        echo "3) Stop Web Services"
        echo "4) Start Web Services"
        echo "5) View Service Status"
        echo "6) View Error Logs"
        echo "7) View Access Logs"
        echo "8) Clear Log Files"
        echo "9) Test Configuration"
        echo "0) Back to Web Menu"
        echo ""
        
        local choice=$(get_menu_choice 9)
        
        case $choice in
            1)
                log_info "Restarting web services..."
                restart_web
                pause
                ;;
            2)
                log_info "Reloading web services..."
                reload_web
                pause
                ;;
            3)
                log_info "Stopping web services..."
                stop_web
                pause
                ;;
            4)
                log_info "Starting web services..."
                start_web
                pause
                ;;
            5)
                log_info "Web service status:"
                status_web
                pause
                ;;
            6)
                log_info "Viewing error logs..."
                view_web_error_logs
                pause
                ;;
            7)
                log_info "Viewing access logs..."
                view_web_access_logs
                pause
                ;;
            8)
                if confirm_action "This will clear all web server log files. Continue?"; then
                    clear_web_logs
                fi
                pause
                ;;
            9)
                log_info "Testing web server configuration..."
                test_web_config
                pause
                ;;
            0)
                break
                ;;
        esac
    done
}

# Add missing functions to work with existing functions.sh
stop_web() {
    if systemctl is-active --quiet apache2; then
        systemctl stop apache2
        log_ok "Apache stopped"
    fi
    if systemctl is-active --quiet nginx; then
        systemctl stop nginx
        log_ok "Nginx stopped"
    fi
}

start_web() {
    if check_service_installed "apache2"; then
        systemctl start apache2
        log_ok "Apache started"
    fi
    if check_service_installed "nginx"; then
        systemctl start nginx
        log_ok "Nginx started"
    fi
}

reload_web() {
    if systemctl is-active --quiet apache2; then
        systemctl reload apache2
        log_ok "Apache reloaded"
    fi
    if systemctl is-active --quiet nginx; then
        nginx -t && systemctl reload nginx
        log_ok "Nginx reloaded"
    fi
}

view_web_error_logs() {
    echo "=== Apache Error Logs ==="
    if [[ -f /var/log/apache2/error.log ]]; then
        tail -20 /var/log/apache2/error.log
    else
        echo "No Apache error log found"
    fi
    
    echo ""
    echo "=== Nginx Error Logs ==="
    if [[ -f /var/log/nginx/error.log ]]; then
        tail -20 /var/log/nginx/error.log
    else
        echo "No Nginx error log found"
    fi
}

view_web_access_logs() {
    echo "=== Apache Access Logs ==="
    if [[ -f /var/log/apache2/access.log ]]; then
        tail -20 /var/log/apache2/access.log
    else
        echo "No Apache access log found"
    fi
    
    echo ""
    echo "=== Nginx Access Logs ==="
    if [[ -f /var/log/nginx/access.log ]]; then
        tail -20 /var/log/nginx/access.log
    else
        echo "No Nginx access log found"
    fi
}

test_web_config() {
    if check_service_installed "apache2"; then
        echo "=== Testing Apache Configuration ==="
        apache2ctl configtest
    fi
    
    if check_service_installed "nginx"; then
        echo "=== Testing Nginx Configuration ==="
        nginx -t
    fi
}

status_web() {
    if check_service_installed "apache2"; then
        echo "=== Apache Status ==="
        systemctl status apache2 --no-pager | head -10
    fi
    
    if check_service_installed "nginx"; then
        echo "=== Nginx Status ==="
        systemctl status nginx --no-pager | head -10
    fi
    
    echo ""
    echo "=== Listening Ports ==="
    netstat -tlnp | grep -E ":80|:443"
}

# Run main function
main "$@"
