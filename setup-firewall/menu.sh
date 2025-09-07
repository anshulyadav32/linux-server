#!/bin/bash
# Firewall Management Menu

while true; do
    clear
    echo "======================================"
    echo "      Firewall Management"
    echo "======================================"
    echo "1) Install Firewall"
    echo "2) Firewall Rules"
    echo "3) Maintain Firewall"
    echo "4) Update Firewall"
    echo "5) Back to Main Menu"
    echo "======================================"
    read -p "Choose an option [1-5]: " choice

    case $choice in
        1) bash setup-firewall/install.sh ;;
        2) 
            while true; do
                clear
                echo "======================================"
                echo "       Firewall Rules"
                echo "======================================"
                echo "1) Allow Port"
                echo "2) Deny Port"
                echo "3) List Rules"
                echo "4) Reset Firewall"
                echo "5) Back"
                echo "======================================"
                read -p "Choose: " rule_choice
                case $rule_choice in
                    1) read -p "Port to allow: " port; ufw allow $port; echo "✅ Port $port allowed" ;;
                    2) read -p "Port to deny: " port; ufw deny $port; echo "✅ Port $port denied" ;;
                    3) ufw status verbose ;;
                    4) ufw --force reset; echo "✅ Firewall reset" ;;
                    5) break ;;
                esac
                sleep 2
            done
            ;;
        3) bash setup-firewall/maintain.sh ;;
        4) bash setup-firewall/update.sh ;;
        5) break ;;
    esac
done
