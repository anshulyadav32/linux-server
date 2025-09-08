#!/bin/bash
# SpamAssassin Manual Fix Script

# Stop services
systemctl stop spamass-milter spamd postfix

# Clean up socket
rm -f /var/spool/postfix/spamass/spamass.sock

# Set up directories
mkdir -p /var/spool/postfix/spamass
chown spamass-milter:postfix /var/spool/postfix/spamass
chmod 750 /var/spool/postfix/spamass

# Start SpamAssassin first
systemctl start spamd
sleep 2

# Start spamass-milter manually
/usr/sbin/spamass-milter -p /var/spool/postfix/spamass/spamass.sock -u spamass-milter -f

# Fix socket permissions
if [ -S /var/spool/postfix/spamass/spamass.sock ]; then
    chown spamass-milter:postfix /var/spool/postfix/spamass/spamass.sock
    chmod 660 /var/spool/postfix/spamass/spamass.sock
fi

# Start Postfix
systemctl start postfix
