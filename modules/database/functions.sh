#!/bin/bash
# Database System Helper Functions
# Purpose: Reusable functions for database management operations

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to update system packages
update_system_packages() {
    echo -e "${YELLOW}Updating system packages...${NC}"
    if command -v apt >/dev/null 2>&1; then
        apt update && apt upgrade -y
    elif command -v yum >/dev/null 2>&1; then
        yum update -y
    elif command -v dnf >/dev/null 2>&1; then
        dnf update -y
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Syu --noconfirm
    else
        echo -e "${RED}Package manager not supported${NC}"
        return 1
    fi
}

# Function to install PostgreSQL
install_postgresql() {
    echo -e "${YELLOW}Installing PostgreSQL...${NC}"
    if command -v apt >/dev/null 2>&1; then
        apt install -y postgresql postgresql-contrib pgadmin4
    elif command -v yum >/dev/null 2>&1; then
        yum install -y postgresql-server postgresql-contrib pgadmin4
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y postgresql-server postgresql-contrib pgadmin4
    elif command -v pacman >/dev/null 2>&1; then
        pacman -S --noconfirm postgresql pgadmin4
    else
        echo -e "${RED}Package manager not supported${NC}"
        return 1
    fi
}

# Function to install MariaDB
install_mariadb() {
    echo -e "${YELLOW}Installing MariaDB...${NC}"
    if command -v apt >/dev/null 2>&1; then
        apt install -y mariadb-server mariadb-client phpmyadmin
    elif command -v yum >/dev/null 2>&1; then
        yum install -y mariadb-server mariadb phpmyadmin
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y mariadb-server mariadb phpmyadmin
    elif command -v pacman >/dev/null 2>&1; then
        pacman -S --noconfirm mariadb phpmyadmin
    else
        echo -e "${RED}Package manager not supported${NC}"
        return 1
    fi
}

# Function to install MongoDB
install_mongodb() {
    echo -e "${YELLOW}Installing MongoDB...${NC}"
    if command -v apt >/dev/null 2>&1; then
        # Add MongoDB repository for Ubuntu/Debian
        wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        apt update
        apt install -y mongodb-org mongodb-compass
    elif command -v yum >/dev/null 2>&1; then
        # Add MongoDB repository for RHEL/CentOS
        cat > /etc/yum.repos.d/mongodb-org-7.0.repo << EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
        yum install -y mongodb-org
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y mongodb-server mongodb
    elif command -v pacman >/dev/null 2>&1; then
        pacman -S --noconfirm mongodb mongodb-tools
    else
        echo -e "${RED}Package manager not supported${NC}"
        return 1
    fi
}

# Function to enable and start database services
start_database_service() {
    local db_type=$1
    echo -e "${YELLOW}Starting $db_type service...${NC}"
    
    case $db_type in
        "postgresql")
            systemctl enable postgresql
            systemctl start postgresql
            ;;
        "mariadb"|"mysql")
            systemctl enable mariadb
            systemctl start mariadb
            ;;
        "mongodb")
            systemctl enable mongod
            systemctl start mongod
            ;;
        *)
            echo -e "${RED}Unknown database type: $db_type${NC}"
            return 1
            ;;
    esac
}

# Function to restart database services
restart_database_service() {
    local db_type=$1
    echo -e "${YELLOW}Restarting $db_type service...${NC}"
    
    case $db_type in
        "postgresql")
            systemctl restart postgresql
            ;;
        "mariadb"|"mysql")
            systemctl restart mariadb
            ;;
        "mongodb")
            systemctl restart mongod
            ;;
        *)
            echo -e "${RED}Unknown database type: $db_type${NC}"
            return 1
            ;;
    esac
}

# Function to check if database service is running
check_database_service() {
    local db_type=$1
    
    case $db_type in
        "postgresql")
            if systemctl is-active --quiet postgresql; then
                echo -e "${GREEN}PostgreSQL is running${NC}"
                return 0
            else
                echo -e "${RED}PostgreSQL is not running${NC}"
                return 1
            fi
            ;;
        "mariadb"|"mysql")
            if systemctl is-active --quiet mariadb; then
                echo -e "${GREEN}MariaDB is running${NC}"
                return 0
            else
                echo -e "${RED}MariaDB is not running${NC}"
                return 1
            fi
            ;;
        "mongodb")
            if systemctl is-active --quiet mongod; then
                echo -e "${GREEN}MongoDB is running${NC}"
                return 0
            else
                echo -e "${RED}MongoDB is not running${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}Unknown database type: $db_type${NC}"
            return 1
            ;;
    esac
}

# Function to create PostgreSQL test database and user
setup_postgresql_test() {
    echo -e "${YELLOW}Setting up PostgreSQL test database...${NC}"
    
    # Switch to postgres user and create test database
    sudo -u postgres psql -c "CREATE DATABASE testdb;"
    sudo -u postgres psql -c "CREATE USER testuser WITH PASSWORD 'testpass123';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE testdb TO testuser;"
    
    echo -e "${GREEN}PostgreSQL test database created successfully${NC}"
    echo -e "${CYAN}Database: testdb${NC}"
    echo -e "${CYAN}User: testuser${NC}"
    echo -e "${CYAN}Password: testpass123${NC}"
}

# Function to create MariaDB test database and user
setup_mariadb_test() {
    echo -e "${YELLOW}Setting up MariaDB test database...${NC}"
    
    # Create test database and user
    mysql -u root <<EOF
CREATE DATABASE testdb;
CREATE USER 'testuser'@'localhost' IDENTIFIED BY 'testpass123';
GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    echo -e "${GREEN}MariaDB test database created successfully${NC}"
    echo -e "${CYAN}Database: testdb${NC}"
    echo -e "${CYAN}User: testuser${NC}"
    echo -e "${CYAN}Password: testpass123${NC}"
}

# Function to create MongoDB test database and user
setup_mongodb_test() {
    echo -e "${YELLOW}Setting up MongoDB test database...${NC}"
    
    # Create test database and user
    mongo <<EOF
use testdb
db.createUser({
    user: "testuser",
    pwd: "testpass123",
    roles: [{ role: "readWrite", db: "testdb" }]
})
EOF
    
    echo -e "${GREEN}MongoDB test database created successfully${NC}"
    echo -e "${CYAN}Database: testdb${NC}"
    echo -e "${CYAN}User: testuser${NC}"
    echo -e "${CYAN}Password: testpass123${NC}"
}

# Function to run PostgreSQL test query
test_postgresql_connection() {
    echo -e "${YELLOW}Testing PostgreSQL connection...${NC}"
    
    # Test connection and list databases
    if sudo -u postgres psql -c "\l" >/dev/null 2>&1; then
        echo -e "${GREEN}PostgreSQL connection test successful${NC}"
        sudo -u postgres psql -c "\l" | head -10
        return 0
    else
        echo -e "${RED}PostgreSQL connection test failed${NC}"
        return 1
    fi
}

# Function to run MariaDB test query
test_mariadb_connection() {
    echo -e "${YELLOW}Testing MariaDB connection...${NC}"
    
    # Test connection and list databases
    if mysql -u root -e "SHOW DATABASES;" >/dev/null 2>&1; then
        echo -e "${GREEN}MariaDB connection test successful${NC}"
        mysql -u root -e "SHOW DATABASES;"
        return 0
    else
        echo -e "${RED}MariaDB connection test failed${NC}"
        return 1
    fi
}

# Function to run MongoDB test query
test_mongodb_connection() {
    echo -e "${YELLOW}Testing MongoDB connection...${NC}"
    
    # Test connection and list databases
    if mongo --eval "db.adminCommand('listDatabases')" >/dev/null 2>&1; then
        echo -e "${GREEN}MongoDB connection test successful${NC}"
        mongo --eval "db.adminCommand('listDatabases')"
        return 0
    else
        echo -e "${RED}MongoDB connection test failed${NC}"
        return 1
    fi
}

# Function to get database status
get_database_status() {
    local db_type=$1
    
    echo -e "${BLUE}=== Database Status Report ===${NC}"
    echo -e "${CYAN}Database Type: $db_type${NC}"
    echo
    
    # Check service status
    check_database_service "$db_type"
    
    # Show version information
    case $db_type in
        "postgresql")
            echo -e "${CYAN}PostgreSQL Version:${NC}"
            sudo -u postgres psql -c "SELECT version();" 2>/dev/null || echo "Unable to get version"
            ;;
        "mariadb"|"mysql")
            echo -e "${CYAN}MariaDB Version:${NC}"
            mysql -u root -e "SELECT VERSION();" 2>/dev/null || echo "Unable to get version"
            ;;
        "mongodb")
            echo -e "${CYAN}MongoDB Version:${NC}"
            mongo --eval "db.version()" 2>/dev/null || echo "Unable to get version"
            ;;
    esac
    
    echo
}

# Function to backup database
backup_database() {
    local db_type=$1
    local db_name=$2
    local backup_dir="/var/backups/databases"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"
    
    echo -e "${YELLOW}Backing up $db_type database: $db_name${NC}"
    
    case $db_type in
        "postgresql")
            sudo -u postgres pg_dump "$db_name" > "$backup_dir/${db_name}_postgresql_${timestamp}.sql"
            ;;
        "mariadb"|"mysql")
            mysqldump -u root "$db_name" > "$backup_dir/${db_name}_mariadb_${timestamp}.sql"
            ;;
        "mongodb")
            mongodump --db "$db_name" --out "$backup_dir/mongodb_${timestamp}"
            ;;
        *)
            echo -e "${RED}Unknown database type for backup: $db_type${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}Database backup completed: $backup_dir${NC}"
}

# Function to restore database
restore_database() {
    local db_type=$1
    local backup_file=$2
    local db_name=$3
    
    echo -e "${YELLOW}Restoring $db_type database from: $backup_file${NC}"
    
    if [[ ! -f "$backup_file" ]]; then
        echo -e "${RED}Backup file not found: $backup_file${NC}"
        return 1
    fi
    
    case $db_type in
        "postgresql")
            sudo -u postgres psql "$db_name" < "$backup_file"
            ;;
        "mariadb"|"mysql")
            mysql -u root "$db_name" < "$backup_file"
            ;;
        "mongodb")
            mongorestore "$backup_file"
            ;;
        *)
            echo -e "${RED}Unknown database type for restore: $db_type${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}Database restore completed${NC}"
}

# Function to secure database installation
secure_database() {
    local db_type=$1
    
    echo -e "${YELLOW}Securing $db_type installation...${NC}"
    
    case $db_type in
        "postgresql")
            # Configure PostgreSQL authentication
            echo -e "${CYAN}Configuring PostgreSQL authentication...${NC}"
            # Add security configurations here
            ;;
        "mariadb"|"mysql")
            echo -e "${CYAN}Running MariaDB security script...${NC}"
            mysql_secure_installation
            ;;
        "mongodb")
            echo -e "${CYAN}Enabling MongoDB authentication...${NC}"
            # Add MongoDB security configurations here
            ;;
    esac
}

# Function to show database logs
show_database_logs() {
    local db_type=$1
    local lines=${2:-50}
    
    echo -e "${YELLOW}Showing last $lines lines of $db_type logs:${NC}"
    
    case $db_type in
        "postgresql")
            journalctl -u postgresql -n "$lines" --no-pager
            ;;
        "mariadb"|"mysql")
            journalctl -u mariadb -n "$lines" --no-pager
            ;;
        "mongodb")
            journalctl -u mongod -n "$lines" --no-pager
            ;;
        *)
            echo -e "${RED}Unknown database type: $db_type${NC}"
            return 1
            ;;
    esac
}
