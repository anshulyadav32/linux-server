#!/bin/bash
# Remote installer for linux-server
set -e

echo "Cloning linux-server repository..."
git clone https://github.com/anshulyadav32/linux-server.git
cd linux-server
echo "Running install.sh..."
sudo bash install.sh
