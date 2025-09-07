#!/bin/bash
# Database System Management Menu
# Purpose: Interactive CLI for comprehensive database system management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Source functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

# Function to display main header
show_header() {
    clear
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}         DATABASE SYSTEM MANAGEMENT            ${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
}

# Function to display main menu
show_main_menu() {
    show_header
    echo -e "${GREEN}Installation & Setup:${NC}"
    echo -e "  ${CYAN}1)${NC} Install database system"
    echo -e "  ${CYAN}2)${NC} Update database system"
    echo
    echo -e "${GREEN}Service Management:${NC}"
    echo -e "  ${CYAN}3)${NC} Check service status"
    echo -e "  ${CYAN}4)${NC} Start/Stop services"
    echo -e "  ${CYAN}5)${NC} Restart all services"
    echo
    echo -e "${GREEN}Database Operations:${NC}"
    echo -e "  ${CYAN}6)${NC} Create database"
    echo -e "  ${CYAN}7)${NC} Manage users"
    echo -e "  ${CYAN}8)${NC} Run SQL queries"
    echo -e "  ${CYAN}9)${NC} Database statistics"
    echo
    echo -e "${GREEN}Backup & Recovery:${NC}"
    echo -e "  ${CYAN}10)${NC} Backup databases"
    echo -e "  ${CYAN}11)${NC} Restore from backup"
    echo -e "  ${CYAN}12)${NC} Manage backups"
    echo
    echo -e "${GREEN}Monitoring & Maintenance:${NC}"
    echo -e "  ${CYAN}13)${NC} View logs"
    echo -e "  ${CYAN}14)${NC} Health checks"
    echo -e "  ${CYAN}15)${NC} Database maintenance"
    echo -e "  ${CYAN}16)${NC} Performance monitoring"
    echo
    echo -e "${GREEN}Security & Configuration:${NC}"
    echo -e "  ${CYAN}17)${NC} Security settings"
    echo -e "  ${CYAN}18)${NC} Connection settings"
    echo -e "  ${CYAN}19)${NC} Firewall configuration"
    echo
    echo -e "${YELLOW}0)${NC} Exit"
    echo
}

# Function to show service control menu
show_service_menu() {
    clear
    echo -e "${BLUE}Database Service Management${NC}"
    echo -e "${GREEN}1)${NC} Start all database services"
    echo -e "${GREEN}2)${NC} Stop all database services"
    echo -e "${GREEN}3)${NC} Start PostgreSQL"
    echo -e "${GREEN}4)${NC} Stop PostgreSQL"
    echo -e "${GREEN}5)${NC} Start MariaDB"
    echo -e "${GREEN}6)${NC} Stop MariaDB"
    echo -e "${GREEN}7)${NC} Start MongoDB"
    echo -e "${GREEN}8)${NC} Stop MongoDB"
    echo -e "${YELLOW}0)${NC} Back to main menu"
    echo
}

# Function to manage database services
manage_services() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required for service management${NC}"
        sleep 2
        return
    fi

    while true; do
        show_service_menu
        read -p "Select an option [0-8]: " service_choice
        
        case $service_choice in
            1)
                echo -e "${YELLOW}Starting all database services...${NC}"
                if systemctl list-units --type=service | grep -q postgresql; then
                    start_database_service "postgresql"
                    echo -e "${GREEN}✓ PostgreSQL started${NC}"
                fi
                if systemctl list-units --type=service | grep -q mariadb; then
                    start_database_service "mariadb"
                    echo -e "${GREEN}✓ MariaDB started${NC}"
                fi
                if systemctl list-units --type=service | grep -q mongod; then
                    start_database_service "mongodb"
                    echo -e "${GREEN}✓ MongoDB started${NC}"
                fi
                sleep 2
                ;;
            2)
                echo -e "${YELLOW}Stopping all database services...${NC}"
                if systemctl list-units --type=service | grep -q postgresql; then
                    systemctl stop postgresql
                    echo -e "${YELLOW}✓ PostgreSQL stopped${NC}"
                fi
                if systemctl list-units --type=service | grep -q mariadb; then
                    systemctl stop mariadb
                    echo -e "${YELLOW}✓ MariaDB stopped${NC}"
                fi
                if systemctl list-units --type=service | grep -q mongod; then
                    systemctl stop mongod
                    echo -e "${YELLOW}✓ MongoDB stopped${NC}"
                fi
                sleep 2
                ;;
            3)
                echo -e "${YELLOW}Starting PostgreSQL...${NC}"
                start_database_service "postgresql"
                echo -e "${GREEN}✓ PostgreSQL started${NC}"
                sleep 2
                ;;
            4)
                echo -e "${YELLOW}Stopping PostgreSQL...${NC}"
                systemctl stop postgresql
                echo -e "${YELLOW}✓ PostgreSQL stopped${NC}"
                sleep 2
                ;;
            5)
                echo -e "${YELLOW}Starting MariaDB...${NC}"
                start_database_service "mariadb"
                echo -e "${GREEN}✓ MariaDB started${NC}"
                sleep 2
                ;;
            6)
                echo -e "${YELLOW}Stopping MariaDB...${NC}"
                systemctl stop mariadb
                echo -e "${YELLOW}✓ MariaDB stopped${NC}"
                sleep 2
                ;;
            7)
                echo -e "${YELLOW}Starting MongoDB...${NC}"
                start_database_service "mongodb"
                echo -e "${GREEN}✓ MongoDB started${NC}"
                sleep 2
                ;;
            8)
                echo -e "${YELLOW}Stopping MongoDB...${NC}"
                systemctl stop mongod
                echo -e "${YELLOW}✓ MongoDB stopped${NC}"
                sleep 2
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Function to create database
create_database() {
    clear
    echo -e "${BLUE}Create New Database${NC}"
    echo
    
    echo -e "${CYAN}Available database systems:${NC}"
    echo -e "1) PostgreSQL"
    echo -e "2) MariaDB"
    echo -e "3) MongoDB"
    echo
    
    read -p "Select database system [1-3]: " db_system
    read -p "Enter database name: " db_name
    
    if [[ -z "$db_name" ]]; then
        echo -e "${RED}Database name cannot be empty${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    case $db_system in
        1)
            if systemctl is-active --quiet postgresql 2>/dev/null; then
                echo -e "${YELLOW}Creating PostgreSQL database: $db_name${NC}"
                sudo -u postgres createdb "$db_name" && echo -e "${GREEN}✓ Database created successfully${NC}" || echo -e "${RED}✗ Failed to create database${NC}"
            else
                echo -e "${RED}PostgreSQL is not running${NC}"
            fi
            ;;
        2)
            if systemctl is-active --quiet mariadb 2>/dev/null; then
                echo -e "${YELLOW}Creating MariaDB database: $db_name${NC}"
                mysql -u root -e "CREATE DATABASE $db_name;" && echo -e "${GREEN}✓ Database created successfully${NC}" || echo -e "${RED}✗ Failed to create database${NC}"
            else
                echo -e "${RED}MariaDB is not running${NC}"
            fi
            ;;
        3)
            if systemctl is-active --quiet mongod 2>/dev/null; then
                echo -e "${YELLOW}Creating MongoDB database: $db_name${NC}"
                mongo "$db_name" --eval "db.createCollection('init')" && echo -e "${GREEN}✓ Database created successfully${NC}" || echo -e "${RED}✗ Failed to create database${NC}"
            else
                echo -e "${RED}MongoDB is not running${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to manage users
manage_users() {
    clear
    echo -e "${BLUE}Database User Management${NC}"
    echo
    
    echo -e "${GREEN}Options:${NC}"
    echo -e "1) Create user"
    echo -e "2) Delete user"
    echo -e "3) Change password"
    echo -e "4) List users"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select option [0-4]: " user_choice
    
    case $user_choice in
        1)
            read -p "Enter username: " username
            read -p "Enter database system (postgresql/mariadb/mongodb): " db_sys
            read -s -p "Enter password: " password
            echo
            
            case $db_sys in
                postgresql)
                    sudo -u postgres createuser "$username" && echo -e "${GREEN}✓ User created${NC}" || echo -e "${RED}✗ Failed to create user${NC}"
                    ;;
                mariadb)
                    mysql -u root -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';" && echo -e "${GREEN}✓ User created${NC}" || echo -e "${RED}✗ Failed to create user${NC}"
                    ;;
                mongodb)
                    mongo admin --eval "db.createUser({user:'$username', pwd:'$password', roles:['readWrite']})" && echo -e "${GREEN}✓ User created${NC}" || echo -e "${RED}✗ Failed to create user${NC}"
                    ;;
                *)
                    echo -e "${RED}Invalid database system${NC}"
                    ;;
            esac
            ;;
        2)
            read -p "Enter username to delete: " del_username
            read -p "Enter database system (postgresql/mariadb/mongodb): " db_sys
            
            case $db_sys in
                postgresql)
                    sudo -u postgres dropuser "$del_username" && echo -e "${GREEN}✓ User deleted${NC}" || echo -e "${RED}✗ Failed to delete user${NC}"
                    ;;
                mariadb)
                    mysql -u root -e "DROP USER '$del_username'@'localhost';" && echo -e "${GREEN}✓ User deleted${NC}" || echo -e "${RED}✗ Failed to delete user${NC}"
                    ;;
                mongodb)
                    mongo admin --eval "db.dropUser('$del_username')" && echo -e "${GREEN}✓ User deleted${NC}" || echo -e "${RED}✗ Failed to delete user${NC}"
                    ;;
                *)
                    echo -e "${RED}Invalid database system${NC}"
                    ;;
            esac
            ;;
        3)
            echo -e "${YELLOW}Password change functionality${NC}"
            echo "Use appropriate database tools for security"
            ;;
        4)
            echo -e "${YELLOW}Listing database users:${NC}"
            if systemctl is-active --quiet postgresql 2>/dev/null; then
                echo -e "${BLUE}PostgreSQL users:${NC}"
                sudo -u postgres psql -c "\du"
            fi
            if systemctl is-active --quiet mariadb 2>/dev/null; then
                echo -e "${BLUE}MariaDB users:${NC}"
                mysql -u root -e "SELECT User, Host FROM mysql.user;"
            fi
            if systemctl is-active --quiet mongod 2>/dev/null; then
                echo -e "${BLUE}MongoDB users:${NC}"
                mongo admin --eval "db.getUsers()"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to run SQL queries
run_queries() {
    clear
    echo -e "${BLUE}Database Query Interface${NC}"
    echo
    
    echo -e "${CYAN}Available database systems:${NC}"
    echo -e "1) PostgreSQL"
    echo -e "2) MariaDB"
    echo -e "3) MongoDB"
    echo
    
    read -p "Select database system [1-3]: " query_system
    
    case $query_system in
        1)
            if systemctl is-active --quiet postgresql 2>/dev/null; then
                echo -e "${YELLOW}Entering PostgreSQL interactive mode...${NC}"
                sudo -u postgres psql
            else
                echo -e "${RED}PostgreSQL is not running${NC}"
            fi
            ;;
        2)
            if systemctl is-active --quiet mariadb 2>/dev/null; then
                echo -e "${YELLOW}Entering MariaDB interactive mode...${NC}"
                mysql -u root -p
            else
                echo -e "${RED}MariaDB is not running${NC}"
            fi
            ;;
        3)
            if systemctl is-active --quiet mongod 2>/dev/null; then
                echo -e "${YELLOW}Entering MongoDB interactive mode...${NC}"
                mongo
            else
                echo -e "${RED}MongoDB is not running${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Function to show database statistics
show_statistics() {
    clear
    echo -e "${BLUE}Database Statistics${NC}"
    echo
    
    # PostgreSQL stats
    if systemctl is-active --quiet postgresql 2>/dev/null; then
        echo -e "${CYAN}PostgreSQL Statistics:${NC}"
        sudo -u postgres psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size FROM pg_database ORDER BY pg_database_size(datname) DESC;"
        echo
    fi
    
    # MariaDB stats
    if systemctl is-active --quiet mariadb 2>/dev/null; then
        echo -e "${CYAN}MariaDB Statistics:${NC}"
        mysql -u root -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables GROUP BY table_schema ORDER BY SUM(data_length + index_length) DESC;"
        echo
    fi
    
    # MongoDB stats
    if systemctl is-active --quiet mongod 2>/dev/null; then
        echo -e "${CYAN}MongoDB Statistics:${NC}"
        mongo --eval "db.adminCommand('listDatabases')"
        echo
    fi
    
    read -p "Press Enter to continue..."
}

# Function for security settings
configure_security() {
    clear
    echo -e "${BLUE}Database Security Configuration${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required for security configuration${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${GREEN}Security options:${NC}"
    echo -e "1) Run MariaDB security script"
    echo -e "2) Configure PostgreSQL authentication"
    echo -e "3) Enable MongoDB authentication"
    echo -e "4) Configure firewall rules"
    echo -e "0) Back to main menu"
    echo
    
    read -p "Select option [0-4]: " security_choice
    
    case $security_choice in
        1)
            if systemctl is-active --quiet mariadb 2>/dev/null; then
                mysql_secure_installation
            else
                echo -e "${RED}MariaDB is not running${NC}"
            fi
            ;;
        2)
            echo -e "${YELLOW}PostgreSQL authentication configuration${NC}"
            echo "Edit /etc/postgresql/*/main/pg_hba.conf for authentication settings"
            ;;
        3)
            echo -e "${YELLOW}MongoDB authentication configuration${NC}"
            echo "Enable security.authorization in /etc/mongod.conf"
            ;;
        4)
            echo -e "${YELLOW}Configuring database firewall rules...${NC}"
            if command -v ufw >/dev/null 2>&1; then
                ufw status
                echo "Database ports: 5432 (PostgreSQL), 3306 (MariaDB), 27017 (MongoDB)"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Main menu loop
while true; do
    show_main_menu
    read -p "Select an option [0-19]: " choice
    
    case $choice in
        1)
            echo -e "${YELLOW}Starting database system installation...${NC}"
            bash "$SCRIPT_DIR/install.sh"
            read -p "Press Enter to continue..."
            ;;
        2)
            echo -e "${YELLOW}Starting database system update...${NC}"
            bash "$SCRIPT_DIR/update.sh"
            read -p "Press Enter to continue..."
            ;;
        3)
            clear
            echo -e "${BLUE}Database Service Status${NC}"
            echo
            get_database_status "postgresql"
            get_database_status "mariadb"
            get_database_status "mongodb"
            read -p "Press Enter to continue..."
            ;;
        4)
            manage_services
            ;;
        5)
            if [[ $EUID -ne 0 ]]; then
                echo -e "${RED}Root privileges required${NC}"
                sleep 2
            else
                echo -e "${YELLOW}Restarting all database services...${NC}"
                if systemctl list-units --type=service | grep -q postgresql; then
                    restart_database_service "postgresql"
                fi
                if systemctl list-units --type=service | grep -q mariadb; then
                    restart_database_service "mariadb"
                fi
                if systemctl list-units --type=service | grep -q mongod; then
                    restart_database_service "mongodb"
                fi
                echo -e "${GREEN}Services restarted${NC}"
                sleep 2
            fi
            ;;
        6)
            create_database
            ;;
        7)
            manage_users
            ;;
        8)
            run_queries
            ;;
        9)
            show_statistics
            ;;
        10)
            clear
            echo -e "${BLUE}Database Backup${NC}"
            if [[ $EUID -ne 0 ]]; then
                echo -e "${RED}Root privileges required${NC}"
            else
                read -p "Enter database type (postgresql/mariadb/mongodb): " backup_type
                read -p "Enter database name (or 'all' for all databases): " backup_db
                backup_database "$backup_type" "$backup_db"
            fi
            read -p "Press Enter to continue..."
            ;;
        11)
            clear
            echo -e "${BLUE}Database Restore${NC}"
            if [[ $EUID -ne 0 ]]; then
                echo -e "${RED}Root privileges required${NC}"
            else
                echo "Available backups in /var/backups/databases:"
                ls -la /var/backups/databases/ 2>/dev/null || echo "No backups found"
                read -p "Enter backup file path: " restore_file
                read -p "Enter database type (postgresql/mariadb/mongodb): " restore_type
                read -p "Enter target database name: " restore_db
                restore_database "$restore_type" "$restore_file" "$restore_db"
            fi
            read -p "Press Enter to continue..."
            ;;
        12)
            clear
            echo -e "${BLUE}Backup Management${NC}"
            echo "Backup directory: /var/backups/databases"
            ls -la /var/backups/databases/ 2>/dev/null || echo "No backups found"
            read -p "Press Enter to continue..."
            ;;
        13)
            clear
            echo -e "${BLUE}Database Logs${NC}"
            echo -e "${GREEN}1)${NC} PostgreSQL logs"
            echo -e "${GREEN}2)${NC} MariaDB logs"
            echo -e "${GREEN}3)${NC} MongoDB logs"
            echo -e "${GREEN}4)${NC} All logs"
            read -p "Select option [1-4]: " log_choice
            case $log_choice in
                1) show_database_logs "postgresql" ;;
                2) show_database_logs "mariadb" ;;
                3) show_database_logs "mongodb" ;;
                4) 
                    show_database_logs "postgresql" 20
                    show_database_logs "mariadb" 20
                    show_database_logs "mongodb" 20
                    ;;
            esac
            read -p "Press Enter to continue..."
            ;;
        14)
            clear
            echo -e "${BLUE}Database Health Checks${NC}"
            test_postgresql_connection
            test_mariadb_connection
            test_mongodb_connection
            read -p "Press Enter to continue..."
            ;;
        15)
            bash "$SCRIPT_DIR/maintain.sh"
            ;;
        16)
            clear
            echo -e "${BLUE}Performance Monitoring${NC}"
            echo "System load:"
            uptime
            echo
            echo "Memory usage:"
            free -h
            echo
            echo "Database processes:"
            ps aux | grep -E 'postgres|mysql|mongo' | grep -v grep
            read -p "Press Enter to continue..."
            ;;
        17)
            configure_security
            ;;
        18)
            clear
            echo -e "${BLUE}Connection Settings${NC}"
            echo -e "${CYAN}Database connection information:${NC}"
            echo "PostgreSQL: localhost:5432"
            echo "MariaDB: localhost:3306"
            echo "MongoDB: localhost:27017"
            echo
            echo "Check respective configuration files for detailed settings"
            read -p "Press Enter to continue..."
            ;;
        19)
            clear
            echo -e "${BLUE}Firewall Configuration${NC}"
            if command -v ufw >/dev/null 2>&1; then
                ufw status
            elif command -v firewall-cmd >/dev/null 2>&1; then
                firewall-cmd --list-all
            else
                echo "No supported firewall found"
            fi
            read -p "Press Enter to continue..."
            ;;
        0)
            echo -e "${YELLOW}Exiting database system management...${NC}"
            break
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 2
            ;;
    esac
done

echo -e "${GREEN}Thank you for using Database System Management!${NC}"
