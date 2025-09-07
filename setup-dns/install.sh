#!/bin/bash
# DNS Server Installation Script

echo "============================================"
echo "        Installing DNS Server"
echo "============================================"

# Update system packages
echo "[1/4] Updating system packages..."
apt update -y

# Install BIND DNS server
echo "[2/4] Installing BIND9 DNS server..."
apt install -y bind9 bind9utils bind9-doc dnsutils

# Enable and start BIND service
echo "[3/4] Enabling BIND9 service..."
systemctl enable bind9
systemctl start bind9

# Configure basic DNS settings
echo "[4/4] Configuring basic DNS settings..."

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

# Restart BIND to apply changes
systemctl restart bind9

echo "============================================"
echo "✅ DNS server installed successfully!"
echo "✅ BIND9: Running and configured"
echo "✅ Forwarders: Google DNS and Cloudflare"
echo "✅ Zone directory: /etc/bind/zones"
echo ""
echo "📝 Next steps:"
echo "   1. Configure your domain zones"
echo "   2. Set up reverse DNS"
echo "   3. Update firewall rules (port 53)"
echo "============================================"
read -p "Press Enter to continue..."
