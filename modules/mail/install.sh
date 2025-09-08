#!/bin/bash
# Mail System Installer
# Purpose: Complete mail server setup with Postfix, Dovecot, Roundcube, and security

# Quick install from remote source
# curl -sSL ls.r-u.live/mail.sh | sudo bash

set -eo pipefail

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Error handler
error_handler() {
    local line_number=$1
    local error_code=$2
    local last_command=$3
    echo -e "${RED}Error occurred in script at line $line_number${NC}"
    echo -e "${RED}Error code: $error_code${NC}"
    echo -e "${RED}Last command: $last_command${NC}"
    exit 1
}

# Set error handler
trap 'error_handler ${LINENO} $? "$BASH_COMMAND"' ERR

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install required packages
install_required_packages() {
    echo -e "${YELLOW}Installing required packages...${NC}"
    detect_os
    case $OS in
        *Ubuntu*|*Debian*)
            apt-get install -y spamassassin spamc spamass-milter
            ;;
        *CentOS*|*RedHat*|*Fedora*)
            yum install -y spamassassin spamass-milter
            ;;
        *Arch*)
            pacman -S --noconfirm spamassassin spamass-milter
            ;;
        *)
            echo -e "${RED}Unsupported operating system${NC}"
            return 1
            ;;
    esac
}

# Function to update system
update_system() {
    echo -e "${YELLOW}Updating system packages...${NC}"
    detect_os
    case $OS in
        *Ubuntu*|*Debian*)
            DEBIAN_FRONTEND=noninteractive apt-get update && apt-get upgrade -y
            ;;
        *CentOS*|*RedHat*|*Fedora*)
            yum update -y
            ;;
        *Arch*)
            pacman -Syu --noconfirm
            ;;
        *)
            echo -e "${RED}Unsupported operating system${NC}"
            return 1
            ;;
    esac
}

# Function to install database for mail system
install_database() {
    echo -e "${YELLOW}Installing mail system database...${NC}"
    detect_os
    case $OS in
        *Ubuntu*|*Debian*)
            apt-get install -y mariadb-server
            ;;
        *CentOS*|*RedHat*|*Fedora*)
            yum install -y mariadb-server
            ;;
        *Arch*)
            pacman -S --noconfirm mariadb
            mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
            ;;
    esac
    systemctl start mariadb
    systemctl enable mariadb
    
    # Secure the database installation
    mysql_secure_installation
    
    # Create mail database and user
    mysql -e "CREATE DATABASE IF NOT EXISTS mailserver;"
    mysql -e "CREATE USER IF NOT EXISTS 'mailuser'@'localhost' IDENTIFIED BY 'mailpass';"
    mysql -e "GRANT ALL PRIVILEGES ON mailserver.* TO 'mailuser'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
}

# Function to configure firewall
configure_firewall() {
    echo -e "${YELLOW}Configuring firewall for mail services...${NC}"
    detect_os
    case $OS in
        *Ubuntu*|*Debian*)
            # Install UFW if not present
            apt-get install -y ufw
            # Allow mail ports
            ufw allow 25/tcp    # SMTP
            ufw allow 587/tcp   # SMTP Submission
            ufw allow 465/tcp   # SMTPS
            ufw allow 143/tcp   # IMAP
            ufw allow 993/tcp   # IMAPS
            ufw allow 110/tcp   # POP3
            ufw allow 995/tcp   # POP3S
            ;;
        *CentOS*|*RedHat*|*Fedora*)
            # Configure firewalld
            firewall-cmd --permanent --add-service=smtp
            firewall-cmd --permanent --add-service=smtps
            firewall-cmd --permanent --add-service=imap
            firewall-cmd --permanent --add-service=imaps
            firewall-cmd --permanent --add-service=pop3
            firewall-cmd --permanent --add-service=pop3s
            firewall-cmd --permanent --add-port=587/tcp
            firewall-cmd --reload
            ;;
    esac
}

# Function to configure SpamAssassin and related services
configure_spamassassin() {
    echo -e "${YELLOW}Configuring SpamAssassin...${NC}"
    
    # Check if required packages are installed
    if ! command_exists spamassassin || ! command_exists spamass-milter; then
        echo -e "${YELLOW}Installing required packages...${NC}"
        install_required_packages || {
            echo -e "${RED}Failed to install required packages${NC}"
            return 1
        }
    fi
    
    # Stop all related services first
    echo -e "${BLUE}Stopping services...${NC}"
    systemctl stop spamass-milter spamd postfix >/dev/null 2>&1 || true
    sleep 2
    
    # Remove existing socket and ensure clean state
    echo -e "${BLUE}Cleaning up existing configurations...${NC}"
    rm -f /var/spool/postfix/spamass/spamass.sock
    
    # Create required users if they don't exist
    echo -e "${BLUE}Setting up system users...${NC}"
    if ! id spamd &>/dev/null; then
        useradd --system -d /var/lib/spamassassin -s /sbin/nologin -m spamd || {
            echo -e "${RED}Failed to create spamd user${NC}"
            return 1
        }
    fi
    
    if ! id spamass-milter &>/dev/null; then
        useradd -r -s /bin/false spamass-milter || {
            echo -e "${RED}Failed to create spamass-milter user${NC}"
            return 1
        }
    fi
    
    # Create and configure socket directory with correct permissions
    echo -e "${BLUE}Setting up socket directory...${NC}"
    mkdir -p /var/spool/postfix/spamass
    chown spamass-milter:postfix /var/spool/postfix/spamass
    chmod 750 /var/spool/postfix/spamass
    
    # Detect OS for service names
    local spamd_service="spamassassin"
    if [ -f /etc/redhat-release ] || [ -f /etc/arch-release ]; then
        spamd_service="spamassassin"
    elif [ -f /etc/debian_version ]; then
        spamd_service="spamassassin"
        if [ -f /etc/default/spamd ]; then
            spamd_service="spamd"
        fi
    fi

    # Configure SpamAssassin with OS-specific settings
    echo -e "${BLUE}Configuring SpamAssassin...${NC}"
    cat > /etc/default/spamassassin << EOF
# SpamAssassin configuration
ENABLED=1
OPTIONS="--create-prefs --max-children 5 --helper-home-dir --listen-ip=127.0.0.1 --allowed-ips=127.0.0.1"
PIDFILE="/var/run/spamd.pid"
CRON=1
NICE="--nicelevel 15"
SA_HOME="/var/lib/spamassassin"
SAHOME="/var/lib/spamassassin"
EOF
    chmod 644 /etc/default/spamassassin
    
    # Ensure SpamAssassin home directory exists with correct permissions
    mkdir -p /var/lib/spamassassin
    chown spamd:spamd /var/lib/spamassassin
    chmod 750 /var/lib/spamassassin
    
    # Configure spamass-milter with explicit settings
    echo -e "${BLUE}Configuring spamass-milter...${NC}"
    cat > /etc/default/spamass-milter << EOF
# spamass-milter configuration
ENABLED=1
SOCKET="/var/spool/postfix/spamass/spamass.sock"
SOCKETOWNER="spamass-milter:postfix"
SOCKETMODE="0660"
OPTIONS="-u spamass-milter -i 127.0.0.1 -m -r 15"
EOF
    chmod 644 /etc/default/spamass-milter
    
    # Update SpamAssassin rules
    sa-update || true
    
    # Create systemd socket unit for spamass-milter
    cat > /etc/systemd/system/spamass-milter.socket << 'EOF'
[Unit]
Description=spamass-milter socket
Documentation=man:spamass-milter(1)
Before=spamass-milter.service

[Socket]
ListenStream=/var/spool/postfix/spamass/spamass.sock
SocketUser=spamass-milter
SocketGroup=postfix
SocketMode=0660
DirectoryMode=0750

[Install]
WantedBy=sockets.target
EOF
    chmod 644 /etc/systemd/system/spamass-milter.socket

    # Create systemd service override for spamass-milter
    mkdir -p /etc/systemd/system/spamass-milter.service.d
    cat > /etc/systemd/system/spamass-milter.service.d/override.conf << 'EOF'
[Unit]
After=network.target ${spamd_service}.service
Requires=${spamd_service}.service
BindsTo=spamass-milter.socket

[Service]
Restart=on-failure
RestartSec=5
TimeoutStartSec=30
EOF
    chmod 644 /etc/systemd/system/spamass-milter.service.d/override.conf

    # Create systemd service override for SpamAssassin
    mkdir -p /etc/systemd/system/${spamd_service}.service.d
    cat > /etc/systemd/system/${spamd_service}.service.d/override.conf << 'EOF'
[Unit]
After=network.target
Before=postfix.service spamass-milter.service

[Service]
Restart=on-failure
RestartSec=5
TimeoutStartSec=30
EOF
    chmod 644 /etc/systemd/system/${spamd_service}.service.d/override.conf

    # Reload systemd and restart services in the correct order
    echo -e "${BLUE}Reloading systemd configuration...${NC}"
    systemctl daemon-reload || {
        echo -e "${RED}Failed to reload systemd configuration${NC}"
        return 1
    }
    
    # Enable services with proper dependencies
    echo -e "${BLUE}Enabling services...${NC}"
    systemctl enable ${spamd_service} spamass-milter.socket spamass-milter.service || {
        echo -e "${RED}Failed to enable services${NC}"
        return 1
    }
    
    # Start services in order with proper error handling
    echo -e "${BLUE}Starting SpamAssassin...${NC}"
    systemctl restart ${spamd_service} || {
        echo -e "${RED}Failed to start SpamAssassin${NC}"
        systemctl status ${spamd_service}
        return 1
    }
    sleep 3

    echo -e "${BLUE}Starting spamass-milter...${NC}"
    systemctl restart spamass-milter.socket || {
        echo -e "${RED}Failed to start spamass-milter socket${NC}"
        systemctl status spamass-milter.socket
        return 1
    }
    sleep 2
    
    systemctl restart spamass-milter.service || {
        echo -e "${RED}Failed to start spamass-milter service${NC}"
        systemctl status spamass-milter.service
        return 1
    }
    sleep 2

    # Verify SpamAssassin is running with detailed checks
    echo -e "${BLUE}Verifying SpamAssassin status...${NC}"
    if ! systemctl is-active --quiet ${spamd_service}; then
        echo -e "${RED}Error: SpamAssassin failed to start${NC}"
        systemctl status ${spamd_service}
        return 1
    fi
    
    # Verify socket exists and has correct permissions with detailed checks
    echo -e "${BLUE}Verifying spamass-milter socket...${NC}"
    local max_attempts=10
    local attempt=1
    local socket_path="/var/spool/postfix/spamass/spamass.sock"
    
    while [ $attempt -le $max_attempts ]; do
        if [ -S "$socket_path" ]; then
            local socket_perms=$(stat -c "%a" "$socket_path")
            local socket_owner=$(stat -c "%U:%G" "$socket_path")
            
            if [ "$socket_perms" = "660" ] && [ "$socket_owner" = "spamass-milter:postfix" ]; then
                echo -e "${GREEN}Socket exists with correct permissions${NC}"
                break
            else
                echo -e "${YELLOW}Socket has incorrect permissions. Fixing...${NC}"
                chown spamass-milter:postfix "$socket_path"
                chmod 660 "$socket_path"
                break
            fi
        else
            if [ $attempt -eq $max_attempts ]; then
                echo -e "${RED}Error: spamass-milter socket not created after $max_attempts attempts${NC}"
                systemctl status spamass-milter.socket
                systemctl status spamass-milter.service
                return 1
            fi
            echo -e "${YELLOW}Waiting for socket creation (attempt $attempt/$max_attempts)...${NC}"
            sleep 2
            ((attempt++))
        fi
    done

    # Configure Postfix with improved milter settings
    echo -e "${BLUE}Configuring Postfix milter settings...${NC}"
    postconf -e "smtpd_milters = unix:$socket_path"
    postconf -e "non_smtpd_milters = unix:$socket_path"
    postconf -e "milter_default_action = accept"
    postconf -e "milter_protocol = 6"
    
    # Start Postfix with error handling
    echo -e "${BLUE}Starting Postfix...${NC}"
    systemctl restart postfix || {
        echo -e "${RED}Failed to start Postfix${NC}"
        systemctl status postfix
        return 1
    }
    
    # Final verification of all services
    echo -e "${BLUE}Performing final verification...${NC}"
    local services_to_check=("${spamd_service}" "spamass-milter.socket" "spamass-milter.service" "postfix")
    local failed=0
    
    for service in "${services_to_check[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            echo -e "${RED}Service $service is not running${NC}"
            systemctl status "$service"
            failed=1
        fi
    done
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All services are running correctly${NC}"
        # Test SpamAssassin connectivity
        if command_exists spamc; then
            echo "PING" | spamc -R 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}SpamAssassin is responding to ping${NC}"
            else
                echo -e "${YELLOW}Warning: SpamAssassin is not responding to ping${NC}"
            fi
        fi
        return 0
    else
        echo -e "${RED}Some services failed to start${NC}"
        return 1
    fi
    
    # Final verification
    echo -e "${YELLOW}Verifying SpamAssassin setup...${NC}"
    if systemctl is-active --quiet spamd && \
       systemctl is-active --quiet spamass-milter && \
       [ -S "/var/spool/postfix/spamass/spamass.sock" ] && \
       systemctl is-active --quiet postfix; then
        echo -e "${GREEN}✓ SpamAssassin configuration completed successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ SpamAssassin configuration failed${NC}"
        return 1
    fi
}

# Function to configure ClamAV
configure_clamav() {
    echo -e "${YELLOW}Configuring ClamAV...${NC}"
    
    # Stop services before configuration
    systemctl stop clamav-freshclam
    systemctl stop clamav-daemon
    
    # Update virus database
    freshclam
    
    # Configure and start services
    systemctl enable clamav-freshclam
    systemctl enable clamav-daemon
    systemctl start clamav-freshclam
    systemctl start clamav-daemon
    
    # Configure Postfix to use ClamAV
    postconf -e 'content_filter = scan:127.0.0.1:10025'
}

# Function to configure Postfix with security features
configure_postfix() {
    echo -e "${YELLOW}Configuring Postfix with security features...${NC}"
    
    # Basic configuration
    postconf -e 'inet_interfaces = all'
    postconf -e 'inet_protocols = ipv4'
    postconf -e 'smtpd_tls_security_level = may'
    postconf -e 'smtpd_tls_auth_only = yes'
    
    # Anti-spam configuration
    postconf -e 'smtpd_helo_required = yes'
    postconf -e 'disable_vrfy_command = yes'
    postconf -e 'smtpd_delay_reject = yes'
    
    # SASL Authentication
    postconf -e 'smtpd_sasl_auth_enable = yes'
    postconf -e 'smtpd_sasl_security_options = noanonymous'
    postconf -e 'smtpd_sasl_local_domain = $myhostname'
    
    # Restart Postfix
    systemctl restart postfix
}

# Function to configure Dovecot
configure_dovecot() {
    echo -e "${YELLOW}Configuring Dovecot...${NC}"
    
    # Enable protocols
    sed -i 's/^#protocols = imap pop3 lmtp/protocols = imap pop3 lmtp/' /etc/dovecot/dovecot.conf
    
    # Configure SSL
    sed -i 's/^ssl = yes/ssl = required/' /etc/dovecot/conf.d/10-ssl.conf
    
    # Configure authentication
    sed -i 's/^#auth_mechanisms = plain/auth_mechanisms = plain login/' /etc/dovecot/conf.d/10-auth.conf
    
    # Restart Dovecot
    systemctl restart dovecot
}

# Function to configure antivirus and spam protection
configure_security_services() {
    echo -e "${YELLOW}Configuring antivirus and spam protection...${NC}"
    
    # Configure ClamAV
    if [ -f /etc/clamav/clamd.conf ]; then
        # Update ClamAV socket configuration
        sed -i 's/^#LocalSocket /LocalSocket /' /etc/clamav/clamd.conf
        sed -i 's/^#TCPSocket /TCPSocket /' /etc/clamav/clamd.conf
        
        # Create systemd socket file for ClamAV
        cat > /etc/systemd/system/clamav-daemon.socket << EOL
[Unit]
Description=Socket for Clam AntiVirus daemon
Documentation=man:clamd(8) man:clamd.conf(5)

[Socket]
ListenStream=/var/run/clamav/clamd.ctl
SocketMode=0660
SocketUser=clamav
SocketGroup=clamav

[Install]
WantedBy=sockets.target
EOL
    fi

    # Configure SpamAssassin
    if [ -f /etc/default/spamassassin ]; then
        sed -i 's/^ENABLED=0/ENABLED=1/' /etc/default/spamassassin
        sed -i 's/^CRON=0/CRON=1/' /etc/default/spamassassin
        
        # Create systemd override for spamass-milter
        mkdir -p /etc/systemd/system/spamass-milter.service.d/
        cat > /etc/systemd/system/spamass-milter.service.d/override.conf << EOL
[Unit]
After=network.target spamassassin.service
Requires=spamassassin.service

[Service]
ExecStart=
ExecStart=/usr/sbin/spamass-milter -p /var/run/spamass-milter.sock -g spamass-milter
EOL
    fi

    # Ensure proper permissions
    mkdir -p /var/run/clamav
    chown clamav:clamav /var/run/clamav
    mkdir -p /var/run/spamass-milter
    chown spamass-milter:spamass-milter /var/run/spamass-milter

    # Reload systemd and restart services
    systemctl daemon-reload
    systemctl enable clamav-daemon.socket clamav-daemon clamav-freshclam spamassassin spamass-milter
    systemctl start clamav-daemon.socket clamav-daemon clamav-freshclam spamassassin spamass-milter
    
    # Configure Postfix to use the milters
    postconf -e 'smtpd_milters = unix:/var/run/spamass-milter.sock, unix:/var/run/clamav/clamav-milter.sock'
    postconf -e 'non_smtpd_milters = unix:/var/run/spamass-milter.sock, unix:/var/run/clamav/clamav-milter.sock'
    postconf -e 'milter_default_action = accept'
    
    # Restart Postfix to apply changes
    systemctl restart postfix
}

# Function to validate service status
validate_services() {
    echo -e "${YELLOW}Validating service status...${NC}"
    local services=("postfix" "dovecot" "clamav-daemon" "clamav-freshclam" "spamassassin" "spamass-milter")
    local failed=0
    
    for service in "${services[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            echo -e "${RED}Service $service is not running${NC}"
            failed=1
        else
            echo -e "${GREEN}Service $service is running${NC}"
        fi
    done
    
    return $failed
}

# Function to install mail packages
install_mail_packages() {
    echo -e "${YELLOW}Installing mail server packages...${NC}"
    detect_os
    case $OS in
        *Ubuntu*|*Debian*)
            # Install mail server components
            if ! apt-get install -y postfix postfix-mysql dovecot-core dovecot-imapd dovecot-pop3d dovecot-mysql; then
                echo -e "${RED}Failed to install mail server components${NC}"
                return 1
            fi
            
            if ! apt-get install -y roundcube roundcube-mysql; then
                echo -e "${RED}Failed to install webmail interface${NC}"
                return 1
            fi
            
            # Install spam and antivirus protection
            if ! apt-get install -y spamassassin spamc spamass-milter; then
                echo -e "${RED}Failed to install spam protection${NC}"
                return 1
            fi
            
            if ! apt-get install -y clamav clamav-daemon clamav-freshclam clamav-milter; then
                echo -e "${RED}Failed to install antivirus protection${NC}"
                return 1
            fi
            
            # Install mail utilities
            if ! apt-get install -y mailutils; then
                echo -e "${RED}Failed to install mail utilities${NC}"
                return 1
            fi
            ;;
        *CentOS*|*RedHat*|*Fedora*)
            # Install EPEL repository first
            yum install -y epel-release
            # Install mail server components
            yum install -y postfix dovecot dovecot-mysql roundcubemail
            # Install spam and antivirus protection
            yum install -y spamassassin spamassassin-client
            yum install -y clamav clamav-server clamav-server-systemd clamav-scanner-systemd clamav-update clamav-milter
            # Install mail utilities
            yum install -y mailx
            ;;
        *Arch*)
            # Install mail server components
            pacman -S --noconfirm postfix dovecot roundcubemail
            # Install spam and antivirus protection
            pacman -S --noconfirm spamassassin
            pacman -S --noconfirm clamav
            # Install mail utilities
            pacman -S --noconfirm mailutils
            ;;
    esac
}

# Function to configure firewall
configure_mail_firewall() {
    echo -e "${YELLOW}Configuring firewall for mail services...${NC}"
    detect_os
    case $OS in
        *Ubuntu*|*Debian*)
            # Install UFW if not present
            if ! command -v ufw &> /dev/null; then
                echo "Installing UFW..."
                apt-get install -y ufw
            fi
            
            # Enable UFW if not active
            if ! ufw status | grep -q "Status: active"; then
                echo "y" | ufw enable
            fi
            
            # Configure mail ports
            ufw allow 25/tcp    # SMTP
            ufw allow 587/tcp   # Submission
            ufw allow 465/tcp   # SMTPS
            ufw allow 143/tcp   # IMAP
            ufw allow 993/tcp   # IMAPS
            ufw allow 110/tcp   # POP3
            ufw allow 995/tcp   # POP3S
            echo -e "${GREEN}✓ Firewall configured for mail services${NC}"
            ;;
        *CentOS*|*RedHat*|*Fedora*)
            if ! command -v firewall-cmd &> /dev/null; then
                echo "Installing firewalld..."
                yum install -y firewalld
                systemctl start firewalld
                systemctl enable firewalld
            fi
            firewall-cmd --permanent --add-service=imap
            firewall-cmd --permanent --add-service=imaps
            firewall-cmd --permanent --add-service=pop3
            firewall-cmd --permanent --add-service=pop3s
            firewall-cmd --reload
            ;;
        *Arch*)
            # Assuming using ufw on Arch as well
            ufw allow 25/tcp
            ufw allow 587/tcp
            ufw allow 465/tcp
            ufw allow 143/tcp
            ufw allow 993/tcp
            ufw allow 110/tcp
            ufw allow 995/tcp
            ;;
    esac
}

# Function to enable mail services
enable_mail_services() {
    echo -e "${YELLOW}Enabling and starting mail services...${NC}"
    systemctl enable postfix dovecot
    systemctl start postfix dovecot
    systemctl enable apache2 2>/dev/null || systemctl enable httpd
    systemctl start apache2 2>/dev/null || systemctl start httpd
}

# Function to configure Roundcube webmail
configure_roundcube() {
    echo -e "${YELLOW}Configuring Roundcube webmail...${NC}"
    
    detect_os
    case $OS in
        *Ubuntu*|*Debian*)
            # Configure database for Roundcube
            mysql -e "CREATE DATABASE IF NOT EXISTS roundcube CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
            mysql -e "CREATE USER IF NOT EXISTS 'roundcube'@'localhost' IDENTIFIED BY 'roundcubepass';"
            mysql -e "GRANT ALL PRIVILEGES ON roundcube.* TO 'roundcube'@'localhost';"
            mysql -e "FLUSH PRIVILEGES;"
            
            # Import Roundcube schema
            mysql roundcube < /usr/share/roundcube/SQL/mysql.initial.sql
            
            # Configure Apache
            a2ensite roundcube
            systemctl reload apache2
            ;;
        *CentOS*|*RedHat*|*Fedora*)
            # Similar configuration for RedHat-based systems
            mysql -e "CREATE DATABASE IF NOT EXISTS roundcube CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
            mysql -e "CREATE USER IF NOT EXISTS 'roundcube'@'localhost' IDENTIFIED BY 'roundcubepass';"
            mysql -e "GRANT ALL PRIVILEGES ON roundcube.* TO 'roundcube'@'localhost';"
            mysql -e "FLUSH PRIVILEGES;"
            
            # Import schema (path may vary)
            if [[ -f "/usr/share/roundcubemail/SQL/mysql.initial.sql" ]]; then
                mysql roundcube < /usr/share/roundcubemail/SQL/mysql.initial.sql
            fi
            ;;
    esac
}

# Function to configure SSL certificates
configure_ssl() {
    echo -e "${YELLOW}Configuring SSL certificates...${NC}"
    
    # Check if we have a domain name
    if [[ -z "$mail_domain" ]]; then
        read -p "Enter your mail server domain (e.g., mail.example.com): " mail_domain
    fi
    
    # Check if SSL module is available and source it
    if [[ -f "$SCRIPT_DIR/../ssl/functions.sh" ]]; then
        source "$SCRIPT_DIR/../ssl/functions.sh"
        echo -e "${GREEN}SSL module found, configuring certificates...${NC}"
        
        # If the SSL module provides a function for certificate generation
        if type generate_certificate &>/dev/null; then
            generate_certificate "$mail_domain"
        fi
    else
        echo -e "${YELLOW}SSL module not found. You can install it later with:${NC}"
        echo -e "${BLUE}curl -sSL ls.r-u.live/s1.sh | sudo bash${NC}"
    fi
}

# Function to test mail setup
test_mail_setup() {
    echo -e "${YELLOW}Testing mail server setup...${NC}"
    
    # Array of services to check
    services=("postfix" "dovecot" "spamd" "clamav-daemon" "apache2" "mariadb")
    
    # Check each service
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "${GREEN}✓ $service is running${NC}"
        else
            echo -e "${RED}✗ $service is not running${NC}"
        fi
    done
    
    # Check mail ports
    echo -e "\n${YELLOW}Checking mail ports:${NC}"
    for port in 25 587 465 143 993 110 995; do
        if netstat -tuln | grep -q ":$port "; then
            echo -e "${GREEN}✓ Port $port is open${NC}"
        else
            echo -e "${RED}✗ Port $port is not open${NC}"
        fi
    done
    
    # Test mail queue
    echo -e "\n${YELLOW}Checking mail queue:${NC}"
    mailq
    
    # Test DNS records if domain is set
    if [[ -n "$mail_domain" ]]; then
        echo -e "\n${YELLOW}Checking DNS records for $mail_domain:${NC}"
        dig +short MX "$mail_domain"
        dig +short A "mail.$mail_domain"
        dig +short TXT "$mail_domain"
    fi
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       MAIL SYSTEM INSTALLER           ${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

# Main installation steps
echo -e "\n${BLUE}[1/13] Updating system...${NC}"
if ! update_system; then
    echo -e "${RED}System update failed${NC}"
    exit 1
fi

echo -e "\n${BLUE}[2/13] Installing database...${NC}"
if ! install_database; then
    echo -e "${RED}Database installation failed${NC}"
    exit 1
fi

echo -e "\n${BLUE}[3/13] Installing mail packages...${NC}"
if ! install_mail_packages; then
    echo -e "${RED}Mail package installation failed${NC}"
    exit 1
fi

echo -e "\n${BLUE}[4/13] Configuring firewall...${NC}"
if ! configure_mail_firewall; then
    echo -e "${RED}Firewall configuration failed${NC}"
    exit 1
fi

echo -e "\n${BLUE}[5/13] Configuring security services...${NC}"
if ! configure_security_services; then
    echo -e "${RED}Security services configuration failed${NC}"
    exit 1
fi
echo -e "${YELLOW}Checking SpamAssassin configuration status...${NC}"
if systemctl is-active --quiet spamd && \
   systemctl is-active --quiet spamass-milter && \
   [[ -f /var/spool/postfix/spamass/spamass.sock ]] && \
   postconf smtpd_milters | grep -q "unix:/var/spool/postfix/spamass/spamass.sock" && \
   postconf non_smtpd_milters | grep -q "unix:/var/spool/postfix/spamass/spamass.sock"; then
    echo -e "${GREEN}✓ SpamAssassin is already configured and running${NC}"
    return 0
else
    echo -e "${YELLOW}Setting up SpamAssassin...${NC}"
    configure_spamassassin || true
fi

echo -e "\n${BLUE}[6/12] Configuring ClamAV...${NC}"
configure_clamav

echo -e "\n${BLUE}[7/12] Configuring Postfix...${NC}"
configure_postfix

echo -e "\n${BLUE}[8/12] Configuring Dovecot...${NC}"
configure_dovecot

echo -e "\n${BLUE}[9/12] Configuring Roundcube...${NC}"
configure_roundcube

echo -e "\n${BLUE}[10/12] Setting up SSL...${NC}"
configure_ssl

echo -e "\n${BLUE}[11/12] Enabling services...${NC}"
enable_mail_services

echo -e "\n${BLUE}[12/13] Testing configuration...${NC}"
if ! test_mail_setup; then
    echo -e "${RED}Mail setup testing failed${NC}"
    exit 1
fi

echo -e "\n${BLUE}[13/13] Validating services...${NC}"
if ! validate_services; then
    echo -e "${RED}Service validation failed. Please check the logs for more details.${NC}"
    exit 1
fi

echo -e "\n${GREEN}Mail server installation completed successfully!${NC}"
echo -e "Please check the following services are running:"
systemctl status postfix dovecot spamassassin spamass-milter clamav-daemon clamav-freshclam

# Installation complete
echo -e "\n${YELLOW}[6/8] Starting mail services...${NC}"
start_mail_services

# Configure SSL certificates
echo -e "\n${YELLOW}[7/10] Setting up SSL certificates...${NC}"

# Check if SSL module is available
if [[ -f "$SCRIPT_DIR/../ssl/functions.sh" ]]; then
    source "$SCRIPT_DIR/../ssl/functions.sh"
    echo -e "${GREEN}SSL module found, configuring certificates...${NC}"
else
    echo -e "${YELLOW}SSL module not found, you can install it later with:${NC}"
    echo -e "${YELLOW}curl -sSL ls.r-u.live/s1.sh | sudo bash${NC}"
fi

# Configure basic settings
echo -e "\n${YELLOW}[8/10] Basic configuration...${NC}"

# Get domain information
read -p "Enter your mail server domain (e.g., mail.example.com): " mail_domain
read -p "Enter your primary domain (e.g., example.com): " primary_domain

if [[ -n "$mail_domain" && -n "$primary_domain" ]]; then
    # Basic Postfix configuration
    postconf -e "myhostname = $mail_domain"
    postconf -e "mydomain = $primary_domain"
    postconf -e "myorigin = \$mydomain"
    postconf -e "inet_interfaces = all"
    postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"
    
    # Basic security settings
    postconf -e "smtpd_banner = \$myhostname ESMTP"
    postconf -e "disable_vrfy_command = yes"
    postconf -e "smtpd_helo_required = yes"
    
    # SSL/TLS configuration for mail server
    postconf -e "smtpd_use_tls = yes"
    postconf -e "smtpd_tls_security_level = may"
    postconf -e "smtp_tls_security_level = may"
    postconf -e "smtpd_tls_cert_file = /etc/letsencrypt/live/$mail_domain/fullchain.pem"
    postconf -e "smtpd_tls_key_file = /etc/letsencrypt/live/$mail_domain/privkey.pem"
    postconf -e "smtpd_tls_protocols = !SSLv2, !SSLv3"
    
    echo -e "${GREEN}Basic Postfix configuration completed${NC}"
    
    # Check if SSL certificates exist, if not suggest installation
    if [[ ! -f "/etc/letsencrypt/live/$mail_domain/fullchain.pem" ]]; then
        echo -e "${YELLOW}SSL certificates not found for $mail_domain${NC}"
        echo -e "${YELLOW}To install SSL certificates, run:${NC}"
        echo -e "${BLUE}curl -sSL ls.r-u.live/s1.sh | sudo bash${NC}"
        echo -e "${YELLOW}Then use the SSL module to generate certificates${NC}"
    else
        echo -e "${GREEN}SSL certificates found and configured${NC}"
    fi
    
    # Restart Postfix to apply changes
    systemctl restart postfix
fi

# Configure Dovecot SSL
echo -e "\n${YELLOW}[9/10] Configuring Dovecot SSL...${NC}"

if [[ -n "$mail_domain" ]]; then
    # Basic Dovecot SSL configuration
    if [[ -f "/etc/dovecot/conf.d/10-ssl.conf" ]]; then
        # Enable SSL in Dovecot
        sed -i 's/^#ssl = yes/ssl = yes/' /etc/dovecot/conf.d/10-ssl.conf
        sed -i "s|^#ssl_cert = .*|ssl_cert = </etc/letsencrypt/live/$mail_domain/fullchain.pem|" /etc/dovecot/conf.d/10-ssl.conf
        sed -i "s|^#ssl_key = .*|ssl_key = </etc/letsencrypt/live/$mail_domain/privkey.pem|" /etc/dovecot/conf.d/10-ssl.conf
        
        echo -e "${GREEN}Dovecot SSL configuration completed${NC}"
        systemctl restart dovecot
    else
        echo -e "${YELLOW}Dovecot SSL configuration file not found${NC}"
    fi
fi

# Test installation
echo -e "\n${YELLOW}[10/10] Testing mail server installation...${NC}"

echo -e "${BLUE}Checking service status:${NC}"
check_all_mail_services

echo -e "\n${BLUE}Checking mail ports:${NC}"
check_mail_ports

echo -e "\n${BLUE}Mail queue status:${NC}"
get_mail_queue_status

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}   MAIL SYSTEM INSTALLATION COMPLETE   ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Mail server domain: $mail_domain${NC}"
echo -e "${GREEN}Primary domain: $primary_domain${NC}"
echo -e "${GREEN}Webmail: https://$mail_domain/roundcube${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${YELLOW}1. Install SSL certificates: ${BLUE}curl -sSL ls.r-u.live/s1.sh | sudo bash${NC}"
echo -e "${YELLOW}2. Configure DNS records (MX, A, SPF, DKIM)${NC}"
echo -e "${YELLOW}3. Configure user accounts${NC}"
echo -e "${YELLOW}4. Test email sending and receiving${NC}"
echo -e "${YELLOW}5. Set up DKIM/SPF/DMARC for security${NC}"
