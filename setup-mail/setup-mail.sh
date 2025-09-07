#!/bin/bash
set -e

# Function to check if a command is installed
check_installed() {
    if command -v $1 >/dev/null 2>&1; then
        echo "✅ $1 installed successfully"
    else
        echo "❌ $1 installation failed"
        exit 1
    fi
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
        echo "🖥️ Detected Linux distribution: $PRETTY_NAME"
    else
        echo "❌ Cannot detect Linux distribution. This script supports Ubuntu/Debian."
        exit 1
    fi
    
    # Check if distribution is Ubuntu or Debian based
    if [[ "$DISTRO" != "ubuntu" && "$DISTRO" != "debian" && "$DISTRO" != "linuxmint" && "$DISTRO" != "pop" ]]; then
        echo "❌ This script is designed for Ubuntu/Debian based distributions."
        echo "   Detected: $DISTRO"
        echo "   Please use the appropriate script for your distribution."
        exit 1
    fi
}

# Function to check if string is a valid domain
is_valid_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](\.[a-zA-Z]{2,})+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Configuration variables (with defaults)
DOMAIN=""
HOSTNAME=""
ADMIN_EMAIL=""
USE_MYSQL=true
USE_POSTGRES=false
INSTALL_WEBMAIL=true
WEBMAIL_TYPE="roundcube" # Options: roundcube, squirrelmail
INSTALL_MSMTP=false
IMAP_SERVER="dovecot" # Options: dovecot, courier
SMTP_SERVER="postfix" # Options: postfix, exim
CONFIGURE_DKIM=true
CONFIGURE_SPF=true
CONFIGURE_DMARC=true
INSTALL_ANTISPAM=true
INSTALL_ANTIVIRUS=true
MAIL_SERVER_TYPE="full" # Options: full, relay, incoming

# Process command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            --domain)
                DOMAIN="$2"
                shift
                shift
                ;;
            --hostname)
                HOSTNAME="$2"
                shift
                shift
                ;;
            --admin-email)
                ADMIN_EMAIL="$2"
                shift
                shift
                ;;
            --no-mysql)
                USE_MYSQL=false
                shift
                ;;
            --use-postgres)
                USE_POSTGRES=true
                shift
                ;;
            --no-webmail)
                INSTALL_WEBMAIL=false
                shift
                ;;
            --webmail-type)
                WEBMAIL_TYPE="$2"
                shift
                shift
                ;;
            --imap-server)
                IMAP_SERVER="$2"
                shift
                shift
                ;;
            --smtp-server)
                SMTP_SERVER="$2"
                shift
                shift
                ;;
            --install-msmtp)
                INSTALL_MSMTP=true
                shift
                ;;
            --no-dkim)
                CONFIGURE_DKIM=false
                shift
                ;;
            --no-spf)
                CONFIGURE_SPF=false
                shift
                ;;
            --no-dmarc)
                CONFIGURE_DMARC=false
                shift
                ;;
            --no-antispam)
                INSTALL_ANTISPAM=false
                shift
                ;;
            --no-antivirus)
                INSTALL_ANTIVIRUS=false
                shift
                ;;
            --server-type)
                MAIL_SERVER_TYPE="$2"
                shift
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "❌ Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    echo "Mail Server Setup Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --domain DOMAIN       Primary domain name for mail server (required)"
    echo "  --hostname HOSTNAME   Server hostname (default: mail.DOMAIN)"
    echo "  --admin-email EMAIL   Admin email address for notifications"
    echo "  --no-mysql            Don't use MySQL for mail storage"
    echo "  --use-postgres        Use PostgreSQL for mail storage"
    echo "  --no-webmail          Don't install webmail"
    echo "  --webmail-type TYPE   Webmail type: roundcube, squirrelmail (default: roundcube)"
    echo "  --imap-server TYPE    IMAP server: dovecot, courier (default: dovecot)"
    echo "  --smtp-server TYPE    SMTP server: postfix, exim (default: postfix)"
    echo "  --install-msmtp       Install msmtp mail client"
    echo "  --no-dkim             Don't configure DKIM"
    echo "  --no-spf              Don't configure SPF"
    echo "  --no-dmarc            Don't configure DMARC"
    echo "  --no-antispam         Don't install anti-spam (SpamAssassin)"
    echo "  --no-antivirus        Don't install anti-virus (ClamAV)"
    echo "  --server-type TYPE    Server type: full, relay, incoming (default: full)"
    echo "  --help                Show this help message"
    echo ""
}

# Check required arguments
check_arguments() {
    if [ -z "$DOMAIN" ]; then
        echo "❌ Domain is required. Use --domain option."
        show_help
        exit 1
    fi

    if ! is_valid_domain "$DOMAIN"; then
        echo "❌ Invalid domain format: $DOMAIN"
        exit 1
    fi

    if [ -z "$HOSTNAME" ]; then
        HOSTNAME="mail.$DOMAIN"
        echo "ℹ️ Using default hostname: $HOSTNAME"
    fi

    if [ -z "$ADMIN_EMAIL" ]; then
        ADMIN_EMAIL="postmaster@$DOMAIN"
        echo "ℹ️ Using default admin email: $ADMIN_EMAIL"
    fi
}

# Update system
update_system() {
    echo "🔄 Updating system..."
    sudo apt update && sudo apt upgrade -y
    echo "✅ System updated"

    # Check for any remaining updates
    echo "🔍 Checking for remaining updates..."
    UPDATES=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)
    if [ "$UPDATES" -gt 0 ]; then
        echo "⚠️ There are still $UPDATES updates available. Some may require a system restart."
    else
        echo "✅ All packages are up to date"
    fi

    # Check if a reboot is required
    if [ -f /var/run/reboot-required ]; then
        echo "⚠️ A system reboot is required to complete updates"
        echo "   Please reboot the system and run this script again."
        exit 1
    fi
}

# Install required packages
install_dependencies() {
    echo "📦 Installing essential packages..."
    sudo apt install -y curl wget gnupg2 dnsutils ssl-cert ca-certificates lsb-release apt-transport-https
    check_installed curl
    check_installed wget
    check_installed dig
    echo "✅ Essential packages installed"
}

# Install and configure Postfix
install_postfix() {
    echo "📧 Installing Postfix..."
    # Pre-configure postfix options non-interactively
    echo "postfix postfix/main_mailer_type select Internet Site" | sudo debconf-set-selections
    echo "postfix postfix/mailname string $HOSTNAME" | sudo debconf-set-selections
    
    sudo apt install -y postfix postfix-pcre
    check_installed postfix
    echo "✅ Postfix installed"
    
    echo "🔧 Configuring Postfix..."
    # Backup original config
    sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.bak
    
    # Configure main.cf
    cat > /tmp/main.cf << EOF
# Basic configuration
smtpd_banner = \$myhostname ESMTP \$mail_name
biff = no
append_dot_mydomain = no
readme_directory = no
compatibility_level = 2

# TLS parameters
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_tls_security_level = may
smtpd_tls_loglevel = 1
smtpd_tls_received_header = yes
smtpd_tls_session_cache_database = btree:\${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache
smtp_tls_security_level = may

# Network settings
myhostname = $HOSTNAME
myorigin = $DOMAIN
mydestination = \$myhostname, localhost.$DOMAIN, localhost, $DOMAIN
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = all

# Virtual domains and users
virtual_mailbox_domains = $DOMAIN
virtual_mailbox_base = /var/mail/vhosts
virtual_mailbox_maps = hash:/etc/postfix/vmailbox
virtual_alias_maps = hash:/etc/postfix/virtual
virtual_minimum_uid = 100
virtual_uid_maps = static:5000
virtual_gid_maps = static:5000

# SMTP restrictions
smtpd_helo_required = yes
smtpd_helo_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_invalid_helo_hostname,
    reject_non_fqdn_helo_hostname
smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination,
    reject_rbl_client zen.spamhaus.org,
    reject_rhsbl_reverse_client dbl.spamhaus.org,
    reject_rhsbl_helo dbl.spamhaus.org,
    reject_rhsbl_sender dbl.spamhaus.org
EOF

    sudo cp /tmp/main.cf /etc/postfix/main.cf
    
    # Create virtual mailbox structure
    echo "📂 Setting up virtual mailboxes..."
    sudo mkdir -p /var/mail/vhosts/$DOMAIN
    sudo groupadd -g 5000 vmail
    sudo useradd -g vmail -u 5000 -d /var/mail/vhosts -c "Virtual Mailbox User" vmail
    sudo chown -R vmail:vmail /var/mail/vhosts
    
    # Create initial vmailbox and virtual files
    echo "admin@$DOMAIN $DOMAIN/admin/" > /tmp/vmailbox
    echo "postmaster@$DOMAIN admin@$DOMAIN" > /tmp/virtual
    
    sudo cp /tmp/vmailbox /etc/postfix/vmailbox
    sudo cp /tmp/virtual /etc/postfix/virtual
    sudo postmap /etc/postfix/vmailbox
    sudo postmap /etc/postfix/virtual
    
    echo "✅ Postfix configured"
}

# Install and configure Courier IMAP
install_courier() {
    echo "📧 Installing Courier IMAP/POP3 server..."
    sudo apt install -y courier-imap courier-pop courier-authlib courier-authlib-mysql
    check_installed courier-imap
    echo "✅ Courier IMAP installed"
    
    echo "🔧 Configuring Courier IMAP..."
    
    # Backup original config files
    sudo cp /etc/courier/imapd /etc/courier/imapd.bak
    sudo cp /etc/courier/authdaemonrc /etc/courier/authdaemonrc.bak
    
    # Configure basic settings
    sudo sed -i 's/^MAXDAEMONS=.*/MAXDAEMONS=40/' /etc/courier/imapd
    sudo sed -i 's/^MAXPERIP=.*/MAXPERIP=20/' /etc/courier/imapd
    
    # Configure authentication
    sudo sed -i 's/^authmodulelist=.*/authmodulelist="authuserdb authpam"/' /etc/courier/authdaemonrc
    
    # Create user database
    echo "📂 Setting up virtual users for Courier..."
    sudo mkdir -p /etc/courier/userdb
    
    # Add admin user
    echo "admin@$DOMAIN|$(openssl passwd -1 changeme)|vmail|vmail|/var/mail/vhosts/$DOMAIN/admin||1000|1000" > /tmp/admin-user
    sudo userdb /tmp/admin-user import
    sudo makeuserdb
    
    # Restart Courier services
    sudo systemctl restart courier-authdaemon
    sudo systemctl restart courier-imap
    
    echo "✅ Courier IMAP configured"
    echo "⚠️ Default admin password is 'changeme'. Please change it immediately!"
}

# Install msmtp for mail sending
install_msmtp() {
    if [ "$INSTALL_MSMTP" = true ]; then
        echo "📧 Installing msmtp mail client..."
        sudo apt install -y msmtp msmtp-mta ca-certificates
        check_installed msmtp
        
        # Configure msmtp
        echo "🔧 Configuring msmtp..."
        
        cat > /tmp/msmtprc << EOF
# Default settings
defaults
auth           on
tls            on
tls_starttls   on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

# Local SMTP server
account        local
host           localhost
port           25
from           admin@$DOMAIN
auth           off
tls            off

# Default account
account default : local
EOF
        sudo cp /tmp/msmtprc /etc/msmtprc
        sudo chmod 644 /etc/msmtprc
        
        # Configure as system mail transport agent
        sudo ln -sf /usr/bin/msmtp /usr/sbin/sendmail
        sudo ln -sf /usr/bin/msmtp /usr/bin/sendmail
        
        echo "✅ msmtp installed and configured"
    fi
}

# Install and configure IMAP server (Dovecot or Courier)
install_imap_server() {
    if [ "$IMAP_SERVER" = "dovecot" ]; then
        install_dovecot
    elif [ "$IMAP_SERVER" = "courier" ]; then
        install_courier
    else
        echo "❌ Unknown IMAP server type: $IMAP_SERVER. Defaulting to Dovecot."
        install_dovecot
    fi
}

# Install and configure Dovecot
install_dovecot() {
    echo "📧 Installing Dovecot IMAP/POP3 server..."
    sudo apt install -y dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd
    check_installed dovecot
    echo "✅ Dovecot installed"
    
    echo "🔧 Configuring Dovecot..."
    # Backup original config files
    sudo cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.bak
    sudo cp /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.bak
    sudo cp /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.bak
    sudo cp /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.bak
    
    # Configure mail settings
    cat > /tmp/10-mail.conf << EOF
mail_location = maildir:/var/mail/vhosts/%d/%n
namespace inbox {
  inbox = yes
}
mail_privileged_group = mail
mail_access_groups = mail
EOF

    # Configure authentication
    cat > /tmp/10-auth.conf << EOF
disable_plaintext_auth = yes
auth_mechanisms = plain login
!include auth-system.conf.ext
!include auth-passwdfile.conf.ext
password_format = PLAIN-MD5
EOF

    # Configure master settings
    cat > /tmp/10-master.conf << EOF
service imap-login {
  inet_listener imap {
    port = 143
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
}
service pop3-login {
  inet_listener pop3 {
    port = 110
  }
  inet_listener pop3s {
    port = 995
    ssl = yes
  }
}
service lmtp {
  unix_listener lmtp {
    mode = 0666
  }
}
service auth {
  unix_listener auth-userdb {
    mode = 0666
    user = vmail
    group = vmail
  }
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
    user = postfix
    group = postfix
  }
}
EOF

    sudo cp /tmp/10-mail.conf /etc/dovecot/conf.d/10-mail.conf
    sudo cp /tmp/10-auth.conf /etc/dovecot/conf.d/10-auth.conf
    sudo cp /tmp/10-master.conf /etc/dovecot/conf.d/10-master.conf
    
    # Create auth-passwdfile.conf.ext
    cat > /tmp/auth-passwdfile.conf.ext << EOF
passdb {
  driver = passwd-file
  args = scheme=PLAIN-MD5 username_format=%u /etc/dovecot/users
}
userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/mail/vhosts/%d/%n
}
EOF

    sudo cp /tmp/auth-passwdfile.conf.ext /etc/dovecot/conf.d/auth-passwdfile.conf.ext
    
    # Create initial users file with admin user (password: changeme)
    echo "admin@$DOMAIN:{PLAIN-MD5}b5bcc7abd5a779cf6c2f24bac64f65c7" > /tmp/users
    sudo cp /tmp/users /etc/dovecot/users
    sudo chown dovecot:dovecot /etc/dovecot/users
    
    echo "✅ Dovecot configured"
    echo "⚠️ Default admin password is 'changeme'. Please change it immediately!"
}

# Install and configure SpamAssassin if requested
install_spamassassin() {
    if [ "$INSTALL_ANTISPAM" = true ]; then
        echo "🛡️ Installing SpamAssassin..."
        sudo apt install -y spamassassin spamc
        check_installed spamassassin
        check_installed spamc
        
        # Enable SpamAssassin service
        sudo systemctl enable spamassassin
        
        # Configure SpamAssassin
        sudo cp /etc/default/spamassassin /etc/default/spamassassin.bak
        sudo sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/spamassassin
        
        # Configure Postfix to use SpamAssassin
        cat >> /tmp/main.cf << EOF

# SpamAssassin integration
smtpd_milters = unix:/var/run/spamass-milter/spamass-milter.sock
milter_connect_macros = j {daemon_name} v {if_name} _
milter_default_action = accept
EOF
        sudo cp /tmp/main.cf /etc/postfix/main.cf
        
        echo "✅ SpamAssassin installed and configured"
    else
        echo "ℹ️ Skipping SpamAssassin installation as requested"
    fi
}

# Install and configure ClamAV if requested
install_clamav() {
    if [ "$INSTALL_ANTIVIRUS" = true ]; then
        echo "🛡️ Installing ClamAV..."
        sudo apt install -y clamav clamav-daemon clamsmtp
        check_installed clamav
        check_installed clamd
        
        # Configure ClamAV
        sudo systemctl stop clamav-freshclam
        sudo freshclam
        sudo systemctl enable --now clamav-daemon
        sudo systemctl enable --now clamav-freshclam
        
        # Configure Postfix to use ClamAV
        cat > /tmp/clamav-milter.conf << EOF
MilterSocket = unix:/var/run/clamav/clamav-milter.sock
MilterSocketMode = 666
FixStaleSocket = true
User = clamav
AllowSupplementaryGroups = true
ReadTimeout = 120
Foreground = false
PidFile = /var/run/clamav/clamav-milter.pid
ClamdSocket = unix:/var/run/clamav/clamd.sock
OnClean = Accept
OnInfected = Reject
OnFail = Defer
AddHeader = Replace
LogSyslog = true
LogFacility = LOG_MAIL
LogVerbose = false
LogInfected = Basic
EOF
        sudo cp /tmp/clamav-milter.conf /etc/clamav/clamav-milter.conf
        
        cat >> /tmp/main.cf << EOF

# ClamAV integration
smtpd_milters += unix:/var/run/clamav/clamav-milter.sock
EOF
        sudo cp /tmp/main.cf /etc/postfix/main.cf
        
        echo "✅ ClamAV installed and configured"
    else
        echo "ℹ️ Skipping ClamAV installation as requested"
    fi
}

# Install Webmail if requested
install_webmail() {
    if [ "$INSTALL_WEBMAIL" = true ]; then
        if [ "$WEBMAIL_TYPE" = "roundcube" ]; then
            install_roundcube
        elif [ "$WEBMAIL_TYPE" = "squirrelmail" ]; then
            install_squirrelmail
        else
            echo "❌ Unknown webmail type: $WEBMAIL_TYPE. Defaulting to Roundcube."
            install_roundcube
        fi
    else
        echo "ℹ️ Skipping webmail installation as requested"
    fi
}

# Install and configure Roundcube
install_roundcube() {
    echo "🌐 Installing Roundcube webmail..."
    
    # Install dependencies first
    sudo apt install -y apache2 php php-cli php-common php-curl php-gd php-intl php-json \
        php-mbstring php-xml php-zip
    check_installed apache2
    check_installed php
    
    # Database support
    if [ "$USE_MYSQL" = true ]; then
        sudo apt install -y php-mysql roundcube-mysql
    fi
    
    if [ "$USE_POSTGRES" = true ]; then
        sudo apt install -y php-pgsql roundcube-pgsql
    fi
    
    # Install Roundcube and plugins
    sudo apt install -y roundcube roundcube-core roundcube-plugins
    
    # Configure Apache for Roundcube
    cat > /tmp/roundcube.conf << EOF
Alias /webmail /var/lib/roundcube

<Directory /var/lib/roundcube>
    Options +FollowSymLinks
    AllowOverride All
    <IfVersion >= 2.3>
        Require all granted
    </IfVersion>
    <IfVersion < 2.3>
        Order allow,deny
        Allow from all
    </IfVersion>
</Directory>
EOF
    sudo cp /tmp/roundcube.conf /etc/apache2/conf-available/roundcube.conf
    sudo a2enconf roundcube
    
    # Configure Roundcube
    echo "🔧 Configuring Roundcube..."
    sudo cp /etc/roundcube/config.inc.php /etc/roundcube/config.inc.php.bak
    
    # Update Roundcube configuration for IMAP and SMTP
    cat > /tmp/roundcube_config.php << EOF
<?php
\$config = array();
\$config['db_dsnw'] = 'sqlite:////var/lib/roundcube/roundcube.db';
\$config['default_host'] = 'localhost';
\$config['default_port'] = 143;
\$config['smtp_server'] = 'localhost';
\$config['smtp_port'] = 25;
\$config['smtp_user'] = '%u';
\$config['smtp_pass'] = '%p';
\$config['support_url'] = '';
\$config['product_name'] = 'Webmail - $DOMAIN';
\$config['des_key'] = '$(openssl rand -base64 24)';
\$config['plugins'] = array('archive', 'zipdownload');
\$config['skin'] = 'elastic';
\$config['enable_spellcheck'] = true;
\$config['spellcheck_engine'] = 'pspell';
\$config['language'] = 'en_US';
EOF
    
    sudo cp /tmp/roundcube_config.php /etc/roundcube/config.inc.php
    sudo chown www-data:www-data /etc/roundcube/config.inc.php
    
    # Enable and secure Roundcube
    sudo a2enmod rewrite
    sudo systemctl reload apache2
    
    echo "✅ Roundcube webmail installed and configured"
    echo "ℹ️ Roundcube is available at http://$HOSTNAME/webmail"
}

# Install and configure SquirrelMail
install_squirrelmail() {
    echo "🌐 Installing SquirrelMail webmail..."
    sudo apt install -y apache2 php php-cli php-common php-pear squirrelmail
    check_installed apache2
    check_installed squirrelmail
    
    # Configure SquirrelMail
    echo "🔧 Configuring SquirrelMail..."
    
    # Create Apache configuration
    cat > /tmp/squirrelmail.conf << EOF
Alias /webmail /usr/share/squirrelmail

<Directory /usr/share/squirrelmail>
    Options FollowSymLinks
    DirectoryIndex index.php
    <IfModule mod_php.c>
        AddType application/x-httpd-php .php
        php_flag magic_quotes_gpc Off
        php_flag track_vars On
        php_flag register_globals Off
        php_value include_path .
    </IfModule>
    <IfVersion >= 2.3>
        Require all granted
    </IfVersion>
    <IfVersion < 2.3>
        Order allow,deny
        Allow from all
    </IfVersion>
</Directory>
EOF
    sudo cp /tmp/squirrelmail.conf /etc/apache2/conf-available/squirrelmail.conf
    sudo a2enconf squirrelmail
    
    # Run squirrelmail configuration tool
    echo "ℹ️ Running SquirrelMail configuration tool..."
    cat > /tmp/squirrelmail-config << EOF
2
localhost
localhost
n
x
1
$DOMAIN
/var/local/squirrelmail/data/
S
Q
EOF
    sudo perl -e "require '/usr/share/squirrelmail/config/conf.pl'; conf_to_command_line();" < /tmp/squirrelmail-config
    
    sudo systemctl reload apache2
    
    echo "✅ SquirrelMail webmail installed and configured"
    echo "ℹ️ SquirrelMail is available at http://$HOSTNAME/webmail"
}

# Configure DKIM if requested
configure_dkim() {
    if [ "$CONFIGURE_DKIM" = true ]; then
        echo "🔑 Setting up DKIM..."
        sudo apt install -y opendkim opendkim-tools
        check_installed opendkim
        
        # Configure OpenDKIM
        sudo mkdir -p /etc/opendkim/keys/$DOMAIN
        
        # Generate keys
        sudo opendkim-genkey -D /etc/opendkim/keys/$DOMAIN/ -d $DOMAIN -s mail
        sudo chown -R opendkim:opendkim /etc/opendkim/keys/$DOMAIN
        
        # Configure OpenDKIM
        cat > /tmp/opendkim.conf << EOF
# OpenDKIM configuration
Syslog                  yes
UMask                   022
KeyTable                refile:/etc/opendkim/key.table
SigningTable            refile:/etc/opendkim/signing.table
ExternalIgnoreList      refile:/etc/opendkim/trusted.hosts
InternalHosts           refile:/etc/opendkim/trusted.hosts
Mode                    sv
PidFile                 /var/run/opendkim/opendkim.pid
Socket                  local:/var/run/opendkim/opendkim.sock
EOF
        sudo cp /tmp/opendkim.conf /etc/opendkim.conf
        
        # Create key table
        echo "mail._domainkey.$DOMAIN $DOMAIN:mail:/etc/opendkim/keys/$DOMAIN/mail.private" > /tmp/key.table
        sudo cp /tmp/key.table /etc/opendkim/key.table
        
        # Create signing table
        echo "*@$DOMAIN mail._domainkey.$DOMAIN" > /tmp/signing.table
        sudo cp /tmp/signing.table /etc/opendkim/signing.table
        
        # Create trusted hosts
        cat > /tmp/trusted.hosts << EOF
127.0.0.1
localhost
$HOSTNAME
$DOMAIN
EOF
        sudo cp /tmp/trusted.hosts /etc/opendkim/trusted.hosts
        
        # Connect Postfix and OpenDKIM
        cat > /tmp/opendkim << EOF
SOCKET="local:/var/run/opendkim/opendkim.sock"
EOF
        sudo cp /tmp/opendkim /etc/default/opendkim
        
        cat >> /tmp/main.cf << EOF

# DKIM integration
milter_default_action = accept
milter_protocol = 2
smtpd_milters += local:/var/run/opendkim/opendkim.sock
non_smtpd_milters = \$smtpd_milters
EOF
        sudo cp /tmp/main.cf /etc/postfix/main.cf
        
        # Create socket directory
        sudo mkdir -p /var/run/opendkim
        sudo chown opendkim:opendkim /var/run/opendkim
        
        # Restart OpenDKIM
        sudo systemctl restart opendkim
        
        # Display DKIM DNS entry
        echo "🔑 DKIM DNS record (add this to your DNS zone):"
        echo "================================================"
        sudo cat /etc/opendkim/keys/$DOMAIN/mail.txt
        echo "================================================"
        echo "✅ DKIM configured"
    else
        echo "ℹ️ Skipping DKIM configuration as requested"
    fi
}

# Create SPF and DMARC DNS records if requested
configure_spf_dmarc() {
    if [ "$CONFIGURE_SPF" = true ]; then
        echo "📝 SPF DNS record (add this to your DNS zone):"
        echo "================================================"
        echo "$DOMAIN.    IN    TXT    \"v=spf1 mx a ip4:$(curl -s ifconfig.me) ~all\""
        echo "================================================"
        echo "✅ SPF record generated"
    else
        echo "ℹ️ Skipping SPF record generation as requested"
    fi
    
    if [ "$CONFIGURE_DMARC" = true ]; then
        echo "📝 DMARC DNS record (add this to your DNS zone):"
        echo "================================================"
        echo "_dmarc.$DOMAIN.    IN    TXT    \"v=DMARC1; p=none; sp=none; rua=mailto:$ADMIN_EMAIL; ruf=mailto:$ADMIN_EMAIL; fo=1; adkim=r; aspf=r; pct=100; rf=afrf\""
        echo "================================================"
        echo "✅ DMARC record generated"
    else
        echo "ℹ️ Skipping DMARC record generation as requested"
    fi
}

# Main function
main() {
    detect_distro
    parse_arguments "$@"
    check_arguments
    
    echo "🚀 Starting mail server setup for domain: $DOMAIN"
    echo "   Hostname: $HOSTNAME"
    echo "   Admin email: $ADMIN_EMAIL"
    echo "   Server type: $MAIL_SERVER_TYPE"
    echo "   Using MySQL: $USE_MYSQL"
    echo "   Using PostgreSQL: $USE_POSTGRES"
    echo "   Installing webmail: $INSTALL_WEBMAIL"
    echo "   Webmail type: $WEBMAIL_TYPE"
    echo "   IMAP server: $IMAP_SERVER"
    echo "   SMTP server: $SMTP_SERVER"
    echo "   Installing msmtp: $INSTALL_MSMTP"
    echo "   Configuring DKIM: $CONFIGURE_DKIM"
    echo "   Configuring SPF: $CONFIGURE_SPF"
    echo "   Configuring DMARC: $CONFIGURE_DMARC"
    echo "   Installing anti-spam: $INSTALL_ANTISPAM"
    echo "   Installing anti-virus: $INSTALL_ANTIVIRUS"
    
    update_system
    install_dependencies
    
    # Install SMTP server based on selection
    if [ "$SMTP_SERVER" = "postfix" ]; then
        install_postfix
    else
        echo "❌ Currently only Postfix is supported as SMTP server"
        install_postfix
    fi
    
    # Install IMAP server based on selection
    install_imap_server
    
    # Install msmtp if requested
    if [ "$INSTALL_MSMTP" = true ]; then
        install_msmtp
    fi
    
    if [ "$INSTALL_ANTISPAM" = true ]; then
        install_spamassassin
    fi
    
    if [ "$INSTALL_ANTIVIRUS" = true ]; then
        install_clamav
    fi
    
    if [ "$INSTALL_WEBMAIL" = true ]; then
        install_webmail
    fi
    
    if [ "$CONFIGURE_DKIM" = true ]; then
        configure_dkim
    fi
    
    configure_spf_dmarc
    
    # Restart services
    echo "🔄 Restarting mail services..."
    sudo systemctl restart postfix dovecot
    
    # Check services status
    echo "🔍 Checking mail services status..."
    echo "SMTP Server: $(systemctl is-active postfix)"
    
    if [ "$IMAP_SERVER" = "dovecot" ]; then
        echo "IMAP Server (Dovecot): $(systemctl is-active dovecot)"
    elif [ "$IMAP_SERVER" = "courier" ]; then
        echo "IMAP Server (Courier): $(systemctl is-active courier-imap)"
    fi
    
    if [ "$INSTALL_ANTISPAM" = true ]; then
        echo "SpamAssassin: $(systemctl is-active spamassassin)"
    fi
    if [ "$INSTALL_ANTIVIRUS" = true ]; then
        echo "ClamAV: $(systemctl is-active clamav-daemon)"
    fi
    if [ "$CONFIGURE_DKIM" = true ]; then
        echo "OpenDKIM: $(systemctl is-active opendkim)"
    fi
    
    if [ "$INSTALL_WEBMAIL" = true ]; then
        echo "Webmail (Apache): $(systemctl is-active apache2)"
    fi
    
    echo "✅ Mail server setup completed successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Add required DNS records (MX, SPF, DKIM, DMARC)"
    echo "2. Change the default admin password"
    echo "3. Configure SSL/TLS certificates with Let's Encrypt"
    echo "4. Test mail delivery with mail-tester.com"
    echo ""
    echo "✉️ Default mail account created:"
    echo "   Username: admin@$DOMAIN"
    echo "   Password: changeme"
    echo ""
    
    if [ "$INSTALL_WEBMAIL" = true ]; then
        echo "🌐 Webmail interface: http://$HOSTNAME/webmail"
        echo "   Type: $WEBMAIL_TYPE"
    fi
    
    echo ""
    echo "🔧 Server Configuration:"
    echo "   SMTP Server: $SMTP_SERVER"
    echo "   IMAP Server: $IMAP_SERVER"
    echo "   Webmail: $INSTALL_WEBMAIL ($WEBMAIL_TYPE)"
    echo ""
}

# Show help if no arguments provided
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Run main function with all arguments
main "$@"
