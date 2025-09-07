#!/bin/bash
# Backup Management Menu

while true; do
    clear
    echo "======================================"
    echo "       Backup & Restore"
    echo "======================================"
    echo "1) Install Backup System"
    echo "2) Backup Operations"
    echo "3) Maintain Backup System"
    echo "4) Update Backup System"
    echo "5) Back to Main Menu"
    echo "======================================"
    read -p "Choose an option [1-5]: " choice

    case $choice in
        1) bash setup-backup/install.sh ;;
        2) 
            while true; do
                clear
                echo "======================================"
                echo "      Backup Operations"
                echo "======================================"
                echo "1) Run Manual Backup"
                echo "2) List Backups"
                echo "3) Restore from Backup"
                echo "4) Schedule Backup"
                echo "5) Back"
                echo "======================================"
                read -p "Choose: " backup_choice
                case $backup_choice in
                    1) /usr/local/bin/backup.sh; echo "✅ Backup completed" ;;
                    2) ls -la /backup/daily/ ;;
                    3) 
                        echo "Available backups:"
                        ls /backup/daily/
                        read -p "Backup file: " backup_file
                        tar -xzf /backup/daily/$backup_file -C /
                        ;;
                    4) crontab -e ;;
                    5) break ;;
                esac
                sleep 2
            done
            ;;
        3) bash setup-backup/maintain.sh ;;
        4) bash setup-backup/update.sh ;;
        5) break ;;
    esac
done
