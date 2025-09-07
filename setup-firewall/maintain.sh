#!/bin/bash
# Firewall Maintenance Script

while true; do
    clear
    echo "======================================"
    echo "      Firewall Maintenance"
    echo "======================================"
    echo "1) Restart UFW"
    echo "2) Restart Fail2Ban"
    echo "3) Check Firewall Status"
    echo "4) View Blocked IPs"
    echo "5) Back"
    echo "======================================"
    read -p "Choose: " choice
    case $choice in
        1) ufw --force disable; ufw --force enable; echo "✅ UFW restarted" ;;
        2) systemctl restart fail2ban; echo "✅ Fail2Ban restarted" ;;
        3) ufw status verbose; fail2ban-client status ;;
        4) fail2ban-client status sshd ;;
        5) break ;;
    esac
    sleep 2
done
