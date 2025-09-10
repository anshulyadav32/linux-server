#!/bin/bash
# Mail Functions Library
# Reusable functions for mail server management

#===========================================
# INSTALLATION FUNCTIONS
#===========================================

install_mail() {
    echo "[INFO] Installing mail server components..."
    
    # Update package list
    apt update -y
    
    # Install Postfix (SMTP) and Dovecot (IMAP/POP3)
    debconf-set-selections <<< "postfix postfix/mailname string $(hostname -f)"
    debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
    
    apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d \
                   dovecot-lmtpd dovecot-mysql opendkim opendkim-tools \
                   spamassassin clamav clamav-daemon amavisd-new
    
    # Start and enable services
    systemctl enable postfix dovecot opendkim spamassassin clamav-daemon
    systemctl start postfix dovecot opendkim spamassassin clamav-daemon
    
    # Configure basic mail settings
    configure_mail_defaults
    echo "[SUCCESS] Mail server installed"
}

configure_mail_defaults() {
    echo "[INFO] Configuring basic mail settings..."
    
    # Basic Postfix configuration
    postconf -e "myhostname = $(hostname -f)"
    postconf -e "mydomain = $(hostname -d)"
    postconf -e "myorigin = \$mydomain"
    postconf -e "inet_interfaces = all"
    postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"
    postconf -e "home_mailbox = Maildir/"
    
    # Basic Dovecot configuration
    sed -i 's/#mail_location = /mail_location = maildir:~\/Maildir/' /etc/dovecot/conf.d/10-mail.conf
    sed -i 's/#listen = \*, ::/listen = */' /etc/dovecot/dovecot.conf
    
    restart_mail_services
}

#===========================================
# USER MANAGEMENT FUNCTIONS
#===========================================

add_mail_user() {
    local username="$1"
    local password="$2"
    local domain="${3:-$(hostname -d)}"
    
    if [[ -z "$username" || -z "$password" ]]; then
        echo "[ERROR] Username and password parameters required"
        return 1
    fi
    
    echo "[INFO] Adding mail user: $username@$domain"
    
    # Create system user for mail
    useradd -m -s /bin/bash "$username" 2>/dev/null || {
        echo "[INFO] User $username already exists, updating password..."
    }
    
    # Set password
    echo "$username:$password" | chpasswd
    
    # Create Maildir
    mkdir -p "/home/$username/Maildir"
    chown -R "$username:$username" "/home/$username/Maildir"
    
    echo "[SUCCESS] Mail user $username@$domain added"
}

remove_mail_user() {
    local username="$1"
    
    if [[ -z "$username" ]]; then
        echo "[ERROR] Username parameter required"
        return 1
    fi
    
    echo "[INFO] Removing mail user: $username"
    
    # Remove user and home directory
    userdel -r "$username" 2>/dev/null
    
    echo "[SUCCESS] Mail user $username removed"
}

list_mail_users() {
    echo "[INFO] Mail users on system:"
    getent passwd | grep "/home/" | cut -d: -f1,5 | while IFS=: read username fullname; do
        if [[ -d "/home/$username/Maildir" ]]; then
            echo "  - $username ($fullname)"
        fi
    done
}

change_mail_password() {
    local username="$1"
    local new_password="$2"
    
    if [[ -z "$username" || -z "$new_password" ]]; then
        echo "[ERROR] Username and new password parameters required"
        return 1
    fi
    
    echo "[INFO] Changing password for: $username"
    echo "$username:$new_password" | chpasswd
    echo "[SUCCESS] Password changed for $username"
}

#===========================================
# DOMAIN MANAGEMENT FUNCTIONS
#===========================================

add_mail_domain() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Adding mail domain: $domain"
    
    # Add to Postfix virtual domains
    echo "$domain" >> /etc/postfix/virtual_domains
    postconf -e "virtual_mailbox_domains = hash:/etc/postfix/virtual_domains"
    postmap /etc/postfix/virtual_domains
    
    restart_mail_services
    echo "[SUCCESS] Mail domain $domain added"
}

remove_mail_domain() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Removing mail domain: $domain"
    
    # Remove from virtual domains
    sed -i "/$domain/d" /etc/postfix/virtual_domains
    postmap /etc/postfix/virtual_domains
    
    restart_mail_services
    echo "[SUCCESS] Mail domain $domain removed"
}

#===========================================
# ALIAS MANAGEMENT FUNCTIONS
#===========================================

add_mail_alias() {
    local alias="$1"
    local destination="$2"
    
    if [[ -z "$alias" || -z "$destination" ]]; then
        echo "[ERROR] Alias and destination parameters required"
        return 1
    fi
    
    echo "[INFO] Adding mail alias: $alias -> $destination"
    
    # Add to aliases file
    echo "$alias: $destination" >> /etc/aliases
    newaliases
    
    echo "[SUCCESS] Mail alias added"
}

remove_mail_alias() {
    local alias="$1"
    
    if [[ -z "$alias" ]]; then
        echo "[ERROR] Alias parameter required"
        return 1
    fi
    
    echo "[INFO] Removing mail alias: $alias"
    
    # Remove from aliases file
    sed -i "/^$alias:/d" /etc/aliases
    newaliases
    
    echo "[SUCCESS] Mail alias removed"
}

list_mail_aliases() {
    echo "[INFO] Mail aliases:"
    grep -v "^#" /etc/aliases | grep -v "^$" | head -20
}

#===========================================
# SECURITY FUNCTIONS
#===========================================

configure_dkim() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] Configuring DKIM for: $domain"
    
    # Create DKIM directory
    mkdir -p "/etc/opendkim/keys/$domain"
    cd "/etc/opendkim/keys/$domain"
    
    # Generate DKIM keys
    opendkim-genkey -t -s mail -d "$domain"
    chown opendkim:opendkim mail.private
    
    # Configure DKIM
    echo "mail._domainkey.$domain $domain:mail:/etc/opendkim/keys/$domain/mail.private" >> /etc/opendkim/KeyTable
    echo "*@$domain mail._domainkey.$domain" >> /etc/opendkim/SigningTable
    echo "$domain" >> /etc/opendkim/TrustedHosts
    
    # Display DNS record
    echo "[INFO] Add this TXT record to your DNS:"
    echo "mail._domainkey IN TXT"
    cat "/etc/opendkim/keys/$domain/mail.txt"
    
    restart_mail_services
    echo "[SUCCESS] DKIM configured for $domain"
}

configure_spf() {
    local domain="$1"
    local server_ip="$2"
    
    if [[ -z "$domain" || -z "$server_ip" ]]; then
        echo "[ERROR] Domain and server IP parameters required"
        return 1
    fi
    
    echo "[INFO] SPF record for $domain:"
    echo "Add this TXT record to your DNS:"
    echo "$domain IN TXT \"v=spf1 ip4:$server_ip ~all\""
}

configure_dmarc() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        echo "[ERROR] Domain parameter required"
        return 1
    fi
    
    echo "[INFO] DMARC record for $domain:"
    echo "Add this TXT record to your DNS:"
    echo "_dmarc.$domain IN TXT \"v=DMARC1; p=quarantine; rua=mailto:dmarc@$domain\""
}

#===========================================
# SERVICE MANAGEMENT FUNCTIONS
#===========================================

restart_mail_services() {
    echo "[INFO] Restarting mail services..."
    systemctl restart postfix
    systemctl restart dovecot
    systemctl restart opendkim
    
    if systemctl is-active --quiet postfix && systemctl is-active --quiet dovecot; then
        echo "[SUCCESS] Mail services restarted successfully"
    else
        echo "[ERROR] Some mail services failed to restart"
        return 1
    fi
}

status_mail_services() {
    echo "[INFO] Mail service status:"
    echo "=== Postfix (SMTP) ==="
    systemctl status postfix --no-pager | head -5
    echo ""
    echo "=== Dovecot (IMAP/POP3) ==="
    systemctl status dovecot --no-pager | head -5
    echo ""
    echo "=== OpenDKIM ==="
    systemctl status opendkim --no-pager | head -5
    echo ""
    echo "Listening ports:"
    netstat -tlnp | grep -E ":25|:587|:993|:995|:110|:143"
}

#===========================================
# MONITORING FUNCTIONS
#===========================================

view_mail_logs() {
    echo "[INFO] Recent mail logs:"
    tail -30 /var/log/mail.log
}

view_mail_queue() {
    echo "[INFO] Mail queue status:"
    postqueue -p
}

clear_mail_queue() {
    echo "[INFO] Clearing mail queue..."
    postsuper -d ALL
    echo "[SUCCESS] Mail queue cleared"
}

test_mail_delivery() {
    local recipient="$1"
    local subject="${2:-Test Mail}"
    
    if [[ -z "$recipient" ]]; then
        echo "[ERROR] Recipient email parameter required"
        return 1
    fi
    
    echo "[INFO] Sending test email to: $recipient"
    echo "This is a test email from $(hostname -f)" | mail -s "$subject" "$recipient"
    echo "[SUCCESS] Test email sent"
}

#===========================================
# MAINTENANCE FUNCTIONS
#===========================================

backup_mail_config() {
    local backup_dir="/root/mail-backup-$(date +%Y%m%d)"
    echo "[INFO] Backing up mail configuration to: $backup_dir"
    
    mkdir -p "$backup_dir"
    cp -r /etc/postfix "$backup_dir/"
    cp -r /etc/dovecot "$backup_dir/"
    cp -r /etc/opendkim "$backup_dir/"
    cp /etc/aliases "$backup_dir/"
    
    tar -czf "$backup_dir.tar.gz" -C "$(dirname $backup_dir)" "$(basename $backup_dir)"
    rm -rf "$backup_dir"
    
    echo "[SUCCESS] Mail configuration backed up to: $backup_dir.tar.gz"
}

#===========================================
# UPDATE FUNCTIONS
#===========================================

update_mail() {
    echo "[INFO] Updating mail server packages..."
    apt update -y
    apt upgrade -y postfix dovecot-core dovecot-imapd dovecot-pop3d \
                   dovecot-lmtpd opendkim opendkim-tools spamassassin \
                   clamav clamav-daemon amavisd-new
    
    # Update ClamAV virus definitions
    freshclam
    
    restart_mail_services
    echo "[SUCCESS] Mail server updated"
}
