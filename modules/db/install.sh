#!/bin/bash

#=============================================================================
# Database Stack Installation Script
# Author: Anshul Yadav
# Description: Automated installation and configuration of complete database stack
# Databases: PostgreSQL, MariaDB/MySQL, MongoDB, SQLite, Redis
# Features: Auto-retry, logging, colored output, health checks
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
LOG_FILE="$(dirname "$0")/../../logs/db_install.log"
SCRIPT_DIR="$(dirname "$0")"
RETRY_COUNT=1
INSTALLED_SERVICES=()
FAILED_SERVICES=()

# Ensure logs directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Initialize log file
echo "Database Stack Installation Log - $(date)" > "$LOG_FILE"
echo "=============================================" >> "$LOG_FILE"

#=============================================================================
# Utility Functions
#=============================================================================

print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                      Database Stack Installer                               ║${NC}"
    echo -e "${PURPLE}║                         $(date)                        ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

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

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for security reasons"
        exit 1
    fi
}

check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        print_info "Please enter your sudo password for system package installation"
        sudo -v
    fi
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        print_error "Cannot detect operating system"
        exit 1
    fi
    
    print_info "Detected OS: $OS $OS_VERSION"
    log_message "INFO" "Operating System: $OS $OS_VERSION"
}

update_package_manager() {
    print_progress "Updating package manager..."
    
    case $OS in
        ubuntu|debian)
            if sudo apt update >> "$LOG_FILE" 2>&1; then
                print_success "Package manager updated successfully"
            else
                print_error "Failed to update package manager"
                return 1
            fi
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                if sudo dnf update -y >> "$LOG_FILE" 2>&1; then
                    print_success "Package manager updated successfully"
                else
                    print_error "Failed to update package manager"
                    return 1
                fi
            elif command -v yum &> /dev/null; then
                if sudo yum update -y >> "$LOG_FILE" 2>&1; then
                    print_success "Package manager updated successfully"
                else
                    print_error "Failed to update package manager"
                    return 1
                fi
            fi
            ;;
        *)
            print_warning "Unsupported OS for automatic package manager update"
            ;;
    esac
}

check_service_status() {
    local service_name="$1"
    if systemctl is-active --quiet "$service_name"; then
        return 0
    else
        return 1
    fi
}

wait_for_service() {
    local service_name="$1"
    local max_attempts=30
    local attempt=0
    
    print_progress "Waiting for $service_name to start..."
    
    while [[ $attempt -lt $max_attempts ]]; do
        if check_service_status "$service_name"; then
            print_success "$service_name is running"
            return 0
        fi
        
        sleep 2
        ((attempt++))
    done
    
    print_error "$service_name failed to start within timeout"
    return 1
}

#=============================================================================
# PostgreSQL Installation Functions
#=============================================================================

install_postgresql() {
    local attempt=0
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        print_progress "Installing PostgreSQL (Attempt: $((attempt + 1)))"
        
        case $OS in
            ubuntu|debian)
                if sudo apt install -y postgresql postgresql-contrib postgresql-client >> "$LOG_FILE" 2>&1; then
                    break
                fi
                ;;
            centos|rhel|fedora)
                if command -v dnf &> /dev/null; then
                    if sudo dnf install -y postgresql postgresql-server postgresql-contrib >> "$LOG_FILE" 2>&1; then
                        # Initialize database for CentOS/RHEL/Fedora
                        sudo postgresql-setup --initdb >> "$LOG_FILE" 2>&1 || true
                        break
                    fi
                elif command -v yum &> /dev/null; then
                    if sudo yum install -y postgresql postgresql-server postgresql-contrib >> "$LOG_FILE" 2>&1; then
                        # Initialize database for CentOS/RHEL
                        sudo postgresql-setup initdb >> "$LOG_FILE" 2>&1 || true
                        break
                    fi
                fi
                ;;
        esac
        
        ((attempt++))
        if [[ $attempt -le $RETRY_COUNT ]]; then
            print_warning "PostgreSQL installation failed, retrying..."
            sleep 5
        fi
    done
    
    if [[ $attempt -gt $RETRY_COUNT ]]; then
        print_error "PostgreSQL installation failed after $RETRY_COUNT retries"
        FAILED_SERVICES+=("PostgreSQL")
        return 1
    fi
    
    print_success "PostgreSQL installed successfully"
    return 0
}

configure_postgresql() {
    print_progress "Configuring PostgreSQL..."
    
    # Start and enable PostgreSQL service
    if sudo systemctl start postgresql >> "$LOG_FILE" 2>&1 && \
       sudo systemctl enable postgresql >> "$LOG_FILE" 2>&1; then
        
        if wait_for_service "postgresql"; then
            # Create a database user for the current user
            if sudo -u postgres createuser -s "$USER" >> "$LOG_FILE" 2>&1 || \
               sudo -u postgres psql -c "ALTER USER \"$USER\" CREATEDB;" >> "$LOG_FILE" 2>&1; then
                print_success "PostgreSQL configured successfully"
                return 0
            fi
        fi
    fi
    
    print_error "PostgreSQL configuration failed"
    return 1
}

test_postgresql() {
    print_progress "Testing PostgreSQL connection..."
    
    if sudo -u postgres psql -c "SELECT version();" >> "$LOG_FILE" 2>&1; then
        print_success "PostgreSQL connection test passed"
        INSTALLED_SERVICES+=("PostgreSQL")
        return 0
    else
        print_error "PostgreSQL connection test failed"
        FAILED_SERVICES+=("PostgreSQL")
        return 1
    fi
}

#=============================================================================
# MariaDB/MySQL Installation Functions
#=============================================================================

install_mariadb() {
    local attempt=0
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        print_progress "Installing MariaDB (Attempt: $((attempt + 1)))"
        
        case $OS in
            ubuntu|debian)
                if sudo apt install -y mariadb-server mariadb-client >> "$LOG_FILE" 2>&1; then
                    break
                fi
                ;;
            centos|rhel|fedora)
                if command -v dnf &> /dev/null; then
                    if sudo dnf install -y mariadb mariadb-server >> "$LOG_FILE" 2>&1; then
                        break
                    fi
                elif command -v yum &> /dev/null; then
                    if sudo yum install -y mariadb mariadb-server >> "$LOG_FILE" 2>&1; then
                        break
                    fi
                fi
                ;;
        esac
        
        ((attempt++))
        if [[ $attempt -le $RETRY_COUNT ]]; then
            print_warning "MariaDB installation failed, retrying..."
            sleep 5
        fi
    done
    
    if [[ $attempt -gt $RETRY_COUNT ]]; then
        print_error "MariaDB installation failed after $RETRY_COUNT retries"
        FAILED_SERVICES+=("MariaDB")
        return 1
    fi
    
    print_success "MariaDB installed successfully"
    return 0
}

configure_mariadb() {
    print_progress "Configuring MariaDB..."
    
    # Start and enable MariaDB service
    if sudo systemctl start mariadb >> "$LOG_FILE" 2>&1 && \
       sudo systemctl enable mariadb >> "$LOG_FILE" 2>&1; then
        
        if wait_for_service "mariadb"; then
            # Secure installation (automated)
            print_progress "Running MariaDB secure installation..."
            
            # Set root password and secure installation
            sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'secure_root_password_123';" >> "$LOG_FILE" 2>&1 || true
            sudo mysql -e "DELETE FROM mysql.user WHERE User='';" >> "$LOG_FILE" 2>&1 || true
            sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" >> "$LOG_FILE" 2>&1 || true
            sudo mysql -e "DROP DATABASE IF EXISTS test;" >> "$LOG_FILE" 2>&1 || true
            sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" >> "$LOG_FILE" 2>&1 || true
            sudo mysql -e "FLUSH PRIVILEGES;" >> "$LOG_FILE" 2>&1 || true
            
            print_success "MariaDB configured successfully"
            print_info "MariaDB root password: secure_root_password_123"
            return 0
        fi
    fi
    
    print_error "MariaDB configuration failed"
    return 1
}

test_mariadb() {
    print_progress "Testing MariaDB connection..."
    
    if mysql -u root -psecure_root_password_123 -e "SELECT VERSION();" >> "$LOG_FILE" 2>&1; then
        print_success "MariaDB connection test passed"
        INSTALLED_SERVICES+=("MariaDB")
        return 0
    else
        print_error "MariaDB connection test failed"
        FAILED_SERVICES+=("MariaDB")
        return 1
    fi
}

#=============================================================================
# MongoDB Installation Functions
#=============================================================================

install_mongodb() {
    local attempt=0
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        print_progress "Installing MongoDB (Attempt: $((attempt + 1)))"
        
        case $OS in
            ubuntu|debian)
                # Import MongoDB public GPG key
                if curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor >> "$LOG_FILE" 2>&1 && \
                   echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list >> "$LOG_FILE" 2>&1 && \
                   sudo apt update >> "$LOG_FILE" 2>&1 && \
                   sudo apt install -y mongodb-org >> "$LOG_FILE" 2>&1; then
                    break
                fi
                ;;
            centos|rhel|fedora)
                # Create MongoDB repository file
                cat << EOF | sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo >> "$LOG_FILE"
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF
                
                if command -v dnf &> /dev/null; then
                    if sudo dnf install -y mongodb-org >> "$LOG_FILE" 2>&1; then
                        break
                    fi
                elif command -v yum &> /dev/null; then
                    if sudo yum install -y mongodb-org >> "$LOG_FILE" 2>&1; then
                        break
                    fi
                fi
                ;;
        esac
        
        ((attempt++))
        if [[ $attempt -le $RETRY_COUNT ]]; then
            print_warning "MongoDB installation failed, retrying..."
            sleep 5
        fi
    done
    
    if [[ $attempt -gt $RETRY_COUNT ]]; then
        print_error "MongoDB installation failed after $RETRY_COUNT retries"
        FAILED_SERVICES+=("MongoDB")
        return 1
    fi
    
    print_success "MongoDB installed successfully"
    return 0
}

configure_mongodb() {
    print_progress "Configuring MongoDB..."
    
    # Start and enable MongoDB service
    if sudo systemctl start mongod >> "$LOG_FILE" 2>&1 && \
       sudo systemctl enable mongod >> "$LOG_FILE" 2>&1; then
        
        if wait_for_service "mongod"; then
            print_success "MongoDB configured successfully"
            return 0
        fi
    fi
    
    print_error "MongoDB configuration failed"
    return 1
}

test_mongodb() {
    print_progress "Testing MongoDB connection..."
    
    if mongosh --eval "db.runCommand({connectionStatus: 1})" >> "$LOG_FILE" 2>&1; then
        print_success "MongoDB connection test passed"
        INSTALLED_SERVICES+=("MongoDB")
        return 0
    else
        print_error "MongoDB connection test failed"
        FAILED_SERVICES+=("MongoDB")
        return 1
    fi
}

#=============================================================================
# SQLite Installation Functions
#=============================================================================

install_sqlite() {
    local attempt=0
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        print_progress "Installing SQLite (Attempt: $((attempt + 1)))"
        
        case $OS in
            ubuntu|debian)
                if sudo apt install -y sqlite3 libsqlite3-dev >> "$LOG_FILE" 2>&1; then
                    break
                fi
                ;;
            centos|rhel|fedora)
                if command -v dnf &> /dev/null; then
                    if sudo dnf install -y sqlite sqlite-devel >> "$LOG_FILE" 2>&1; then
                        break
                    fi
                elif command -v yum &> /dev/null; then
                    if sudo yum install -y sqlite sqlite-devel >> "$LOG_FILE" 2>&1; then
                        break
                    fi
                fi
                ;;
        esac
        
        ((attempt++))
        if [[ $attempt -le $RETRY_COUNT ]]; then
            print_warning "SQLite installation failed, retrying..."
            sleep 5
        fi
    done
    
    if [[ $attempt -gt $RETRY_COUNT ]]; then
        print_error "SQLite installation failed after $RETRY_COUNT retries"
        FAILED_SERVICES+=("SQLite")
        return 1
    fi
    
    print_success "SQLite installed successfully"
    return 0
}

test_sqlite() {
    print_progress "Testing SQLite..."
    
    # Create a test database and perform operations
    local test_db="/tmp/test_sqlite.db"
    
    if sqlite3 "$test_db" "CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT); INSERT INTO test (name) VALUES ('test'); SELECT * FROM test;" >> "$LOG_FILE" 2>&1; then
        rm -f "$test_db"
        print_success "SQLite test passed"
        INSTALLED_SERVICES+=("SQLite")
        return 0
    else
        print_error "SQLite test failed"
        FAILED_SERVICES+=("SQLite")
        return 1
    fi
}

#=============================================================================
# Redis Installation Functions
#=============================================================================

install_redis() {
    local attempt=0
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        print_progress "Installing Redis (Attempt: $((attempt + 1)))"
        
        case $OS in
            ubuntu|debian)
                if sudo apt install -y redis-server >> "$LOG_FILE" 2>&1; then
                    break
                fi
                ;;
            centos|rhel|fedora)
                if command -v dnf &> /dev/null; then
                    if sudo dnf install -y redis >> "$LOG_FILE" 2>&1; then
                        break
                    fi
                elif command -v yum &> /dev/null; then
                    if sudo yum install -y redis >> "$LOG_FILE" 2>&1; then
                        break
                    fi
                fi
                ;;
        esac
        
        ((attempt++))
        if [[ $attempt -le $RETRY_COUNT ]]; then
            print_warning "Redis installation failed, retrying..."
            sleep 5
        fi
    done
    
    if [[ $attempt -gt $RETRY_COUNT ]]; then
        print_error "Redis installation failed after $RETRY_COUNT retries"
        FAILED_SERVICES+=("Redis")
        return 1
    fi
    
    print_success "Redis installed successfully"
    return 0
}

configure_redis() {
    print_progress "Configuring Redis..."
    
    # Start and enable Redis service
    if sudo systemctl start redis-server >> "$LOG_FILE" 2>&1 || sudo systemctl start redis >> "$LOG_FILE" 2>&1; then
        if sudo systemctl enable redis-server >> "$LOG_FILE" 2>&1 || sudo systemctl enable redis >> "$LOG_FILE" 2>&1; then
            if wait_for_service "redis-server" || wait_for_service "redis"; then
                print_success "Redis configured successfully"
                return 0
            fi
        fi
    fi
    
    print_error "Redis configuration failed"
    return 1
}

test_redis() {
    print_progress "Testing Redis connection..."
    
    if redis-cli ping | grep -q "PONG" >> "$LOG_FILE" 2>&1; then
        print_success "Redis connection test passed"
        INSTALLED_SERVICES+=("Redis")
        return 0
    else
        print_error "Redis connection test failed"
        FAILED_SERVICES+=("Redis")
        return 1
    fi
}

#=============================================================================
# Main Installation Functions
#=============================================================================

install_database() {
    local db_name="$1"
    local install_func="$2"
    local configure_func="$3"
    local test_func="$4"
    
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                          Installing $db_name                                  ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    if $install_func; then
        if [[ -n "$configure_func" ]] && command -v "$configure_func" &> /dev/null; then
            if $configure_func; then
                if [[ -n "$test_func" ]] && command -v "$test_func" &> /dev/null; then
                    $test_func
                else
                    INSTALLED_SERVICES+=("$db_name")
                fi
            else
                FAILED_SERVICES+=("$db_name")
            fi
        elif [[ -n "$test_func" ]] && command -v "$test_func" &> /dev/null; then
            $test_func
        else
            INSTALLED_SERVICES+=("$db_name")
        fi
    else
        FAILED_SERVICES+=("$db_name")
    fi
}

print_summary() {
    echo
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                          Installation Summary                               ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    if [[ ${#INSTALLED_SERVICES[@]} -gt 0 ]]; then
        echo -e "${GREEN}✅ Successfully Installed Services:${NC}"
        for service in "${INSTALLED_SERVICES[@]}"; do
            echo -e "   ${GREEN}• $service${NC}"
        done
        echo
    fi
    
    if [[ ${#FAILED_SERVICES[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Failed to Install:${NC}"
        for service in "${FAILED_SERVICES[@]}"; do
            echo -e "   ${RED}• $service${NC}"
        done
        echo
    fi
    
    echo -e "${CYAN}📊 Installation Statistics:${NC}"
    echo -e "   ${GREEN}Successful: ${#INSTALLED_SERVICES[@]}${NC}"
    echo -e "   ${RED}Failed: ${#FAILED_SERVICES[@]}${NC}"
    echo -e "   ${BLUE}Total: $((${#INSTALLED_SERVICES[@]} + ${#FAILED_SERVICES[@]}))${NC}"
    echo
    
    echo -e "${CYAN}📁 Log file: $LOG_FILE${NC}"
    echo -e "${CYAN}📅 Installation completed: $(date)${NC}"
    echo
    
    # Log summary
    log_message "SUMMARY" "Successfully installed: ${INSTALLED_SERVICES[*]}"
    log_message "SUMMARY" "Failed to install: ${FAILED_SERVICES[*]}"
    log_message "SUMMARY" "Installation completed at $(date)"
    
    if [[ ${#FAILED_SERVICES[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Some services failed to install. Check the log file for details.${NC}"
        return 1
    else
        echo -e "${GREEN}🎉 All database services installed successfully!${NC}"
        return 0
    fi
}

print_service_info() {
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                          Service Information                                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    for service in "${INSTALLED_SERVICES[@]}"; do
        case $service in
            "PostgreSQL")
                echo -e "${GREEN}PostgreSQL:${NC}"
                echo -e "  • Connect: psql -U $USER"
                echo -e "  • Admin user: postgres"
                echo -e "  • Default port: 5432"
                echo
                ;;
            "MariaDB")
                echo -e "${GREEN}MariaDB:${NC}"
                echo -e "  • Connect: mysql -u root -p"
                echo -e "  • Root password: secure_root_password_123"
                echo -e "  • Default port: 3306"
                echo
                ;;
            "MongoDB")
                echo -e "${GREEN}MongoDB:${NC}"
                echo -e "  • Connect: mongosh"
                echo -e "  • Default port: 27017"
                echo -e "  • Config: /etc/mongod.conf"
                echo
                ;;
            "SQLite")
                echo -e "${GREEN}SQLite:${NC}"
                echo -e "  • Command: sqlite3 <database_file>"
                echo -e "  • File-based database"
                echo
                ;;
            "Redis")
                echo -e "${GREEN}Redis:${NC}"
                echo -e "  • Connect: redis-cli"
                echo -e "  • Default port: 6379"
                echo -e "  • Test: redis-cli ping"
                echo
                ;;
        esac
    done
}

#=============================================================================
# Main Execution
#=============================================================================

main() {
    print_header
    
    # Pre-installation checks
    check_root
    check_sudo
    detect_os
    
    print_info "Starting database stack installation..."
    print_info "Log file: $LOG_FILE"
    echo
    
    # Update package manager
    if ! update_package_manager; then
        print_error "Failed to update package manager. Continuing anyway..."
    fi
    
    # Install databases
    install_database "PostgreSQL" "install_postgresql" "configure_postgresql" "test_postgresql"
    install_database "MariaDB" "install_mariadb" "configure_mariadb" "test_mariadb"
    install_database "MongoDB" "install_mongodb" "configure_mongodb" "test_mongodb"
    install_database "SQLite" "install_sqlite" "" "test_sqlite"
    install_database "Redis" "install_redis" "configure_redis" "test_redis"
    
    # Print results
    print_summary
    print_service_info
    
    # Return appropriate exit code
    if [[ ${#FAILED_SERVICES[@]} -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Trap to ensure cleanup on script exit
trap 'log_message "INFO" "Script execution terminated"' EXIT

# Run main function
main "$@"
