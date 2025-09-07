#!/bin/bash
set -e

# Function to check if a command is installed
check_installed() {
    if command -v $1 >/dev/null 2>&1; then
        echo "✅ $1 installed successfully"
    else
        echo "❌ $1 installation failed"
        exit 1
    fi
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
        echo "🖥️ Detected Linux distribution: $PRETTY_NAME"
    else
        echo "❌ Cannot detect Linux distribution. This script supports Ubuntu/Debian."
        exit 1
    fi
    
    # Check if distribution is Ubuntu or Debian based
    if [[ "$DISTRO" != "ubuntu" && "$DISTRO" != "debian" && "$DISTRO" != "linuxmint" && "$DISTRO" != "pop" ]]; then
        echo "❌ This script is designed for Ubuntu/Debian based distributions."
        echo "   Detected: $DISTRO"
        echo "   Please use the appropriate script for your distribution."
        exit 1
    fi
}

# Function to check if string is a valid domain
is_valid_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](\.[a-zA-Z]{2,})+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Configuration variables (with defaults)
DOMAIN=""
SERVER_IP=""
FORWARDERS="8.8.8.8;8.8.4.4"
SETUP_MASTER=true
SETUP_SLAVE=false
SETUP_CACHING=false
ENABLE_DNSSEC=true
MASTER_DNS=""
IS_INTERNAL=false
DNS_PORT=53
ALLOW_TRANSFER=""
DNS_LISTEN_ON="any"

# Process command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            --domain)
                DOMAIN="$2"
                shift
                shift
                ;;
            --server-ip)
                SERVER_IP="$2"
                shift
                shift
                ;;
            --forwarders)
                FORWARDERS="$2"
                shift
                shift
                ;;
            --setup-master)
                SETUP_MASTER=true
                SETUP_SLAVE=false
                SETUP_CACHING=false
                shift
                ;;
            --setup-slave)
                SETUP_MASTER=false
                SETUP_SLAVE=true
                SETUP_CACHING=false
                shift
                ;;
            --setup-caching)
                SETUP_MASTER=false
                SETUP_SLAVE=false
                SETUP_CACHING=true
                shift
                ;;
            --no-dnssec)
                ENABLE_DNSSEC=false
                shift
                ;;
            --master-dns)
                MASTER_DNS="$2"
                shift
                shift
                ;;
            --internal)
                IS_INTERNAL=true
                shift
                ;;
            --port)
                DNS_PORT="$2"
                shift
                shift
                ;;
            --allow-transfer)
                ALLOW_TRANSFER="$2"
                shift
                shift
                ;;
            --listen-on)
                DNS_LISTEN_ON="$2"
                shift
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "❌ Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    echo "BIND DNS Server Setup Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --domain DOMAIN       Primary domain name for DNS server (required for master/slave)"
    echo "  --server-ip IP        Server IP address (required for master)"
    echo "  --forwarders IPS      DNS forwarders separated by semicolons (default: 8.8.8.8;8.8.4.4)"
    echo "  --setup-master        Setup as master/primary DNS server (default)"
    echo "  --setup-slave         Setup as slave/secondary DNS server"
    echo "  --setup-caching       Setup as caching-only DNS server"
    echo "  --no-dnssec           Disable DNSSEC validation"
    echo "  --master-dns IP       Master DNS IP (required for slave setup)"
    echo "  --internal            Configure for internal network use only"
    echo "  --port PORT           DNS port (default: 53)"
    echo "  --allow-transfer IPS  IPs allowed for zone transfers (semicolon-separated)"
    echo "  --listen-on ADDR      Address to listen on (default: any)"
    echo "  --help                Show this help message"
    echo ""
}

# Check required arguments
check_arguments() {
    if [ "$SETUP_MASTER" = true ] || [ "$SETUP_SLAVE" = true ]; then
        if [ -z "$DOMAIN" ]; then
            echo "❌ Domain is required for master/slave setup. Use --domain option."
            show_help
            exit 1
        fi

        if ! is_valid_domain "$DOMAIN"; then
            echo "❌ Invalid domain format: $DOMAIN"
            exit 1
        fi
    fi
    
    if [ "$SETUP_MASTER" = true ] && [ -z "$SERVER_IP" ]; then
        # Try to auto-detect IP
        SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
        if [ -z "$SERVER_IP" ]; then
            echo "❌ Server IP is required for master DNS setup. Use --server-ip option."
            show_help
            exit 1
        else
            echo "ℹ️ Auto-detected server IP: $SERVER_IP"
        fi
    fi
    
    if [ "$SETUP_SLAVE" = true ] && [ -z "$MASTER_DNS" ]; then
        echo "❌ Master DNS IP is required for slave setup. Use --master-dns option."
        show_help
        exit 1
    fi
}

# Update system
update_system() {
    echo "🔄 Updating system..."
    sudo apt update && sudo apt upgrade -y
    echo "✅ System updated"

    # Check for any remaining updates
    echo "🔍 Checking for remaining updates..."
    UPDATES=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)
    if [ "$UPDATES" -gt 0 ]; then
        echo "⚠️ There are still $UPDATES updates available. Some may require a system restart."
    else
        echo "✅ All packages are up to date"
    fi

    # Check if a reboot is required
    if [ -f /var/run/reboot-required ]; then
        echo "⚠️ A system reboot is required to complete updates"
        echo "   Please reboot the system and run this script again."
        exit 1
    fi
}

# Install required packages
install_dependencies() {
    echo "📦 Installing essential packages..."
    sudo apt install -y bind9 bind9utils bind9-doc dnsutils
    check_installed named
    check_installed dig
    check_installed host
    echo "✅ BIND9 DNS server installed"
}

# Configure BIND as master/primary DNS server
configure_master_dns() {
    echo "🔧 Configuring BIND as master/primary DNS server for $DOMAIN..."
    
    # Backup original config
    sudo cp /etc/bind/named.conf /etc/bind/named.conf.bak
    sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak
    sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak
    
    # Configure named.conf.options
    local_forwarders=$(echo "$FORWARDERS" | sed 's/;/; /g')
    
    cat > /tmp/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    
    // Listen on local interfaces only by default
    listen-on {
        127.0.0.1;
        $SERVER_IP;
EOF
    
    if [ "$DNS_LISTEN_ON" = "any" ]; then
        echo "        any;" >> /tmp/named.conf.options
    else
        echo "        $DNS_LISTEN_ON;" >> /tmp/named.conf.options
    fi

    cat >> /tmp/named.conf.options << EOF
    };
    
    listen-on-v6 { ::1; };
    
    // Configure forwarders
    forwarders {
        $local_forwarders;
    };
    
    // Enable/disable DNSSEC validation
    dnssec-validation $(if [ "$ENABLE_DNSSEC" = true ]; then echo "auto"; else echo "no"; fi);
    
    // Allow recursive queries from trusted networks only
    allow-recursion {
        localhost;
        localnets;
EOF
    
    if [ "$IS_INTERNAL" = true ]; then
        echo "        10.0.0.0/8;" >> /tmp/named.conf.options
        echo "        172.16.0.0/12;" >> /tmp/named.conf.options
        echo "        192.168.0.0/16;" >> /tmp/named.conf.options
    fi

    cat >> /tmp/named.conf.options << EOF
    };
    
    allow-transfer {
        localhost;
EOF

    if [ -n "$ALLOW_TRANSFER" ]; then
        for ip in $(echo "$ALLOW_TRANSFER" | sed 's/;/ /g'); do
            echo "        $ip;" >> /tmp/named.conf.options
        done
    fi

    cat >> /tmp/named.conf.options << EOF
    };
    
    // Reduce network traffic
    minimal-responses yes;
    
    // Prevent DNS cache poisoning and related attacks
    additional-from-auth no;
    additional-from-cache no;
    
    // Hide version number from clients for security
    version "DNS Server";
};
EOF

    sudo cp /tmp/named.conf.options /etc/bind/named.conf.options
    
    # Configure named.conf.local for the zone
    cat > /tmp/named.conf.local << EOF
zone "$DOMAIN" {
    type master;
    file "/etc/bind/zones/db.$DOMAIN";
    allow-update { none; };
};

zone "$(echo "$SERVER_IP" | awk -F. '{print $3"."$2"."$1}").in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.$(echo "$SERVER_IP" | cut -d. -f1-3)";
    allow-update { none; };
};
EOF

    sudo cp /tmp/named.conf.local /etc/bind/named.conf.local
    
    # Create zones directory if it doesn't exist
    sudo mkdir -p /etc/bind/zones
    
    # Create forward zone file
    cat > /tmp/db.$DOMAIN << EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. (
                     $(date +%Y%m%d)01     ; Serial
                         604800     ; Refresh
                          86400     ; Retry
                        2419200     ; Expire
                         604800 )   ; Negative Cache TTL
;
@       IN      NS      ns1.$DOMAIN.
@       IN      NS      ns2.$DOMAIN.
@       IN      A       $SERVER_IP
@       IN      MX      10 mail.$DOMAIN.
@       IN      TXT     "v=spf1 mx a -all"
_dmarc  IN      TXT     "v=DMARC1; p=none; sp=none; rua=mailto:admin@$DOMAIN; ruf=mailto:admin@$DOMAIN; fo=1; adkim=r; aspf=r; pct=100; rf=afrf"

ns1     IN      A       $SERVER_IP
ns2     IN      A       $SERVER_IP
www     IN      A       $SERVER_IP
mail    IN      A       $SERVER_IP
EOF

    sudo cp /tmp/db.$DOMAIN /etc/bind/zones/db.$DOMAIN
    
    # Create reverse zone file
    IP_REV=$(echo "$SERVER_IP" | awk -F. '{print $3"."$2"."$1}')
    IP_LAST_OCTET=$(echo "$SERVER_IP" | cut -d. -f4)
    IP_PREFIX=$(echo "$SERVER_IP" | cut -d. -f1-3)
    
    cat > /tmp/db.$IP_PREFIX << EOF
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. (
                     $(date +%Y%m%d)01     ; Serial
                         604800     ; Refresh
                          86400     ; Retry
                        2419200     ; Expire
                         604800 )   ; Negative Cache TTL
;
@       IN      NS      ns1.$DOMAIN.
@       IN      NS      ns2.$DOMAIN.
$IP_LAST_OCTET   IN      PTR     $DOMAIN.
$IP_LAST_OCTET   IN      PTR     ns1.$DOMAIN.
$IP_LAST_OCTET   IN      PTR     www.$DOMAIN.
$IP_LAST_OCTET   IN      PTR     mail.$DOMAIN.
EOF

    sudo cp /tmp/db.$IP_PREFIX /etc/bind/zones/db.$IP_PREFIX
    
    echo "✅ Master DNS server configured"
}

# Configure BIND as slave/secondary DNS server
configure_slave_dns() {
    echo "🔧 Configuring BIND as slave/secondary DNS server for $DOMAIN..."
    
    # Backup original config
    sudo cp /etc/bind/named.conf /etc/bind/named.conf.bak
    sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak
    sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak
    
    # Configure named.conf.options
    local_forwarders=$(echo "$FORWARDERS" | sed 's/;/; /g')
    
    cat > /tmp/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    
    // Listen on local interfaces only by default
    listen-on { 127.0.0.1; any; };
    listen-on-v6 { ::1; };
    
    // Configure forwarders
    forwarders {
        $local_forwarders;
    };
    
    // Enable/disable DNSSEC validation
    dnssec-validation $(if [ "$ENABLE_DNSSEC" = true ]; then echo "auto"; else echo "no"; fi);
    
    // Allow recursive queries from trusted networks only
    allow-recursion {
        localhost;
        localnets;
    };
    
    // Reduce network traffic
    minimal-responses yes;
    
    // Prevent DNS cache poisoning and related attacks
    additional-from-auth no;
    additional-from-cache no;
    
    // Hide version number from clients for security
    version "DNS Server";
};
EOF

    sudo cp /tmp/named.conf.options /etc/bind/named.conf.options
    
    # Configure named.conf.local for the zone
    cat > /tmp/named.conf.local << EOF
zone "$DOMAIN" {
    type slave;
    file "db.$DOMAIN";
    masters { $MASTER_DNS; };
};

// Configure reverse zone if needed
EOF

    sudo cp /tmp/named.conf.local /etc/bind/named.conf.local
    
    echo "✅ Slave DNS server configured"
}

# Configure BIND as caching-only DNS server
configure_caching_dns() {
    echo "🔧 Configuring BIND as caching-only DNS server..."
    
    # Backup original config
    sudo cp /etc/bind/named.conf /etc/bind/named.conf.bak
    sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak
    
    # Configure named.conf.options
    local_forwarders=$(echo "$FORWARDERS" | sed 's/;/; /g')
    
    cat > /tmp/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    
    // Listen on local interfaces only by default
    listen-on { 127.0.0.1; any; };
    listen-on-v6 { ::1; };
    
    // Configure forwarders
    forwarders {
        $local_forwarders;
    };
    
    // Enable/disable DNSSEC validation
    dnssec-validation $(if [ "$ENABLE_DNSSEC" = true ]; then echo "auto"; else echo "no"; fi);
    
    // Allow recursive queries from trusted networks only
    allow-recursion {
        localhost;
        localnets;
    };
    
    // Reduce network traffic
    minimal-responses yes;
    
    // Prevent DNS cache poisoning and related attacks
    additional-from-auth no;
    additional-from-cache no;
    
    // Hide version number from clients for security
    version "DNS Server";
};
EOF

    sudo cp /tmp/named.conf.options /etc/bind/named.conf.options
    
    # Clear local zones configuration
    cat > /tmp/named.conf.local << EOF
// Caching-only DNS server, no local zones defined
EOF

    sudo cp /tmp/named.conf.local /etc/bind/named.conf.local
    
    echo "✅ Caching-only DNS server configured"
}

# Configure firewall
configure_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        echo "🔧 Configuring firewall..."
        sudo ufw allow $DNS_PORT/tcp
        sudo ufw allow $DNS_PORT/udp
        echo "✅ Firewall configured"
    else
        echo "ℹ️ UFW firewall not installed, skipping firewall configuration"
    fi
}

# Verify configuration
verify_configuration() {
    echo "🔍 Verifying BIND configuration..."
    sudo named-checkconf
    
    if [ "$SETUP_MASTER" = true ]; then
        sudo named-checkzone $DOMAIN /etc/bind/zones/db.$DOMAIN
        IP_PREFIX=$(echo "$SERVER_IP" | cut -d. -f1-3)
        sudo named-checkzone $IP_REV.in-addr.arpa /etc/bind/zones/db.$IP_PREFIX
    fi
    
    echo "✅ BIND configuration verified"
}

# Main function
main() {
    detect_distro
    parse_arguments "$@"
    check_arguments
    
    echo "🚀 Starting BIND DNS server setup"
    if [ "$SETUP_MASTER" = true ]; then
        echo "   Mode: Primary/Master DNS server"
        echo "   Domain: $DOMAIN"
        echo "   Server IP: $SERVER_IP"
    elif [ "$SETUP_SLAVE" = true ]; then
        echo "   Mode: Secondary/Slave DNS server"
        echo "   Domain: $DOMAIN"
        echo "   Master DNS: $MASTER_DNS"
    else
        echo "   Mode: Caching-only DNS server"
    fi
    
    update_system
    install_dependencies
    
    if [ "$SETUP_MASTER" = true ]; then
        configure_master_dns
    elif [ "$SETUP_SLAVE" = true ]; then
        configure_slave_dns
    else
        configure_caching_dns
    fi
    
    configure_firewall
    verify_configuration
    
    # Restart BIND
    echo "🔄 Restarting BIND DNS server..."
    sudo systemctl restart bind9
    sudo systemctl enable bind9
    
    # Check service status
    echo "🔍 Checking BIND DNS server status..."
    sudo systemctl status bind9 --no-pager
    
    echo "✅ BIND DNS server setup completed successfully!"
    echo ""
    echo "📝 Next steps:"
    if [ "$SETUP_MASTER" = true ]; then
        echo "1. Make sure your domain registrar points to this DNS server"
        echo "2. If this is a public DNS server, ensure port $DNS_PORT is forwarded to this server"
        echo "3. Test your DNS server with: dig @$SERVER_IP $DOMAIN"
        echo "4. Consider setting up a secondary/slave DNS server for redundancy"
    elif [ "$SETUP_SLAVE" = true ]; then
        echo "1. Ensure the master DNS server allows zone transfers to this server"
        echo "2. Test your DNS server with: dig @localhost $DOMAIN"
    else
        echo "1. Configure clients to use this DNS server"
        echo "2. Test your caching DNS server with: dig @localhost google.com"
    fi
    echo ""
}

# Show help if no arguments provided
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Run main function with all arguments
main "$@"
