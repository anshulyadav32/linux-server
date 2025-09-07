#!/bin/bash
# Enhanced DNS Functions Library
# Comprehensive functions for DNS server management

#===========================================
# CONSTANTS AND CONFIGURATIONS
#===========================================
readonly DNS_ZONES_DIR="/etc/bind/zones"
readonly DNS_CONF_DIR="/etc/bind"
readonly DNS_CACHE_DIR="/var/cache/bind"
readonly DNS_LOG_FILE="/var/log/named/named.log"
readonly BACKUP_DIR="/var/backups/bind9"

#===========================================
# VALIDATION FUNCTIONS
#===========================================
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        return $?
    fi
    return 1
}

validate_domain() {
    local domain=$1
    [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]
    return $?
}

validate_record_type() {
    local type=$1
    case $type in
        A|AAAA|CNAME|MX|TXT|SRV|PTR|NS) return 0 ;;
        *) return 1 ;;
    esac
}

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
    if [[ -f "$DNS_LOG_FILE" ]]; then
        tail -n 50 "$DNS_LOG_FILE"
    else
        journalctl -u bind9 -n 50 --no-pager
    fi
}

clear_dns_cache() {
    echo "[INFO] Clearing DNS cache..."
    rndc flush
    rndc reload
    echo "[SUCCESS] DNS cache cleared and zones reloaded"
}

check_dns_performance() {
    local domain=${1:-"google.com"}
    echo "[INFO] Testing DNS resolution performance..."
    echo "Resolution time for $domain:"
    dig @localhost "$domain" | grep "Query time"
    
    echo -e "\nConnection test results:"
    for server in 8.8.8.8 1.1.1.1 localhost; do
        echo "Testing $server:"
        dig @"$server" "$domain" +short +stats | grep "Query time"
    done
}

monitor_dns_queries() {
    echo "[INFO] Starting DNS query monitoring..."
    if command -v tcpdump &>/dev/null; then
        tcpdump -i any port 53
    else
        echo "[ERROR] tcpdump not installed. Installing..."
        apt-get install -y tcpdump
        tcpdump -i any port 53
    fi
}

check_zone_serial_numbers() {
    echo "[INFO] Checking zone serial numbers..."
    for zone_file in "$DNS_ZONES_DIR"/db.*; do
        if [[ -f "$zone_file" ]]; then
            local zone=$(basename "$zone_file" | sed 's/db\.//')
            local serial=$(grep "Serial" "$zone_file" | awk '{print $1}')
            echo "Zone: $zone, Serial: $serial"
        fi
    done
}

validate_all_zones() {
    echo "[INFO] Validating all DNS zones..."
    local errors=0
    for zone_file in "$DNS_ZONES_DIR"/db.*; do
        if [[ -f "$zone_file" ]]; then
            local zone=$(basename "$zone_file" | sed 's/db\.//')
            echo -n "Checking zone $zone... "
            if named-checkzone "$zone" "$zone_file" >/dev/null 2>&1; then
                echo "[OK]"
            else
                echo "[FAILED]"
                errors=$((errors + 1))
            fi
        fi
    done
    return $errors
}

backup_dns_config() {
    local backup_file="$BACKUP_DIR/bind9_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    echo "[INFO] Creating backup: $backup_file"
    mkdir -p "$BACKUP_DIR"
    tar -czf "$backup_file" "$DNS_CONF_DIR" "$DNS_ZONES_DIR" "$DNS_CACHE_DIR" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo "[SUCCESS] Backup created successfully"
        return 0
    else
        echo "[ERROR] Backup creation failed"
        return 1
    fi
}

restore_dns_config() {
    local backup_file=$1
    if [[ ! -f "$backup_file" ]]; then
        echo "[ERROR] Backup file not found"
        return 1
    fi
    
    echo "[INFO] Restoring from backup: $backup_file"
    systemctl stop bind9
    tar -xzf "$backup_file" -C / >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        systemctl start bind9
        echo "[SUCCESS] Configuration restored successfully"
        return 0
    else
        echo "[ERROR] Restore failed"
        return 1
    fi
}

test_dns_configuration() {
    echo "[INFO] Testing DNS configuration..."
    
    # Check main configuration
    echo -n "Testing named.conf... "
    if named-checkconf; then
        echo "[OK]"
    else
        echo "[FAILED]"
        return 1
    fi
    
    # Test zone files
    validate_all_zones
    
    # Test DNS resolution
    echo -n "Testing local resolution... "
    if dig @localhost google.com +short >/dev/null; then
        echo "[OK]"
    else
        echo "[FAILED]"
    fi
    
    # Test DNSSEC
    echo -n "Testing DNSSEC validation... "
    if dig +dnssec @localhost google.com >/dev/null 2>&1; then
        echo "[OK]"
    else
        echo "[WARNING] DNSSEC validation may not be enabled"
    fi
    
    return 0
}

analyze_dns_security() {
    echo "[INFO] Analyzing DNS security configuration..."
    
    # Check DNSSEC
    if grep -q "dnssec-validation auto" "$DNS_CONF_DIR/named.conf.options"; then
        echo "✓ DNSSEC validation is enabled"
    else
        echo "✗ DNSSEC validation is not enabled"
    fi
    
    # Check query restrictions
    if grep -q "allow-query" "$DNS_CONF_DIR/named.conf.options"; then
        echo "✓ Query restrictions are configured"
    else
        echo "✗ No query restrictions found"
    fi
    
    # Check recursion settings
    if grep -q "recursion no" "$DNS_CONF_DIR/named.conf.options"; then
        echo "✓ Recursion is disabled (more secure)"
    else
        echo "! Recursion is enabled (review if needed)"
    fi
    
    # Check version disclosure
    if grep -q "version none" "$DNS_CONF_DIR/named.conf.options"; then
        echo "✓ Version disclosure is disabled"
    else
        echo "! Version disclosure is enabled"
    fi
}

#===========================================
# UPDATE FUNCTIONS
#===========================================

update_dns() {
    echo "[INFO] Updating DNS server packages..."
    
    # Create backup before update
    backup_dns_config
    
    # Update package lists
    apt update -y
    
    # Store current version
    local old_version=$(named -v 2>&1 | head -1)
    
    # Perform upgrade
    apt upgrade -y bind9 bind9utils bind9-doc dnsutils
    
    # Update root hints file
    echo "[INFO] Updating root hints..."
    wget -O "$DNS_CONF_DIR/db.root" https://www.internic.net/domain/named.root 2>/dev/null || \
        echo "[WARNING] Failed to update root hints"
    
    # Verify configuration after update
    if ! named-checkconf; then
        echo "[ERROR] Configuration error after update"
        echo "Restoring from backup..."
        restore_dns_config "$BACKUP_DIR/$(ls -t "$BACKUP_DIR" | head -1)"
        return 1
    fi
    
    # Restart service
    restart_dns
    
    # Show version comparison
    local new_version=$(named -v 2>&1 | head -1)
    echo "[INFO] Version update:"
    echo "Old: $old_version"
    echo "New: $new_version"
    
    echo "[SUCCESS] DNS server updated"
    return 0
}
