#!/bin/bash
# SpamAssassin Fix Script

# Create spamd user if it doesn't exist
# Configure spamass-milter default file
cat > /etc/default/spamass-milter << 'EOF'
# Enable spamass-milter
ENABLED=1

# Specify options here
# -p: socket path
# -f: fork into background
OPTIONS="-p /var/spool/postfix/spamass/spamass.sock -u spamass-milter -f"
EOF &>/dev/null; then
    useradd --system -d /var/lib/spamassassin -s /sbin/nologin -m spamd
fi

# Create spamass-milter user if it doesn't exist
if ! id spamass-milter &>/dev/null; then
    useradd -r -s /bin/false spamass-milter
fi

# Configure SpamAssassin default file
cat > /etc/default/spamassassin << 'EOF'
# /etc/default/spamassassin

# Change to one to enable spamd
ENABLED=1

# Options
# See man spamd for possible options. The -d option is automatically added.
OPTIONS="--create-prefs --max-children 5 --helper-home-dir"

# Pid file
PIDFILE="/var/run/spamd.pid"

# Set nice level of spamd
#NICE="--nicelevel 15"

# Enable automatic rule updates
CRON=1
EOF
chmod 644 /etc/default/spamassassin

# Create and configure spamass-milter socket directory
mkdir -p /var/spool/postfix/spamass
chown spamass-milter:postfix /var/spool/postfix/spamass
chmod 750 /var/spool/postfix/spamass

# Configure spamass-milter systemd socket
cat > /etc/systemd/system/spamass-milter.socket << 'EOF'
[Unit]
Description=SpamAssassin Milter Socket
Documentation=man:spamass-milter(1)
Before=spamass-milter.service

[Socket]
ListenStream=/var/spool/postfix/spamass/spamass.sock
SocketUser=spamass-milter
SocketGroup=postfix
SocketMode=0660

[Install]
WantedBy=sockets.target
EOF
chmod 644 /etc/systemd/system/spamass-milter.socket

# Configure spamass-milter
cat > /etc/default/spamass-milter << 'EOF'
# Defaults for spamass-milter

# Enable spamass-milter
ENABLED=1

# Specify options here
OPTIONS="-i 127.0.0.1"
EOF
chmod 644 /etc/default/spamass-milter

# Update SpamAssassin rules
sa-update

# Stop all services
systemctl stop spamass-milter spamass-milter.socket spamd || true

# Clean up any existing sockets
rm -f /var/spool/postfix/spamass/spamass.sock

# Configure default file with correct socket path
cat > /etc/default/spamass-milter << 'EOF'
# Enable spamass-milter
ENABLED=1

# Use a socket in the Postfix chroot
SOCKET="/var/spool/postfix/spamass/spamass.sock"
SOCKETOWNER="spamass-milter:postfix"
SOCKETMODE="0660"

# Additional options
OPTIONS="-i 127.0.0.1"
EOF
chmod 644 /etc/default/spamass-milter

# Create and set socket directory permissions
rm -rf /var/spool/postfix/spamass
mkdir -p /var/spool/postfix/spamass
chown spamass-milter:postfix /var/spool/postfix/spamass
chmod 750 /var/spool/postfix/spamass

# Enable and start services
systemctl enable spamd
systemctl enable spamass-milter
systemctl start spamd
systemctl start spamass-milter

# Wait for socket creation
sleep 5

# Verify socket exists and fix permissions if needed
if [ -S "/var/spool/postfix/spamass/spamass.sock" ]; then
    chown spamass-milter:postfix /var/spool/postfix/spamass/spamass.sock
    chmod 660 /var/spool/postfix/spamass/spamass.sock
fi

# Check if socket exists and has correct permissions
if [ -S "/var/spool/postfix/spamass/spamass.sock" ]; then
    chown spamass-milter:postfix /var/spool/postfix/spamass/spamass.sock
    chmod 660 /var/spool/postfix/spamass/spamass.sock
    
    # Configure Postfix to use spamass-milter
    postconf -e "smtpd_milters = unix:/var/spool/postfix/spamass/spamass.sock"
    postconf -e "non_smtpd_milters = unix:/var/spool/postfix/spamass/spamass.sock"
    systemctl reload postfix
    
    echo "SpamAssassin configuration completed successfully"
else
    echo "Error: spamass-milter socket not created"
    exit 1
fi
