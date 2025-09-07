#!/bin/bash
# Database Maintenance Script

while true; do
    clear
    echo "======================================"
    echo "      Database Maintenance"
    echo "======================================"
    echo "1) Restart MySQL"
    echo "2) Restart PostgreSQL"
    echo "3) Restart Redis"
    echo "4) Check Database Status"
    echo "5) Back"
    echo "======================================"
    read -p "Choose: " choice
    case $choice in
        1) systemctl restart mysql; echo "✅ MySQL restarted" ;;
        2) systemctl restart postgresql; echo "✅ PostgreSQL restarted" ;;
        3) systemctl restart redis-server; echo "✅ Redis restarted" ;;
        4) 
            systemctl status mysql --no-pager
            systemctl status postgresql --no-pager
            systemctl status redis-server --no-pager
            ;;
        5) break ;;
    esac
    sleep 2
done
