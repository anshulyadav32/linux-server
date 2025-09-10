

#!/bin/bash


echo "Installing Webserver module..."
sudo su -c "bash $(pwd)/modules/webserver/install.sh" &

echo "Installing Database module..."
sudo su -c "bash $(pwd)/modules/database/install.sh" &

wait
echo "Both installations completed."
