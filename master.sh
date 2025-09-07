#!/bin/bash
# Master Server Management CLI

show_header() {
    clear
    echo "=============================="
    echo "   MASTER SERVER MANAGEMENT"
    echo "=============================="
    echo "1) Web-server Management"
    echo "2) Mail System Management"
    echo "3) DNS Management"
    echo "4) Databases Management"
    echo "5) Firewall Management"
    echo "6) Domain SSL Management"
    echo "7) System Management"
    echo "8) Backup & Restore"
    echo "9) Exit"
    echo "=============================="
}

while true; do
    show_header
    read -p "Choose an option [1-9]: " choice

    case $choice in
        1) bash setup-web/menu.sh ;;
        2) bash setup-mail/menu.sh ;;
        3) bash setup-dns/menu.sh ;;
        4) bash setup-db/menu.sh ;;
        5) bash setup-firewall/menu.sh ;;
        6) bash setup-ssl/menu.sh ;;
        7) bash setup-system/menu.sh ;;
        8) bash setup-backup/menu.sh ;;
        9) 
            echo "Exiting Master Server Management..."
            exit 0 
            ;;
        *) 
            echo "Invalid choice! Please enter 1-9."
            sleep 2
            ;;
    esac
done
