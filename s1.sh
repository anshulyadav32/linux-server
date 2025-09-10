#!/bin/bash
# Remote installer for linux-server
set -e


if [ -d "linux-server" ]; then
	echo "linux-server directory exists. Pulling latest changes..."
	cd linux-server
	git pull origin main
else
	echo "Cloning linux-server repository..."
	git clone https://github.com/anshulyadav32/linux-server.git
	cd linux-server
fi
echo "Running install.sh..."
sudo bash install.sh
