#!/bin/bash
# Database System Installation
# Purpose: Automated setup of database server infrastructure

# Quick install from remote source
# curl -sSL ls.r-u.live/database.sh | sudo bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print step headers
print_step() {
    echo -e "\n${YELLOW}Step $1/$2: $3...${NC}"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif [ -f /etc/debian_version ]; then
        OS="Debian"
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        OS="RedHat"
        VER=$(rpm -qa \*-release | grep -v "^(redhat|centos)-release" | cut -d"-" -f3)
    else
        OS="Unknown"
        VER="Unknown"
    fi
}

# Function to update system
update_system() {
    echo -e "${YELLOW}Updating system packages...${NC}"
    detect_os
    case $OS in
        *Ubuntu*|*Debian*)
            apt-get update && apt-get upgrade -y
            ;;
        *CentOS*|*RedHat*|*Fedora*)
            yum update -y
            ;;
        *Arch*)
            pacman -Syu --noconfirm
            ;;
        *)
            echo -e "${RED}Unsupported operating system${NC}"
            exit 1
            ;;
    esac
}

# Function to install PostgreSQL
install_postgresql() {
    echo -e "${YELLOW}Installing PostgreSQL...${NC}"
    detect_os
    case $OS in
        *Ubuntu*|*Debian*)
            apt-get install -y postgresql postgresql-contrib postgresql-client pgadmin4
            ;;
        *CentOS*|*RedHat*|*Fedora*)
            yum install -y postgresql-server postgresql-contrib pgadmin4
            postgresql-setup --initdb
            ;;
        *Arch*)
            pacman -S --noconfirm postgresql pgadmin4
            ;;
    esac
    systemctl start postgresql
    systemctl enable postgresql
}

# Function to install MariaDB
install_mariadb() {
    echo -e "${YELLOW}Installing MariaDB...${NC}"
    detect_os
    case $OS in
        *Ubuntu*|*Debian*)
            apt-get install -y mariadb-server mariadb-client phpmyadmin
            ;;
        *CentOS*|*RedHat*|*Fedora*)
            yum install -y mariadb-server mariadb phpmyadmin
            ;;
        *Arch*)
            pacman -S --noconfirm mariadb phpmyadmin
            mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
            ;;
    esac
    systemctl start mariadb
    systemctl enable mariadb
    mysql_secure_installation
}

# Function to install MongoDB
install_mongodb() {
    echo -e "${YELLOW}Installing MongoDB...${NC}"
    detect_os
    case $OS in
        *Ubuntu*|*Debian*)
            wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
            echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
            apt-get update
            apt-get install -y mongodb-org mongodb-compass
            ;;
        *CentOS*|*RedHat*|*Fedora*)
            echo "[mongodb-org-6.0]" | tee /etc/yum.repos.d/mongodb-org-6.0.repo
            echo "name=MongoDB Repository" | tee -a /etc/yum.repos.d/mongodb-org-6.0.repo
            echo "baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/6.0/x86_64/" | tee -a /etc/yum.repos.d/mongodb-org-6.0.repo
            echo "gpgcheck=1" | tee -a /etc/yum.repos.d/mongodb-org-6.0.repo
            echo "enabled=1" | tee -a /etc/yum.repos.d/mongodb-org-6.0.repo
            yum install -y mongodb-org mongodb-compass
            ;;
        *Arch*)
            pacman -S --noconfirm mongodb-bin mongodb-compass
            ;;
    esac
    systemctl start mongod
    systemctl enable mongod
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}      DATABASE SYSTEM INSTALLATION     ${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Function to show database options
show_database_options() {
    echo -e "${CYAN}Available Database Systems:${NC}"
    echo -e "${GREEN}1)${NC} PostgreSQL + pgAdmin (Enterprise-grade)"
    echo -e "${GREEN}2)${NC} MariaDB + phpMyAdmin (MySQL alternative)"
    echo -e "${GREEN}3)${NC} MongoDB + Compass (NoSQL document database)"
    echo -e "${GREEN}4)${NC} Install All (PostgreSQL + MariaDB + MongoDB)"
    echo
}


# Function to get user choice (non-interactive)
get_database_choice() {
    show_database_options
    # Priority: first argument, environment variable, REPLY, else default to 4
    if [ -n "$1" ]; then
        db_choice="$1"
    elif [ -n "$DB_CHOICE" ]; then
        db_choice="$DB_CHOICE"
    elif [ -n "$REPLY" ]; then
        db_choice="$REPLY"
    else
        db_choice="4"
        echo -e "${YELLOW}No selection provided. Defaulting to Install All.${NC}"
    fi
    case $db_choice in
        1|2|3|4)
            echo $db_choice
            return 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please select 1-4.${NC}"
            return 1
            ;;
    esac
}

echo -e "${YELLOW}Starting database system installation...${NC}"
echo

# Step 1: System Update
echo -e "${BLUE}Step 1/8: Updating system packages...${NC}"
update_system
echo -e "${GREEN}✓ System packages updated${NC}"
echo


# Step 2: Get database choice
echo -e "${BLUE}Step 2/8: Database selection...${NC}"
user_choice=$(get_database_choice "$1")
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Invalid database selection${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Database system selected${NC}"
echo

# Step 3: Install selected database(s)
echo -e "${BLUE}Step 3/8: Installing database software...${NC}"

install_postgresql_flag=false
install_mariadb_flag=false
install_mongodb_flag=false

case $user_choice in
    1)
        install_postgresql
        install_postgresql_flag=true
        echo -e "${GREEN}✓ PostgreSQL installed${NC}"
        ;;
    2)
        install_mariadb
        install_mariadb_flag=true
        echo -e "${GREEN}✓ MariaDB installed${NC}"
        ;;
    3)
        install_mongodb
        install_mongodb_flag=true
        echo -e "${GREEN}✓ MongoDB installed${NC}"
        ;;
    4)
        install_postgresql
        install_mariadb
        install_mongodb
        install_postgresql_flag=true
        install_mariadb_flag=true
        install_mongodb_flag=true
        echo -e "${GREEN}✓ All database systems installed${NC}"
        ;;
esac
echo

# Step 4: Start and enable services
echo -e "${BLUE}Step 4/8: Starting database services...${NC}"

if $install_postgresql_flag; then
    start_database_service "postgresql"
    echo -e "${GREEN}✓ PostgreSQL service started${NC}"
fi

if $install_mariadb_flag; then
    start_database_service "mariadb"
    echo -e "${GREEN}✓ MariaDB service started${NC}"
fi

if $install_mongodb_flag; then
    start_database_service "mongodb"
    echo -e "${GREEN}✓ MongoDB service started${NC}"
fi
echo

# Step 5: Configure firewall
echo -e "${BLUE}Step 5/8: Configuring firewall rules...${NC}"

if command -v ufw >/dev/null 2>&1; then
    if $install_postgresql_flag; then
        ufw allow 5432/tcp comment "PostgreSQL"
        echo -e "${CYAN}✓ PostgreSQL port 5432 opened${NC}"
    fi
    
    if $install_mariadb_flag; then
        ufw allow 3306/tcp comment "MariaDB"
        echo -e "${CYAN}✓ MariaDB port 3306 opened${NC}"
    fi
    
    if $install_mongodb_flag; then
        ufw allow 27017/tcp comment "MongoDB"
        echo -e "${CYAN}✓ MongoDB port 27017 opened${NC}"
    fi
elif command -v firewall-cmd >/dev/null 2>&1; then
    if $install_postgresql_flag; then
        firewall-cmd --permanent --add-port=5432/tcp
        echo -e "${CYAN}✓ PostgreSQL port 5432 opened${NC}"
    fi
    
    if $install_mariadb_flag; then
        firewall-cmd --permanent --add-port=3306/tcp
        echo -e "${CYAN}✓ MariaDB port 3306 opened${NC}"
    fi
    
    if $install_mongodb_flag; then
        firewall-cmd --permanent --add-port=27017/tcp
        echo -e "${CYAN}✓ MongoDB port 27017 opened${NC}"
    fi
    
    firewall-cmd --reload
fi
echo -e "${GREEN}✓ Firewall configured${NC}"
echo

# Step 6: Create test databases and users
echo -e "${BLUE}Step 6/8: Creating test databases and users...${NC}"

if $install_postgresql_flag; then
    setup_postgresql_test
fi

if $install_mariadb_flag; then
    setup_mariadb_test
fi

if $install_mongodb_flag; then
    setup_mongodb_test
fi
echo -e "${GREEN}✓ Test databases created${NC}"
echo

# Step 7: Run connection tests
echo -e "${BLUE}Step 7/8: Testing database connections...${NC}"

if $install_postgresql_flag; then
    test_postgresql_connection
fi

if $install_mariadb_flag; then
    test_mariadb_connection
fi

if $install_mongodb_flag; then
    test_mongodb_connection
fi
echo -e "${GREEN}✓ Connection tests completed${NC}"
echo

# Step 8: Security configuration
echo -e "${BLUE}Step 8/8: Configuring security settings...${NC}"

if $install_mariadb_flag; then
    echo -e "${YELLOW}MariaDB security configuration will be interactive...${NC}"
    read -p "Press Enter to continue with MariaDB security setup..."
    secure_database "mariadb"
fi

echo -e "${GREEN}✓ Security configuration completed${NC}"
echo

# Installation summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}      INSTALLATION COMPLETED           ${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo -e "${GREEN}Database system(s) installed successfully!${NC}"
echo

if $install_postgresql_flag; then
    echo -e "${CYAN}PostgreSQL Information:${NC}"
    echo -e "  Service: systemctl status postgresql"
    echo -e "  Connect: sudo -u postgres psql"
    echo -e "  Test DB: testdb (user: testuser, pass: testpass123)"
    echo
fi

if $install_mariadb_flag; then
    echo -e "${CYAN}MariaDB Information:${NC}"
    echo -e "  Service: systemctl status mariadb"
    echo -e "  Connect: mysql -u root -p"
    echo -e "  Test DB: testdb (user: testuser, pass: testpass123)"
    echo
fi

if $install_mongodb_flag; then
    echo -e "${CYAN}MongoDB Information:${NC}"
    echo -e "  Service: systemctl status mongod"
    echo -e "  Connect: mongo"
    echo -e "  Test DB: testdb (user: testuser, pass: testpass123)"
    echo
fi

echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Test database connections using the commands above"
echo -e "2. Configure additional users and databases as needed"
echo -e "3. Set up regular backups using the backup module"
echo -e "4. Configure monitoring and maintenance schedules"
echo

echo -e "${GREEN}Database installation completed successfully!${NC}"
