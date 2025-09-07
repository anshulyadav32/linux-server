#!/bin/bash
# Database System Maintenance
# Purpose: Daily operational checks and maintenance for database systems

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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}      DATABASE SYSTEM MAINTENANCE      ${NC}"
echo -e "${BLUE}========================================${NC}"

# Function to show maintenance menu
show_maintenance_menu() {
    clear
    echo -e "${BLUE}Database System Maintenance Options:${NC}"
    echo -e "${GREEN}1)${NC} Check all database services"
    echo -e "${GREEN}2)${NC} Run database health checks"
    echo -e "${GREEN}3)${NC} View database logs"
    echo -e "${GREEN}4)${NC} Backup databases"
    echo -e "${GREEN}5)${NC} Restore from backup"
    echo -e "${GREEN}6)${NC} Optimize databases"
    echo -e "${GREEN}7)${NC} Monitor disk usage"
    echo -e "${GREEN}8)${NC} Restart database services"
    echo -e "${GREEN}9)${NC} Full system check"
    echo -e "${YELLOW}0)${NC} Return to main menu"
    echo
}

# Function to check all database services
check_all_services() {
    echo -e "${YELLOW}Checking database service status...${NC}"
    echo
    
    # Check PostgreSQL
    if systemctl list-units --type=service | grep -q postgresql; then
        echo -e "${BLUE}PostgreSQL Status:${NC}"
        check_database_service "postgresql"
        echo
    fi
    
    # Check MariaDB
    if systemctl list-units --type=service | grep -q mariadb; then
        echo -e "${BLUE}MariaDB Status:${NC}"
        check_database_service "mariadb"
        echo
    fi
    
    # Check MongoDB
    if systemctl list-units --type=service | grep -q mongod; then
        echo -e "${BLUE}MongoDB Status:${NC}"
        check_database_service "mongodb"
        echo
    fi
    
    # Check ports
    echo -e "${BLUE}Database Ports:${NC}"
    if command -v netstat >/dev/null 2>&1; then
        netstat -tlnp | grep -E ':5432|:3306|:27017' || echo "No database ports found listening"
    elif command -v ss >/dev/null 2>&1; then
        ss -tlnp | grep -E ':5432|:3306|:27017' || echo "No database ports found listening"
    fi
    echo
    
    read -p "Press Enter to continue..."
}

# Function to run health checks
run_health_checks() {
    echo -e "${YELLOW}Running database health checks...${NC}"
    echo
    
    # PostgreSQL health check
    if systemctl is-active --quiet postgresql 2>/dev/null; then
        echo -e "${BLUE}PostgreSQL Health Check:${NC}"
        if test_postgresql_connection; then
            echo -e "${GREEN}✓ PostgreSQL is healthy${NC}"
        else
            echo -e "${RED}✗ PostgreSQL health check failed${NC}"
        fi
        echo
    fi
    
    # MariaDB health check
    if systemctl is-active --quiet mariadb 2>/dev/null; then
        echo -e "${BLUE}MariaDB Health Check:${NC}"
        if test_mariadb_connection; then
            echo -e "${GREEN}✓ MariaDB is healthy${NC}"
        else
            echo -e "${RED}✗ MariaDB health check failed${NC}"
        fi
        echo
    fi
    
    # MongoDB health check
    if systemctl is-active --quiet mongod 2>/dev/null; then
        echo -e "${BLUE}MongoDB Health Check:${NC}"
        if test_mongodb_connection; then
            echo -e "${GREEN}✓ MongoDB is healthy${NC}"
        else
            echo -e "${RED}✗ MongoDB health check failed${NC}"
        fi
        echo
    fi
    
    read -p "Press Enter to continue..."
}

# Function to view logs
view_logs() {
    clear
    echo -e "${BLUE}Database Logs${NC}"
    echo -e "${CYAN}1)${NC} PostgreSQL logs"
    echo -e "${CYAN}2)${NC} MariaDB logs"
    echo -e "${CYAN}3)${NC} MongoDB logs"
    echo -e "${CYAN}4)${NC} All database logs"
    echo -e "${CYAN}5)${NC} Back to maintenance menu"
    echo
    read -p "Select option [1-5]: " log_choice
    
    case $log_choice in
        1)
            if systemctl list-units --type=service | grep -q postgresql; then
                echo -e "${YELLOW}PostgreSQL logs:${NC}"
                show_database_logs "postgresql"
            else
                echo -e "${RED}PostgreSQL not installed${NC}"
            fi
            ;;
        2)
            if systemctl list-units --type=service | grep -q mariadb; then
                echo -e "${YELLOW}MariaDB logs:${NC}"
                show_database_logs "mariadb"
            else
                echo -e "${RED}MariaDB not installed${NC}"
            fi
            ;;
        3)
            if systemctl list-units --type=service | grep -q mongod; then
                echo -e "${YELLOW}MongoDB logs:${NC}"
                show_database_logs "mongodb"
            else
                echo -e "${RED}MongoDB not installed${NC}"
            fi
            ;;
        4)
            echo -e "${YELLOW}All database logs:${NC}"
            if systemctl list-units --type=service | grep -q postgresql; then
                echo -e "${BLUE}=== PostgreSQL ===${NC}"
                show_database_logs "postgresql" 20
            fi
            if systemctl list-units --type=service | grep -q mariadb; then
                echo -e "${BLUE}=== MariaDB ===${NC}"
                show_database_logs "mariadb" 20
            fi
            if systemctl list-units --type=service | grep -q mongod; then
                echo -e "${BLUE}=== MongoDB ===${NC}"
                show_database_logs "mongodb" 20
            fi
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    echo
    read -p "Press Enter to continue..."
}

# Function to backup databases
backup_databases() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required for backup${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}Database backup options:${NC}"
    echo -e "${CYAN}1)${NC} Backup all databases"
    echo -e "${CYAN}2)${NC} Backup PostgreSQL only"
    echo -e "${CYAN}3)${NC} Backup MariaDB only"
    echo -e "${CYAN}4)${NC} Backup MongoDB only"
    echo -e "${CYAN}5)${NC} Back to maintenance menu"
    echo
    read -p "Select backup option [1-5]: " backup_choice
    
    case $backup_choice in
        1)
            echo -e "${YELLOW}Backing up all databases...${NC}"
            if systemctl is-active --quiet postgresql 2>/dev/null; then
                backup_database "postgresql" "all"
            fi
            if systemctl is-active --quiet mariadb 2>/dev/null; then
                backup_database "mariadb" "all"
            fi
            if systemctl is-active --quiet mongod 2>/dev/null; then
                backup_database "mongodb" "all"
            fi
            ;;
        2)
            if systemctl is-active --quiet postgresql 2>/dev/null; then
                backup_database "postgresql" "all"
            else
                echo -e "${RED}PostgreSQL not running${NC}"
            fi
            ;;
        3)
            if systemctl is-active --quiet mariadb 2>/dev/null; then
                backup_database "mariadb" "all"
            else
                echo -e "${RED}MariaDB not running${NC}"
            fi
            ;;
        4)
            if systemctl is-active --quiet mongod 2>/dev/null; then
                backup_database "mongodb" "all"
            else
                echo -e "${RED}MongoDB not running${NC}"
            fi
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    echo
    read -p "Press Enter to continue..."
}

# Function to restore from backup
restore_from_backup() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required for restore${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}Available backup files:${NC}"
    backup_dir="/var/backups/databases"
    
    if [[ -d "$backup_dir" ]]; then
        ls -la "$backup_dir" 2>/dev/null || echo "No backup files found"
        echo
        read -p "Enter backup file path to restore: " restore_file
        
        if [[ -f "$restore_file" ]]; then
            echo -e "${YELLOW}Restoring from: $restore_file${NC}"
            # Determine database type from filename
            if [[ "$restore_file" == *"postgresql"* ]]; then
                read -p "Enter database name to restore to: " db_name
                restore_database "postgresql" "$restore_file" "$db_name"
            elif [[ "$restore_file" == *"mariadb"* ]]; then
                read -p "Enter database name to restore to: " db_name
                restore_database "mariadb" "$restore_file" "$db_name"
            elif [[ "$restore_file" == *"mongodb"* ]]; then
                restore_database "mongodb" "$restore_file" ""
            else
                echo -e "${RED}Cannot determine database type from filename${NC}"
            fi
        else
            echo -e "${RED}Backup file not found${NC}"
        fi
    else
        echo -e "${RED}Backup directory not found: $backup_dir${NC}"
    fi
    echo
    read -p "Press Enter to continue..."
}

# Function to optimize databases
optimize_databases() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required for optimization${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}Optimizing databases...${NC}"
    echo
    
    # Optimize PostgreSQL
    if systemctl is-active --quiet postgresql 2>/dev/null; then
        echo -e "${CYAN}Optimizing PostgreSQL...${NC}"
        sudo -u postgres psql -c "VACUUM ANALYZE;" 2>/dev/null && echo -e "${GREEN}✓ PostgreSQL optimized${NC}" || echo -e "${RED}✗ PostgreSQL optimization failed${NC}"
    fi
    
    # Optimize MariaDB
    if systemctl is-active --quiet mariadb 2>/dev/null; then
        echo -e "${CYAN}Optimizing MariaDB...${NC}"
        mysqlcheck --optimize --all-databases 2>/dev/null && echo -e "${GREEN}✓ MariaDB optimized${NC}" || echo -e "${RED}✗ MariaDB optimization failed${NC}"
    fi
    
    # MongoDB doesn't need regular optimization like SQL databases
    if systemctl is-active --quiet mongod 2>/dev/null; then
        echo -e "${CYAN}MongoDB is running (no optimization needed)${NC}"
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Function to monitor disk usage
monitor_disk_usage() {
    echo -e "${YELLOW}Database disk usage:${NC}"
    echo
    
    # General disk usage
    echo -e "${BLUE}Overall disk usage:${NC}"
    df -h
    echo
    
    # PostgreSQL data directory
    if [[ -d "/var/lib/postgresql" ]]; then
        echo -e "${BLUE}PostgreSQL data usage:${NC}"
        du -sh /var/lib/postgresql/* 2>/dev/null || echo "Cannot access PostgreSQL data directory"
        echo
    fi
    
    # MariaDB data directory
    if [[ -d "/var/lib/mysql" ]]; then
        echo -e "${BLUE}MariaDB data usage:${NC}"
        du -sh /var/lib/mysql/* 2>/dev/null || echo "Cannot access MariaDB data directory"
        echo
    fi
    
    # MongoDB data directory
    if [[ -d "/var/lib/mongodb" ]]; then
        echo -e "${BLUE}MongoDB data usage:${NC}"
        du -sh /var/lib/mongodb/* 2>/dev/null || echo "Cannot access MongoDB data directory"
        echo
    fi
    
    # Backup directory usage
    if [[ -d "/var/backups" ]]; then
        echo -e "${BLUE}Backup directory usage:${NC}"
        du -sh /var/backups/* 2>/dev/null || echo "No backups found"
        echo
    fi
    
    read -p "Press Enter to continue..."
}

# Function to restart services
restart_services() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Root privileges required to restart services${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}Restarting database services...${NC}"
    echo
    
    # Restart PostgreSQL
    if systemctl list-units --type=service | grep -q postgresql; then
        echo -e "${CYAN}Restarting PostgreSQL...${NC}"
        restart_database_service "postgresql"
        check_database_service "postgresql"
        echo
    fi
    
    # Restart MariaDB
    if systemctl list-units --type=service | grep -q mariadb; then
        echo -e "${CYAN}Restarting MariaDB...${NC}"
        restart_database_service "mariadb"
        check_database_service "mariadb"
        echo
    fi
    
    # Restart MongoDB
    if systemctl list-units --type=service | grep -q mongod; then
        echo -e "${CYAN}Restarting MongoDB...${NC}"
        restart_database_service "mongodb"
        check_database_service "mongodb"
        echo
    fi
    
    echo -e "${GREEN}Database services restart completed${NC}"
    echo
    read -p "Press Enter to continue..."
}

# Function for full system check
full_system_check() {
    echo -e "${YELLOW}Performing full database system check...${NC}"
    echo
    
    echo -e "${BLUE}=== Service Status ===${NC}"
    if systemctl list-units --type=service | grep -q postgresql; then
        check_database_service "postgresql"
    fi
    if systemctl list-units --type=service | grep -q mariadb; then
        check_database_service "mariadb"
    fi
    if systemctl list-units --type=service | grep -q mongod; then
        check_database_service "mongodb"
    fi
    echo
    
    echo -e "${BLUE}=== Connection Tests ===${NC}"
    if systemctl is-active --quiet postgresql 2>/dev/null; then
        test_postgresql_connection >/dev/null 2>&1 && echo -e "${GREEN}✓ PostgreSQL connection OK${NC}" || echo -e "${RED}✗ PostgreSQL connection failed${NC}"
    fi
    if systemctl is-active --quiet mariadb 2>/dev/null; then
        test_mariadb_connection >/dev/null 2>&1 && echo -e "${GREEN}✓ MariaDB connection OK${NC}" || echo -e "${RED}✗ MariaDB connection failed${NC}"
    fi
    if systemctl is-active --quiet mongod 2>/dev/null; then
        test_mongodb_connection >/dev/null 2>&1 && echo -e "${GREEN}✓ MongoDB connection OK${NC}" || echo -e "${RED}✗ MongoDB connection failed${NC}"
    fi
    echo
    
    echo -e "${BLUE}=== Disk Usage Summary ===${NC}"
    df -h | grep -E '/$|/var'
    echo
    
    echo -e "${BLUE}=== Recent Errors ===${NC}"
    if systemctl list-units --type=service | grep -q postgresql; then
        journalctl -u postgresql -p err --since "1 hour ago" --no-pager | tail -5 || echo "No recent PostgreSQL errors"
    fi
    if systemctl list-units --type=service | grep -q mariadb; then
        journalctl -u mariadb -p err --since "1 hour ago" --no-pager | tail -5 || echo "No recent MariaDB errors"
    fi
    if systemctl list-units --type=service | grep -q mongod; then
        journalctl -u mongod -p err --since "1 hour ago" --no-pager | tail -5 || echo "No recent MongoDB errors"
    fi
    echo
    
    echo -e "${GREEN}Full system check completed${NC}"
    echo
    read -p "Press Enter to continue..."
}

# Main maintenance loop
while true; do
    show_maintenance_menu
    read -p "Select an option [0-9]: " choice
    
    case $choice in
        1)
            check_all_services
            ;;
        2)
            run_health_checks
            ;;
        3)
            view_logs
            ;;
        4)
            backup_databases
            ;;
        5)
            restore_from_backup
            ;;
        6)
            optimize_databases
            ;;
        7)
            monitor_disk_usage
            ;;
        8)
            restart_services
            ;;
        9)
            full_system_check
            ;;
        0)
            echo -e "${YELLOW}Returning to main menu...${NC}"
            break
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 2
            ;;
    esac
done
