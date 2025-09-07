#!/bin/bash
# DNS Server Maintenance Script

# Get base directory and source functions
BASE_DIR="$(dirname "$0")"
source "$BASE_DIR/functions.sh"
source "$(dirname "$BASE_DIR")/common.sh"

# Function to perform comprehensive system check
perform_system_check() {
    local errors=0
    local warnings=0
    
    echo "=== DNS Server System Check ==="
    echo "Starting comprehensive system check..."
    echo
    
    # Check DNS service status
    echo "1. Service Status Check"
    if systemctl is-active --quiet bind9; then
        echo "  ✓ BIND9 service is running"
    else
        echo "  ✗ BIND9 service is not running"
        errors=$((errors + 1))
    fi
    
    # Check disk space
    echo -e "\n2. Disk Space Check"
    local space=$(df -h /var/cache/bind | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ $space -gt 90 ]]; then
        echo "  ! WARNING: Disk space usage is high ($space%)"
        warnings=$((warnings + 1))
    else
        echo "  ✓ Disk space usage is acceptable ($space%)"
    fi
    
    # Check configuration files
    echo -e "\n3. Configuration Check"
    if named-checkconf >/dev/null 2>&1; then
        echo "  ✓ Configuration syntax is valid"
    else
        echo "  ✗ Configuration has errors"
        errors=$((errors + 1))
    fi
    
    # Check zone files
    echo -e "\n4. Zone Files Check"
    local zone_errors=0
    for zone_file in /etc/bind/zones/db.*; do
        if [[ -f "$zone_file" ]]; then
            local zone=$(basename "$zone_file" | sed 's/db\.//')
            if ! named-checkzone "$zone" "$zone_file" >/dev/null 2>&1; then
                echo "  ! Zone $zone has errors"
                zone_errors=$((zone_errors + 1))
            fi
        fi
    done
    if [[ $zone_errors -eq 0 ]]; then
        echo "  ✓ All zone files are valid"
    else
        echo "  ✗ Found $zone_errors zone(s) with errors"
        errors=$((errors + 1))
    fi
    
    # Check DNS resolution
    echo -e "\n5. DNS Resolution Check"
    if dig @localhost google.com +short >/dev/null 2>&1; then
        echo "  ✓ DNS resolution is working"
    else
        echo "  ✗ DNS resolution failed"
        errors=$((errors + 1))
    fi
    
    # Check log files
    echo -e "\n6. Log Files Check"
    if [[ -f /var/log/named/named.log ]]; then
        local log_errors=$(grep -i "error" /var/log/named/named.log | wc -l)
        if [[ $log_errors -gt 0 ]]; then
            echo "  ! Found $log_errors error(s) in log file"
            warnings=$((warnings + 1))
        else
            echo "  ✓ No errors found in log file"
        fi
    fi
    
    # Summary
    echo -e "\n=== Check Summary ==="
    echo "Found $errors error(s) and $warnings warning(s)"
    
    return $errors
}

# Main maintenance menu
main() {
    while true; do
        clear
        show_header "DNS SERVER MAINTENANCE"
        
        # Check service status and show system health
        if systemctl is-active --quiet bind9; then
            echo -e "${GREEN}BIND9 Status: Active${NC}"
            local uptime=$(systemctl show bind9 --property=ActiveEnterTimestamp | cut -d= -f2)
            echo -e "Uptime: $uptime"
        elif check_service_installed "bind9"; then
            echo -e "${RED}BIND9 Status: Inactive${NC}"
        else
            echo -e "${YELLOW}BIND9 Status: Not Installed${NC}"
        fi
        
        echo ""
        echo "=== Service Management ==="
        echo "1) Restart DNS Service"
        echo "2) Reload DNS Configuration"
        echo "3) Stop DNS Service"
        echo "4) Start DNS Service"
        echo "5) View DNS Status"
        
        echo -e "\n=== Monitoring & Diagnostics ==="
        echo "6) View DNS Logs"
        echo "7) Clear DNS Cache"
        echo "8) Monitor DNS Queries"
        echo "9) Check DNS Performance"
        echo "10) View Query Statistics"
        
        echo -e "\n=== Maintenance Tasks ==="
        echo "11) Perform System Check"
        echo "12) Validate All Zones"
        echo "13) Analyze Security Settings"
        echo "14) Check Zone Serial Numbers"
        
        echo -e "\n=== Backup & Recovery ==="
        echo "15) Create Configuration Backup"
        echo "16) Restore from Backup"
        echo "17) Manage Backup Files"
        
        echo -e "\n0) Back to DNS Menu"
        echo ""
        
        local choice=$(get_menu_choice 17)
        
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
                log_info "Monitoring DNS queries (Ctrl+C to stop)..."
                monitor_dns_queries
                ;;
            9)
                log_info "Checking DNS performance..."
                check_dns_performance
                pause
                ;;
            10)
                log_info "Viewing query statistics..."
                rndc stats
                cat /var/cache/bind/named.stats
                pause
                ;;
            11)
                log_info "Performing system check..."
                perform_system_check
                pause
                ;;
            12)
                log_info "Validating all DNS zones..."
                validate_all_zones
                pause
                ;;
            13)
                log_info "Analyzing security settings..."
                analyze_dns_security
                pause
                ;;
            14)
                log_info "Checking zone serial numbers..."
                check_zone_serial_numbers
                pause
                ;;
            15)
                log_info "Creating configuration backup..."
                backup_dns_config
                pause
                ;;
            16)
                local backups=( "$BACKUP_DIR"/*.tar.gz )
                if [[ ${#backups[@]} -eq 0 ]]; then
                    log_error "No backup files found"
                else
                    echo "Available backups:"
                    select backup in "${backups[@]}"; do
                        if [[ -n "$backup" ]]; then
                            restore_dns_config "$backup"
                            break
                        fi
                    done
                fi
                pause
                ;;
            17)
                echo "Backup files in $BACKUP_DIR:"
                ls -lh "$BACKUP_DIR"
                echo
                if confirm_action "Delete backups older than 30 days?"; then
                    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
                    echo "Old backups deleted"
                fi
                pause
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
