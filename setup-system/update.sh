#!/bin/bash
# System Update Script

echo "Updating system packages..."
apt update -y
apt upgrade -y
apt dist-upgrade -y
apt autoremove -y
echo "✅ System updated successfully!"
read -p "Press Enter to continue..."
