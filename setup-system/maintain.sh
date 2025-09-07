#!/bin/bash
# System Maintenance Script

while true; do
    clear
    echo "======================================"
    echo "       System Maintenance"
    echo "======================================"
    echo "1) Clean System Logs"
    echo "2) Update Package Lists"
    echo "3) Clean Package Cache"
    echo "4) Check Disk Space"
    echo "5) System Reboot"
    echo "6) Back"
    echo "======================================"
    read -p "Choose: " choice
    case $choice in
        1) journalctl --vacuum-time=7d; echo "✅ Logs cleaned" ;;
        2) apt update; echo "✅ Package lists updated" ;;
        3) apt autoremove -y; apt autoclean; echo "✅ Package cache cleaned" ;;
        4) df -h; du -sh /var/log ;;
        5) 
            read -p "Reboot system? (y/N): " confirm
            [[ $confirm == "y" ]] && reboot
            ;;
        6) break ;;
    esac
    sleep 2
done
