
#!/bin/bash

# Switch to root user before running the webserver and DNS install scripts
echo "Installing Webserver module..."
sudo su -c "bash $(pwd)/modules/webserver/install.sh"

echo "Installing DNS module..."
sudo su -c "bash $(pwd)/modules/dns/install.sh"


echo "Installing Database module..."
sudo su -c "bash $(pwd)/modules/database/install.sh"
echo "Running Database main script..."
sudo su -c "bash $(pwd)/modules/database/main.sh"
echo "Running Database maintenance..."
sudo su -c "bash $(pwd)/modules/database/maintain.sh"
echo "Running Database menu script..."
sudo su -c "bash $(pwd)/modules/database/menu.sh"
echo "Running Database update script..."
sudo su -c "bash $(pwd)/modules/database/update.sh"
echo "Running Database functions script..."
sudo su -c "bash $(pwd)/modules/database/functions.sh"

echo "Installing Firewall module..."
sudo su -c "bash $(pwd)/modules/firewall/install.sh"
echo "Running Firewall maintenance..."
sudo su -c "bash $(pwd)/modules/firewall/maintain.sh"
