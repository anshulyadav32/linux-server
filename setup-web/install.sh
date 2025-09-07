#!/bin/bash
# Web-server Installation Script

echo "============================================"
echo "   Installing Web-server Stack"
echo "============================================"

# Update system packages
echo "[1/4] Updating system packages..."
apt update -y

# Install Apache, Nginx, PHP, Node.js
echo "[2/4] Installing Apache, Nginx, PHP, Node.js..."
apt install -y apache2 nginx php libapache2-mod-php nodejs npm php-mysql php-curl php-gd php-mbstring php-xml php-zip

# Enable services
echo "[3/4] Enabling web services..."
systemctl enable apache2
systemctl enable nginx
systemctl start apache2
systemctl start nginx

# Configure basic settings
echo "[4/4] Configuring basic settings..."
# Stop nginx by default to avoid port conflicts
systemctl stop nginx

# Create default web directory structure
mkdir -p /var/www/html/default
echo "<h1>Welcome to Your Web Server</h1><p>Apache is running successfully!</p>" > /var/www/html/index.html

echo "============================================"
echo "✅ Web-server stack installed successfully!"
echo "✅ Apache: Running on port 80"
echo "✅ Nginx: Installed (stopped to avoid conflicts)"
echo "✅ PHP: Installed with common modules"
echo "✅ Node.js: Installed with npm"
echo "============================================"
read -p "Press Enter to continue..."
