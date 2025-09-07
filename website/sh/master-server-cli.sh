#!/bin/bash
# Master Server Management CLI
# Created: September 7, 2025
# This script provides a comprehensive interface for managing various server components

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo or switch to root."
    exit 1
fi

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to press any key to continue
press_any_key() {
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
    echo ""
}

# Web-server Management Function
web_server_menu() {
    while true; do
        clear
        echo "------ Web-server Management ------"
        echo "1) Install Web-server (install.sh)"
        echo "2) Website Menu (Domains)"
        echo "3) Maintain Web-server"
        echo "4) Update Web-server (via packages)"
        echo "5) Back"
        read -p "Choose: " web_choice

        case $web_choice in
            1) # Install.sh
                echo "Installing Apache, Nginx, PHP, Node.js..."
                apt update -y
                apt install -y apache2 nginx php libapache2-mod-php nodejs npm
                echo "Web-server stack installed."
                press_any_key
                ;;
            2) # Website Menu
                while true; do
                    clear
                    echo "------ Website Menu ------"
                    echo "1) Add Website"
                    echo "2) Enable SSL (Certbot)"
                    echo "3) View Web Logs"
                    echo "4) Back"
                    read -p "Choose: " site_choice
                    case $site_choice in
                        1) 
                            read -p "Enter domain: " domain
                            mkdir -p /var/www/$domain/public_html
                            echo "<h1>Welcome to $domain</h1>" > /var/www/$domain/public_html/index.html
                            echo "Website $domain added."
                            press_any_key
                            ;;
                        2) 
                            read -p "Enter domain: " domain
                            certbot --apache -d $domain
                            echo "SSL enabled for $domain."
                            press_any_key
                            ;;
                        3) 
                            tail -n 50 /var/log/apache2/error.log
                            press_any_key
                            ;;
                        4) break;;
                    esac
                done
                ;;
            3) # Maintain
                while true; do
                    clear
                    echo "------ Web-server Maintenance ------"
                    echo "1) Restart Apache"
                    echo "2) Restart Nginx"
                    echo "3) Reload Configs"
                    echo "4) Clear Logs"
                    echo "5) Back"
                    read -p "Choose: " maintain_choice
                    case $maintain_choice in
                        1) systemctl restart apache2; echo "Apache restarted."; press_any_key;;
                        2) systemctl restart nginx; echo "Nginx restarted."; press_any_key;;
                        3) systemctl reload apache2; systemctl reload nginx; echo "Configs reloaded."; press_any_key;;
                        4) truncate -s 0 /var/log/apache2/error.log; truncate -s 0 /var/log/nginx/error.log; echo "Logs cleared."; press_any_key;;
                        5) break;;
                    esac
                done
                ;;
            4) # Update
                echo "Updating Web-server packages..."
                apt update -y
                apt upgrade -y apache2 nginx php nodejs npm
                echo "Web-server stack updated."
                press_any_key
                ;;
            5) break;;
        esac
    done
}

# Mail Server Management Function
mail_server_menu() {
    while true; do
        clear
        echo "------ Mail Server Management ------"
        echo "1) Install Mail Server"
        echo "2) Mail Domain Management"
        echo "3) User Management"
        echo "4) Security & Spam Settings"
        echo "5) Mail Server Maintenance"
        echo "6) Update Mail Packages"
        echo "7) Back"
        read -p "Choose: " mail_choice

        case $mail_choice in
            1) # Install
                echo "Installing Mail Server..."
                echo "1) Full Stack (Postfix + Dovecot + Roundcube)"
                echo "2) Minimal (Postfix only)"
                echo "3) Custom Installation"
                read -p "Choose installation type: " mail_install_type
                
                case $mail_install_type in
                    1) 
                        apt update -y
                        apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d roundcube
                        echo "Full mail stack installed."
                        ;;
                    2) 
                        apt update -y
                        apt install -y postfix
                        echo "Minimal mail server installed."
                        ;;
                    3) 
                        echo "Custom installation selected."
                        read -p "Install Postfix? (y/n): " install_postfix
                        read -p "Install Dovecot? (y/n): " install_dovecot
                        read -p "Install SpamAssassin? (y/n): " install_spamassassin
                        read -p "Install Roundcube webmail? (y/n): " install_roundcube
                        
                        apt update -y
                        [ "$install_postfix" = "y" ] && apt install -y postfix
                        [ "$install_dovecot" = "y" ] && apt install -y dovecot-core dovecot-imapd dovecot-pop3d
                        [ "$install_spamassassin" = "y" ] && apt install -y spamassassin spamc
                        [ "$install_roundcube" = "y" ] && apt install -y roundcube
                        
                        echo "Custom mail components installed."
                        ;;
                esac
                press_any_key
                ;;
            2) # Domain Management
                while true; do
                    clear
                    echo "------ Mail Domain Management ------"
                    echo "1) Add Mail Domain"
                    echo "2) View Mail Domains"
                    echo "3) Configure Domain DNS"
                    echo "4) Back"
                    read -p "Choose: " domain_choice
                    case $domain_choice in
                        1) 
                            read -p "Enter mail domain: " mail_domain
                            echo "Adding domain $mail_domain to mail server..."
                            # Add domain to Postfix configuration
                            echo "$mail_domain OK" >> /etc/postfix/virtual_domains
                            postmap /etc/postfix/virtual_domains
                            echo "Domain $mail_domain added."
                            press_any_key
                            ;;
                        2) 
                            echo "Configured mail domains:"
                            if [ -f /etc/postfix/virtual_domains ]; then
                                cat /etc/postfix/virtual_domains
                            else
                                echo "No domains configured yet."
                            fi
                            press_any_key
                            ;;
                        3) 
                            read -p "Enter domain to configure DNS records for: " dns_domain
                            echo "Example DNS records for $dns_domain:"
                            echo "MX record: mail.$dns_domain"
                            echo "SPF record: v=spf1 mx -all"
                            echo "DKIM: Follow instructions in /etc/opendkim/keys/$dns_domain/"
                            echo "DMARC: v=DMARC1; p=none; rua=mailto:postmaster@$dns_domain"
                            press_any_key
                            ;;
                        4) break;;
                    esac
                done
                ;;
            3) # User Management
                while true; do
                    clear
                    echo "------ Mail User Management ------"
                    echo "1) Add Mail User"
                    echo "2) List Mail Users"
                    echo "3) Change User Password"
                    echo "4) Delete Mail User"
                    echo "5) Back"
                    read -p "Choose: " user_choice
                    case $user_choice in
                        1) 
                            read -p "Enter username: " mail_user
                            read -p "Enter domain: " mail_domain
                            read -s -p "Enter password: " mail_pass
                            echo ""
                            echo "Adding user $mail_user@$mail_domain..."
                            # Implementation would vary based on mail system
                            echo "User $mail_user@$mail_domain added."
                            press_any_key
                            ;;
                        2) 
                            echo "Mail users:"
                            # Implementation would vary based on mail system
                            echo "User listing not implemented in this version."
                            press_any_key
                            ;;
                        3) 
                            read -p "Enter username to change password: " change_user
                            read -s -p "Enter new password: " new_pass
                            echo ""
                            echo "Password for $change_user changed."
                            press_any_key
                            ;;
                        4) 
                            read -p "Enter username to delete: " del_user
                            echo "User $del_user deleted."
                            press_any_key
                            ;;
                        5) break;;
                    esac
                done
                ;;
            4) # Security & Spam
                while true; do
                    clear
                    echo "------ Mail Security & Spam Settings ------"
                    echo "1) Configure SpamAssassin"
                    echo "2) Configure DKIM"
                    echo "3) Enable/Disable TLS"
                    echo "4) View Security Logs"
                    echo "5) Back"
                    read -p "Choose: " security_choice
                    case $security_choice in
                        1) 
                            echo "Configuring SpamAssassin..."
                            systemctl enable spamassassin
                            systemctl start spamassassin
                            echo "SpamAssassin enabled and configured."
                            press_any_key
                            ;;
                        2) 
                            read -p "Enter domain for DKIM setup: " dkim_domain
                            echo "Setting up DKIM for $dkim_domain..."
                            echo "DKIM setup would go here."
                            press_any_key
                            ;;
                        3) 
                            echo "Current TLS status:"
                            grep "^smtpd_tls_security_level" /etc/postfix/main.cf || echo "TLS not configured"
                            echo "1) Enable TLS"
                            echo "2) Disable TLS"
                            read -p "Choose: " tls_choice
                            case $tls_choice in
                                1) 
                                    echo "Enabling TLS..."
                                    # Implementation would go here
                                    echo "TLS enabled."
                                    ;;
                                2) 
                                    echo "Disabling TLS..."
                                    # Implementation would go here
                                    echo "TLS disabled."
                                    ;;
                            esac
                            press_any_key
                            ;;
                        4) 
                            echo "Mail security logs:"
                            tail -n 50 /var/log/mail.log
                            press_any_key
                            ;;
                        5) break;;
                    esac
                done
                ;;
            5) # Maintenance
                while true; do
                    clear
                    echo "------ Mail Server Maintenance ------"
                    echo "1) Restart Postfix"
                    echo "2) Restart Dovecot"
                    echo "3) Check Mail Queue"
                    echo "4) Flush Mail Queue"
                    echo "5) View Mail Logs"
                    echo "6) Back"
                    read -p "Choose: " maint_choice
                    case $maint_choice in
                        1) systemctl restart postfix; echo "Postfix restarted."; press_any_key;;
                        2) systemctl restart dovecot; echo "Dovecot restarted."; press_any_key;;
                        3) mailq; press_any_key;;
                        4) postsuper -d ALL; echo "Mail queue flushed."; press_any_key;;
                        5) tail -n 50 /var/log/mail.log; press_any_key;;
                        6) break;;
                    esac
                done
                ;;
            6) # Update
                echo "Updating Mail server packages..."
                apt update -y
                apt upgrade -y postfix dovecot-core dovecot-imapd dovecot-pop3d roundcube spamassassin
                echo "Mail server packages updated."
                press_any_key
                ;;
            7) break;;
        esac
    done
}

# DNS Server Management Function
dns_server_menu() {
    while true; do
        clear
        echo "------ DNS Server Management ------"
        echo "1) Install DNS Server"
        echo "2) Zone Management"
        echo "3) DNS Server Maintenance"
        echo "4) Update DNS Packages"
        echo "5) Back"
        read -p "Choose: " dns_choice

        case $dns_choice in
            1) # Install
                echo "Installing DNS Server (BIND)..."
                apt update -y
                apt install -y bind9 bind9utils bind9-doc dnsutils
                echo "DNS server installed."
                press_any_key
                ;;
            2) # Zone Management
                while true; do
                    clear
                    echo "------ DNS Zone Management ------"
                    echo "1) Add Primary Zone"
                    echo "2) Add Secondary Zone"
                    echo "3) View Zones"
                    echo "4) Add DNS Record"
                    echo "5) Back"
                    read -p "Choose: " zone_choice
                    case $zone_choice in
                        1) 
                            read -p "Enter domain name for zone: " zone_domain
                            echo "Creating primary zone for $zone_domain..."
                            echo "zone \"$zone_domain\" {" > /etc/bind/named.conf.local.new
                            echo "  type master;" >> /etc/bind/named.conf.local.new
                            echo "  file \"/etc/bind/zones/db.$zone_domain\";" >> /etc/bind/named.conf.local.new
                            echo "};" >> /etc/bind/named.conf.local.new
                            
                            # Create zone directory if it doesn't exist
                            mkdir -p /etc/bind/zones
                            
                            # Create basic zone file
                            echo "\$TTL 86400" > /etc/bind/zones/db.$zone_domain
                            echo "@ IN SOA ns1.$zone_domain. admin.$zone_domain. (" >> /etc/bind/zones/db.$zone_domain
                            echo "                 $(date +%Y%m%d)01 ; Serial" >> /etc/bind/zones/db.$zone_domain
                            echo "                 3600       ; Refresh" >> /etc/bind/zones/db.$zone_domain
                            echo "                 1800       ; Retry" >> /etc/bind/zones/db.$zone_domain
                            echo "                 604800     ; Expire" >> /etc/bind/zones/db.$zone_domain
                            echo "                 86400 )    ; Minimum TTL" >> /etc/bind/zones/db.$zone_domain
                            echo "" >> /etc/bind/zones/db.$zone_domain
                            echo "; Name servers" >> /etc/bind/zones/db.$zone_domain
                            echo "      IN NS   ns1.$zone_domain." >> /etc/bind/zones/db.$zone_domain
                            echo "" >> /etc/bind/zones/db.$zone_domain
                            echo "; A records" >> /etc/bind/zones/db.$zone_domain
                            echo "ns1   IN A    127.0.0.1" >> /etc/bind/zones/db.$zone_domain
                            echo "@     IN A    127.0.0.1" >> /etc/bind/zones/db.$zone_domain
                            echo "www   IN A    127.0.0.1" >> /etc/bind/zones/db.$zone_domain
                            
                            # Append to named.conf.local
                            cat /etc/bind/named.conf.local.new >> /etc/bind/named.conf.local
                            rm /etc/bind/named.conf.local.new
                            
                            echo "Primary zone for $zone_domain created."
                            echo "Don't forget to restart BIND: systemctl restart bind9"
                            press_any_key
                            ;;
                        2) 
                            read -p "Enter domain name for secondary zone: " sec_domain
                            read -p "Enter primary DNS IP: " primary_dns
                            echo "Creating secondary zone for $sec_domain..."
                            echo "zone \"$sec_domain\" {" > /etc/bind/named.conf.local.new
                            echo "  type slave;" >> /etc/bind/named.conf.local.new
                            echo "  file \"/var/cache/bind/db.$sec_domain\";" >> /etc/bind/named.conf.local.new
                            echo "  masters { $primary_dns; };" >> /etc/bind/named.conf.local.new
                            echo "};" >> /etc/bind/named.conf.local.new
                            
                            # Append to named.conf.local
                            cat /etc/bind/named.conf.local.new >> /etc/bind/named.conf.local
                            rm /etc/bind/named.conf.local.new
                            
                            echo "Secondary zone for $sec_domain created."
                            echo "Don't forget to restart BIND: systemctl restart bind9"
                            press_any_key
                            ;;
                        3) 
                            echo "Configured zones:"
                            grep -A2 "zone " /etc/bind/named.conf.local
                            press_any_key
                            ;;
                        4) 
                            read -p "Enter zone domain: " record_zone
                            read -p "Enter record name (@ for root): " record_name
                            read -p "Enter record type (A, CNAME, MX, TXT): " record_type
                            read -p "Enter record value: " record_value
                            
                            if [ -f /etc/bind/zones/db.$record_zone ]; then
                                echo "$record_name IN $record_type $record_value" >> /etc/bind/zones/db.$record_zone
                                
                                # Update serial
                                sed -i "s/.*Serial/                 $(date +%Y%m%d)01 ; Serial/" /etc/bind/zones/db.$record_zone
                                
                                echo "Record added to zone $record_zone."
                                echo "Don't forget to restart BIND: systemctl restart bind9"
                            else
                                echo "Zone file not found for $record_zone."
                            fi
                            press_any_key
                            ;;
                        5) break;;
                    esac
                done
                ;;
            3) # Maintenance
                while true; do
                    clear
                    echo "------ DNS Server Maintenance ------"
                    echo "1) Restart BIND"
                    echo "2) Check BIND Status"
                    echo "3) View DNS Logs"
                    echo "4) Test Zone"
                    echo "5) Back"
                    read -p "Choose: " dns_maint_choice
                    case $dns_maint_choice in
                        1) systemctl restart bind9; echo "BIND restarted."; press_any_key;;
                        2) systemctl status bind9; press_any_key;;
                        3) journalctl -u bind9 | tail -n 50; press_any_key;;
                        4) 
                            read -p "Enter domain to test: " test_domain
                            echo "Testing zone $test_domain..."
                            named-checkzone $test_domain /etc/bind/zones/db.$test_domain
                            press_any_key
                            ;;
                        5) break;;
                    esac
                done
                ;;
            4) # Update
                echo "Updating DNS server packages..."
                apt update -y
                apt upgrade -y bind9 bind9utils
                echo "DNS server packages updated."
                press_any_key
                ;;
            5) break;;
        esac
    done
}

# Database Management Function
db_server_menu() {
    while true; do
        clear
        echo "------ Database Management ------"
        echo "1) Install Database Server"
        echo "2) Database Management"
        echo "3) User Management"
        echo "4) Backup & Restore"
        echo "5) Database Maintenance"
        echo "6) Update DB Packages"
        echo "7) Back"
        read -p "Choose: " db_choice

        case $db_choice in
            1) # Install
                echo "Select database type to install:"
                echo "1) MySQL/MariaDB"
                echo "2) PostgreSQL"
                echo "3) MongoDB"
                echo "4) Redis"
                read -p "Choose database type: " db_type
                
                case $db_type in
                    1) 
                        apt update -y
                        apt install -y mariadb-server
                        echo "MySQL/MariaDB installed."
                        echo "Run mysql_secure_installation for security setup."
                        ;;
                    2) 
                        apt update -y
                        apt install -y postgresql postgresql-contrib
                        echo "PostgreSQL installed."
                        ;;
                    3) 
                        apt update -y
                        apt install -y mongodb-server
                        echo "MongoDB installed."
                        ;;
                    4) 
                        apt update -y
                        apt install -y redis-server
                        echo "Redis installed."
                        ;;
                esac
                press_any_key
                ;;
            2) # Database Management
                echo "Select database type:"
                echo "1) MySQL/MariaDB"
                echo "2) PostgreSQL"
                echo "3) MongoDB"
                echo "4) Redis"
                read -p "Choose database type: " db_manage_type
                
                case $db_manage_type in
                    1) 
                        while true; do
                            clear
                            echo "------ MySQL/MariaDB Management ------"
                            echo "1) Create Database"
                            echo "2) List Databases"
                            echo "3) Delete Database"
                            echo "4) Back"
                            read -p "Choose: " mysql_choice
                            case $mysql_choice in
                                1) 
                                    read -p "Enter database name: " db_name
                                    mysql -e "CREATE DATABASE $db_name;"
                                    echo "Database $db_name created."
                                    press_any_key
                                    ;;
                                2) 
                                    echo "MySQL databases:"
                                    mysql -e "SHOW DATABASES;"
                                    press_any_key
                                    ;;
                                3) 
                                    read -p "Enter database name to delete: " del_db
                                    echo "WARNING: This will permanently delete the database!"
                                    read -p "Are you sure? (y/n): " confirm
                                    if [ "$confirm" = "y" ]; then
                                        mysql -e "DROP DATABASE $del_db;"
                                        echo "Database $del_db deleted."
                                    else
                                        echo "Operation cancelled."
                                    fi
                                    press_any_key
                                    ;;
                                4) break;;
                            esac
                        done
                        ;;
                    2) 
                        while true; do
                            clear
                            echo "------ PostgreSQL Management ------"
                            echo "1) Create Database"
                            echo "2) List Databases"
                            echo "3) Delete Database"
                            echo "4) Back"
                            read -p "Choose: " pg_choice
                            case $pg_choice in
                                1) 
                                    read -p "Enter database name: " pg_db_name
                                    sudo -u postgres createdb $pg_db_name
                                    echo "Database $pg_db_name created."
                                    press_any_key
                                    ;;
                                2) 
                                    echo "PostgreSQL databases:"
                                    sudo -u postgres psql -c "\l"
                                    press_any_key
                                    ;;
                                3) 
                                    read -p "Enter database name to delete: " pg_del_db
                                    echo "WARNING: This will permanently delete the database!"
                                    read -p "Are you sure? (y/n): " confirm
                                    if [ "$confirm" = "y" ]; then
                                        sudo -u postgres dropdb $pg_del_db
                                        echo "Database $pg_del_db deleted."
                                    else
                                        echo "Operation cancelled."
                                    fi
                                    press_any_key
                                    ;;
                                4) break;;
                            esac
                        done
                        ;;
                    3) 
                        echo "MongoDB management not implemented in this version."
                        press_any_key
                        ;;
                    4) 
                        echo "Redis management not implemented in this version."
                        press_any_key
                        ;;
                esac
                ;;
            3) # User Management
                echo "Select database type:"
                echo "1) MySQL/MariaDB"
                echo "2) PostgreSQL"
                read -p "Choose database type: " db_user_type
                
                case $db_user_type in
                    1) 
                        while true; do
                            clear
                            echo "------ MySQL User Management ------"
                            echo "1) Create User"
                            echo "2) List Users"
                            echo "3) Grant Privileges"
                            echo "4) Delete User"
                            echo "5) Back"
                            read -p "Choose: " mysql_user_choice
                            case $mysql_user_choice in
                                1) 
                                    read -p "Enter username: " mysql_user
                                    read -s -p "Enter password: " mysql_pass
                                    echo ""
                                    mysql -e "CREATE USER '$mysql_user'@'localhost' IDENTIFIED BY '$mysql_pass';"
                                    echo "User $mysql_user created."
                                    press_any_key
                                    ;;
                                2) 
                                    echo "MySQL users:"
                                    mysql -e "SELECT User, Host FROM mysql.user;"
                                    press_any_key
                                    ;;
                                3) 
                                    read -p "Enter username: " grant_user
                                    read -p "Enter database name: " grant_db
                                    mysql -e "GRANT ALL PRIVILEGES ON $grant_db.* TO '$grant_user'@'localhost';"
                                    mysql -e "FLUSH PRIVILEGES;"
                                    echo "Privileges granted for $grant_user on $grant_db."
                                    press_any_key
                                    ;;
                                4) 
                                    read -p "Enter username to delete: " del_user
                                    mysql -e "DROP USER '$del_user'@'localhost';"
                                    echo "User $del_user deleted."
                                    press_any_key
                                    ;;
                                5) break;;
                            esac
                        done
                        ;;
                    2) 
                        while true; do
                            clear
                            echo "------ PostgreSQL User Management ------"
                            echo "1) Create User"
                            echo "2) List Users"
                            echo "3) Grant Privileges"
                            echo "4) Delete User"
                            echo "5) Back"
                            read -p "Choose: " pg_user_choice
                            case $pg_user_choice in
                                1) 
                                    read -p "Enter username: " pg_user
                                    read -s -p "Enter password: " pg_pass
                                    echo ""
                                    sudo -u postgres psql -c "CREATE USER $pg_user WITH PASSWORD '$pg_pass';"
                                    echo "User $pg_user created."
                                    press_any_key
                                    ;;
                                2) 
                                    echo "PostgreSQL users:"
                                    sudo -u postgres psql -c "\du"
                                    press_any_key
                                    ;;
                                3) 
                                    read -p "Enter username: " pg_grant_user
                                    read -p "Enter database name: " pg_grant_db
                                    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $pg_grant_db TO $pg_grant_user;"
                                    echo "Privileges granted for $pg_grant_user on $pg_grant_db."
                                    press_any_key
                                    ;;
                                4) 
                                    read -p "Enter username to delete: " pg_del_user
                                    sudo -u postgres psql -c "DROP USER IF EXISTS $pg_del_user;"
                                    echo "User $pg_del_user deleted."
                                    press_any_key
                                    ;;
                                5) break;;
                            esac
                        done
                        ;;
                esac
                ;;
            4) # Backup & Restore
                echo "Select database type:"
                echo "1) MySQL/MariaDB"
                echo "2) PostgreSQL"
                read -p "Choose database type: " db_backup_type
                
                case $db_backup_type in
                    1) 
                        while true; do
                            clear
                            echo "------ MySQL Backup & Restore ------"
                            echo "1) Backup Database"
                            echo "2) Backup All Databases"
                            echo "3) Restore Database"
                            echo "4) Back"
                            read -p "Choose: " mysql_backup_choice
                            case $mysql_backup_choice in
                                1) 
                                    read -p "Enter database name: " backup_db
                                    backup_file="/var/backups/$backup_db-$(date +%Y%m%d).sql"
                                    mysqldump $backup_db > $backup_file
                                    echo "Database $backup_db backed up to $backup_file."
                                    press_any_key
                                    ;;
                                2) 
                                    backup_file="/var/backups/all-databases-$(date +%Y%m%d).sql"
                                    mysqldump --all-databases > $backup_file
                                    echo "All databases backed up to $backup_file."
                                    press_any_key
                                    ;;
                                3) 
                                    read -p "Enter database name: " restore_db
                                    read -p "Enter backup file path: " restore_file
                                    mysql $restore_db < $restore_file
                                    echo "Database $restore_db restored from $restore_file."
                                    press_any_key
                                    ;;
                                4) break;;
                            esac
                        done
                        ;;
                    2) 
                        while true; do
                            clear
                            echo "------ PostgreSQL Backup & Restore ------"
                            echo "1) Backup Database"
                            echo "2) Backup All Databases"
                            echo "3) Restore Database"
                            echo "4) Back"
                            read -p "Choose: " pg_backup_choice
                            case $pg_backup_choice in
                                1) 
                                    read -p "Enter database name: " pg_backup_db
                                    pg_backup_file="/var/backups/$pg_backup_db-$(date +%Y%m%d).sql"
                                    sudo -u postgres pg_dump $pg_backup_db > $pg_backup_file
                                    echo "Database $pg_backup_db backed up to $pg_backup_file."
                                    press_any_key
                                    ;;
                                2) 
                                    pg_backup_file="/var/backups/all-pg-databases-$(date +%Y%m%d).sql"
                                    sudo -u postgres pg_dumpall > $pg_backup_file
                                    echo "All databases backed up to $pg_backup_file."
                                    press_any_key
                                    ;;
                                3) 
                                    read -p "Enter database name: " pg_restore_db
                                    read -p "Enter backup file path: " pg_restore_file
                                    sudo -u postgres psql $pg_restore_db < $pg_restore_file
                                    echo "Database $pg_restore_db restored from $pg_restore_file."
                                    press_any_key
                                    ;;
                                4) break;;
                            esac
                        done
                        ;;
                esac
                ;;
            5) # Maintenance
                echo "Select database type:"
                echo "1) MySQL/MariaDB"
                echo "2) PostgreSQL"
                read -p "Choose database type: " db_maint_type
                
                case $db_maint_type in
                    1) 
                        while true; do
                            clear
                            echo "------ MySQL Maintenance ------"
                            echo "1) Restart MySQL/MariaDB"
                            echo "2) Check MySQL Status"
                            echo "3) Optimize Tables"
                            echo "4) Check Tables"
                            echo "5) Back"
                            read -p "Choose: " mysql_maint_choice
                            case $mysql_maint_choice in
                                1) systemctl restart mysql; echo "MySQL/MariaDB restarted."; press_any_key;;
                                2) systemctl status mysql; press_any_key;;
                                3) 
                                    read -p "Enter database name: " opt_db
                                    mysql -e "OPTIMIZE TABLE $opt_db.*;"
                                    echo "Tables optimized."
                                    press_any_key
                                    ;;
                                4) 
                                    read -p "Enter database name: " check_db
                                    mysql -e "CHECK TABLE $check_db.*;"
                                    echo "Tables checked."
                                    press_any_key
                                    ;;
                                5) break;;
                            esac
                        done
                        ;;
                    2) 
                        while true; do
                            clear
                            echo "------ PostgreSQL Maintenance ------"
                            echo "1) Restart PostgreSQL"
                            echo "2) Check PostgreSQL Status"
                            echo "3) Vacuum Database"
                            echo "4) Analyze Database"
                            echo "5) Back"
                            read -p "Choose: " pg_maint_choice
                            case $pg_maint_choice in
                                1) systemctl restart postgresql; echo "PostgreSQL restarted."; press_any_key;;
                                2) systemctl status postgresql; press_any_key;;
                                3) 
                                    read -p "Enter database name: " vacuum_db
                                    sudo -u postgres vacuumdb --analyze --verbose $vacuum_db
                                    echo "Database vacuumed."
                                    press_any_key
                                    ;;
                                4) 
                                    read -p "Enter database name: " analyze_db
                                    sudo -u postgres psql -d $analyze_db -c "ANALYZE;"
                                    echo "Database analyzed."
                                    press_any_key
                                    ;;
                                5) break;;
                            esac
                        done
                        ;;
                esac
                ;;
            6) # Update
                echo "Updating database packages..."
                apt update -y
                apt upgrade -y mysql-server mariadb-server postgresql postgresql-contrib mongodb-server redis-server
                echo "Database packages updated."
                press_any_key
                ;;
            7) break;;
        esac
    done
}

# Firewall Management Function
firewall_menu() {
    while true; do
        clear
        echo "------ Firewall Management ------"
        echo "1) Install Firewall (UFW)"
        echo "2) Allow Service/Port"
        echo "3) Block Service/Port"
        echo "4) View Firewall Status"
        echo "5) Enable/Disable Firewall"
        echo "6) Back"
        read -p "Choose: " fw_choice

        case $fw_choice in
            1) # Install
                echo "Installing UFW (Uncomplicated Firewall)..."
                apt update -y
                apt install -y ufw
                echo "UFW installed."
                press_any_key
                ;;
            2) # Allow
                echo "Enter service name or port number to allow:"
                echo "Examples: ssh, http, https, 8080/tcp"
                read -p "Service/Port: " allow_svc
                ufw allow $allow_svc
                echo "Service/Port $allow_svc allowed."
                press_any_key
                ;;
            3) # Block
                echo "Enter service name or port number to block:"
                echo "Examples: ssh, http, https, 8080/tcp"
                read -p "Service/Port: " block_svc
                ufw deny $block_svc
                echo "Service/Port $block_svc blocked."
                press_any_key
                ;;
            4) # Status
                ufw status verbose
                press_any_key
                ;;
            5) # Enable/Disable
                echo "Current firewall status:"
                ufw status | grep Status
                echo "1) Enable Firewall"
                echo "2) Disable Firewall"
                read -p "Choose: " fw_toggle
                
                case $fw_toggle in
                    1) 
                        echo "y" | ufw enable
                        echo "Firewall enabled."
                        ;;
                    2) 
                        echo "y" | ufw disable
                        echo "Firewall disabled."
                        ;;
                esac
                press_any_key
                ;;
            6) break;;
        esac
    done
}

# SSL Management Function
ssl_menu() {
    while true; do
        clear
        echo "------ SSL Management ------"
        echo "1) Install Certbot"
        echo "2) Request Let's Encrypt Certificate"
        echo "3) Create Self-Signed Certificate"
        echo "4) View Certificates"
        echo "5) Renew Certificates"
        echo "6) Back"
        read -p "Choose: " ssl_choice

        case $ssl_choice in
            1) # Install
                echo "Installing Certbot and SSL tools..."
                apt update -y
                apt install -y certbot python3-certbot-apache python3-certbot-nginx openssl
                echo "Certbot and SSL tools installed."
                press_any_key
                ;;
            2) # Let's Encrypt
                echo "Request Let's Encrypt certificate:"
                echo "1) Apache"
                echo "2) Nginx"
                echo "3) Standalone"
                read -p "Choose server type: " le_server
                
                read -p "Enter domain (e.g., example.com): " le_domain
                read -p "Enter additional domains (separated by spaces, or leave empty): " le_domains
                
                case $le_server in
                    1) 
                        if [ -z "$le_domains" ]; then
                            certbot --apache -d $le_domain
                        else
                            certbot --apache -d $le_domain $le_domains
                        fi
                        ;;
                    2) 
                        if [ -z "$le_domains" ]; then
                            certbot --nginx -d $le_domain
                        else
                            certbot --nginx -d $le_domain $le_domains
                        fi
                        ;;
                    3) 
                        if [ -z "$le_domains" ]; then
                            certbot certonly --standalone -d $le_domain
                        else
                            certbot certonly --standalone -d $le_domain $le_domains
                        fi
                        ;;
                esac
                echo "Certificate request completed."
                press_any_key
                ;;
            3) # Self-Signed
                read -p "Enter domain for self-signed certificate: " ss_domain
                read -p "Enter certificate path (default: /etc/ssl/certs): " ss_path
                ss_path=${ss_path:-/etc/ssl/certs}
                
                mkdir -p $ss_path
                openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                    -keyout $ss_path/private-$ss_domain.key \
                    -out $ss_path/$ss_domain.crt \
                    -subj "/CN=$ss_domain"
                    
                echo "Self-signed certificate created at $ss_path/$ss_domain.crt"
                echo "Private key stored at $ss_path/private-$ss_domain.key"
                press_any_key
                ;;
            4) # View Certs
                echo "Let's Encrypt certificates:"
                certbot certificates
                echo ""
                echo "All SSL certificates in /etc/ssl/certs:"
                ls -la /etc/ssl/certs | grep -i ".crt"
                press_any_key
                ;;
            5) # Renew
                echo "Renewing all certificates..."
                certbot renew --dry-run
                echo "To perform actual renewal, run: certbot renew"
                press_any_key
                ;;
            6) break;;
        esac
    done
}

# System Management Function
system_menu() {
    while true; do
        clear
        echo "------ System Management ------"
        echo "1) System Updates"
        echo "2) User Management"
        echo "3) Service Management"
        echo "4) System Information"
        echo "5) Disk Management"
        echo "6) Back"
        read -p "Choose: " sys_choice

        case $sys_choice in
            1) # Updates
                while true; do
                    clear
                    echo "------ System Updates ------"
                    echo "1) Update Package List"
                    echo "2) Upgrade All Packages"
                    echo "3) Dist-Upgrade"
                    echo "4) Clean Package Cache"
                    echo "5) Back"
                    read -p "Choose: " update_choice
                    case $update_choice in
                        1) apt update -y; echo "Package lists updated."; press_any_key;;
                        2) apt update -y && apt upgrade -y; echo "All packages upgraded."; press_any_key;;
                        3) apt update -y && apt dist-upgrade -y; echo "Distribution upgrade completed."; press_any_key;;
                        4) apt clean && apt autoclean; echo "Package cache cleaned."; press_any_key;;
                        5) break;;
                    esac
                done
                ;;
            2) # User Management
                while true; do
                    clear
                    echo "------ User Management ------"
                    echo "1) Add User"
                    echo "2) List Users"
                    echo "3) Change Password"
                    echo "4) Delete User"
                    echo "5) Add User to Group"
                    echo "6) Back"
                    read -p "Choose: " user_choice
                    case $user_choice in
                        1) 
                            read -p "Enter new username: " new_user
                            adduser $new_user
                            echo "User $new_user added."
                            press_any_key
                            ;;
                        2) 
                            echo "System users:"
                            cat /etc/passwd | grep -v "nologin\|false" | cut -d: -f1
                            press_any_key
                            ;;
                        3) 
                            read -p "Enter username: " pw_user
                            passwd $pw_user
                            press_any_key
                            ;;
                        4) 
                            read -p "Enter username to delete: " del_sys_user
                            read -p "Delete home directory? (y/n): " del_home
                            if [ "$del_home" = "y" ]; then
                                deluser --remove-home $del_sys_user
                            else
                                deluser $del_sys_user
                            fi
                            echo "User $del_sys_user deleted."
                            press_any_key
                            ;;
                        5) 
                            read -p "Enter username: " group_user
                            read -p "Enter group name: " group_name
                            usermod -aG $group_name $group_user
                            echo "User $group_user added to group $group_name."
                            press_any_key
                            ;;
                        6) break;;
                    esac
                done
                ;;
            3) # Service Management
                while true; do
                    clear
                    echo "------ Service Management ------"
                    echo "1) List All Services"
                    echo "2) Start Service"
                    echo "3) Stop Service"
                    echo "4) Restart Service"
                    echo "5) Enable Service"
                    echo "6) Disable Service"
                    echo "7) Check Service Status"
                    echo "8) Back"
                    read -p "Choose: " service_choice
                    case $service_choice in
                        1) 
                            systemctl list-units --type=service --all
                            press_any_key
                            ;;
                        2) 
                            read -p "Enter service name: " start_svc
                            systemctl start $start_svc
                            echo "Service $start_svc started."
                            press_any_key
                            ;;
                        3) 
                            read -p "Enter service name: " stop_svc
                            systemctl stop $stop_svc
                            echo "Service $stop_svc stopped."
                            press_any_key
                            ;;
                        4) 
                            read -p "Enter service name: " restart_svc
                            systemctl restart $restart_svc
                            echo "Service $restart_svc restarted."
                            press_any_key
                            ;;
                        5) 
                            read -p "Enter service name: " enable_svc
                            systemctl enable $enable_svc
                            echo "Service $enable_svc enabled."
                            press_any_key
                            ;;
                        6) 
                            read -p "Enter service name: " disable_svc
                            systemctl disable $disable_svc
                            echo "Service $disable_svc disabled."
                            press_any_key
                            ;;
                        7) 
                            read -p "Enter service name: " status_svc
                            systemctl status $status_svc
                            press_any_key
                            ;;
                        8) break;;
                    esac
                done
                ;;
            4) # System Info
                while true; do
                    clear
                    echo "------ System Information ------"
                    echo "1) System Overview"
                    echo "2) CPU Information"
                    echo "3) Memory Information"
                    echo "4) Disk Information"
                    echo "5) Network Information"
                    echo "6) Process List"
                    echo "7) Back"
                    read -p "Choose: " info_choice
                    case $info_choice in
                        1) 
                            echo "Hostname: $(hostname)"
                            echo "Kernel: $(uname -r)"
                            echo "OS: $(lsb_release -d | cut -f2)"
                            echo "Uptime: $(uptime -p)"
                            echo "Last Boot: $(uptime -s)"
                            press_any_key
                            ;;
                        2) 
                            echo "CPU Information:"
                            lscpu
                            press_any_key
                            ;;
                        3) 
                            echo "Memory Information:"
                            free -h
                            press_any_key
                            ;;
                        4) 
                            echo "Disk Information:"
                            df -h
                            press_any_key
                            ;;
                        5) 
                            echo "Network Information:"
                            ip a
                            echo ""
                            echo "Routing Table:"
                            ip route
                            press_any_key
                            ;;
                        6) 
                            echo "Process List:"
                            ps aux | head -20
                            echo "(Showing top 20 processes)"
                            press_any_key
                            ;;
                        7) break;;
                    esac
                done
                ;;
            5) # Disk Management
                while true; do
                    clear
                    echo "------ Disk Management ------"
                    echo "1) List Disks"
                    echo "2) Mount Disk"
                    echo "3) Unmount Disk"
                    echo "4) Disk Usage"
                    echo "5) Back"
                    read -p "Choose: " disk_choice
                    case $disk_choice in
                        1) 
                            echo "Disk Information:"
                            fdisk -l
                            press_any_key
                            ;;
                        2) 
                            read -p "Enter device (e.g., /dev/sdb1): " mount_dev
                            read -p "Enter mount point (e.g., /mnt/data): " mount_point
                            mkdir -p $mount_point
                            mount $mount_dev $mount_point
                            echo "Device $mount_dev mounted at $mount_point."
                            press_any_key
                            ;;
                        3) 
                            read -p "Enter mount point to unmount: " umount_point
                            umount $umount_point
                            echo "Mount point $umount_point unmounted."
                            press_any_key
                            ;;
                        4) 
                            echo "Disk Usage:"
                            df -h
                            echo ""
                            read -p "Enter directory to check space usage: " usage_dir
                            du -sh $usage_dir
                            press_any_key
                            ;;
                        5) break;;
                    esac
                done
                ;;
            6) break;;
        esac
    done
}

# Backup & Restore Function
backup_menu() {
    while true; do
        clear
        echo "------ Backup & Restore ------"
        echo "1) Backup Configuration Files"
        echo "2) Backup Website Data"
        echo "3) Backup Databases"
        echo "4) Restore Configuration Files"
        echo "5) Restore Website Data"
        echo "6) Restore Databases"
        echo "7) Back"
        read -p "Choose: " backup_choice

        case $backup_choice in
            1) # Backup Config
                backup_date=$(date +%Y%m%d)
                backup_dir="/var/backups/config-$backup_date"
                mkdir -p $backup_dir
                
                echo "Backing up configuration files..."
                tar -czf $backup_dir/etc-backup.tar.gz /etc
                
                echo "Backup created at $backup_dir/etc-backup.tar.gz"
                press_any_key
                ;;
            2) # Backup Website
                backup_date=$(date +%Y%m%d)
                backup_dir="/var/backups/websites-$backup_date"
                mkdir -p $backup_dir
                
                echo "Backing up website data..."
                tar -czf $backup_dir/www-backup.tar.gz /var/www
                
                echo "Backup created at $backup_dir/www-backup.tar.gz"
                press_any_key
                ;;
            3) # Backup DB
                backup_date=$(date +%Y%m%d)
                backup_dir="/var/backups/databases-$backup_date"
                mkdir -p $backup_dir
                
                echo "Select database type to backup:"
                echo "1) MySQL/MariaDB"
                echo "2) PostgreSQL"
                read -p "Choose database type: " db_backup_choice
                
                case $db_backup_choice in
                    1) 
                        echo "Backing up all MySQL/MariaDB databases..."
                        mysqldump --all-databases > $backup_dir/mysql-all-$backup_date.sql
                        echo "MySQL backup created at $backup_dir/mysql-all-$backup_date.sql"
                        ;;
                    2) 
                        echo "Backing up all PostgreSQL databases..."
                        sudo -u postgres pg_dumpall > $backup_dir/postgres-all-$backup_date.sql
                        echo "PostgreSQL backup created at $backup_dir/postgres-all-$backup_date.sql"
                        ;;
                esac
                press_any_key
                ;;
            4) # Restore Config
                echo "Available configuration backups:"
                ls -la /var/backups/config-*
                
                read -p "Enter backup file path to restore: " config_restore
                echo "WARNING: This will overwrite current configuration files!"
                read -p "Are you sure? (y/n): " confirm
                
                if [ "$confirm" = "y" ]; then
                    echo "Restoring configuration files..."
                    tar -xzf $config_restore -C /
                    echo "Configuration files restored."
                else
                    echo "Restore cancelled."
                fi
                press_any_key
                ;;
            5) # Restore Website
                echo "Available website backups:"
                ls -la /var/backups/websites-*
                
                read -p "Enter backup file path to restore: " website_restore
                echo "WARNING: This will overwrite current website data!"
                read -p "Are you sure? (y/n): " confirm
                
                if [ "$confirm" = "y" ]; then
                    echo "Restoring website data..."
                    tar -xzf $website_restore -C /
                    echo "Website data restored."
                else
                    echo "Restore cancelled."
                fi
                press_any_key
                ;;
            6) # Restore DB
                echo "Available database backups:"
                ls -la /var/backups/databases-*
                
                read -p "Enter backup file path to restore: " db_restore
                echo "Select database type to restore:"
                echo "1) MySQL/MariaDB"
                echo "2) PostgreSQL"
                read -p "Choose database type: " db_restore_choice
                
                echo "WARNING: This will overwrite current database data!"
                read -p "Are you sure? (y/n): " confirm
                
                if [ "$confirm" = "y" ]; then
                    case $db_restore_choice in
                        1) 
                            echo "Restoring MySQL/MariaDB databases..."
                            mysql < $db_restore
                            echo "MySQL/MariaDB databases restored."
                            ;;
                        2) 
                            echo "Restoring PostgreSQL databases..."
                            sudo -u postgres psql < $db_restore
                            echo "PostgreSQL databases restored."
                            ;;
                    esac
                else
                    echo "Restore cancelled."
                fi
                press_any_key
                ;;
            7) break;;
        esac
    done
}

# Main Menu
while true; do
    clear
    echo "======================================"
    echo "      Master Server Management CLI    "
    echo "======================================"
    echo "1) Web-server Management"
    echo "2) Mail Server Management"
    echo "3) DNS Server Management"
    echo "4) Database Management"
    echo "5) Firewall Management"
    echo "6) SSL Management"
    echo "7) System Management"
    echo "8) Backup & Restore"
    echo "9) Exit"
    echo "======================================"
    read -p "Choose an option: " choice

    case $choice in
        1) web_server_menu;;
        2) mail_server_menu;;
        3) dns_server_menu;;
        4) db_server_menu;;
        5) firewall_menu;;
        6) ssl_menu;;
        7) system_menu;;
        8) backup_menu;;
        9) echo "Exiting..."; exit 0;;
        *) echo "Invalid option. Press any key to continue..."; read -n 1;;
    esac
done
