#!/bin/bash
# setup-dns-quick.sh - DNS Server quick setup script
# Can be executed directly via: curl -sSL ls.r-u.live/sh/setup-dns-quick.sh | sudo bash

set -e

echo "====================================================="
echo "  DNS Server Setup Script - Quick Install"
echo "  From ls.r-u.live"
echo "====================================================="

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  echo "Try: sudo bash"
  exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$NAME
  VER=$VERSION_ID
else
  echo "Cannot detect OS. Exiting."
  exit 1
fi

echo "Detected: $OS $VER"

# Update system
echo "Updating system packages..."
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
  apt update -y
  apt upgrade -y
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
  yum update -y
else
  echo "Unsupported OS: $OS"
  exit 1
fi

# Install BIND DNS server
echo "Installing BIND DNS server..."
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
  apt install -y bind9 bind9utils bind9-doc dnsutils
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
  yum install -y bind bind-utils
fi

# Create directories if they don't exist
mkdir -p /etc/bind/zones

# Ask for domain name
echo ""
echo "Please enter the domain name for your primary zone:"
read -p "Domain (e.g., example.com): " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
  DOMAIN_NAME="example.com"
  echo "Using default domain: $DOMAIN_NAME"
fi

# Ask for server role
echo ""
echo "Select DNS server role:"
echo "1) Master (Primary) DNS server"
echo "2) Slave (Secondary) DNS server"
echo "3) Caching DNS server"
read -p "Enter your choice [1-3]: " SERVER_ROLE

case $SERVER_ROLE in
  1)
    # Configure as Master DNS server
    echo "Configuring as Master DNS server..."
    
    # Create zone file
    cat > /etc/bind/zones/db.$DOMAIN_NAME << EOF
\$TTL 86400
@       IN      SOA     ns1.$DOMAIN_NAME. admin.$DOMAIN_NAME. (
                        $(date +%Y%m%d)01 ; Serial
                        3600        ; Refresh
                        1800        ; Retry
                        604800      ; Expire
                        86400 )     ; Minimum TTL

; Name servers
@       IN      NS      ns1.$DOMAIN_NAME.
@       IN      NS      ns2.$DOMAIN_NAME.

; A records
@       IN      A       192.168.1.10
ns1     IN      A       192.168.1.10
ns2     IN      A       192.168.1.11
www     IN      A       192.168.1.10
mail    IN      A       192.168.1.20

; Mail records
@       IN      MX      10 mail.$DOMAIN_NAME.
EOF

    # Update named.conf.local
    cat > /etc/bind/named.conf.local << EOF
zone "$DOMAIN_NAME" {
    type master;
    file "/etc/bind/zones/db.$DOMAIN_NAME";
    allow-transfer { 192.168.1.11; }; // Allow zone transfer to secondary server
};
EOF
    ;;
    
  2)
    # Configure as Slave DNS server
    echo "Configuring as Slave DNS server..."
    echo "Please enter the IP address of the master DNS server:"
    read -p "Master DNS IP: " MASTER_IP
    
    if [ -z "$MASTER_IP" ]; then
      MASTER_IP="192.168.1.10"
      echo "Using default Master IP: $MASTER_IP"
    fi
    
    # Update named.conf.local
    cat > /etc/bind/named.conf.local << EOF
zone "$DOMAIN_NAME" {
    type slave;
    file "db.$DOMAIN_NAME";
    masters { $MASTER_IP; };
};
EOF
    ;;
    
  3)
    # Configure as Caching DNS server
    echo "Configuring as Caching DNS server..."
    
    # Create caching configuration
    cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
    
    forward only;
    
    dnssec-validation auto;
    
    auth-nxdomain no;    # conform to RFC1035
    listen-on-v6 { any; };
};
EOF
    ;;
    
  *)
    echo "Invalid choice. Configuring as Caching DNS server by default."
    # Create default caching configuration
    cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
    
    forward only;
    
    dnssec-validation auto;
    
    auth-nxdomain no;    # conform to RFC1035
    listen-on-v6 { any; };
};
EOF
    ;;
esac

# Configure firewall
echo "Configuring firewall for DNS..."
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
  apt install -y ufw
  ufw allow 53/tcp
  ufw allow 53/udp
  echo "y" | ufw enable
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
  yum install -y firewalld
  systemctl enable firewalld
  systemctl start firewalld
  firewall-cmd --permanent --add-service=dns
  firewall-cmd --reload
fi

# Restart BIND
echo "Restarting BIND DNS server..."
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
  systemctl restart bind9
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
  systemctl restart named
fi

# Check status
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
  systemctl status bind9
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
  systemctl status named
fi

echo "====================================================="
echo "  DNS Server setup complete!"
echo "  Visit ls.r-u.live for more scripts"
echo "====================================================="

# Test DNS server
echo "Testing DNS server configuration..."
dig @localhost $DOMAIN_NAME

exit 0
