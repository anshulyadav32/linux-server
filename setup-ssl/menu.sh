#!/bin/bash
# SSL Management Menu

while true; do
    clear
    echo "======================================"
    echo "       SSL Management"
    echo "======================================"
    echo "1) Install SSL (Certbot)"
    echo "2) SSL Operations"
    echo "3) Maintain SSL"
    echo "4) Update SSL"
    echo "5) Back to Main Menu"
    echo "======================================"
    read -p "Choose an option [1-5]: " choice

    case $choice in
        1) bash setup-ssl/install.sh ;;
        2) 
            while true; do
                clear
                echo "======================================"
                echo "        SSL Operations"
                echo "======================================"
                echo "1) Issue SSL Certificate"
                echo "2) List Certificates"
                echo "3) Renew Certificates"
                echo "4) Revoke Certificate"
                echo "5) Back"
                echo "======================================"
                read -p "Choose: " ssl_choice
                case $ssl_choice in
                    1) 
                        read -p "Domain: " domain
                        read -p "Web server (apache/nginx): " server
                        certbot --$server -d $domain
                        ;;
                    2) certbot certificates ;;
                    3) certbot renew ;;
                    4) 
                        read -p "Domain to revoke: " domain
                        certbot revoke --cert-name $domain
                        ;;
                    5) break ;;
                esac
                sleep 2
            done
            ;;
        3) bash setup-ssl/maintain.sh ;;
        4) bash setup-ssl/update.sh ;;
        5) break ;;
    esac
done
