#!/bin/bash
# Database Installation Script

echo "============================================"
echo "       Installing Database Systems"
echo "============================================"

# Update system packages
echo "[1/4] Updating system packages..."
apt update -y

# Install MySQL Server
echo "[2/4] Installing MySQL Server..."
debconf-set-selections <<< "mysql-server mysql-server/root_password password rootpass123"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password rootpass123"
apt install -y mysql-server mysql-client

# Install PostgreSQL
echo "[3/4] Installing PostgreSQL..."
apt install -y postgresql postgresql-contrib postgresql-client

# Install Redis (in-memory database)
echo "[4/4] Installing Redis..."
apt install -y redis-server

# Enable and start services
echo "Enabling database services..."
systemctl enable mysql
systemctl enable postgresql
systemctl enable redis-server
systemctl start mysql
systemctl start postgresql
systemctl start redis-server

# Secure MySQL installation (basic)
echo "Configuring MySQL..."
mysql -u root -prootpass123 -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin123';"
mysql -u root -prootpass123 -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;"
mysql -u root -prootpass123 -e "FLUSH PRIVILEGES;"

# Configure PostgreSQL
echo "Configuring PostgreSQL..."
sudo -u postgres createuser --superuser admin
sudo -u postgres psql -c "ALTER USER admin PASSWORD 'admin123';"

echo "============================================"
echo "✅ Database systems installed successfully!"
echo "✅ MySQL: Running (root/rootpass123, admin/admin123)"
echo "✅ PostgreSQL: Running (admin/admin123)"
echo "✅ Redis: Running"
echo ""
echo "📝 Security Note:"
echo "   Change default passwords immediately!"
echo "   Configure proper user permissions!"
echo "============================================"
read -p "Press Enter to continue..."
