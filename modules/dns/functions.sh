#!/bin/bash
# =============================================================================
# Linux Setup - DNS Module Functions
# =============================================================================
# Author: Anshul Yadav
# Description: Core functions for DNS module management
# =============================================================================

# Load common functions
source "$(dirname "$0")/../common.sh" 2>/dev/null || true

# ==========================================
# BIND9 DNS SERVER FUNCTIONS
# ==========================================

install_bind9() {
    print_step "Installing BIND9 DNS Server"
    
    apt-get update >/dev/null 2>&1
    apt-get install -y bind9 bind9utils bind9-doc dnsutils >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "BIND9 installed successfully"
        
        # Start and enable service
        systemctl start bind9
        systemctl enable bind9
        
        return 0
    else
        print_error "Failed to install BIND9"
        return 1
    fi
}

check_bind9() {
    print_step "Checking BIND9 installation"
    
    # Check if service exists
    if ! systemctl list-unit-files | grep -q "bind9.service\|named.service"; then
        print_error "BIND9 service not found"
        return 1
    fi
    
    # Check if service is active
    if systemctl is-active --quiet bind9 || systemctl is-active --quiet named; then
        print_success "BIND9 service is running"
        
        # Check if DNS is responding
        if nslookup localhost 127.0.0.1 >/dev/null 2>&1; then
            print_success "DNS server responding"
        else
            print_warning "DNS server running but not responding"
        fi
        
        return 0
    else
        print_error "BIND9 service is not running"
        return 1
    fi
}

update_bind9() {
    print_step "Updating BIND9"
    
    # Check if installed first
    if ! check_bind9 >/dev/null 2>&1; then
        print_error "BIND9 not installed"
        return 1
    fi
    
    # Update packages
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y bind9 bind9utils bind9-doc dnsutils >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "BIND9 updated successfully"
        
        # Restart service
        systemctl restart bind9
        return 0
    else
        print_error "Failed to update BIND9"
        return 1
    fi
}

configure_bind9() {
    print_substep "Configuring BIND9"
    
    local domain="${1:-example.com}"
    local server_ip="${2:-$(hostname -I | awk '{print $1}')}"
    
    # Backup original configuration
    cp /etc/bind/named.conf.local /etc/bind/named.conf.local.backup 2>/dev/null
    
    # Configure main zone
    cat >> /etc/bind/named.conf.local << EOF

zone "$domain" {
    type master;
    file "/etc/bind/db.$domain";
};

zone "$(echo $server_ip | awk -F. '{print $3"."$2"."$1}').in-addr.arpa" {
    type master;
    file "/etc/bind/db.$(echo $server_ip | awk -F. '{print $1"."$2"."$3}')";
};
EOF

    # Create forward zone file
    cat > /etc/bind/db.$domain << EOF
\$TTL    604800
@       IN      SOA     ns.$domain. admin.$domain. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.$domain.
@       IN      A       $server_ip
ns      IN      A       $server_ip
www     IN      A       $server_ip
mail    IN      A       $server_ip
@       IN      MX  10  mail.$domain.
EOF

    # Create reverse zone file
    local reverse_ip=$(echo $server_ip | awk -F. '{print $4}')
    cat > /etc/bind/db.$(echo $server_ip | awk -F. '{print $1"."$2"."$3}') << EOF
\$TTL    604800
@       IN      SOA     ns.$domain. admin.$domain. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.$domain.
$reverse_ip     IN      PTR     $domain.
EOF

    # Test configuration
    if named-checkconf && named-checkzone $domain /etc/bind/db.$domain >/dev/null 2>&1; then
        systemctl restart bind9
        print_success "BIND9 configured for domain: $domain"
    else
        print_error "BIND9 configuration error"
        return 1
    fi
}

create_dns_record() {
    local domain="$1"
    local record_type="${2:-A}"
    local name="$3"
    local value="$4"
    
    if [[ -z "$domain" || -z "$name" || -z "$value" ]]; then
        print_error "Domain, name, and value parameters required"
        return 1
    fi
    
    print_substep "Creating DNS record: $name.$domain ($record_type)"
    
    local zone_file="/etc/bind/db.$domain"
    
    if [[ -f "$zone_file" ]]; then
        # Backup zone file
        cp "$zone_file" "$zone_file.backup"
        
        # Add record
        case "$record_type" in
            "A")
                echo "$name      IN      A       $value" >> "$zone_file"
                ;;
            "CNAME")
                echo "$name      IN      CNAME   $value" >> "$zone_file"
                ;;
            "MX")
                local priority="${5:-10}"
                echo "$name      IN      MX  $priority  $value" >> "$zone_file"
                ;;
            "TXT")
                echo "$name      IN      TXT     \"$value\"" >> "$zone_file"
                ;;
        esac
        
        # Increment serial number
        local current_serial=$(grep -o "Serial" -A 1 "$zone_file" | tail -1 | tr -d ' ')
        local new_serial=$((current_serial + 1))
        sed -i "s/$current_serial.*; Serial/$new_serial         ; Serial/" "$zone_file"
        
        # Test and reload
        if named-checkzone $domain "$zone_file" >/dev/null 2>&1; then
            systemctl reload bind9
            print_success "DNS record created successfully"
        else
            # Restore backup
            mv "$zone_file.backup" "$zone_file"
            print_error "Invalid DNS record, changes reverted"
            return 1
        fi
    else
        print_error "Zone file not found: $zone_file"
        return 1
    fi
}

# ==========================================
# DNSMASQ FUNCTIONS (Lightweight DNS)
# ==========================================

install_dnsmasq() {
    print_step "Installing dnsmasq"
    
    apt-get update >/dev/null 2>&1
    apt-get install -y dnsmasq >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "dnsmasq installed successfully"
        
        # Stop and disable systemd-resolved if running (conflicts with dnsmasq)
        systemctl stop systemd-resolved 2>/dev/null
        systemctl disable systemd-resolved 2>/dev/null
        
        # Start and enable dnsmasq
        systemctl start dnsmasq
        systemctl enable dnsmasq
        
        return 0
    else
        print_error "Failed to install dnsmasq"
        return 1
    fi
}

check_dnsmasq() {
    print_step "Checking dnsmasq installation"
    
    # Check if service exists
    if ! systemctl list-unit-files | grep -q "dnsmasq.service"; then
        print_error "dnsmasq service not found"
        return 1
    fi
    
    # Check if service is active
    if systemctl is-active --quiet dnsmasq; then
        print_success "dnsmasq service is running"
        
        # Check if DNS is responding
        if nslookup localhost 127.0.0.1 >/dev/null 2>&1; then
            print_success "DNS server responding"
        else
            print_warning "DNS server running but not responding"
        fi
        
        return 0
    else
        print_error "dnsmasq service is not running"
        return 1
    fi
}

update_dnsmasq() {
    print_step "Updating dnsmasq"
    
    # Check if installed first
    if ! check_dnsmasq >/dev/null 2>&1; then
        print_error "dnsmasq not installed"
        return 1
    fi
    
    # Update package
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y dnsmasq >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "dnsmasq updated successfully"
        
        # Restart service
        systemctl restart dnsmasq
        return 0
    else
        print_error "Failed to update dnsmasq"
        return 1
    fi
}

configure_dnsmasq() {
    print_substep "Configuring dnsmasq"
    
    local domain="${1:-local}"
    
    # Backup original configuration
    cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup 2>/dev/null
    
    # Create new configuration
    cat > /etc/dnsmasq.conf << EOF
# DNS Configuration
port=53
domain-needed
bogus-priv
no-resolv
no-poll
server=8.8.8.8
server=8.8.4.4
local=/$domain/
domain=$domain
expand-hosts
cache-size=1000

# DHCP Configuration (if needed)
# dhcp-range=192.168.1.100,192.168.1.200,12h
# dhcp-option=3,192.168.1.1
# dhcp-option=6,192.168.1.1

# Log queries (for debugging)
# log-queries
# log-dhcp
EOF

    # Test configuration
    dnsmasq --test 2>/dev/null
    if [[ $? -eq 0 ]]; then
        systemctl restart dnsmasq
        print_success "dnsmasq configured for domain: $domain"
    else
        print_error "dnsmasq configuration error"
        return 1
    fi
}

# ==========================================
# DNS MODULE MAIN FUNCTIONS
# ==========================================

install_dns_module() {
    print_header "Installing DNS Module"
    
    local dns_type="${1:-bind9}"  # bind9 or dnsmasq
    
    case "$dns_type" in
        "bind9")
            if install_bind9; then
                configure_bind9
                print_success "DNS module (BIND9) installed successfully"
                return 0
            else
                print_error "DNS module installation failed"
                return 1
            fi
            ;;
        "dnsmasq")
            if install_dnsmasq; then
                configure_dnsmasq
                print_success "DNS module (dnsmasq) installed successfully"
                return 0
            else
                print_error "DNS module installation failed"
                return 1
            fi
            ;;
        *)
            print_error "Invalid DNS type. Use 'bind9' or 'dnsmasq'"
            return 1
            ;;
    esac
}

check_dns_module() {
    print_header "Checking DNS Module"
    
    local bind9_status=0
    local dnsmasq_status=0
    
    # Check BIND9
    if check_bind9 >/dev/null 2>&1; then
        bind9_status=1
    fi
    
    # Check dnsmasq
    if check_dnsmasq >/dev/null 2>&1; then
        dnsmasq_status=1
    fi
    
    if [[ $bind9_status -eq 1 || $dnsmasq_status -eq 1 ]]; then
        print_success "DNS module is operational"
        return 0
    else
        print_error "DNS module is not operational"
        return 1
    fi
}

update_dns_module() {
    print_header "Updating DNS Module"
    
    local updated=0
    
    # Update BIND9 if installed
    if systemctl list-unit-files | grep -q "bind9.service\|named.service"; then
        if update_bind9; then
            updated=1
        fi
    fi
    
    # Update dnsmasq if installed
    if systemctl list-unit-files | grep -q "dnsmasq.service"; then
        if update_dnsmasq; then
            updated=1
        fi
    fi
    
    if [[ $updated -eq 1 ]]; then
        print_success "DNS module updated successfully"
        return 0
    else
        print_warning "No DNS services to update"
        return 0
    fi
}

check_dns_update() {
    print_header "Checking DNS Module Updates"
    
    # Check for available updates
    apt-get update >/dev/null 2>&1
    
    local updates_available=0
    
    # Check BIND9 updates
    if apt list --upgradable 2>/dev/null | grep -q "bind9"; then
        print_info "BIND9 updates available"
        updates_available=1
    fi
    
    # Check dnsmasq updates
    if apt list --upgradable 2>/dev/null | grep -q "dnsmasq"; then
        print_info "dnsmasq updates available"
        updates_available=1
    fi
    
    if [[ $updates_available -eq 1 ]]; then
        print_warning "DNS updates available"
        return 1
    else
        print_success "DNS module is up to date"
        return 0
    fi
}

# ==========================================
# DNS TESTING FUNCTIONS
# ==========================================

test_dns_resolution() {
    local test_domain="${1:-google.com}"
    
    print_step "Testing DNS resolution"
    
    # Test forward lookup
    if nslookup "$test_domain" >/dev/null 2>&1; then
        print_success "Forward DNS resolution working"
    else
        print_error "Forward DNS resolution failed"
        return 1
    fi
    
    # Test reverse lookup
    local ip=$(nslookup "$test_domain" | grep "Address:" | tail -1 | awk '{print $2}')
    if [[ -n "$ip" ]] && nslookup "$ip" >/dev/null 2>&1; then
        print_success "Reverse DNS resolution working"
    else
        print_warning "Reverse DNS resolution failed"
    fi
    
    return 0
}

backup_dns_config() {
    print_step "Backing up DNS configuration"
    
    local backup_dir="/root/backups/dns"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    # Backup BIND9 configuration
    if [[ -d /etc/bind ]]; then
        tar -czf "$backup_dir/bind9_config_$timestamp.tar.gz" -C /etc bind 2>/dev/null
        print_substep "BIND9 configuration backed up"
    fi
    
    # Backup dnsmasq configuration
    if [[ -f /etc/dnsmasq.conf ]]; then
        cp /etc/dnsmasq.conf "$backup_dir/dnsmasq_$timestamp.conf"
        print_substep "dnsmasq configuration backed up"
    fi
    
    print_success "DNS configuration backup completed"
}
