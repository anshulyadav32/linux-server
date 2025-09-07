#!/bin/bash
# DNS Server Maintenance Script

# Get base directory and source functions
BASE_DIR="$(dirname "$0")"
source "$BASE_DIR/functions.sh"
source "$(dirname "$BASE_DIR")/common.sh"

# Main maintenance menu
main() {
    while true; do
        clear
        show_header "DNS SERVER MAINTENANCE"
        
        # Check service status
        if systemctl is-active --quiet bind9; then
            echo -e "${GREEN}BIND9 Status: Active${NC}"
        elif check_service_installed "bind9"; then
            echo -e "${RED}BIND9 Status: Inactive${NC}"
        else
            echo -e "${YELLOW}BIND9 Status: Not Installed${NC}"
        fi
        
        echo ""
        echo "1) Restart DNS Service"
        echo "2) Reload DNS Configuration"
        echo "3) Stop DNS Service"
        echo "4) Start DNS Service"
        echo "5) View DNS Status"
        echo "6) View DNS Logs"
        echo "7) Clear DNS Cache"
        echo "8) Test DNS Configuration"
        echo "9) Validate All Zones"
        echo "10) Monitor DNS Queries"
        echo "0) Back to DNS Menu"
        echo ""
        
        local choice=$(get_menu_choice 10)
        
        case $choice in
            1)
                log_info "Restarting DNS service..."
                restart_dns
                pause
                ;;
            2)
                log_info "Reloading DNS configuration..."
                reload_dns
                pause
                ;;
            3)
                log_info "Stopping DNS service..."
                stop_dns
                pause
                ;;
            4)
                log_info "Starting DNS service..."
                start_dns
                pause
                ;;
            5)
                log_info "DNS service status:"
                status_dns
                pause
                ;;
            6)
                log_info "Viewing DNS logs..."
                view_dns_logs
                pause
                ;;
            7)
                if confirm_action "This will clear the DNS cache. Continue?"; then
                    clear_dns_cache
                fi
                pause
                ;;
            8)
                log_info "Testing DNS configuration..."
                test_dns_configuration
                pause
                ;;
            9)
                log_info "Validating all DNS zones..."
                validate_all_zones
                pause
                ;;
            10)
                log_info "Monitoring DNS queries (Ctrl+C to stop)..."
                monitor_dns_queries
                ;;
            0)
                break
                ;;
        esac
    done
}

# Additional maintenance functions
stop_dns() {
    systemctl stop bind9
    if systemctl is-active --quiet bind9; then
        log_error "Failed to stop DNS service"
    else
        log_ok "DNS service stopped"
    fi
}

start_dns() {
    systemctl start bind9
    if systemctl is-active --quiet bind9; then
        log_ok "DNS service started"
    else
        log_error "Failed to start DNS service"
    fi
}

test_dns_configuration() {
    echo "=== Testing BIND9 Configuration ==="
    if named-checkconf; then
        log_ok "Configuration syntax is valid"
    else
        log_error "Configuration has errors"
    fi
    
    echo ""
    echo "=== Testing Listening Ports ==="
    if netstat -tlnp | grep -q ":53"; then
        log_ok "DNS service is listening on port 53"
        netstat -tlnp | grep ":53"
    else
        log_error "DNS service is not listening on port 53"
    fi
    
    echo ""
    echo "=== Testing DNS Resolution ==="
    local test_domains=("google.com" "cloudflare.com")
    for domain in "${test_domains[@]}"; do
        if dig @localhost "$domain" +short | grep -q "^[0-9]"; then
            log_ok "Successfully resolved $domain"
        else
            log_error "Failed to resolve $domain"
        fi
    done
}

validate_all_zones() {
    if [[ ! -d /etc/bind/zones ]]; then
        log_warn "No zones directory found"
        return
    fi
    
    local zones_found=false
    for zone_file in /etc/bind/zones/db.*; do
        if [[ -f "$zone_file" ]]; then
            zones_found=true
            local zone_name=$(basename "$zone_file" | sed 's/^db\.//')
            echo "Validating zone: $zone_name"
            if validate_zone "$zone_name"; then
                log_ok "$zone_name: Valid"
            else
                log_error "$zone_name: Invalid"
            fi
        fi
    done
    
    if [[ "$zones_found" = false ]]; then
        log_warn "No zone files found to validate"
    fi
}

monitor_dns_queries() {
    if ! command_exists tcpdump; then
        log_error "tcpdump not installed. Installing..."
        apt update -y >/dev/null 2>&1
        apt install -y tcpdump
    fi
    
    echo "Monitoring DNS queries on port 53..."
    echo "Press Ctrl+C to stop monitoring"
    echo ""
    
    tcpdump -i any -n port 53 2>/dev/null | while read line; do
        echo "[$(date '+%H:%M:%S')] $line"
    done
}

# Run main function
main "$@"
