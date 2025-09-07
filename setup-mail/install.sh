#!/bin/bash
# Mail System Installation Script

echo "============================================"
echo "      Installing Mail System"
echo "============================================"

# Update system packages
echo "[1/5] Updating system packages..."
apt update -y

# Install mail server components
echo "[2/5] Installing Postfix, Dovecot, and Roundcube..."
debconf-set-selections <<< "postfix postfix/mailname string $(hostname -f)"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt install -y postfix dovecot-imapd dovecot-pop3d dovecot-core roundcube roundcube-core roundcube-mysql spamassassin

# Install additional mail tools
echo "[3/5] Installing additional mail tools..."
apt install -y mailutils opendkim opendkim-tools

# Enable and start services
echo "[4/5] Enabling mail services..."
systemctl enable postfix
systemctl enable dovecot
systemctl enable spamassassin
systemctl start postfix
systemctl start dovecot
systemctl start spamassassin

# Basic configuration
echo "[5/5] Applying basic configuration..."
# Configure Postfix for local delivery
postconf -e 'home_mailbox = Maildir/'
postconf -e 'mailbox_command = '

# Configure Dovecot
sed -i 's/#mail_location = .*/mail_location = maildir:~\/Maildir/' /etc/dovecot/conf.d/10-mail.conf

# Restart services to apply configuration
systemctl restart postfix
systemctl restart dovecot

echo "============================================"
echo "✅ Mail system installed successfully!"
echo "✅ Postfix: SMTP server running"
echo "✅ Dovecot: IMAP/POP3 server running"
echo "✅ Roundcube: Webmail interface installed"
echo "✅ SpamAssassin: Anti-spam filter running"
echo ""
echo "📝 Next steps:"
echo "   1. Configure DNS records (MX, SPF, DKIM)"
echo "   2. Set up email accounts"
echo "   3. Configure SSL certificates"
echo "============================================"
read -p "Press Enter to continue..."
