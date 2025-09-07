#!/bin/bash
# Backup Maintenance Script

while true; do
    clear
    echo "======================================"
    echo "      Backup Maintenance"
    echo "======================================"
    echo "1) Check Backup Space"
    echo "2) Clean Old Backups"
    echo "3) Test Backup Script"
    echo "4) View Backup Schedule"
    echo "5) Back"
    echo "======================================"
    read -p "Choose: " choice
    case $choice in
        1) df -h /backup ;;
        2) find /backup -type f -mtime +30 -delete; echo "✅ Old backups cleaned" ;;
        3) /usr/local/bin/backup.sh ;;
        4) crontab -l | grep backup ;;
        5) break ;;
    esac
    sleep 2
done
