#!/bin/bash
# DNS Functions Library
# Reusable functions for DNS server management

#===========================================
# INSTALLATION FUNCTIONS
#===========================================

install_dns() {
    echo "[INFO] Installing BIND9 DNS server..."
    apt update -y
    apt install -y bind9 bind9utils bind9-doc dnsutils
    systemctl enable bind9
    systemctl start bind9
    
    # Configure basic DNS settings
    configure_dns_defaults
    echo "[SUCCESS] DNS server installed"
}

configure_dns_defaults() {
    echo "[INFO] Configuring basic DNS settings..."
    
    # Create basic configuration
    cat > /etc/bind/named.conf.options << 'EOF'
options {
    directory "/var/cache/bind";
    
    // Forwarders - using Google and Cloudflare DNS
    forwarders {
        8.8.8.8;
        8.8.4.4;
        1.1.1.1;
        1.0.0.1;
    };
    
    // Enable recursive queries
    recursion yes;
    
    // Listen on all interfaces
    listen-on { any; };
    listen-on-v6 { any; };
    
    // Allow queries from anywhere (adjust as needed)
    allow-query { any; };
    
    // DNSSEC validation
    dnssec-validation auto;
    auth-nxdomain no;
};
EOF
    
    # Create zones directory
    mkdir -p /etc/bind/zones
    restart_dns
}

#===========================================
# ZONE MANAGEMENT FUNCTIONS
#===========================================

add_zone() {
    local domain="$1"
    local server_ip="$2"
    
    if [[ -z "$domain" || -z "$server_ip" ]]; then
        echo "[ERROR] Domain and server IP parameters required"
        return 1
    fi
    
    echo "[INFO] Adding DNS zone: $domain"
    
    # Create zone file
    cat > "/etc/bind/zones/db.$domain" << EOF
\$TTL    604800
@       IN      SOA     ns1.$domain. admin.$domain. (
                        $(date +%Y%m%d)01 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL

; Name servers
@       IN      NS      ns1.$domain.
@       IN      NS      ns2.$domain.

; A records
@       IN      A       $server_ip
ns1     IN      A       $server_ip
ns2     IN      A       $server_ip
www     IN      A       $server_ip
mail    IN      A       $server_ip

; MX record
@       IN      MX 10   mail.$domain.

; CNAME records
ftp     IN      CNAME   @
EOF

    # Add zone to named.conf.local
    cat >> /etc/bind/named.conf.local << EOF

zone "$domain" {
    type master;
    file "/etc/bind/zones/db.$domain";
};
EOF

    # Validate and reload
    if validate_zone "$domain"; then
        reload_dns
        echo "[SUCCESS] Zone $domain added successfully"
    else
        echo "[ERROR] Zone validation failed"
        return 1
    fi
}

remove_zone() {
    local domain="$1"
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Removing DNS zone: $domain"
    
    # Remove from named.conf.local
    sed -i "/zone \"$domain\"/,/};/d" /etc/bind/named.conf.local
    # Remove zone file
    rm -f "/etc/bind/zones/db.$domain"
    reload_dns
    
    echo "[SUCCESS] Zone $domain removed"
}

add_record() {
    local zone="$1"
    local record_name="$2"
    local record_type="$3"
    local record_value="$4"
    
    if [[ -z "$zone" || -z "$record_name" || -z "$record_type" || -z "$record_value" ]]; then
        echo "[ERROR] All parameters required: zone, record_name, record_type, record_value"
        return 1
    fi
    
    echo "[INFO] Adding DNS record: $record_name.$zone $record_type $record_value"
    
    # Add record to zone file
    echo "$record_name    IN      $record_type    $record_value" >> "/etc/bind/zones/db.$zone"
    
    # Increment serial number
    increment_zone_serial "$zone"
    
    if validate_zone "$zone"; then
        reload_dns
        echo "[SUCCESS] DNS record added"
    else
        echo "[ERROR] Zone validation failed"
        return 1
    fi
}

remove_record() {
    local zone="$1"
    local record_name="$2"
    
    if [[ -z "$zone" || -z "$record_name" ]]; then
        echo "[ERROR] Zone and record name parameters required"
        return 1
    fi
    
    echo "[INFO] Removing DNS record: $record_name from $zone"
    
    # Remove record from zone file
    sed -i "/^$record_name/d" "/etc/bind/zones/db.$zone"
    
    # Increment serial number
    increment_zone_serial "$zone"
    
    if validate_zone "$zone"; then
        reload_dns
        echo "[SUCCESS] DNS record removed"
    else
        echo "[ERROR] Zone validation failed"
        return 1
    fi
}

list_zones() {
    echo "[INFO] Active DNS zones:"
    grep -E "^zone" /etc/bind/named.conf.local | awk '{print $2}' | tr -d '"' | while read zone; do
        if [[ -n "$zone" ]]; then
            echo "  - $zone"
        fi
    done
}

#===========================================
# UTILITY FUNCTIONS
#===========================================

increment_zone_serial() {
    local zone="$1"
    local zone_file="/etc/bind/zones/db.$zone"
    
    if [[ -f "$zone_file" ]]; then
        # Update serial number (simple increment)
        local new_serial=$(date +%Y%m%d)$(printf "%02d" $(($(date +%H) + 1)))
        sed -i "s/[0-9]\{10\} ; Serial/$new_serial ; Serial/" "$zone_file"
    fi
}

validate_zone() {
    local zone="$1"
    local zone_file="/etc/bind/zones/db.$zone"
    
    if named-checkzone "$zone" "$zone_file" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

test_dns_resolution() {
    local domain="$1"
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Testing DNS resolution for: $domain"
    dig @localhost "$domain" +short
}

#===========================================
# SERVICE MANAGEMENT FUNCTIONS
#===========================================

restart_dns() {
    echo "[INFO] Restarting BIND9..."
    systemctl restart bind9
    if systemctl is-active --quiet bind9; then
        echo "[SUCCESS] BIND9 restarted successfully"
    else
        echo "[ERROR] BIND9 failed to restart"
        return 1
    fi
}

reload_dns() {
    echo "[INFO] Reloading DNS configuration..."
    if named-checkconf; then
        systemctl reload bind9
        echo "[SUCCESS] DNS configuration reloaded"
    else
        echo "[ERROR] Configuration has errors"
        return 1
    fi
}

status_dns() {
    echo "[INFO] DNS service status:"
    systemctl status bind9 --no-pager | head -5
    echo ""
    echo "Listening ports:"
    netstat -tlnp | grep :53
}

#===========================================
# MAINTENANCE FUNCTIONS
#===========================================

view_dns_logs() {
    echo "[INFO] Recent DNS logs:"
    journalctl -u bind9 -n 20 --no-pager
}

clear_dns_cache() {
    echo "[INFO] Clearing DNS cache..."
    rndc flush
    echo "[SUCCESS] DNS cache cleared"
}

#===========================================
# UPDATE FUNCTIONS
#===========================================

update_dns() {
    echo "[INFO] Updating DNS server packages..."
    apt update -y
    apt upgrade -y bind9 bind9utils bind9-doc dnsutils
    
    # Update root hints file
    wget -O /etc/bind/db.root https://www.internic.net/domain/named.root 2>/dev/null || echo "[WARNING] Failed to update root hints"
    
    restart_dns
    echo "[SUCCESS] DNS server updated"
}
