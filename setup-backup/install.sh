#!/bin/bash
# Backup Installation Script

echo "============================================"
echo "        Installing Backup System"
echo "============================================"

apt update -y
apt install -y rsync cron borgbackup

# Create backup directory
mkdir -p /backup
mkdir -p /backup/daily
mkdir -p /backup/weekly
mkdir -p /backup/monthly

# Create backup script
cat > /usr/local/bin/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf /backup/daily/system_$DATE.tar.gz /etc /var/www /home
find /backup/daily -type f -mtime +7 -delete
EOF

chmod +x /usr/local/bin/backup.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup.sh") | crontab -

echo "✅ Backup system installed successfully!"
echo "✅ Backup directory: /backup"
echo "✅ Daily backup scheduled at 2 AM"
read -p "Press Enter to continue..."
