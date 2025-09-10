

#!/bin/bash


echo "Installing Webserver module..."
sudo su -c "bash $(pwd)/modules/webserver/install.sh" &
webserver_pid=$!

echo "Installing Database module..."
sudo su -c "bash $(pwd)/modules/database/install.sh" &
database_pid=$!

wait $webserver_pid
webserver_status=$?
wait $database_pid
database_status=$?

if [ $webserver_status -eq 0 ] && [ $database_status -eq 0 ]; then
	echo "Both installations completed successfully."
else
	echo "One or both installations failed."
	exit 1
fi
