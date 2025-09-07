#!/bin/bash
# Firewall Installation Script

echo "============================================"
echo "        Installing Firewall (UFW)"
echo "============================================"

apt update -y
apt install -y ufw fail2ban

# Configure UFW with secure defaults
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https

# Enable UFW
echo "y" | ufw enable

# Configure Fail2Ban
systemctl enable fail2ban
systemctl start fail2ban

echo "✅ Firewall installed and configured!"
echo "✅ UFW: Enabled with secure defaults"
echo "✅ Fail2Ban: Running for intrusion prevention"
read -p "Press Enter to continue..."
