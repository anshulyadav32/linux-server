#!/bin/bash
# Database Functions Library
# Reusable functions for database server management

#===========================================
# INSTALLATION FUNCTIONS
#===========================================

install_mysql() {
    echo "[INFO] Installing MySQL server..."
    
    # Set non-interactive mode
    export DEBIAN_FRONTEND=noninteractive
    
    # Update package list
    apt update -y
    
    # Install MySQL server
    apt install -y mysql-server mysql-client
    
    # Secure MySQL installation
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'admin123';"
    mysql -u root -padmin123 -e "DELETE FROM mysql.user WHERE User='';"
    mysql -u root -padmin123 -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -u root -padmin123 -e "DROP DATABASE IF EXISTS test;"
    mysql -u root -padmin123 -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    mysql -u root -padmin123 -e "FLUSH PRIVILEGES;"
    
    # Start and enable MySQL
    systemctl enable mysql
    systemctl start mysql
    
    configure_mysql_defaults
    echo "[SUCCESS] MySQL server installed"
}

install_postgresql() {
    echo "[INFO] Installing PostgreSQL server..."
    
    # Update package list
    apt update -y
    
    # Install PostgreSQL
    apt install -y postgresql postgresql-contrib postgresql-client
    
    # Start and enable PostgreSQL
    systemctl enable postgresql
    systemctl start postgresql
    
    # Set password for postgres user
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'admin123';"
    
    configure_postgresql_defaults
    echo "[SUCCESS] PostgreSQL server installed"
}

install_db() {
    local db_type="$1"
    
    case "$db_type" in
        "mysql"|"MySQL")
            install_mysql
            ;;
        "postgresql"|"postgres"|"PostgreSQL")
            install_postgresql
            ;;
        *)
            echo "[ERROR] Supported database types: mysql, postgresql"
            return 1
            ;;
    esac
}

configure_mysql_defaults() {
    echo "[INFO] Configuring MySQL defaults..."
    
    # Create custom configuration
    cat > /etc/mysql/mysql.conf.d/custom.cnf << 'EOF'
[mysqld]
# Basic settings
bind-address = 0.0.0.0
max_connections = 200
innodb_buffer_pool_size = 256M

# Security settings
local_infile = 0
skip_symbolic_links

# Logging
general_log = 1
general_log_file = /var/log/mysql/general.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
EOF
    
    restart_mysql
}

configure_postgresql_defaults() {
    echo "[INFO] Configuring PostgreSQL defaults..."
    
    # Update postgresql.conf
    PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1)
    PG_CONFIG="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
    
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONFIG"
    sed -i "s/#max_connections = 100/max_connections = 200/" "$PG_CONFIG"
    sed -i "s/#shared_buffers = 128MB/shared_buffers = 256MB/" "$PG_CONFIG"
    
    # Update pg_hba.conf for authentication
    PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
    echo "host all all 0.0.0.0/0 md5" >> "$PG_HBA"
    
    restart_postgresql
}

#===========================================
# DATABASE MANAGEMENT FUNCTIONS
#===========================================

create_mysql_db() {
    local db_name="$1"
    local db_user="$2"
    local db_password="$3"
    
    if [[ -z "$db_name" || -z "$db_user" || -z "$db_password" ]]; then
        echo "[ERROR] Database name, user, and password parameters required"
        return 1
    fi
    
    echo "[INFO] Creating MySQL database: $db_name"
    
    mysql -u root -padmin123 << EOF
CREATE DATABASE IF NOT EXISTS $db_name;
CREATE USER IF NOT EXISTS '$db_user'@'%' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%';
FLUSH PRIVILEGES;
EOF
    
    echo "[SUCCESS] MySQL database $db_name created with user $db_user"
}

create_postgresql_db() {
    local db_name="$1"
    local db_user="$2"
    local db_password="$3"
    
    if [[ -z "$db_name" || -z "$db_user" || -z "$db_password" ]]; then
        echo "[ERROR] Database name, user, and password parameters required"
        return 1
    fi
    
    echo "[INFO] Creating PostgreSQL database: $db_name"
    
    sudo -u postgres psql << EOF
CREATE DATABASE $db_name;
CREATE USER $db_user WITH ENCRYPTED PASSWORD '$db_password';
GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;
EOF
    
    echo "[SUCCESS] PostgreSQL database $db_name created with user $db_user"
}

drop_mysql_db() {
    local db_name="$1"
    
    if [[ -z "$db_name" ]]; then
        echo "[ERROR] Database name parameter required"
        return 1
    fi
    
    echo "[WARNING] This will permanently delete database: $db_name"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        mysql -u root -padmin123 -e "DROP DATABASE IF EXISTS $db_name;"
        echo "[SUCCESS] Database $db_name dropped"
    else
        echo "[INFO] Operation cancelled"
    fi
}

drop_postgresql_db() {
    local db_name="$1"
    
    if [[ -z "$db_name" ]]; then
        echo "[ERROR] Database name parameter required"
        return 1
    fi
    
    echo "[WARNING] This will permanently delete database: $db_name"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sudo -u postgres dropdb "$db_name"
        echo "[SUCCESS] Database $db_name dropped"
    else
        echo "[INFO] Operation cancelled"
    fi
}

list_mysql_databases() {
    echo "[INFO] MySQL databases:"
    mysql -u root -padmin123 -e "SHOW DATABASES;" | grep -v -E "^(Database|information_schema|mysql|performance_schema|sys)$"
}

list_postgresql_databases() {
    echo "[INFO] PostgreSQL databases:"
    sudo -u postgres psql -l | grep -v -E "^(List|Name|template|postgres|\-|\()" | awk '{print $1}' | grep -v "^$"
}

#===========================================
# USER MANAGEMENT FUNCTIONS
#===========================================

create_mysql_user() {
    local username="$1"
    local password="$2"
    local privileges="${3:-SELECT,INSERT,UPDATE,DELETE}"
    
    if [[ -z "$username" || -z "$password" ]]; then
        echo "[ERROR] Username and password parameters required"
        return 1
    fi
    
    echo "[INFO] Creating MySQL user: $username"
    
    mysql -u root -padmin123 << EOF
CREATE USER IF NOT EXISTS '$username'@'%' IDENTIFIED BY '$password';
GRANT $privileges ON *.* TO '$username'@'%';
FLUSH PRIVILEGES;
EOF
    
    echo "[SUCCESS] MySQL user $username created"
}

create_postgresql_user() {
    local username="$1"
    local password="$2"
    
    if [[ -z "$username" || -z "$password" ]]; then
        echo "[ERROR] Username and password parameters required"
        return 1
    fi
    
    echo "[INFO] Creating PostgreSQL user: $username"
    
    sudo -u postgres psql << EOF
CREATE USER $username WITH ENCRYPTED PASSWORD '$password';
EOF
    
    echo "[SUCCESS] PostgreSQL user $username created"
}

#===========================================
# BACKUP FUNCTIONS
#===========================================

backup_mysql_db() {
    local db_name="$1"
    local backup_path="${2:-/root/mysql-backup-$(date +%Y%m%d_%H%M%S).sql}"
    
    if [[ -z "$db_name" ]]; then
        echo "[ERROR] Database name parameter required"
        return 1
    fi
    
    echo "[INFO] Backing up MySQL database: $db_name"
    
    mysqldump -u root -padmin123 "$db_name" > "$backup_path"
    
    if [[ -f "$backup_path" ]]; then
        gzip "$backup_path"
        echo "[SUCCESS] Database backed up to: $backup_path.gz"
    else
        echo "[ERROR] Backup failed"
        return 1
    fi
}

backup_postgresql_db() {
    local db_name="$1"
    local backup_path="${2:-/root/postgresql-backup-$(date +%Y%m%d_%H%M%S).sql}"
    
    if [[ -z "$db_name" ]]; then
        echo "[ERROR] Database name parameter required"
        return 1
    fi
    
    echo "[INFO] Backing up PostgreSQL database: $db_name"
    
    sudo -u postgres pg_dump "$db_name" > "$backup_path"
    
    if [[ -f "$backup_path" ]]; then
        gzip "$backup_path"
        echo "[SUCCESS] Database backed up to: $backup_path.gz"
    else
        echo "[ERROR] Backup failed"
        return 1
    fi
}

backup_all_mysql() {
    local backup_dir="/root/mysql-full-backup-$(date +%Y%m%d_%H%M%S)"
    echo "[INFO] Backing up all MySQL databases..."
    
    mkdir -p "$backup_dir"
    mysqldump -u root -padmin123 --all-databases > "$backup_dir/all-databases.sql"
    
    tar -czf "$backup_dir.tar.gz" -C "$(dirname $backup_dir)" "$(basename $backup_dir)"
    rm -rf "$backup_dir"
    
    echo "[SUCCESS] All databases backed up to: $backup_dir.tar.gz"
}

backup_all_postgresql() {
    local backup_dir="/root/postgresql-full-backup-$(date +%Y%m%d_%H%M%S)"
    echo "[INFO] Backing up all PostgreSQL databases..."
    
    mkdir -p "$backup_dir"
    sudo -u postgres pg_dumpall > "$backup_dir/all-databases.sql"
    
    tar -czf "$backup_dir.tar.gz" -C "$(dirname $backup_dir)" "$(basename $backup_dir)"
    rm -rf "$backup_dir"
    
    echo "[SUCCESS] All databases backed up to: $backup_dir.tar.gz"
}

restore_mysql_db() {
    local db_name="$1"
    local backup_file="$2"
    
    if [[ -z "$db_name" || -z "$backup_file" ]]; then
        echo "[ERROR] Database name and backup file parameters required"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        echo "[ERROR] Backup file not found: $backup_file"
        return 1
    fi
    
    echo "[INFO] Restoring MySQL database: $db_name"
    
    # Handle compressed files
    if [[ "$backup_file" == *.gz ]]; then
        zcat "$backup_file" | mysql -u root -padmin123 "$db_name"
    else
        mysql -u root -padmin123 "$db_name" < "$backup_file"
    fi
    
    echo "[SUCCESS] Database $db_name restored"
}

restore_postgresql_db() {
    local db_name="$1"
    local backup_file="$2"
    
    if [[ -z "$db_name" || -z "$backup_file" ]]; then
        echo "[ERROR] Database name and backup file parameters required"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        echo "[ERROR] Backup file not found: $backup_file"
        return 1
    fi
    
    echo "[INFO] Restoring PostgreSQL database: $db_name"
    
    # Handle compressed files
    if [[ "$backup_file" == *.gz ]]; then
        zcat "$backup_file" | sudo -u postgres psql "$db_name"
    else
        sudo -u postgres psql "$db_name" < "$backup_file"
    fi
    
    echo "[SUCCESS] Database $db_name restored"
}

#===========================================
# SERVICE MANAGEMENT FUNCTIONS
#===========================================

restart_mysql() {
    echo "[INFO] Restarting MySQL..."
    systemctl restart mysql
    if systemctl is-active --quiet mysql; then
        echo "[SUCCESS] MySQL restarted successfully"
    else
        echo "[ERROR] MySQL failed to restart"
        return 1
    fi
}

restart_postgresql() {
    echo "[INFO] Restarting PostgreSQL..."
    systemctl restart postgresql
    if systemctl is-active --quiet postgresql; then
        echo "[SUCCESS] PostgreSQL restarted successfully"
    else
        echo "[ERROR] PostgreSQL failed to restart"
        return 1
    fi
}

restart_db_services() {
    echo "[INFO] Restarting database services..."
    
    if systemctl is-active --quiet mysql; then
        restart_mysql
    fi
    
    if systemctl is-active --quiet postgresql; then
        restart_postgresql
    fi
}

status_db_services() {
    echo "[INFO] Database service status:"
    
    if systemctl is-enabled mysql &>/dev/null; then
        echo "=== MySQL ==="
        systemctl status mysql --no-pager | head -5
        echo ""
    fi
    
    if systemctl is-enabled postgresql &>/dev/null; then
        echo "=== PostgreSQL ==="
        systemctl status postgresql --no-pager | head -5
        echo ""
    fi
    
    echo "Listening ports:"
    netstat -tlnp | grep -E ":3306|:5432"
}

#===========================================
# MONITORING FUNCTIONS
#===========================================

view_mysql_logs() {
    echo "[INFO] Recent MySQL logs:"
    tail -30 /var/log/mysql/error.log
}

view_postgresql_logs() {
    echo "[INFO] Recent PostgreSQL logs:"
    journalctl -u postgresql -n 20 --no-pager
}

mysql_process_list() {
    echo "[INFO] MySQL process list:"
    mysql -u root -padmin123 -e "SHOW PROCESSLIST;"
}

postgresql_activity() {
    echo "[INFO] PostgreSQL activity:"
    sudo -u postgres psql -c "SELECT pid, usename, application_name, client_addr, state, query FROM pg_stat_activity WHERE state = 'active';"
}

#===========================================
# UPDATE FUNCTIONS
#===========================================

update_mysql() {
    echo "[INFO] Updating MySQL server..."
    apt update -y
    apt upgrade -y mysql-server mysql-client
    restart_mysql
    echo "[SUCCESS] MySQL server updated"
}

update_postgresql() {
    echo "[INFO] Updating PostgreSQL server..."
    apt update -y
    apt upgrade -y postgresql postgresql-contrib postgresql-client
    restart_postgresql
    echo "[SUCCESS] PostgreSQL server updated"
}

update_db() {
    echo "[INFO] Updating database servers..."
    
    if systemctl is-enabled mysql &>/dev/null; then
        update_mysql
    fi
    
    if systemctl is-enabled postgresql &>/dev/null; then
        update_postgresql
    fi
}
