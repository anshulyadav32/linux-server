#!/bin/bash
# Remote installer for linux-server
set -e

# Check if specific module is requested
MODULE="$1"

if [ -d "linux-server" ]; then
	echo "linux-server directory exists. Pulling latest changes..."
	cd linux-server
	git pull origin main
else
	echo "Cloning linux-server repository..."
	git clone https://github.com/anshulyadav32/linux-server.git
	cd linux-server
fi

if [ -n "$MODULE" ]; then
	echo "Installing specific module: $MODULE"
	if [ -f "modules/$MODULE/install.sh" ]; then
		sudo bash "modules/$MODULE/install.sh"
	else
		echo "Error: Module '$MODULE' not found"
		echo "Available modules: webserver, database, dns, domain, firewall, ssl, backup"
		exit 1
	fi
else
	echo "Running full installation..."
	sudo bash install.sh
fi
