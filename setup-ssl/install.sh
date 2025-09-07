#!/bin/bash
# SSL Installation Script

echo "============================================"
echo "         Installing SSL (Certbot)"
echo "============================================"

apt update -y
apt install -y certbot python3-certbot-apache python3-certbot-nginx

echo "✅ Certbot installed successfully!"
echo "✅ Apache plugin: Available"
echo "✅ Nginx plugin: Available"
echo ""
echo "Usage examples:"
echo "  certbot --apache -d domain.com"
echo "  certbot --nginx -d domain.com"
read -p "Press Enter to continue..."
