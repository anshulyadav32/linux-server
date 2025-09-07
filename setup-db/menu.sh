#!/bin/bash
# Database Management Menu

while true; do
    clear
    echo "======================================"
    echo "     Database Management"
    echo "======================================"
    echo "1) Install Database Systems"
    echo "2) Database Operations"
    echo "3) Maintain Databases"
    echo "4) Update Database Systems"
    echo "5) Back to Main Menu"
    echo "======================================"
    read -p "Choose an option [1-5]: " choice

    case $choice in
        1) 
            bash setup-db/install.sh 
            ;;
        2) 
            # Database Operations Submenu
            while true; do
                clear
                echo "======================================"
                echo "      Database Operations"
                echo "======================================"
                echo "1) MySQL Operations"
                echo "2) PostgreSQL Operations"
                echo "3) Redis Operations"
                echo "4) Database Backup"
                echo "5) Database Restore"
                echo "6) Back"
                echo "======================================"
                read -p "Choose an option [1-6]: " db_choice
                
                case $db_choice in
                    1) 
                        echo "MySQL Console Access:"
                        echo "mysql -u admin -p"
                        echo ""
                        echo "Quick Commands:"
                        echo "- Show databases: SHOW DATABASES;"
                        echo "- Create database: CREATE DATABASE dbname;"
                        echo "- Drop database: DROP DATABASE dbname;"
                        read -p "Press Enter to continue..."
                        ;;
                    2)
                        echo "PostgreSQL Console Access:"
                        echo "sudo -u postgres psql"
                        echo ""
                        echo "Quick Commands:"
                        echo "- List databases: \\l"
                        echo "- Create database: CREATE DATABASE dbname;"
                        echo "- Drop database: DROP DATABASE dbname;"
                        read -p "Press Enter to continue..."
                        ;;
                    3)
                        echo "Redis Console Access:"
                        echo "redis-cli"
                        echo ""
                        echo "Quick Commands:"
                        echo "- Test connection: PING"
                        echo "- Get all keys: KEYS *"
                        echo "- Flush all data: FLUSHALL"
                        read -p "Press Enter to continue..."
                        ;;
                    4)
                        read -p "Enter database name: " dbname
                        read -p "Choose type (mysql/postgres): " dbtype
                        timestamp=$(date +%Y%m%d_%H%M%S)
                        
                        if [[ "$dbtype" == "mysql" ]]; then
                            mysqldump -u admin -p $dbname > /backup/${dbname}_${timestamp}.sql
                            echo "✅ MySQL backup created: /backup/${dbname}_${timestamp}.sql"
                        elif [[ "$dbtype" == "postgres" ]]; then
                            sudo -u postgres pg_dump $dbname > /backup/${dbname}_${timestamp}.sql
                            echo "✅ PostgreSQL backup created: /backup/${dbname}_${timestamp}.sql"
                        fi
                        sleep 3
                        ;;
                    5)
                        echo "Available backups:"
                        ls -la /backup/*.sql 2>/dev/null || echo "No backups found"
                        read -p "Enter backup file path: " backup_file
                        read -p "Choose type (mysql/postgres): " dbtype
                        
                        if [[ "$dbtype" == "mysql" ]]; then
                            mysql -u admin -p < $backup_file
                            echo "✅ MySQL database restored"
                        elif [[ "$dbtype" == "postgres" ]]; then
                            sudo -u postgres psql < $backup_file
                            echo "✅ PostgreSQL database restored"
                        fi
                        sleep 3
                        ;;
                    6) 
                        break 
                        ;;
                    *) 
                        echo "Invalid choice!" 
                        sleep 2
                        ;;
                esac
            done
            ;;
        3) 
            bash setup-db/maintain.sh 
            ;;
        4) 
            bash setup-db/update.sh 
            ;;
        5) 
            break 
            ;;
        *) 
            echo "Invalid choice!" 
            sleep 2
            ;;
    esac
done
