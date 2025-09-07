#!/bin/bash
# setup-mail-quick.sh - Mail Server quick setup script
# Can be executed directly via: curl -sSL ls.r-u.live/sh/setup-mail-quick.sh | sudo bash

set -e

echo "====================================================="
echo "  Mail Server Setup Script - Quick Install"
echo "  From ls.r-u.live"
echo "====================================================="

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  echo "Try: sudo bash"
  exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$NAME
  VER=$VERSION_ID
else
  echo "Cannot detect OS. Exiting."
  exit 1
fi

echo "Detected: $OS $VER"

# Update system
echo "Updating system packages..."
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
  apt update -y
  apt upgrade -y
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
  yum update -y
else
  echo "Unsupported OS: $OS"
  exit 1
fi

# Get domain name for mail server
echo ""
echo "Please enter the domain name for your mail server:"
read -p "Domain (e.g., example.com): " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
  DOMAIN_NAME="example.com"
  echo "Using default domain: $DOMAIN_NAME"
fi

# Set hostname and FQDN
HOSTNAME="mail"
FQDN="${HOSTNAME}.${DOMAIN_NAME}"
echo "$FQDN" > /etc/hostname
hostname "$FQDN"

# Update hosts file
grep -v "$HOSTNAME" /etc/hosts > /etc/hosts.new
echo "127.0.1.1 $FQDN $HOSTNAME" >> /etc/hosts.new
mv /etc/hosts.new /etc/hosts

# Select mail components to install
echo ""
echo "Select mail server components:"
echo "1) Postfix + Dovecot + RoundCube (Recommended)"
echo "2) Postfix + Courier + SquirrelMail"
echo "3) Postfix only (SMTP server)"
read -p "Enter your choice [1-3]: " MAIL_COMPONENTS

case $MAIL_COMPONENTS in
  2)
    # Postfix + Courier + SquirrelMail
    SMTP_SERVER="postfix"
    IMAP_SERVER="courier"
    WEBMAIL="squirrelmail"
    ;;
  3)
    # Postfix only
    SMTP_SERVER="postfix"
    IMAP_SERVER="none"
    WEBMAIL="none"
    ;;
  *)
    # Default: Postfix + Dovecot + RoundCube
    SMTP_SERVER="postfix"
    IMAP_SERVER="dovecot"
    WEBMAIL="roundcube"
    ;;
esac

# Install SMTP server (Postfix)
echo "Installing SMTP server ($SMTP_SERVER)..."
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
  DEBIAN_FRONTEND=noninteractive apt install -y postfix
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
  yum install -y postfix
fi

# Configure Postfix
echo "Configuring Postfix..."
postconf -e "myhostname = $FQDN"
postconf -e "mydomain = $DOMAIN_NAME"
postconf -e "myorigin = \$mydomain"
postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"
postconf -e "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128"
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = all"
postconf -e "smtpd_banner = \$myhostname ESMTP \$mail_name"
postconf -e "smtpd_tls_cert_file = /etc/ssl/certs/ssl-cert-snakeoil.pem"
postconf -e "smtpd_tls_key_file = /etc/ssl/private/ssl-cert-snakeoil.key"
postconf -e "smtpd_tls_security_level = may"

# Install IMAP/POP3 server
if [[ "$IMAP_SERVER" == "dovecot" ]]; then
  echo "Installing IMAP/POP3 server (Dovecot)..."
  if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
    apt install -y dovecot-imapd dovecot-pop3d
  elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
    yum install -y dovecot
  fi
  
  # Configure Dovecot
  echo "Configuring Dovecot..."
  sed -i "s/#mail_location =/mail_location = maildir:~\/Maildir/" /etc/dovecot/conf.d/10-mail.conf
  sed -i "s/#disable_plaintext_auth = yes/disable_plaintext_auth = no/" /etc/dovecot/conf.d/10-auth.conf
  
elif [[ "$IMAP_SERVER" == "courier" ]]; then
  echo "Installing IMAP/POP3 server (Courier)..."
  if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
    apt install -y courier-imap courier-pop
  elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
    yum install -y courier-imap
  fi
fi

# Install webmail interface
if [[ "$WEBMAIL" == "roundcube" ]]; then
  echo "Installing webmail interface (Roundcube)..."
  if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
    apt install -y apache2 mariadb-server roundcube
    echo "Include /etc/roundcube/apache.conf" >> /etc/apache2/apache2.conf
  elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
    yum install -y httpd mariadb-server roundcubemail
  fi
  
elif [[ "$WEBMAIL" == "squirrelmail" ]]; then
  echo "Installing webmail interface (SquirrelMail)..."
  if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
    apt install -y apache2 squirrelmail
  elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
    yum install -y httpd squirrelmail
  fi
fi

# Install spam filter
echo "Installing SpamAssassin..."
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
  apt install -y spamassassin spamc
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
  yum install -y spamassassin
fi

# Create mail user
echo "Creating mail user..."
read -p "Enter username for mail account: " MAIL_USER
if [ -z "$MAIL_USER" ]; then
  MAIL_USER="user"
  echo "Using default username: $MAIL_USER"
fi

# Generate random password if user doesn't provide one
read -s -p "Enter password for $MAIL_USER@$DOMAIN_NAME (or leave blank for auto-generated): " MAIL_PASS
echo ""

if [ -z "$MAIL_PASS" ]; then
  MAIL_PASS=$(tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom | head -c 12)
  echo "Generated password: $MAIL_PASS"
fi

# Add user
if id "$MAIL_USER" &>/dev/null; then
  echo "User $MAIL_USER already exists"
else
  useradd -m -s /bin/bash "$MAIL_USER"
  echo "$MAIL_USER:$MAIL_PASS" | chpasswd
  echo "Created user $MAIL_USER with password $MAIL_PASS"
  
  # Create Maildir
  mkdir -p /home/$MAIL_USER/Maildir/{new,cur,tmp}
  chown -R $MAIL_USER:$MAIL_USER /home/$MAIL_USER/Maildir
fi

# Configure firewall
echo "Configuring firewall for mail services..."
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
  apt install -y ufw
  ufw allow 25/tcp   # SMTP
  ufw allow 465/tcp  # SMTPS
  ufw allow 587/tcp  # Submission
  ufw allow 110/tcp  # POP3
  ufw allow 995/tcp  # POP3S
  ufw allow 143/tcp  # IMAP
  ufw allow 993/tcp  # IMAPS
  ufw allow 80/tcp   # HTTP (webmail)
  ufw allow 443/tcp  # HTTPS (webmail)
  echo "y" | ufw enable
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
  yum install -y firewalld
  systemctl enable firewalld
  systemctl start firewalld
  firewall-cmd --permanent --add-service=smtp
  firewall-cmd --permanent --add-service=smtps
  firewall-cmd --permanent --add-service=pop3
  firewall-cmd --permanent --add-service=pop3s
  firewall-cmd --permanent --add-service=imap
  firewall-cmd --permanent --add-service=imaps
  firewall-cmd --permanent --add-service=http
  firewall-cmd --permanent --add-service=https
  firewall-cmd --reload
fi

# Restart services
echo "Restarting mail services..."
systemctl restart postfix
if [[ "$IMAP_SERVER" == "dovecot" ]]; then
  systemctl restart dovecot
elif [[ "$IMAP_SERVER" == "courier" ]]; then
  systemctl restart courier-imap
fi

if [[ "$WEBMAIL" != "none" ]]; then
  if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
    systemctl restart apache2
  elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
    systemctl restart httpd
  fi
fi

echo "====================================================="
echo "  Mail Server setup complete!"
echo "====================================================="
echo "Server configuration:"
echo "- Domain: $DOMAIN_NAME"
echo "- SMTP Server: $SMTP_SERVER"
echo "- IMAP/POP3 Server: $IMAP_SERVER"
echo "- Webmail Interface: $WEBMAIL"
echo ""
echo "Test account:"
echo "- Email: $MAIL_USER@$DOMAIN_NAME"
echo "- Password: $MAIL_PASS"
echo ""
if [[ "$WEBMAIL" != "none" ]]; then
  echo "Access webmail at: http://$FQDN/webmail"
fi
echo "====================================================="
echo "  Visit ls.r-u.live for more scripts"
echo "====================================================="

exit 0
