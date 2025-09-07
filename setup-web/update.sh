#!/bin/bash
# Web-server Update Script

echo "============================================"
echo "      Updating Web-server Stack"
echo "============================================"

# Update package lists
echo "[1/3] Updating package lists..."
apt update -y

# Update web server packages
echo "[2/3] Updating web server packages..."
apt upgrade -y apache2 nginx php libapache2-mod-php nodejs npm php-mysql php-curl php-gd php-mbstring php-xml php-zip

# Update Node.js packages globally
echo "[3/3] Updating global Node.js packages..."
npm update -g

echo "============================================"
echo "✅ Web-server stack updated successfully!"
echo ""
echo "Current versions:"
apache2 -v | head -1
nginx -v
php -v | head -1
node -v
npm -v
echo "============================================"
read -p "Press Enter to continue..."
