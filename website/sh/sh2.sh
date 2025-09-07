#!/bin/bash
set -e

echo "📧 Running Mail Server Setup Script (sh2.sh)"
echo "==========================================="

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

# Install Postfix
install_postfix() {
    echo "📨 Installing Postfix mail server..."
    debconf-set-selections <<< "postfix postfix/mailname string $(hostname -f)"
    debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
    apt-get install -y postfix
    check_installed postfix
    echo "✅ Postfix installed"
}

# Install Dovecot
install_dovecot() {
    echo "📬 Installing Dovecot IMAP/POP3 server..."
    apt-get install -y dovecot-core dovecot-imapd dovecot-pop3d
    check_installed dovecot
    echo "✅ Dovecot installed"
}

# Install SpamAssassin
install_spamassassin() {
    echo "🛡️ Installing SpamAssassin..."
    apt-get install -y spamassassin spamc
    check_installed spamassassin
    echo "✅ SpamAssassin installed"
}

# Install Webmail (Roundcube)
install_webmail() {
    echo "🌐 Installing Roundcube webmail..."
    apt-get install -y roundcube roundcube-core roundcube-mysql roundcube-plugins
    check_installed roundcube-cli
    echo "✅ Roundcube webmail installed"
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
    install_postfix
    install_dovecot
    install_spamassassin
    install_webmail
    
    echo "✅ Mail server setup completed successfully!"
    echo "📝 Remember to configure your DNS records for proper mail delivery"
    echo "🔗 Visit ls.r-u.live for more server setup scripts"
}

# Run the main function
main "$@"
