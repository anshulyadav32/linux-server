#!/bin/bash
# Backup Update Script

echo "Updating backup system..."
apt update -y
apt upgrade -y rsync borgbackup
echo "✅ Backup system updated!"
read -p "Press Enter to continue..."
