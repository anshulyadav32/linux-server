#!/bin/bash
# System Installation Script

echo "============================================"
echo "       Installing System Tools"
echo "============================================"

apt update -y
apt install -y htop ncdu tree curl wget git unzip zip nano vim fail2ban logwatch

# Create system user
useradd -m -s /bin/bash sysadmin
usermod -aG sudo sysadmin

# Install monitoring tools
apt install -y nmon iotop

echo "✅ System tools installed successfully!"
echo "✅ Monitoring: htop, nmon, iotop"
echo "✅ Security: fail2ban, logwatch"
echo "✅ User created: sysadmin"
read -p "Press Enter to continue..."
