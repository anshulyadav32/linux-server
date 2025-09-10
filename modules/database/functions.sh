#!/bin/bash
# =============================================================================
# Linux Setup - Database Module Functions
# =============================================================================
# Author: Anshul Yadav
# Description: Core functions for database module management
# =============================================================================

# Load common functions
source "$(dirname "$0")/../common.sh" 2>/dev/null || true

# ==========================================
# MYSQL/MARIADB FUNCTIONS
# ==========================================

install_mysql() {
    print_step "Installing MySQL/MariaDB Server"
    
    # Install MariaDB (drop-in replacement for MySQL)
    apt-get update >/dev/null 2>&1
    apt-get install -y mariadb-server mariadb-client >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "MariaDB installed successfully"
        
        # Start and enable service
        systemctl start mariadb
        systemctl enable mariadb
        
        return 0
    else
        print_error "Failed to install MariaDB"
        return 1
    fi
}

check_mysql() {
    print_step "Checking MySQL/MariaDB installation"
    
    # Check if service exists
    if ! systemctl list-unit-files | grep -q "mariadb.service\|mysql.service"; then
        print_error "MySQL/MariaDB service not found"
        return 1
    fi
    
    # Check if service is active
    if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
        print_success "MySQL/MariaDB service is running"
        
        # Check if we can connect
        if mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
            print_success "MySQL/MariaDB connection test passed"
        else
            print_warning "MySQL/MariaDB service running but connection failed"
        fi
        
        return 0
    else
        print_error "MySQL/MariaDB service is not running"
        return 1
    fi
}

update_mysql() {
    print_step "Updating MySQL/MariaDB"
    
    # Check if installed first
    if ! check_mysql >/dev/null 2>&1; then
        print_error "MySQL/MariaDB not installed"
        return 1
    fi
    
    # Update packages
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y mariadb-server mariadb-client >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "MySQL/MariaDB updated successfully"
        
        # Restart service
        systemctl restart mariadb
        return 0
    else
        print_error "Failed to update MySQL/MariaDB"
        return 1
    fi
}

secure_mysql() {
    print_substep "Securing MySQL installation"
    
    # Set root password
    mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'admin123';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

    if [[ $? -eq 0 ]]; then
        print_success "MySQL secured successfully"
    else
        print_warning "Failed to secure MySQL"
    fi
}

create_mysql_database() {
    local db_name="$1"
    local db_user="${2:-$db_name}"
    local db_pass="${3:-$(openssl rand -base64 12)}"
    
    if [[ -z "$db_name" ]]; then
        print_error "Database name required"
        return 1
    fi
    
    print_substep "Creating MySQL database: $db_name"
    
    mysql -u root -padmin123 <<EOF
CREATE DATABASE IF NOT EXISTS \`$db_name\`;
CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';
GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
EOF

    if [[ $? -eq 0 ]]; then
        print_success "Database created: $db_name"
        echo "User: $db_user, Password: $db_pass" >> /root/database_credentials.txt
    else
        print_error "Failed to create database: $db_name"
        return 1
    fi
}

# ==========================================
# POSTGRESQL FUNCTIONS
# ==========================================

install_postgresql() {
    print_step "Installing PostgreSQL Server"
    
    apt-get update >/dev/null 2>&1
    apt-get install -y postgresql postgresql-contrib >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "PostgreSQL installed successfully"
        
        # Start and enable service
        systemctl start postgresql
        systemctl enable postgresql
        
        return 0
    else
        print_error "Failed to install PostgreSQL"
        return 1
    fi
}

check_postgresql() {
    print_step "Checking PostgreSQL installation"
    
    # Check if service exists
    if ! systemctl list-unit-files | grep -q "postgresql.service"; then
        print_error "PostgreSQL service not found"
        return 1
    fi
    
    # Check if service is active
    if systemctl is-active --quiet postgresql; then
        print_success "PostgreSQL service is running"
        
        # Check if we can connect
        if sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then
            print_success "PostgreSQL connection test passed"
        else
            print_warning "PostgreSQL service running but connection failed"
        fi
        
        return 0
    else
        print_error "PostgreSQL service is not running"
        return 1
    fi
}

update_postgresql() {
    print_step "Updating PostgreSQL"
    
    # Check if installed first
    if ! check_postgresql >/dev/null 2>&1; then
        print_error "PostgreSQL not installed"
        return 1
    fi
    
    # Update packages
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y postgresql postgresql-contrib >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "PostgreSQL updated successfully"
        
        # Restart service
        systemctl restart postgresql
        return 0
    else
        print_error "Failed to update PostgreSQL"
        return 1
    fi
}

setup_postgresql() {
    print_substep "Setting up PostgreSQL"
    
    # Set postgres user password
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'admin123';" >/dev/null 2>&1
    
    # Configure authentication
    local pg_version=$(sudo -u postgres psql -t -c "SELECT version();" | grep -o "PostgreSQL [0-9]\+\.[0-9]\+" | grep -o "[0-9]\+\.[0-9]\+")
    local pg_hba="/etc/postgresql/$pg_version/main/pg_hba.conf"
    
    if [[ -f "$pg_hba" ]]; then
        # Backup original
        cp "$pg_hba" "$pg_hba.backup"
        
        # Allow local connections with password
        sed -i 's/local   all             postgres                                peer/local   all             postgres                                md5/' "$pg_hba"
        
        # Restart PostgreSQL
        systemctl restart postgresql
        
        print_success "PostgreSQL configured"
    fi
}

create_postgresql_database() {
    local db_name="$1"
    local db_user="${2:-$db_name}"
    local db_pass="${3:-$(openssl rand -base64 12)}"
    
    if [[ -z "$db_name" ]]; then
        print_error "Database name required"
        return 1
    fi
    
    print_substep "Creating PostgreSQL database: $db_name"
    
    sudo -u postgres psql <<EOF
CREATE DATABASE "$db_name";
CREATE USER "$db_user" WITH ENCRYPTED PASSWORD '$db_pass';
GRANT ALL PRIVILEGES ON DATABASE "$db_name" TO "$db_user";
EOF

    if [[ $? -eq 0 ]]; then
        print_success "Database created: $db_name"
        echo "PostgreSQL - User: $db_user, Password: $db_pass, Database: $db_name" >> /root/database_credentials.txt
    else
        print_error "Failed to create database: $db_name"
        return 1
    fi
}

# ==========================================
# DATABASE MODULE MAIN FUNCTIONS
# ==========================================

install_database_module() {
    print_header "Installing Database Module"
    
    local mysql_success=0
    local postgresql_success=0
    
    # Install MySQL/MariaDB
    if install_mysql; then
        secure_mysql
        mysql_success=1
    fi
    
    # Install PostgreSQL
    if install_postgresql; then
        setup_postgresql
        postgresql_success=1
    fi
    
    # Install additional database tools
    print_step "Installing database management tools"
    apt-get install -y phpmyadmin adminer >/dev/null 2>&1
    
    if [[ $mysql_success -eq 1 && $postgresql_success -eq 1 ]]; then
        print_success "Database module installed successfully"
        return 0
    elif [[ $mysql_success -eq 1 || $postgresql_success -eq 1 ]]; then
        print_warning "Database module partially installed"
        return 0
    else
        print_error "Database module installation failed"
        return 1
    fi
}

check_database_module() {
    print_header "Checking Database Module"
    
    local mysql_status=0
    local postgresql_status=0
    
    # Check MySQL
    if check_mysql >/dev/null 2>&1; then
        mysql_status=1
    fi
    
    # Check PostgreSQL
    if check_postgresql >/dev/null 2>&1; then
        postgresql_status=1
    fi
    
    if [[ $mysql_status -eq 1 && $postgresql_status -eq 1 ]]; then
        print_success "Database module is fully operational"
        return 0
    elif [[ $mysql_status -eq 1 || $postgresql_status -eq 1 ]]; then
        print_warning "Database module is partially operational"
        return 0
    else
        print_error "Database module is not operational"
        return 1
    fi
}

update_database_module() {
    print_header "Updating Database Module"
    
    local mysql_updated=0
    local postgresql_updated=0
    
    # Update MySQL if installed
    if systemctl list-unit-files | grep -q "mariadb.service\|mysql.service"; then
        if update_mysql; then
            mysql_updated=1
        fi
    fi
    
    # Update PostgreSQL if installed
    if systemctl list-unit-files | grep -q "postgresql.service"; then
        if update_postgresql; then
            postgresql_updated=1
        fi
    fi
    
    # Update additional tools
    print_step "Updating database management tools"
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y phpmyadmin adminer >/dev/null 2>&1
    
    if [[ $mysql_updated -eq 1 || $postgresql_updated -eq 1 ]]; then
        print_success "Database module updated successfully"
        return 0
    else
        print_warning "No database systems to update"
        return 0
    fi
}

check_database_update() {
    print_header "Checking Database Module Updates"
    
    # Check for available updates
    apt-get update >/dev/null 2>&1
    
    local updates_available=0
    
    # Check MySQL/MariaDB updates
    if apt list --upgradable 2>/dev/null | grep -q "mariadb\|mysql"; then
        print_info "MySQL/MariaDB updates available"
        updates_available=1
    fi
    
    # Check PostgreSQL updates
    if apt list --upgradable 2>/dev/null | grep -q "postgresql"; then
        print_info "PostgreSQL updates available"
        updates_available=1
    fi
    
    if [[ $updates_available -eq 1 ]]; then
        print_warning "Database updates available"
        return 1
    else
        print_success "Database module is up to date"
        return 0
    fi
}

# ==========================================
# DATABASE BACKUP FUNCTIONS
# ==========================================

backup_databases() {
    print_step "Backing up databases"
    
    local backup_dir="/root/backups/databases"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    # Backup MySQL databases
    if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
        print_substep "Backing up MySQL databases"
        mysqldump -u root -padmin123 --all-databases > "$backup_dir/mysql_backup_$timestamp.sql" 2>/dev/null
        gzip "$backup_dir/mysql_backup_$timestamp.sql"
    fi
    
    # Backup PostgreSQL databases
    if systemctl is-active --quiet postgresql; then
        print_substep "Backing up PostgreSQL databases"
        sudo -u postgres pg_dumpall > "$backup_dir/postgresql_backup_$timestamp.sql" 2>/dev/null
        gzip "$backup_dir/postgresql_backup_$timestamp.sql"
    fi
    
    print_success "Database backups completed"
}
