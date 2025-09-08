#!/bin/bash

# install-all.sh - Sequential installation of all modules
# Author: System Setup Script
# Description: Executes each module's install.sh script in proper order

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# Define installation order (dependencies first)
MODULES=(
    "database"
    "firewall" 
    "webserver"
    "ssl"
    "mail"
    "dns"
    "backup"
)

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "info")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "success")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "warning")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "error")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
    esac
}

# Function to install a single module
install_module() {
    local module=$1
    local install_script="$MODULES_DIR/$module/install.sh"
    
    print_status "info" "Starting installation of module: $module"
    
    # Check if install script exists
    if [[ ! -f "$install_script" ]]; then
        print_status "error" "Install script not found: $install_script"
        return 1
    fi
    
    # Make script executable
    chmod +x "$install_script"
    
    # Execute the install script
    if bash "$install_script"; then
        print_status "success" "Module $module installed successfully"
        return 0
    else
        print_status "error" "Module $module installation failed"
        return 1
    fi
}

# Function to show installation summary
show_summary() {
    echo ""
    echo "============================================"
    echo "         INSTALLATION SUMMARY"
    echo "============================================"
    echo "Total modules: ${#MODULES[@]}"
    echo "Successful: $successful_count"
    echo "Failed: $failed_count"
    
    if [[ $failed_count -gt 0 ]]; then
        echo ""
        echo "Failed modules:"
        for module in "${failed_modules[@]}"; do
            echo "  - $module"
        done
    fi
    echo "============================================"
}

# Main installation function
main() {
    print_status "info" "Starting sequential module installation"
    echo ""
    
    # Initialize counters
    local successful_count=0
    local failed_count=0
    local failed_modules=()
    
    # Install each module
    for module in "${MODULES[@]}"; do
        echo ""
        echo "----------------------------------------"
        if install_module "$module"; then
            ((successful_count++))
        else
            ((failed_count++))
            failed_modules+=("$module")
        fi
        echo "----------------------------------------"
        
        # Pause between installations
        if [[ $successful_count -lt ${#MODULES[@]} ]]; then
            print_status "info" "Waiting 2 seconds before next installation..."
            sleep 2
        fi
    done
    
    # Show summary
    show_summary
    
    # Exit with appropriate code
    if [[ $failed_count -eq 0 ]]; then
        print_status "success" "All modules installed successfully!"
        exit 0
    else
        print_status "error" "Some modules failed to install. Check logs above."
        exit 1
    fi
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_status "warning" "This script should be run as root for proper installation"
    print_status "info" "Continuing anyway..."
fi

# Check if modules directory exists
if [[ ! -d "$MODULES_DIR" ]]; then
    print_status "error" "Modules directory not found: $MODULES_DIR"
    exit 1
fi

# Start main installation
main "$@"
