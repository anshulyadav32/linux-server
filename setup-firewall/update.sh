#!/bin/bash
# Firewall Update Script

echo "Updating firewall systems..."
apt update -y
apt upgrade -y ufw fail2ban
systemctl restart fail2ban
echo "✅ Firewall systems updated!"
read -p "Press Enter to continue..."
