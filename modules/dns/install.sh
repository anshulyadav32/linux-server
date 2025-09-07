#!/bin/bash
# Enhanced DNS Server Installation Script with Dependency Management and Error Handling

# Get base directory and source functions
BASE_DIR="$(dirname "$0")"
source "$BASE_DIR/functions.sh"
source "$(dirname "$BASE_DIR")/common.sh"

# Define required packages
REQUIRED_PACKAGES=(
    "bind9"
    "bind9utils"
    "bind9-doc"
    "dnsutils"
    "resolvconf"
    "net-tools"
)

# Initialize installation status tracking
declare -A INSTALLED_PACKAGES
declare -A FAILED_PACKAGES
MAX_RETRIES=3

# Function to check system requirements
check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
    
    # Check system memory
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $total_mem -lt 512 ]]; then
        log_warn "System has less than 512MB RAM. DNS server may not perform optimally."
        if ! confirm_action "Continue anyway?"; then
            exit 1
        fi
    fi
    
    # Check available disk space
    local available_space=$(df -m /var | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 1024 ]]; then
        log_warn "Less than 1GB free space available. This might be insufficient."
        if ! confirm_action "Continue anyway?"; then
            exit 1
        fi
    fi
}

# Function to install a single package with retry mechanism
install_package() {
    local package=$1
    local retries=0
    
    while [[ $retries -lt $MAX_RETRIES ]]; do
        log_info "Installing package: $package (Attempt $(($retries + 1))/$MAX_RETRIES)"
        
        if apt-get install -y "$package" >/dev/null 2>&1; then
            INSTALLED_PACKAGES[$package]=1
            log_ok "Successfully installed $package"
            return 0
        else
            retries=$((retries + 1))
            log_warn "Failed to install $package (Attempt $retries/$MAX_RETRIES)"
            
            if [[ $retries -lt $MAX_RETRIES ]]; then
                log_info "Retrying in 5 seconds..."
                sleep 5
                apt-get update -y >/dev/null 2>&1
            fi
        fi
    done
    
    FAILED_PACKAGES[$package]=1
    return 1
}

# Function to verify DNS service is running correctly
verify_dns_service() {
    log_info "Verifying DNS service..."
    
    # Check if bind9 service is running
    if ! systemctl is-active --quiet bind9; then
        log_error "BIND9 service is not running"
        systemctl start bind9
        if ! systemctl is-active --quiet bind9; then
            return 1
        fi
    fi
    
    # Test DNS resolution
    if ! nslookup google.com 127.0.0.1 >/dev/null 2>&1; then
        log_error "DNS resolution test failed"
        return 1
    fi
    
    # Check port 53 is listening
    if ! netstat -tuln | grep -q ":53 "; then
        log_error "DNS port 53 is not listening"
        return 1
    fi
    
    return 0
}

# Function to create checkpoint file
create_checkpoint() {
    local checkpoint_file="/var/lib/dns_install_checkpoint"
    declare -p INSTALLED_PACKAGES > "$checkpoint_file"
}

# Function to restore from checkpoint
restore_from_checkpoint() {
    local checkpoint_file="/var/lib/dns_install_checkpoint"
    if [[ -f "$checkpoint_file" ]]; then
        source "$checkpoint_file"
        log_info "Restored installation progress from checkpoint"
    fi
}

# Main installation function
main() {
    clear
    show_header "DNS SERVER INSTALLATION"
    
    log_info "Starting enhanced DNS server installation..."
    echo ""
    
    # Check system requirements
    check_system_requirements
    
    # Restore from checkpoint if exists
    restore_from_checkpoint
    
    # Update package lists
    log_info "Updating package lists..."
    apt-get update -y
    
    # Install required packages
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if [[ -z "${INSTALLED_PACKAGES[$package]}" ]]; then
            install_package "$package"
            create_checkpoint
        else
            log_info "Package $package is already installed"
        fi
    done
    
    # Check for any failed packages
    if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
        log_error "The following packages failed to install:"
        for package in "${!FAILED_PACKAGES[@]}"; do
            echo "  ✗ $package"
        done
        if ! confirm_action "Continue with installation?"; then
            exit 1
        fi
    fi
    
    # Configure DNS server
    log_info "Configuring DNS server..."
    configure_dns_defaults
    
    # Verify installation
    if verify_dns_service; then
        log_ok "DNS service verification successful"
    else
        log_error "DNS service verification failed"
        if ! confirm_action "Continue anyway?"; then
            exit 1
        fi
    fi
    
    # Display installation summary
    echo ""
    log_ok "DNS server installation completed!"
    echo ""
    log_info "Successfully installed packages:"
    for package in "${!INSTALLED_PACKAGES[@]}"; do
        echo "  ✓ $package"
    done
    
    if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
        echo ""
        log_warn "Failed packages:"
        for package in "${!FAILED_PACKAGES[@]}"; do
            echo "  ✗ $package"
        done
    fi
    
    echo ""
    log_info "DNS server is now configured with:"
    echo "  ✓ BIND9 DNS server"
    echo "  ✓ Basic security configuration"
    echo "  ✓ Forwarders configured (Google DNS, Cloudflare)"
    echo "  ✓ Zone management tools"
    echo ""
    echo "Next steps:"
    echo "  - Add DNS zones for your domains"
    echo "  - Configure DNS records (A, CNAME, MX, etc.)"
    echo "  - Update nameserver settings with your domain registrar"
    echo ""
    
    # Show server IP for reference
    local server_ip=$(get_server_ip)
    log_info "Your server IP address: $server_ip"
    echo "Use this IP when configuring nameservers at your domain registrar"
    echo ""
    
    pause "Press Enter to return to DNS management menu..."
}

# Run main function
main "$@"
