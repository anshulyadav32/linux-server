#!/bin/bash
# System Management Menu

while true; do
    clear
    echo "======================================"
    echo "       System Management"
    echo "======================================"
    echo "1) Install System Tools"
    echo "2) System Operations"
    echo "3) Maintain System"
    echo "4) Update System"
    echo "5) Back to Main Menu"
    echo "======================================"
    read -p "Choose an option [1-5]: " choice

    case $choice in
        1) bash setup-system/install.sh ;;
        2) 
            while true; do
                clear
                echo "======================================"
                echo "      System Operations"
                echo "======================================"
                echo "1) System Monitor (htop)"
                echo "2) Disk Usage (ncdu)"
                echo "3) Add User"
                echo "4) System Info"
                echo "5) Back"
                echo "======================================"
                read -p "Choose: " sys_choice
                case $sys_choice in
                    1) htop ;;
                    2) ncdu / ;;
                    3) 
                        read -p "Username: " username
                        useradd -m -s /bin/bash $username
                        passwd $username
                        ;;
                    4) 
                        echo "System Information:"
                        uname -a
                        df -h
                        free -h
                        uptime
                        ;;
                    5) break ;;
                esac
                sleep 2
            done
            ;;
        3) bash setup-system/maintain.sh ;;
        4) bash setup-system/update.sh ;;
        5) break ;;
    esac
done
