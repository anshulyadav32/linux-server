#!/bin/bash
# Mail System Update Script

echo "============================================"
echo "        Updating Mail System"
echo "============================================"

# Update package lists
echo "[1/3] Updating package lists..."
apt update -y

# Update mail server packages
echo "[2/3] Updating mail server packages..."
apt upgrade -y postfix dovecot-imapd dovecot-pop3d dovecot-core roundcube roundcube-core roundcube-mysql spamassassin mailutils opendkim opendkim-tools

# Update SpamAssassin rules
echo "[3/3] Updating SpamAssassin rules..."
sa-update 2>/dev/null
systemctl restart spamassassin

echo "============================================"
echo "✅ Mail system updated successfully!"
echo ""
echo "Current versions:"
postconf mail_version
dovecot --version
spamassassin --version | head -1
echo "============================================"
read -p "Press Enter to continue..."
