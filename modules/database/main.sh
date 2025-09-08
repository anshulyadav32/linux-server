#!/bin/bash
# Database System Management
# Purpose: Main interface for database operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install.sh"
MAINTAIN_SCRIPT="$SCRIPT_DIR/maintain.sh"
UPDATE_SCRIPT="$SCRIPT_DIR/update.sh"

# Function to print headers
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗ $1${NC}"
    return 1
}

# Function to check if a script exists and is executable
check_script() {
    local script=$1
    if [[ -f "$script" && -x "$script" ]]; then
        return 0
    else
        print_error "Script not found or not executable: $script"
        return 1
    fi
}

# Function to check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to show database status
show_database_status() {
    print_header "Database Services Status"
    
    # PostgreSQL
    if systemctl is-active --quiet postgresql; then
        print_success "PostgreSQL is running"
        echo "Version: $(su - postgres -c 'psql -t -c "SELECT version();"' 2>/dev/null | head -n 1)"
    else
        print_error "PostgreSQL is not running"
    fi
    
    # MariaDB
    if systemctl is-active --quiet mariadb; then
        print_success "MariaDB is running"
        echo "Version: $(mariadb -V)"
    else
        print_error "MariaDB is not running"
    fi
    
    # MongoDB
    if systemctl is-active --quiet mongod; then
        print_success "MongoDB is running"
        echo "Version: $(mongosh --eval "db.version()" --quiet)"
    else
        print_error "MongoDB is not running"
    fi
}

# Function to show main menu
show_menu() {
    print_header "Database Management System"
    echo "1) Install Database Systems"
    echo "2) Maintenance Operations"
    echo "3) Update Database Systems"
    echo "4) Show Database Status"
    echo "5) Start All Services"
    echo "6) Stop All Services"
    echo "7) Restart All Services"
    echo "8) View System Logs"
    echo "0) Exit"
    echo
    read -p "Select an option [0-8]: " choice
}

# Function to start all services
start_all_services() {
    print_header "Starting Database Services"
    systemctl start postgresql && print_success "PostgreSQL started" || print_error "Failed to start PostgreSQL"
    systemctl start mariadb && print_success "MariaDB started" || print_error "Failed to start MariaDB"
    systemctl start mongod && print_success "MongoDB started" || print_error "Failed to start MongoDB"
}

# Function to stop all services
stop_all_services() {
    print_header "Stopping Database Services"
    systemctl stop mongodb && print_success "MongoDB stopped" || print_error "Failed to stop MongoDB"
    systemctl stop mariadb && print_success "MariaDB stopped" || print_error "Failed to stop MariaDB"
    systemctl stop postgresql && print_success "PostgreSQL stopped" || print_error "Failed to stop PostgreSQL"
}

# Function to restart all services
restart_all_services() {
    print_header "Restarting Database Services"
    systemctl restart postgresql && print_success "PostgreSQL restarted" || print_error "Failed to restart PostgreSQL"
    systemctl restart mariadb && print_success "MariaDB restarted" || print_error "Failed to restart MariaDB"
    systemctl restart mongod && print_success "MongoDB restarted" || print_error "Failed to restart MongoDB"
}

# Function to view system logs
view_system_logs() {
    print_header "Database System Logs"
    echo -e "${YELLOW}PostgreSQL Logs:${NC}"
    tail -n 10 /var/log/postgresql/postgresql-*.log 2>/dev/null || echo "No PostgreSQL logs found"
    echo -e "\n${YELLOW}MariaDB Logs:${NC}"
    tail -n 10 /var/log/mysql/error.log 2>/dev/null || echo "No MariaDB logs found"
    echo -e "\n${YELLOW}MongoDB Logs:${NC}"
    tail -n 10 /var/log/mongodb/mongod.log 2>/dev/null || echo "No MongoDB logs found"
}

# Main function
main() {
    check_root
    
    while true; do
        show_menu
        case $choice in
            1)
                if check_script "$INSTALL_SCRIPT"; then
                    "$INSTALL_SCRIPT"
                fi
                ;;
            2)
                if check_script "$MAINTAIN_SCRIPT"; then
                    "$MAINTAIN_SCRIPT"
                fi
                ;;
            3)
                if check_script "$UPDATE_SCRIPT"; then
                    "$UPDATE_SCRIPT"
                fi
                ;;
            4)
                show_database_status
                ;;
            5)
                start_all_services
                ;;
            6)
                stop_all_services
                ;;
            7)
                restart_all_services
                ;;
            8)
                view_system_logs
                ;;
            0)
                print_success "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac
        echo
        read -p "Press Enter to continue..."
    done
}

# Start the script
main
