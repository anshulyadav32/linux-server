#!/bin/bash
# s1.sh - Simple server setup script
# Can be executed directly via: curl -sSL ls.r-u.live/sh/s1.sh | bash

set -e

echo "====================================================="
echo "  Server Setup Script - Quick Install"
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

# Install essential packages
echo "Installing essential packages..."
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
  apt install -y curl wget git unzip htop nano
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
  yum install -y curl wget git unzip htop nano
fi

# Configure firewall
echo "Configuring firewall..."
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
  apt install -y ufw
  ufw allow ssh
  ufw allow http
  ufw allow https
  echo "y" | ufw enable
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
  yum install -y firewalld
  systemctl enable firewalld
  systemctl start firewalld
  firewall-cmd --permanent --add-service=ssh
  firewall-cmd --permanent --add-service=http
  firewall-cmd --permanent --add-service=https
  firewall-cmd --reload
fi

# Configure SSH
echo "Securing SSH..."
sed -i 's/#PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
systemctl restart sshd

# Set up automatic updates
echo "Setting up automatic updates..."
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
  apt install -y unattended-upgrades
  dpkg-reconfigure -plow unattended-upgrades
fi

echo "====================================================="
echo "  Basic server setup complete!"
echo "  Visit ls.r-u.live for more scripts"
echo "====================================================="

# You can add more scripts or installations here
echo "Would you like to install additional components? (y/n)"
read -p "> " INSTALL_MORE

if [[ "$INSTALL_MORE" == "y" ]]; then
  echo "Visit ls.r-u.live for more installation options"
  echo "Try: curl -sSL ls.r-u.live/sh/setup-mail.sh | bash"
  echo "Or:  curl -sSL ls.r-u.live/sh/setup-dns.sh | bash"
fi

exit 0
