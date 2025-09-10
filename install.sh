echo "Installing Firewall module..."
sudo su -c "bash $(pwd)/modules/firewall/install.sh" &
firewall_pid=$!

echo "Installing SSL module..."
sudo su -c "bash $(pwd)/modules/ssl/install.sh" &
ssl_pid=$!

echo "Installing Backup module..."
sudo su -c "bash $(pwd)/modules/backup/install.sh" &
backup_pid=$!

wait $firewall_pid
firewall_status=$?
wait $ssl_pid
ssl_status=$?
wait $backup_pid
backup_status=$?


#!/bin/bash


echo "Installing Database module..."
sudo su -c "bash $(pwd)/modules/database/install.sh" &
database_pid=$!
wait $webserver_pid
wait $database_pid
echo "Installing Webserver module..."
sudo su -c "bash $(pwd)/modules/webserver/install.sh" &
webserver_pid=$!

echo "Installing Database module..."
sudo su -c "bash $(pwd)/modules/database/install.sh" &
database_pid=$!

echo "Installing DNS module..."
sudo su -c "bash $(pwd)/modules/dns/install.sh" &
dns_pid=$!

wait $webserver_pid
webserver_status=$?
wait $database_pid
database_status=$?
wait $dns_pid
dns_status=$?

if [ $webserver_status -eq 0 ] && [ $database_status -eq 0 ] && [ $dns_status -eq 0 ] && [ $firewall_status -eq 0 ] && [ $ssl_status -eq 0 ] && [ $backup_status -eq 0 ]; then
	echo "All installations completed successfully."
else
	echo "One or more installations failed."
	exit 1
fi
