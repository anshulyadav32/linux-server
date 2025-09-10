
#!/bin/bash

# Switch to root user before running the webserver and DNS install scripts
echo "Installing Webserver module..."
sudo su -c "bash $(pwd)/modules/webserver/install.sh"

echo "Installing DNS module..."
sudo su -c "bash $(pwd)/modules/dns/install.sh"

echo "Installing Database module..."
sudo su -c "bash $(pwd)/modules/database/install.sh"
echo "Running Database maintenance..."
sudo su -c "bash $(pwd)/modules/database/maintain.sh"

echo "Installing Firewall module..."
sudo su -c "bash $(pwd)/modules/firewall/install.sh"
echo "Running Firewall maintenance..."
sudo su -c "bash $(pwd)/modules/firewall/maintain.sh"
