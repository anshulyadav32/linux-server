#!/bin/bash
# Database Update Script

echo "Updating database systems..."
apt update -y
apt upgrade -y mysql-server mysql-client postgresql postgresql-contrib redis-server
echo "✅ Database systems updated!"
read -p "Press Enter to continue..."
