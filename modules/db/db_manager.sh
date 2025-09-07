#!/bin/bash

#=============================================================================
# Database Stack Manager - Interactive Menu System
# Author: Anshul Yadav
# Description: Modular management system for complete database stack
# Databases: PostgreSQL, MariaDB/MySQL, MongoDB, SQLite, Redis
# Features: Interactive menu, logging, health checks, maintenance
#=============================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="$(dirname "$0")/../../logs/db_manager.log"
SCRIPT_DIR="$(dirname "$0")"
RETRY_COUNT=1

# Database configurations
declare -A DB_PORTS=(
    ["postgresql"]="5432"
    ["mariadb"]="3306"
    ["mongodb"]="27017"
    ["redis"]="6379"
)

declare -A DB_SERVICES=(
    ["postgresql"]="postgresql"
    ["mariadb"]="mariadb"
    ["mongodb"]="mongod"
    ["redis"]="redis-server"
)

declare -A DB_PACKAGES=(
    ["postgresql"]="postgresql postgresql-contrib postgresql-client"
    ["mariadb"]="mariadb-server mariadb-client"
    ["mongodb"]="mongodb-org"
    ["sqlite"]="sqlite3 libsqlite3-dev"
    ["redis"]="redis-server"
)

# Global arrays for tracking
INSTALLED_DBS=()
FAILED_DBS=()
SERVICE_STATUS=()
CONNECTIVITY_STATUS=()
PORT_STATUS=()

#=============================================================================
# Utility Functions
#=============================================================================

# Ensure logs directory exists and initialize log
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "Database Manager Log - $(date)" > "$LOG_FILE"
        echo "=====================================" >> "$LOG_FILE"
    fi
}

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Output functions with logging
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log_message "SUCCESS" "$1"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    log_message "ERROR" "$1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log_message "WARNING" "$1"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
    log_message "INFO" "$1"
}

print_progress() {
    echo -e "${YELLOW}🔄 $1${NC}"
    log_message "PROGRESS" "$1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for security reasons"
        exit 1
    fi
}

# Check sudo access
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        print_info "Please enter your sudo password for system operations"
        sudo -v
    fi
}

# Wait for user input
wait_for_input() {
    echo
    read -p "Press Enter to continue..." -r
}

#=============================================================================
# Installation Functions
#=============================================================================

# Update package manager
update_package_manager() {
    print_progress "Updating package manager..."
    
    if sudo apt update >> "$LOG_FILE" 2>&1; then
        print_success "Package manager updated successfully"
        return 0
    else
        print_error "Failed to update package manager"
        return 1
    fi
}

# Install PostgreSQL
install_postgresql() {
    local attempt=0
    
    print_progress "Installing PostgreSQL..."
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        if sudo apt install -y ${DB_PACKAGES["postgresql"]} >> "$LOG_FILE" 2>&1; then
            print_success "PostgreSQL installed successfully"
            
            # Configure PostgreSQL
            if sudo systemctl start postgresql >> "$LOG_FILE" 2>&1 && \
               sudo systemctl enable postgresql >> "$LOG_FILE" 2>&1; then
                
                # Create user for current user
                sudo -u postgres createuser -s "$USER" >> "$LOG_FILE" 2>&1 || true
                print_success "PostgreSQL configured successfully"
                INSTALLED_DBS+=("PostgreSQL")
                return 0
            fi
        fi
        
        ((attempt++))
        if [[ $attempt -le $RETRY_COUNT ]]; then
            print_warning "PostgreSQL installation failed, retrying..."
            sleep 3
        fi
    done
    
    print_error "PostgreSQL installation failed after retries"
    FAILED_DBS+=("PostgreSQL")
    return 1
}

# Install MariaDB
install_mariadb() {
    local attempt=0
    
    print_progress "Installing MariaDB..."
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        if sudo apt install -y ${DB_PACKAGES["mariadb"]} >> "$LOG_FILE" 2>&1; then
            print_success "MariaDB installed successfully"
            
            # Configure MariaDB
            if sudo systemctl start mariadb >> "$LOG_FILE" 2>&1 && \
               sudo systemctl enable mariadb >> "$LOG_FILE" 2>&1; then
                
                # Secure installation
                sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'secure_root_123';" >> "$LOG_FILE" 2>&1 || true
                sudo mysql -e "DELETE FROM mysql.user WHERE User='';" >> "$LOG_FILE" 2>&1 || true
                sudo mysql -e "DROP DATABASE IF EXISTS test;" >> "$LOG_FILE" 2>&1 || true
                sudo mysql -e "FLUSH PRIVILEGES;" >> "$LOG_FILE" 2>&1 || true
                
                print_success "MariaDB configured successfully"
                print_info "MariaDB root password: secure_root_123"
                INSTALLED_DBS+=("MariaDB")
                return 0
            fi
        fi
        
        ((attempt++))
        if [[ $attempt -le $RETRY_COUNT ]]; then
            print_warning "MariaDB installation failed, retrying..."
            sleep 3
        fi
    done
    
    print_error "MariaDB installation failed after retries"
    FAILED_DBS+=("MariaDB")
    return 1
}

# Install MongoDB
install_mongodb() {
    local attempt=0
    
    print_progress "Installing MongoDB..."
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        # Import MongoDB public GPG key and add repository
        if curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor >> "$LOG_FILE" 2>&1 && \
           echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list >> "$LOG_FILE" 2>&1 && \
           sudo apt update >> "$LOG_FILE" 2>&1 && \
           sudo apt install -y ${DB_PACKAGES["mongodb"]} >> "$LOG_FILE" 2>&1; then
            
            print_success "MongoDB installed successfully"
            
            # Configure MongoDB
            if sudo systemctl start mongod >> "$LOG_FILE" 2>&1 && \
               sudo systemctl enable mongod >> "$LOG_FILE" 2>&1; then
                
                print_success "MongoDB configured successfully"
                INSTALLED_DBS+=("MongoDB")
                return 0
            fi
        fi
        
        ((attempt++))
        if [[ $attempt -le $RETRY_COUNT ]]; then
            print_warning "MongoDB installation failed, retrying..."
            sleep 3
        fi
    done
    
    print_error "MongoDB installation failed after retries"
    FAILED_DBS+=("MongoDB")
    return 1
}

# Install SQLite
install_sqlite() {
    local attempt=0
    
    print_progress "Installing SQLite..."
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        if sudo apt install -y ${DB_PACKAGES["sqlite"]} >> "$LOG_FILE" 2>&1; then
            print_success "SQLite installed successfully"
            INSTALLED_DBS+=("SQLite")
            return 0
        fi
        
        ((attempt++))
        if [[ $attempt -le $RETRY_COUNT ]]; then
            print_warning "SQLite installation failed, retrying..."
            sleep 3
        fi
    done
    
    print_error "SQLite installation failed after retries"
    FAILED_DBS+=("SQLite")
    return 1
}

# Install Redis
install_redis() {
    local attempt=0
    
    print_progress "Installing Redis..."
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        if sudo apt install -y ${DB_PACKAGES["redis"]} >> "$LOG_FILE" 2>&1; then
            print_success "Redis installed successfully"
            
            # Configure Redis
            if sudo systemctl start redis-server >> "$LOG_FILE" 2>&1 && \
               sudo systemctl enable redis-server >> "$LOG_FILE" 2>&1; then
                
                print_success "Redis configured successfully"
                INSTALLED_DBS+=("Redis")
                return 0
            fi
        fi
        
        ((attempt++))
        if [[ $attempt -le $RETRY_COUNT ]]; then
            print_warning "Redis installation failed, retrying..."
            sleep 3
        fi
    done
    
    print_error "Redis installation failed after retries"
    FAILED_DBS+=("Redis")
    return 1
}

# Main installation function
install_database_stack() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                        Database Stack Installation                          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Reset arrays
    INSTALLED_DBS=()
    FAILED_DBS=()
    
    # Pre-installation checks
    check_sudo
    update_package_manager
    
    echo
    print_info "Starting database stack installation..."
    
    # Install each database
    install_postgresql
    echo
    install_mariadb
    echo
    install_mongodb
    echo
    install_sqlite
    echo
    install_redis
    
    # Show summary
    echo
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                          Installation Summary                               ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    if [[ ${#INSTALLED_DBS[@]} -gt 0 ]]; then
        echo -e "${GREEN}✅ Successfully Installed:${NC}"
        for db in "${INSTALLED_DBS[@]}"; do
            echo -e "   ${GREEN}• $db${NC}"
        done
    fi
    
    if [[ ${#FAILED_DBS[@]} -gt 0 ]]; then
        echo
        echo -e "${RED}❌ Failed to Install:${NC}"
        for db in "${FAILED_DBS[@]}"; do
            echo -e "   ${RED}• $db${NC}"
        done
    fi
    
    echo
    echo -e "${CYAN}📊 Total: ${#INSTALLED_DBS[@]} successful, ${#FAILED_DBS[@]} failed${NC}"
    
    wait_for_input
}

#=============================================================================
# Update Functions
#=============================================================================

update_database_stack() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                        Database Stack Update                                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    check_sudo
    
    print_progress "Updating package manager..."
    if sudo apt update >> "$LOG_FILE" 2>&1; then
        print_success "Package manager updated"
    else
        print_error "Failed to update package manager"
        wait_for_input
        return 1
    fi
    
    print_progress "Upgrading database packages..."
    
    # Update all database packages
    local all_packages=""
    for db in "${!DB_PACKAGES[@]}"; do
        all_packages+="${DB_PACKAGES[$db]} "
    done
    
    if sudo apt upgrade -y $all_packages >> "$LOG_FILE" 2>&1; then
        print_success "Database packages updated successfully"
    else
        print_warning "Some packages may have failed to update (check logs)"
    fi
    
    print_info "Update completed"
    wait_for_input
}

#=============================================================================
# Maintenance Check Functions
#=============================================================================

# Check service status
check_service_status() {
    local service="$1"
    local display_name="$2"
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        print_success "$display_name service is running"
        SERVICE_STATUS+=("$display_name: ✅ Running")
        return 0
    else
        print_error "$display_name service is not running"
        SERVICE_STATUS+=("$display_name: ❌ Stopped")
        return 1
    fi
}

# Check PostgreSQL connectivity
check_postgresql_connectivity() {
    if command -v psql &> /dev/null; then
        if sudo -u postgres psql -c "SELECT version();" >> "$LOG_FILE" 2>&1; then
            print_success "PostgreSQL connectivity test passed"
            CONNECTIVITY_STATUS+=("PostgreSQL: ✅ Connected")
            return 0
        fi
    fi
    print_error "PostgreSQL connectivity test failed"
    CONNECTIVITY_STATUS+=("PostgreSQL: ❌ Failed")
    return 1
}

# Check MariaDB connectivity
check_mariadb_connectivity() {
    if command -v mysqladmin &> /dev/null; then
        if mysqladmin ping -u root -psecure_root_123 >> "$LOG_FILE" 2>&1; then
            print_success "MariaDB connectivity test passed"
            CONNECTIVITY_STATUS+=("MariaDB: ✅ Connected")
            return 0
        fi
    fi
    print_error "MariaDB connectivity test failed"
    CONNECTIVITY_STATUS+=("MariaDB: ❌ Failed")
    return 1
}

# Check MongoDB connectivity
check_mongodb_connectivity() {
    if command -v mongosh &> /dev/null; then
        if mongosh --eval "db.stats()" >> "$LOG_FILE" 2>&1; then
            print_success "MongoDB connectivity test passed"
            CONNECTIVITY_STATUS+=("MongoDB: ✅ Connected")
            return 0
        fi
    elif command -v mongo &> /dev/null; then
        if mongo --eval "db.stats()" >> "$LOG_FILE" 2>&1; then
            print_success "MongoDB connectivity test passed"
            CONNECTIVITY_STATUS+=("MongoDB: ✅ Connected")
            return 0
        fi
    fi
    print_error "MongoDB connectivity test failed"
    CONNECTIVITY_STATUS+=("MongoDB: ❌ Failed")
    return 1
}

# Check SQLite
check_sqlite_status() {
    if command -v sqlite3 &> /dev/null; then
        local version=$(sqlite3 --version 2>/dev/null)
        if [[ -n "$version" ]]; then
            print_success "SQLite is installed (Version: ${version%% *})"
            CONNECTIVITY_STATUS+=("SQLite: ✅ Available")
            return 0
        fi
    fi
    print_error "SQLite is not available"
    CONNECTIVITY_STATUS+=("SQLite: ❌ Not Available")
    return 1
}

# Check Redis connectivity
check_redis_connectivity() {
    if command -v redis-cli &> /dev/null; then
        if redis-cli ping 2>/dev/null | grep -q "PONG"; then
            print_success "Redis connectivity test passed"
            CONNECTIVITY_STATUS+=("Redis: ✅ Connected")
            return 0
        fi
    fi
    print_error "Redis connectivity test failed"
    CONNECTIVITY_STATUS+=("Redis: ❌ Failed")
    return 1
}

# Check port availability
check_port() {
    local port="$1"
    local service="$2"
    
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        print_success "$service port $port is open"
        PORT_STATUS+=("$service (Port $port): ✅ Open")
        return 0
    else
        print_warning "$service port $port is not accessible"
        PORT_STATUS+=("$service (Port $port): ⚠️  Not accessible")
        return 1
    fi
}

# Main maintenance check function
maintenance_check() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                          Maintenance Check                                  ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Reset status arrays
    SERVICE_STATUS=()
    CONNECTIVITY_STATUS=()
    PORT_STATUS=()
    
    # Check services
    echo -e "${YELLOW}🔍 Checking Service Status...${NC}"
    echo
    check_service_status "postgresql" "PostgreSQL"
    check_service_status "mariadb" "MariaDB"
    check_service_status "mongod" "MongoDB"
    check_service_status "redis-server" "Redis"
    
    echo
    echo -e "${YELLOW}🔍 Checking Connectivity...${NC}"
    echo
    check_postgresql_connectivity
    check_mariadb_connectivity
    check_mongodb_connectivity
    check_sqlite_status
    check_redis_connectivity
    
    echo
    echo -e "${YELLOW}🔍 Checking Ports...${NC}"
    echo
    check_port "5432" "PostgreSQL"
    check_port "3306" "MariaDB"
    check_port "27017" "MongoDB"
    check_port "6379" "Redis"
    
    # Show summary
    echo
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                          Maintenance Summary                                ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    echo -e "${CYAN}📋 Service Status:${NC}"
    for status in "${SERVICE_STATUS[@]}"; do
        echo "   $status"
    done
    
    echo
    echo -e "${CYAN}🔗 Connectivity Status:${NC}"
    for status in "${CONNECTIVITY_STATUS[@]}"; do
        echo "   $status"
    done
    
    echo
    echo -e "${CYAN}🌐 Port Status:${NC}"
    for status in "${PORT_STATUS[@]}"; do
        echo "   $status"
    done
    
    wait_for_input
}

#=============================================================================
# Log and Summary Functions
#=============================================================================

view_logs() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                              View Logs                                      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${CYAN}📁 Log file: $LOG_FILE${NC}"
        echo -e "${CYAN}📏 File size: $(du -h "$LOG_FILE" | cut -f1)${NC}"
        echo
        echo -e "${YELLOW}Last 50 lines:${NC}"
        echo "────────────────────────────────────────────────────────────────────────────────"
        tail -50 "$LOG_FILE"
        echo "────────────────────────────────────────────────────────────────────────────────"
    else
        print_warning "Log file not found: $LOG_FILE"
    fi
    
    wait_for_input
}

show_installation_summary() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                        Installation Summary                                 ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${CYAN}📦 Checking installed packages...${NC}"
    echo
    
    # Check each database
    local installed_packages=()
    
    # PostgreSQL
    if dpkg -l | grep -q "postgresql"; then
        local pg_version=$(dpkg -l | grep "postgresql-[0-9]" | head -1 | awk '{print $3}')
        installed_packages+=("PostgreSQL (Version: $pg_version)")
        print_success "PostgreSQL is installed"
    else
        print_error "PostgreSQL is not installed"
    fi
    
    # MariaDB
    if dpkg -l | grep -q "mariadb-server"; then
        local mariadb_version=$(dpkg -l | grep "mariadb-server" | awk '{print $3}')
        installed_packages+=("MariaDB (Version: $mariadb_version)")
        print_success "MariaDB is installed"
    else
        print_error "MariaDB is not installed"
    fi
    
    # MongoDB
    if dpkg -l | grep -q "mongodb-org"; then
        local mongo_version=$(dpkg -l | grep "mongodb-org-server" | awk '{print $3}')
        installed_packages+=("MongoDB (Version: $mongo_version)")
        print_success "MongoDB is installed"
    else
        print_error "MongoDB is not installed"
    fi
    
    # SQLite
    if dpkg -l | grep -q "sqlite3"; then
        local sqlite_version=$(sqlite3 --version 2>/dev/null | cut -d' ' -f1)
        installed_packages+=("SQLite (Version: $sqlite_version)")
        print_success "SQLite is installed"
    else
        print_error "SQLite is not installed"
    fi
    
    # Redis
    if dpkg -l | grep -q "redis-server"; then
        local redis_version=$(dpkg -l | grep "redis-server" | awk '{print $3}')
        installed_packages+=("Redis (Version: $redis_version)")
        print_success "Redis is installed"
    else
        print_error "Redis is not installed"
    fi
    
    # Show summary
    echo
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                          Installed Packages                                ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    if [[ ${#installed_packages[@]} -gt 0 ]]; then
        echo
        for package in "${installed_packages[@]}"; do
            echo -e "   ${GREEN}✅ $package${NC}"
        done
        echo
        echo -e "${CYAN}📊 Total installed: ${#installed_packages[@]} database systems${NC}"
    else
        echo
        print_warning "No database packages found"
    fi
    
    wait_for_input
}

#=============================================================================
# Menu System
#=============================================================================

show_menu() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                         Database Stack Manager                              ║${NC}"
    echo -e "${PURPLE}║                            $(date)                       ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}Please select an option:${NC}"
    echo
    echo -e "${WHITE}1)${NC} ${GREEN}Install Database Stack${NC}"
    echo -e "${WHITE}2)${NC} ${YELLOW}Update Database Stack${NC}"
    echo -e "${WHITE}3)${NC} ${BLUE}Maintenance Check (services, queries, ports)${NC}"
    echo -e "${WHITE}4)${NC} ${CYAN}View Logs${NC}"
    echo -e "${WHITE}5)${NC} ${PURPLE}Show Installation Summary${NC}"
    echo -e "${WHITE}6)${NC} ${RED}Exit${NC}"
    echo
    echo -e "${YELLOW}Supported Databases: PostgreSQL, MariaDB, MongoDB, SQLite, Redis${NC}"
    echo
}

get_user_choice() {
    while true; do
        read -p "Enter your choice (1-6): " choice
        case $choice in
            1|2|3|4|5|6)
                echo "$choice"
                return 0
                ;;
            *)
                print_error "Invalid option. Please enter a number between 1-6."
                ;;
        esac
    done
}

#=============================================================================
# Main Function
#=============================================================================

main() {
    # Initialize
    init_logging
    check_root
    
    # Main menu loop
    while true; do
        show_menu
        choice=$(get_user_choice)
        
        case $choice in
            1)
                install_database_stack
                ;;
            2)
                update_database_stack
                ;;
            3)
                maintenance_check
                ;;
            4)
                view_logs
                ;;
            5)
                show_installation_summary
                ;;
            6)
                clear
                echo -e "${GREEN}Thank you for using Database Stack Manager!${NC}"
                echo -e "${CYAN}Logs saved to: $LOG_FILE${NC}"
                exit 0
                ;;
        esac
    done
}

# Trap to ensure cleanup
trap 'log_message "INFO" "Database Manager session ended"' EXIT

# Run main function
main "$@"
