#!/bin/bash
set -e

echo "🚀 Running Server Setup Script (s1.sh)"
echo "======================================"

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

# Install essential tools
install_essentials() {
    echo "🔧 Installing essential tools..."
    apt-get install -y curl wget git unzip zip nano htop ncdu net-tools
    check_installed curl
    check_installed wget
    check_installed git
    echo "✅ Essential tools installed"
}

# Setup basic firewall
setup_firewall() {
    echo "🔥 Setting up firewall..."
    apt-get install -y ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow http
    ufw allow https
    echo "y" | ufw enable
    check_installed ufw
    echo "✅ Firewall configured"
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
    install_essentials
    setup_firewall
    
    echo "✅ Server setup completed successfully!"
    echo "🔗 Visit ls.r-u.live for more server setup scripts"
}

# Run the main function
main "$@"
