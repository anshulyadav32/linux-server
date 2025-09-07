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

# Run distribution detection
detect_distro

echo "🔄 Updating system..."
sudo apt update && sudo apt upgrade -y
echo "✅ System updated"

# Check for any remaining updates and notify user
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
fi

echo "📦 Installing Git..."
sudo apt install -y git
check_installed git

echo "📦 Installing GitHub CLI..."
sudo apt install -y curl
if ! command -v gh >/dev/null 2>&1; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
      sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt update && sudo apt install -y gh
fi
check_installed gh

echo "📦 Installing Node.js (LTS)..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
check_installed node
check_installed npm

echo "📦 Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib
check_installed psql

echo "📦 Installing MySQL..."
sudo apt install -y mysql-server
check_installed mysql

echo "📦 Installing Docker & Compose..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
check_installed docker
check_installed docker-compose || echo "⚠️ Docker Compose plugin may be 'docker compose' command instead"

sudo usermod -aG docker $USER

echo "📦 Installing Fail2Ban..."
sudo apt install -y fail2ban
check_installed fail2ban-client

echo "📦 Installing Roundcube & dependencies..."
sudo apt install -y apache2 php php-cli php-mbstring php-xml php-mysql php-pgsql php-intl php-curl roundcube roundcube-core roundcube-mysql roundcube-pgsql
check_installed roundcube-config || echo "⚠️ Roundcube installed, but check Apache/PHP configs manually"

echo "📦 Installing SSL (OpenSSL & Certbot)..."
sudo apt install -y openssl certbot python3-certbot-apache
check_installed openssl
check_installed certbot

echo "📦 Installing SSH server & client..."
sudo apt install -y openssh-server openssh-client
check_installed ssh
check_installed sshd

echo "📦 Installing terminal utilities..."
sudo apt install -y zsh tmux htop nano vim
check_installed zsh
check_installed tmux
check_installed htop

echo "🎯 FINAL CHECKPOINTS:"
echo "   - Git:        $(git --version)"
echo "   - GH CLI:     $(gh --version | head -n 1)"
echo "   - Node.js:    $(node -v)"
echo "   - NPM:        $(npm -v)"
echo "   - PostgreSQL: $(psql --version)"
echo "   - MySQL:      $(mysql --version)"
echo "   - Docker:     $(docker --version)"
echo "   - Fail2Ban:   $(fail2ban-client --version)"
echo "   - OpenSSL:    $(openssl version)"
echo "   - SSH:        $(ssh -V 2>&1)"
echo "   - ZSH:        $(zsh --version)"

echo "✅ All installations completed successfully!"
echo "👉 Reboot or run 'newgrp docker' to use Docker without sudo."
echo "👉 Configure Roundcube + DB + Apache manually."
echo "👉 Setup Fail2Ban jail rules in /etc/fail2ban/jail.local"
