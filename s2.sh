#!/bin/bash
# s2.sh - Check for required dependencies for linux-server modules

REQUIRED_CMDS=(git curl bash sudo)
MODULES=(webserver database dns firewall ssl backup)

missing=()

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing+=("$cmd")
    fi
done

if [ ${#missing[@]} -ne 0 ]; then
    echo "Missing required commands: ${missing[*]}"
    echo "Please install them before running linux-server."
    exit 1
else
    echo "All base dependencies are installed."
fi

for module in "${MODULES[@]}"; do
    script="modules/$module/install.sh"
    if [ ! -f "$script" ]; then
        echo "Warning: $script not found. $module module may not install."
    fi
done

echo "Dependency check complete."
