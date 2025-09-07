#!/bin/bash
# Common functions & colors for server management system

# Color definitions
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Logging functions
log_info() { 
    echo -e "${CYAN}[INFO]${NC} $1" 
}

log_ok() { 
    echo -e "${GREEN}[SUCCESS]${NC} $1" 
}

log_success() { 
    echo -e "${GREEN}[SUCCESS]${NC} $1" 
}

log_error() { 
    echo -e "${RED}[ERROR]${NC} $1" 
}

log_warn() { 
    echo -e "${YELLOW}[WARNING]${NC} $1" 
}

log_warning() { 
    echo -e "${YELLOW}[WARNING]${NC} $1" 
}

log_debug() { 
    echo -e "${PURPLE}[DEBUG]${NC} $1" 
}

# Display functions
print_section_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}>>> $1${NC}"
}

print_success() {
    echo ""
    echo -e "${GREEN}✅ $1${NC}"
    echo ""
}

# System check functions
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

detect_system() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [[ -f /etc/redhat-release ]]; then
        OS="Red Hat Enterprise Linux"
        VER=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+')
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    log_info "Detected system: $OS $VER"
}

# System resource check functions
get_total_memory() {
    local memory_kb
    if [[ -f /proc/meminfo ]]; then
        memory_kb=$(grep "MemTotal:" /proc/meminfo | awk '{print $2}')
        echo $((memory_kb / 1024))  # Convert to MB
    else
        echo "1024"  # Default fallback
    fi
}

get_available_space() {
    local path="${1:-/}"
    if command -v df >/dev/null 2>&1; then
        # Get available space in KB and convert to GB
        local space_kb=$(df "$path" | tail -1 | awk '{print $4}')
        echo $((space_kb / 1024 / 1024))  # Convert KB to GB
    else
        echo "10"  # Default fallback
    fi
}

check_port_availability() {
    local port="$1"
    local service_name="${2:-Service}"
    
    if command -v netstat >/dev/null 2>&1; then
        if netstat -tuln | grep -q ":$port "; then
            log_warning "$service_name port $port is already in use"
            return 1
        fi
    elif command -v ss >/dev/null 2>&1; then
        if ss -tuln | grep -q ":$port "; then
            log_warning "$service_name port $port is already in use"
            return 1
        fi
    else
        log_info "Cannot check port availability. Proceeding..."
    fi
    
    log_info "$service_name port $port is available"
    return 0
}

# Utility functions
pause() {
    echo ""
    read -p "$1"
}

# Input helper functions
ask_domain() {
    read -p "Enter domain name (e.g., example.com): " domain
    if [[ -z "$domain" ]]; then
        log_error "Domain name cannot be empty"
        return 1
    fi
    echo "$domain"
}

ask_email() {
    read -p "Enter email address: " email
    if [[ -z "$email" ]]; then
        log_error "Email address cannot be empty"
        return 1
    fi
    echo "$email"
}

ask_username() {
    read -p "Enter username: " username
    if [[ -z "$username" ]]; then
        log_error "Username cannot be empty"
        return 1
    fi
    echo "$username"
}

ask_password() {
    read -s -p "Enter password: " password
    echo ""
    if [[ -z "$password" ]]; then
        log_error "Password cannot be empty"
        return 1
    fi
    echo "$password"
}

ask_port() {
    read -p "Enter port number: " port
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
        log_error "Invalid port number"
        return 1
    fi
    echo "$port"
}

ask_ip() {
    read -p "Enter IP address: " ip
    if [[ ! "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid IP address format"
        return 1
    fi
    echo "$ip"
}

# Confirmation function
confirm_action() {
    local message="$1"
    echo -e "${YELLOW}$message${NC}"
    read -p "Are you sure? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]]
}

# Wait for user input
pause() {
    local message="${1:-Press Enter to continue...}"
    read -p "$message"
}

# Display header
show_header() {
    local title="$1"
    local width=50
    local padding=$(( (width - ${#title}) / 2 ))
    
    echo -e "${CYAN}"
    printf '=%.0s' $(seq 1 $width)
    echo ""
    printf '%*s%s%*s\n' $padding '' "$title" $padding ''
    printf '=%.0s' $(seq 1 $width)
    echo -e "${NC}"
}

# Check if script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Check if service exists and is installed
check_service_installed() {
    local service="$1"
    if systemctl list-unit-files | grep -q "^$service"; then
        return 0
    else
        return 1
    fi
}

# Check if package is installed
check_package_installed() {
    local package="$1"
    if dpkg -l | grep -q "^ii  $package "; then
        return 0
    else
        return 1
    fi
}

# Get server IP address
get_server_ip() {
    # Try to get public IP first
    local public_ip=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null)
    if [[ -n "$public_ip" ]]; then
        echo "$public_ip"
    else
        # Fallback to local IP
        local local_ip=$(ip route get 8.8.8.8 | awk '{print $7; exit}' 2>/dev/null)
        echo "${local_ip:-127.0.0.1}"
    fi
}

# Create backup of file before modification
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backup created for $file"
    fi
}

# Validate domain format
validate_domain() {
    local domain="$1"
    if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Display menu with options
display_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    show_header "$title"
    echo ""
    
    for i in "${!options[@]}"; do
        echo "$((i+1))) ${options[$i]}"
    done
    echo "0) Back/Exit"
    echo ""
}

# Get menu choice
get_menu_choice() {
    local max_option="$1"
    local choice
    
    while true; do
        read -p "Choose an option [0-$max_option]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 0 ]] && [[ "$choice" -le "$max_option" ]]; then
            echo "$choice"
            return
        else
            log_error "Invalid choice. Please enter a number between 0 and $max_option"
        fi
    done
}
