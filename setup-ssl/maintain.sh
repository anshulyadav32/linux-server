#!/bin/bash
# SSL Maintenance Script

while true; do
    clear
    echo "======================================"
    echo "        SSL Maintenance"
    echo "======================================"
    echo "1) Test Certificate Renewal"
    echo "2) Check Certificate Status"
    echo "3) View Certificate Details"
    echo "4) Force Renewal"
    echo "5) Back"
    echo "======================================"
    read -p "Choose: " choice
    case $choice in
        1) certbot renew --dry-run ;;
        2) certbot certificates ;;
        3) 
            read -p "Domain: " domain
            openssl x509 -in /etc/letsencrypt/live/$domain/cert.pem -text -noout
            ;;
        4) certbot renew --force-renewal ;;
        5) break ;;
    esac
    sleep 2
done
