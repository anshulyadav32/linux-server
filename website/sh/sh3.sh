#!/bin/bash
set -e

echo "🌐 Running DNS Server Setup Script (sh3.sh)"
echo "=========================================="

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

# Update system packages
update_system() {
    echo "📦 Updating system packages..."
    apt-get update -y
    apt-get upgrade -y
    check_installed apt-get
}

# Install BIND DNS Server
install_bind() {
    echo "🔍 Installing BIND DNS server..."
    apt-get install -y bind9 bind9utils bind9-doc dnsutils
    check_installed named
    systemctl enable bind9
    systemctl start bind9
    echo "✅ BIND DNS server installed"
}

# Configure basic DNS settings
configure_dns() {
    echo "⚙️ Configuring basic DNS settings..."
    
    # Create a backup of the configuration file
    cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak
    
    # Configure DNS options with forwarders
    cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    
    // Forwarders - using Google DNS
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
    
    // If you want to enable recursive queries
    recursion yes;
    
    // Listen on all interfaces
    listen-on { any; };
    listen-on-v6 { any; };
    
    // Allow queries from local network only
    allow-query { localhost; localnets; };
    
    dnssec-validation auto;
    auth-nxdomain no;
};
EOF
    
    echo "✅ DNS configuration updated"
}

# Main execution
main() {
    # Check if script is run as root
    if [ "$(id -u)" -ne 0 ]; then
        echo "❌ This script must be run as root"
        exit 1
    fi
    
    detect_distro
    update_system
    install_bind
    configure_dns
    
    # Restart BIND to apply changes
    systemctl restart bind9
    
    echo "✅ DNS server setup completed successfully!"
    echo "📝 Remember to configure your zone files for your domains"
    echo "🔗 Visit ls.r-u.live for more server setup scripts"
}

# Run the main function
main "$@"
