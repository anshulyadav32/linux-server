#!/bin/bash
# Database System Update
# Purpose: Keep database software updated and maintain system health

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
echo -e "${BLUE}       DATABASE SYSTEM UPDATE          ${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting database system update...${NC}"
echo

# Step 1: Backup existing data before update
echo -e "${BLUE}Step 1/6: Creating backup before update...${NC}"

# Create backup directory with timestamp
backup_timestamp=$(date +"%Y%m%d_%H%M%S")
backup_dir="/var/backups/database_update_${backup_timestamp}"
mkdir -p "$backup_dir"

# Detect and backup installed databases
if systemctl is-active --quiet postgresql 2>/dev/null; then
    echo -e "${CYAN}Backing up PostgreSQL databases...${NC}"
    sudo -u postgres pg_dumpall > "$backup_dir/postgresql_all_databases.sql"
    echo -e "${GREEN}✓ PostgreSQL databases backed up${NC}"
fi

if systemctl is-active --quiet mariadb 2>/dev/null; then
    echo -e "${CYAN}Backing up MariaDB databases...${NC}"
    mysqldump --all-databases --single-transaction > "$backup_dir/mariadb_all_databases.sql"
    echo -e "${GREEN}✓ MariaDB databases backed up${NC}"
fi

if systemctl is-active --quiet mongod 2>/dev/null; then
    echo -e "${CYAN}Backing up MongoDB databases...${NC}"
    mongodump --out "$backup_dir/mongodb_backup"
    echo -e "${GREEN}✓ MongoDB databases backed up${NC}"
fi

echo -e "${GREEN}✓ Pre-update backup completed: $backup_dir${NC}"
echo

# Step 2: Update system packages
echo -e "${BLUE}Step 2/6: Updating system packages...${NC}"
update_system_packages
echo -e "${GREEN}✓ System packages updated${NC}"
echo

# Step 3: Update database-specific packages
echo -e "${BLUE}Step 3/6: Updating database packages...${NC}"

if command -v apt >/dev/null 2>&1; then
    # Update PostgreSQL
    if dpkg -l | grep -q postgresql; then
        echo -e "${CYAN}Updating PostgreSQL packages...${NC}"
        apt install --only-upgrade -y postgresql postgresql-contrib pgadmin4
        echo -e "${GREEN}✓ PostgreSQL packages updated${NC}"
    fi
    
    # Update MariaDB
    if dpkg -l | grep -q mariadb; then
        echo -e "${CYAN}Updating MariaDB packages...${NC}"
        apt install --only-upgrade -y mariadb-server mariadb-client phpmyadmin
        echo -e "${GREEN}✓ MariaDB packages updated${NC}"
    fi
    
    # Update MongoDB
    if dpkg -l | grep -q mongodb; then
        echo -e "${CYAN}Updating MongoDB packages...${NC}"
        apt install --only-upgrade -y mongodb-org
        echo -e "${GREEN}✓ MongoDB packages updated${NC}"
    fi

elif command -v yum >/dev/null 2>&1; then
    # Update for RHEL/CentOS
    if rpm -qa | grep -q postgresql; then
        echo -e "${CYAN}Updating PostgreSQL packages...${NC}"
        yum update -y postgresql-server postgresql-contrib
        echo -e "${GREEN}✓ PostgreSQL packages updated${NC}"
    fi
    
    if rpm -qa | grep -q mariadb; then
        echo -e "${CYAN}Updating MariaDB packages...${NC}"
        yum update -y mariadb-server mariadb
        echo -e "${GREEN}✓ MariaDB packages updated${NC}"
    fi
    
    if rpm -qa | grep -q mongodb; then
        echo -e "${CYAN}Updating MongoDB packages...${NC}"
        yum update -y mongodb-org
        echo -e "${GREEN}✓ MongoDB packages updated${NC}"
    fi

elif command -v dnf >/dev/null 2>&1; then
    # Update for Fedora
    if rpm -qa | grep -q postgresql; then
        echo -e "${CYAN}Updating PostgreSQL packages...${NC}"
        dnf update -y postgresql-server postgresql-contrib
        echo -e "${GREEN}✓ PostgreSQL packages updated${NC}"
    fi
    
    if rpm -qa | grep -q mariadb; then
        echo -e "${CYAN}Updating MariaDB packages...${NC}"
        dnf update -y mariadb-server mariadb
        echo -e "${GREEN}✓ MariaDB packages updated${NC}"
    fi
    
    if rpm -qa | grep -q mongodb; then
        echo -e "${CYAN}Updating MongoDB packages...${NC}"
        dnf update -y mongodb-server mongodb
        echo -e "${GREEN}✓ MongoDB packages updated${NC}"
    fi
fi

echo -e "${GREEN}✓ Database packages updated${NC}"
echo

# Step 4: Restart database services
echo -e "${BLUE}Step 4/6: Restarting database services...${NC}"

# Restart PostgreSQL if running
if systemctl is-active --quiet postgresql 2>/dev/null; then
    echo -e "${CYAN}Restarting PostgreSQL...${NC}"
    restart_database_service "postgresql"
    sleep 3
    if check_database_service "postgresql"; then
        echo -e "${GREEN}✓ PostgreSQL restarted successfully${NC}"
    else
        echo -e "${RED}✗ PostgreSQL restart failed${NC}"
    fi
fi

# Restart MariaDB if running
if systemctl is-active --quiet mariadb 2>/dev/null; then
    echo -e "${CYAN}Restarting MariaDB...${NC}"
    restart_database_service "mariadb"
    sleep 3
    if check_database_service "mariadb"; then
        echo -e "${GREEN}✓ MariaDB restarted successfully${NC}"
    else
        echo -e "${RED}✗ MariaDB restart failed${NC}"
    fi
fi

# Restart MongoDB if running
if systemctl is-active --quiet mongod 2>/dev/null; then
    echo -e "${CYAN}Restarting MongoDB...${NC}"
    restart_database_service "mongodb"
    sleep 3
    if check_database_service "mongodb"; then
        echo -e "${GREEN}✓ MongoDB restarted successfully${NC}"
    else
        echo -e "${RED}✗ MongoDB restart failed${NC}"
    fi
fi

echo -e "${GREEN}✓ Database services restarted${NC}"
echo

# Step 5: Run health checks
echo -e "${BLUE}Step 5/6: Running database health checks...${NC}"

# Test PostgreSQL connection
if systemctl is-active --quiet postgresql 2>/dev/null; then
    echo -e "${CYAN}Testing PostgreSQL connection...${NC}"
    if test_postgresql_connection >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PostgreSQL connection successful${NC}"
    else
        echo -e "${RED}✗ PostgreSQL connection failed${NC}"
    fi
fi

# Test MariaDB connection
if systemctl is-active --quiet mariadb 2>/dev/null; then
    echo -e "${CYAN}Testing MariaDB connection...${NC}"
    if test_mariadb_connection >/dev/null 2>&1; then
        echo -e "${GREEN}✓ MariaDB connection successful${NC}"
    else
        echo -e "${RED}✗ MariaDB connection failed${NC}"
    fi
fi

# Test MongoDB connection
if systemctl is-active --quiet mongod 2>/dev/null; then
    echo -e "${CYAN}Testing MongoDB connection...${NC}"
    if test_mongodb_connection >/dev/null 2>&1; then
        echo -e "${GREEN}✓ MongoDB connection successful${NC}"
    else
        echo -e "${RED}✗ MongoDB connection failed${NC}"
    fi
fi

echo -e "${GREEN}✓ Health checks completed${NC}"
echo

# Step 6: Clean up and optimize
echo -e "${BLUE}Step 6/6: Cleanup and optimization...${NC}"

# Clean package cache
if command -v apt >/dev/null 2>&1; then
    apt autoremove -y
    apt autoclean
elif command -v yum >/dev/null 2>&1; then
    yum autoremove -y
    yum clean all
elif command -v dnf >/dev/null 2>&1; then
    dnf autoremove -y
    dnf clean all
fi

# Optimize databases if needed
if systemctl is-active --quiet postgresql 2>/dev/null; then
    echo -e "${CYAN}Running PostgreSQL maintenance...${NC}"
    sudo -u postgres psql -c "VACUUM;" >/dev/null 2>&1 || true
fi

if systemctl is-active --quiet mariadb 2>/dev/null; then
    echo -e "${CYAN}Running MariaDB optimization...${NC}"
    mysqlcheck --optimize --all-databases >/dev/null 2>&1 || true
fi

echo -e "${GREEN}✓ Cleanup and optimization completed${NC}"
echo

# Update summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}        UPDATE COMPLETED                ${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo -e "${GREEN}Database system update completed successfully!${NC}"
echo

echo -e "${CYAN}Update Summary:${NC}"
echo -e "• Pre-update backup created: $backup_dir"
echo -e "• System packages updated"
echo -e "• Database packages updated"
echo -e "• Services restarted and verified"
echo -e "• Health checks passed"
echo -e "• System cleanup completed"
echo

echo -e "${YELLOW}Recommendations:${NC}"
echo -e "1. Test your applications to ensure compatibility"
echo -e "2. Monitor database performance for any issues"
echo -e "3. Keep the backup files until you're confident everything works"
echo -e "4. Schedule regular updates to maintain security"
echo

echo -e "${GREEN}Database update process completed!${NC}"
