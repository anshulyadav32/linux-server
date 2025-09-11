#!/bin/bash

# WSL Setup and Root Access Helper
# Configures WSL environment for running Linux Server Automation Suite
# Part of the Linux Server Automation Suite WSL support

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script location detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [COMMAND]

WSL setup and management helper for Linux Server Automation Suite.
Provides easy access to root privileges and WSL-specific configurations.

COMMANDS:
    setup           Complete WSL environment setup
    root            Switch to root user (sudo -i)
    fix-scripts     Fix line endings in all shell scripts
    install         Run the main installation as root
    check           Run system health check as root
    update          Run system update as root

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -d, --dry-run   Show what would be done without executing

EXAMPLES:
    # Complete WSL setup
    $0 setup
    
    # Switch to root user
    $0 root
    
    # Fix line endings in scripts
    $0 fix-scripts
    
    # Install server components as root
    $0 install
    
    # Run health check
    $0 check

NOTES:
    - Run this script from WSL (Windows Subsystem for Linux)
    - Requires sudo privileges for most operations
    - Automatically detects and fixes Windows line ending issues
    - Provides wrapper commands for common root operations

EOF
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_verbose() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

check_wsl() {
    # Check if running in WSL
    if [[ -f /proc/version && $(grep -c "Microsoft\|WSL" /proc/version) -gt 0 ]]; then
        log_verbose "WSL environment detected"
        return 0
    fi
    
    # Alternative WSL detection methods
    if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        log_verbose "WSL environment detected via WSL_DISTRO_NAME"
        return 0
    fi
    
    if [[ -n "${WSLENV:-}" ]]; then
        log_verbose "WSL environment detected via WSLENV"
        return 0
    fi
    
    log_warning "WSL environment not detected - script optimized for WSL"
    log_info "You can still use this script on regular Linux systems"
    return 1
}

check_root_access() {
    if ! sudo -n true 2>/dev/null; then
        log_info "This script requires sudo privileges"
        log_info "You may be prompted for your password"
        
        if ! sudo true; then
            log_error "Failed to obtain sudo privileges"
            return 1
        fi
    fi
    
    log_verbose "Sudo privileges confirmed"
    return 0
}

check_dependencies() {
    local missing_deps=()
    
    # Check for required commands
    for cmd in bash sudo find; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

install_dos2unix() {
    log_info "Installing dos2unix for line ending conversion..."
    
    # Detect package manager and install dos2unix
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y dos2unix
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y dos2unix
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y dos2unix
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm dos2unix
    else
        log_warning "Could not detect package manager"
        log_info "Please install dos2unix manually for optimal line ending conversion"
        return 1
    fi
    
    log_success "dos2unix installed successfully"
    return 0
}

setup_wsl_environment() {
    log_info "Setting up WSL environment for Linux Server Automation Suite"
    
    # Check WSL
    check_wsl
    
    # Check dependencies
    if ! check_dependencies; then
        log_error "Missing required dependencies"
        return 1
    fi
    
    # Check root access
    if ! check_root_access; then
        return 1
    fi
    
    # Install dos2unix if not present
    if ! command -v dos2unix >/dev/null 2>&1; then
        log_info "dos2unix not found - installing..."
        install_dos2unix || log_warning "Failed to install dos2unix - line ending fix may use fallback method"
    else
        log_verbose "dos2unix already installed"
    fi
    
    # Fix line endings in scripts
    log_info "Checking and fixing line endings in shell scripts..."
    if [[ -f "$SCRIPT_DIR/fix-line-endings.sh" ]]; then
        bash "$SCRIPT_DIR/fix-line-endings.sh" "$PROJECT_ROOT"
    else
        log_warning "Line ending fix script not found"
    fi
    
    # Make all scripts executable
    log_info "Making scripts executable..."
    find "$PROJECT_ROOT" -name "*.sh" -type f -exec chmod +x {} \;
    
    # Display WSL-specific information
    cat << EOF

${GREEN}WSL Setup Complete!${NC}

${BLUE}WSL Root Access Commands:${NC}
  • Switch to root in current session:  sudo -i
  • Start new WSL session as root:      wsl -u root  (from Windows)

${BLUE}Quick Start Commands:${NC}
  • Run installation:     $0 install
  • Check system health:  $0 check
  • Update server:        $0 update
  • Fix line endings:     $0 fix-scripts

${BLUE}WSL Tips:${NC}
  • Use 'wsl -u root' from Windows PowerShell for direct root access
  • Scripts are now executable and have correct line endings
  • You can run any script with: sudo ./script-name.sh

EOF
    
    log_success "WSL environment setup completed successfully"
    return 0
}

switch_to_root() {
    log_info "Switching to root user..."
    log_info "Use 'exit' to return to your regular user"
    
    # Check if we can get root access first
    if ! check_root_access; then
        return 1
    fi
    
    # Switch to root interactively
    exec sudo -i
}

fix_line_endings() {
    log_info "Fixing line endings in shell scripts..."
    
    if [[ -f "$SCRIPT_DIR/fix-line-endings.sh" ]]; then
        bash "$SCRIPT_DIR/fix-line-endings.sh" "${1:-$PROJECT_ROOT}"
    else
        log_error "Line ending fix script not found at: $SCRIPT_DIR/fix-line-endings.sh"
        return 1
    fi
}

run_installation() {
    log_info "Running Linux Server Automation Suite installation..."
    
    if ! check_root_access; then
        return 1
    fi
    
    # Fix line endings first
    fix_line_endings
    
    # Run installation
    if [[ -f "$PROJECT_ROOT/install.sh" ]]; then
        sudo bash "$PROJECT_ROOT/install.sh"
    else
        log_error "Installation script not found at: $PROJECT_ROOT/install.sh"
        return 1
    fi
}

run_health_check() {
    log_info "Running system health check..."
    
    if ! check_root_access; then
        return 1
    fi
    
    if [[ -f "$PROJECT_ROOT/s3.sh" ]]; then
        sudo bash "$PROJECT_ROOT/s3.sh"
    else
        log_error "Health check script not found at: $PROJECT_ROOT/s3.sh"
        return 1
    fi
}

run_update() {
    log_info "Running system update..."
    
    if ! check_root_access; then
        return 1
    fi
    
    if [[ -f "$PROJECT_ROOT/update-server.sh" ]]; then
        sudo bash "$PROJECT_ROOT/update-server.sh"
    else
        log_error "Update script not found at: $PROJECT_ROOT/update-server.sh"
        return 1
    fi
}

main() {
    local command=""
    local dry_run=false
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                export VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            setup|root|fix-scripts|install|check|update)
                if [[ -n "$command" ]]; then
                    log_error "Multiple commands specified: $command and $1"
                    exit 1
                fi
                command="$1"
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
            *)
                log_error "Unknown argument: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Default command is setup
    if [[ -z "$command" ]]; then
        command="setup"
    fi
    
    log_info "Linux Server Automation Suite - WSL Helper"
    
    if [[ "$dry_run" == "true" ]]; then
        log_warning "DRY RUN MODE - Would execute: $command"
        exit 0
    fi
    
    # Execute command
    case "$command" in
        setup)
            setup_wsl_environment
            ;;
        root)
            switch_to_root
            ;;
        fix-scripts)
            fix_line_endings
            ;;
        install)
            run_installation
            ;;
        check)
            run_health_check
            ;;
        update)
            run_update
            ;;
        *)
            log_error "Unknown command: $command"
            exit 1
            ;;
    esac
}

# Handle script being sourced vs executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi