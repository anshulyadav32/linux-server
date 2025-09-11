#!/bin/bash
run_and_checkpoint() {
    local name="$1"
    local script="$2"
    echo "Installing $name module..."
    sudo bash "$script"
    local status=$?
    if [ $status -eq 0 ]; then
        echo "[Checkpoint] $name module installed successfully."
    else
        echo "[Checkpoint] $name module installation failed. Exiting."
        exit 1
    fi
}

run_and_checkpoint "Webserver" "$(pwd)/modules/webserver/install.sh"

echo "Webserver installation completed successfully."
