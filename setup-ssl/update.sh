#!/bin/bash
# SSL Update Script

echo "Updating SSL (Certbot)..."
apt update -y
apt upgrade -y certbot python3-certbot-apache python3-certbot-nginx
echo "✅ SSL system updated!"
read -p "Press Enter to continue..."
