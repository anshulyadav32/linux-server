#!/bin/bash
# DNS Server Update Script

echo "============================================"
echo "         Updating DNS Server"
echo "============================================"

# Update package lists
echo "[1/3] Updating package lists..."
apt update -y

# Update BIND DNS server packages
echo "[2/3] Updating BIND9 packages..."
apt upgrade -y bind9 bind9utils bind9-doc dnsutils

# Update root hints file
echo "[3/3] Updating root hints file..."
wget -O /etc/bind/db.root https://www.internic.net/domain/named.root 2>/dev/null || echo "Failed to update root hints"

# Restart BIND to apply updates
systemctl restart bind9

echo "============================================"
echo "✅ DNS server updated successfully!"
echo ""
echo "Current version:"
named -v
echo ""
echo "Service status:"
systemctl is-active bind9
echo "============================================"
read -p "Press Enter to continue..."
