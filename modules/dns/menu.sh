#!/bin/bash
# DNS Server Management Menu

# Get base directory and source functions
BASE_DIR="$(dirname "$0")"
source "$BASE_DIR/functions.sh"
source "$(dirname "$BASE_DIR")/common.sh"

# Main menu function
main() {
    while true; do
        clear
        show_header "DNS SERVER MANAGEMENT"
        
        # Show current status
        echo -e "${WHITE}Current Status:${NC}"
        if systemctl is-active --quiet bind9; then
            echo -e "  ${GREEN}✓${NC} BIND9: Running"
            local zones_count=$(ls -1 /etc/bind/zones/db.* 2>/dev/null | wc -l)
            echo -e "  ${BLUE}○${NC} Active Zones: $zones_count"
        elif check_service_installed "bind9"; then
            echo -e "  ${RED}✗${NC} BIND9: Stopped"
        else
            echo -e "  ${YELLOW}○${NC} BIND9: Not Installed"
        fi
        
        echo ""
        echo -e "${WHITE}Management Options:${NC}"
        echo ""
        echo "1) Install DNS Server (BIND9)"
        echo "2) Add DNS Zone"
        echo "3) Remove DNS Zone"
        echo "4) Add DNS Record"
        echo "5) Remove DNS Record"
        echo "6) List DNS Zones"
        echo "7) Test DNS Resolution"
        echo "8) DNS Server Maintenance"
        echo "9) Update DNS Components"
        echo "10) Advanced DNS Configuration"
        echo "0) Back to Main Menu"
        echo ""
        
        local choice=$(get_menu_choice 10)
        
        case $choice in
            1)
                bash "$BASE_DIR/install.sh"
                ;;
            2)
                add_zone_interactive
                ;;
            3)
                remove_zone_interactive
                ;;
            4)
                add_record_interactive
                ;;
            5)
                remove_record_interactive
                ;;
            6)
                list_zones_interactive
                ;;
            7)
                test_dns_interactive
                ;;
            8)
                bash "$BASE_DIR/maintain.sh"
                ;;
            9)
                bash "$BASE_DIR/update.sh"
                ;;
            10)
                advanced_dns_menu
                ;;
            0)
                break
                ;;
        esac
    done
}

# Interactive zone addition
add_zone_interactive() {
    clear
    show_header "ADD DNS ZONE"
    
    if ! check_service_installed "bind9"; then
        log_error "DNS server is not installed. Please install it first."
        pause "Press Enter to continue..."
        return
    fi
    
    echo "This will create a new DNS zone for your domain."
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
    
    local server_ip=$(ask_ip)
    if [[ $? -ne 0 ]]; then
        echo "Using server's primary IP address..."
        server_ip=$(get_server_ip)
    fi
    
    log_info "Creating DNS zone for: $domain"
    log_info "Using IP address: $server_ip"
    
    add_zone "$domain" "$server_ip"
    
    echo ""
    log_info "Zone created successfully! Don't forget to:"
    echo "  1. Update nameservers at your domain registrar to point to this server"
    echo "  2. Add additional DNS records as needed (MX, CNAME, etc.)"
    echo "  3. Test DNS resolution from external locations"
    
    pause "Press Enter to continue..."
}

# Interactive zone removal
remove_zone_interactive() {
    clear
    show_header "REMOVE DNS ZONE"
    
    if ! check_service_installed "bind9"; then
        log_error "DNS server is not installed."
        pause "Press Enter to continue..."
        return
    fi
    
    # Show existing zones
    echo "Existing DNS zones:"
    list_zones
    echo ""
    
    local domain=$(ask_domain)
    if [[ $? -ne 0 ]]; then
        pause "Press Enter to continue..."
        return
    fi
    
    if [[ ! -f "/etc/bind/zones/db.$domain" ]]; then
        log_error "Zone for $domain does not exist"
        pause "Press Enter to continue..."
        return
    fi
    
    if confirm_action "This will permanently remove the DNS zone for $domain. Continue?"; then
        remove_zone "$domain"
        log_ok "DNS zone for $domain removed successfully"
    else
        log_info "Zone removal cancelled"
    fi
    
    pause "Press Enter to continue..."
}

# Interactive record addition
add_record_interactive() {
    clear
    show_header "ADD DNS RECORD"
    
    if ! check_service_installed "bind9"; then
        log_error "DNS server is not installed."
        pause "Press Enter to continue..."
        return
    fi
    
    # Show existing zones
    echo "Available DNS zones:"
    list_zones
    echo ""
    
    local zone=$(ask_domain)
    if [[ $? -ne 0 ]]; then
        pause "Press Enter to continue..."
        return
    fi
    
    if [[ ! -f "/etc/bind/zones/db.$zone" ]]; then
        log_error "Zone for $zone does not exist. Please create the zone first."
        pause "Press Enter to continue..."
        return
    fi
    
    echo ""
    read -p "Enter record name (e.g., www, mail, ftp): " record_name
    if [[ -z "$record_name" ]]; then
        log_error "Record name cannot be empty"
        pause "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo "DNS Record Types:"
    echo "1) A Record (IPv4 address)"
    echo "2) AAAA Record (IPv6 address)"
    echo "3) CNAME Record (alias)"
    echo "4) MX Record (mail exchange)"
    echo "5) TXT Record (text)"
    echo "0) Cancel"
    echo ""
    
    local type_choice=$(get_menu_choice 5)
    local record_type=""
    local record_value=""
    
    case $type_choice in
        1)
            record_type="A"
            record_value=$(ask_ip)
            ;;
        2)
            record_type="AAAA"
            read -p "Enter IPv6 address: " record_value
            ;;
        3)
            record_type="CNAME"
            read -p "Enter target domain: " record_value
            ;;
        4)
            record_type="MX"
            read -p "Enter priority (10): " priority
            priority=${priority:-10}
            read -p "Enter mail server: " mail_server
            record_value="$priority $mail_server"
            ;;
        5)
            record_type="TXT"
            read -p "Enter text value: " record_value
            record_value="\"$record_value\""
            ;;
        0)
            log_info "Record addition cancelled"
            pause "Press Enter to continue..."
            return
            ;;
    esac
    
    if [[ -n "$record_value" ]]; then
        log_info "Adding $record_type record: $record_name.$zone -> $record_value"
        add_record "$zone" "$record_name" "$record_type" "$record_value"
    fi
    
    pause "Press Enter to continue..."
}

# Interactive record removal
remove_record_interactive() {
    clear
    show_header "REMOVE DNS RECORD"
    
    # Show existing zones
    echo "Available DNS zones:"
    list_zones
    echo ""
    
    local zone=$(ask_domain)
    if [[ $? -ne 0 ]]; then
        pause "Press Enter to continue..."
        return
    fi
    
    if [[ ! -f "/etc/bind/zones/db.$zone" ]]; then
        log_error "Zone for $zone does not exist"
        pause "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo "Current records in zone $zone:"
    grep -E "^[^;].*IN" "/etc/bind/zones/db.$zone" | head -20
    echo ""
    
    read -p "Enter record name to remove: " record_name
    if [[ -z "$record_name" ]]; then
        log_error "Record name cannot be empty"
        pause "Press Enter to continue..."
        return
    fi
    
    if confirm_action "This will remove all records named '$record_name' from zone $zone. Continue?"; then
        remove_record "$zone" "$record_name"
    else
        log_info "Record removal cancelled"
    fi
    
    pause "Press Enter to continue..."
}

# List zones with details
list_zones_interactive() {
    clear
    show_header "DNS ZONES LIST"
    
    if ! check_service_installed "bind9"; then
        log_error "DNS server is not installed."
        pause "Press Enter to continue..."
        return
    fi
    
    echo "=== Configured DNS Zones ==="
    list_zones
    
    echo ""
    echo "=== Zone File Details ==="
    if [[ -d /etc/bind/zones ]]; then
        for zone_file in /etc/bind/zones/db.*; do
            if [[ -f "$zone_file" ]]; then
                local zone_name=$(basename "$zone_file" | sed 's/^db\.//')
                echo ""
                echo "Zone: $zone_name"
                echo "File: $zone_file"
                echo "Records:"
                grep -E "^[^;].*IN" "$zone_file" | head -10 | sed 's/^/  /'
                if [[ $(grep -E "^[^;].*IN" "$zone_file" | wc -l) -gt 10 ]]; then
                    echo "  ... and more"
                fi
            fi
        done
    else
        log_warn "No zones directory found"
    fi
    
    pause "Press Enter to continue..."
}

# Test DNS resolution
test_dns_interactive() {
    clear
    show_header "TEST DNS RESOLUTION"
    
    echo "DNS Resolution Testing"
    echo ""
    
    # Test local DNS server
    echo "=== Testing Local DNS Server ==="
    if systemctl is-active --quiet bind9; then
        log_ok "DNS server is running"
        
        # Test some common domains
        local test_domains=("google.com" "cloudflare.com" "github.com")
        for domain in "${test_domains[@]}"; do
            echo -n "Testing $domain: "
            if dig @localhost "$domain" +short | grep -q "^[0-9]"; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC}"
            fi
        done
    else
        log_error "DNS server is not running"
    fi
    
    echo ""
    echo "=== Testing Custom Zones ==="
    if [[ -d /etc/bind/zones ]]; then
        for zone_file in /etc/bind/zones/db.*; do
            if [[ -f "$zone_file" ]]; then
                local zone_name=$(basename "$zone_file" | sed 's/^db\.//')
                echo -n "Testing $zone_name: "
                if test_dns_resolution "$zone_name" | grep -q "^[0-9]"; then
                    echo -e "${GREEN}✓${NC}"
                else
                    echo -e "${RED}✗${NC}"
                fi
            fi
        done
    fi
    
    echo ""
    echo "=== Manual DNS Test ==="
    local test_domain=$(ask_domain)
    if [[ $? -eq 0 ]] && [[ -n "$test_domain" ]]; then
        echo ""
        echo "Testing resolution for: $test_domain"
        echo "Local DNS server result:"
        test_dns_resolution "$test_domain" || echo "No result"
        
        echo ""
        echo "External DNS server result (8.8.8.8):"
        dig @8.8.8.8 "$test_domain" +short || echo "No result"
    fi
    
    pause "Press Enter to continue..."
}

# Advanced DNS configuration menu
advanced_dns_menu() {
    while true; do
        clear
        show_header "ADVANCED DNS CONFIGURATION"
        
        echo "1) Configure DNS Forwarders"
        echo "2) Setup DNS Security (DNSSEC)"
        echo "3) Configure Zone Transfers"
        echo "4) Setup DNS over HTTPS (DoH)"
        echo "5) Configure Logging"
        echo "6) Backup DNS Configuration"
        echo "7) Restore DNS Configuration"
        echo "8) View DNS Statistics"
        echo "0) Back"
        echo ""
        
        local choice=$(get_menu_choice 8)
        
        case $choice in
            1) configure_forwarders ;;
            2) configure_dnssec ;;
            3) configure_zone_transfers ;;
            4) configure_doh ;;
            5) configure_dns_logging ;;
            6) backup_dns_config ;;
            7) restore_dns_config ;;
            8) view_dns_statistics ;;
            0) break ;;
        esac
        
        pause "Press Enter to continue..."
    done
}

# Advanced configuration functions (placeholders)
configure_forwarders() {
    log_info "Configuring DNS forwarders..."
    log_warn "Feature not yet implemented"
}

configure_dnssec() {
    log_info "Configuring DNSSEC..."
    log_warn "Feature not yet implemented"
}

configure_zone_transfers() {
    log_info "Configuring zone transfers..."
    log_warn "Feature not yet implemented"
}

configure_doh() {
    log_info "Configuring DNS over HTTPS..."
    log_warn "Feature not yet implemented"
}

configure_dns_logging() {
    log_info "Configuring DNS logging..."
    log_warn "Feature not yet implemented"
}

backup_dns_config() {
    log_info "Backing up DNS configuration..."
    local backup_dir="/root/dns-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    cp -r /etc/bind "$backup_dir/"
    tar -czf "$backup_dir.tar.gz" -C "$(dirname $backup_dir)" "$(basename $backup_dir)"
    rm -rf "$backup_dir"
    
    log_ok "DNS configuration backed up to: $backup_dir.tar.gz"
}

restore_dns_config() {
    log_info "Restoring DNS configuration..."
    log_warn "Feature not yet implemented"
}

view_dns_statistics() {
    echo "=== DNS Query Statistics ==="
    if command_exists rndc; then
        rndc stats
        if [[ -f /var/cache/bind/named.stats ]]; then
            tail -20 /var/cache/bind/named.stats
        fi
    else
        log_warn "RNDC not available for statistics"
    fi
}

# Run main function
main "$@"
