#!/bin/bash
# =============================================================================
# Linux Setup - Server Update Script
# =============================================================================
# Author: Anshul Yadav
# Description: Master update script that runs all module updates
# Version: 1.0
# =============================================================================

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common functions
source "$SCRIPT_DIR/modules/common.sh" 2>/dev/null || {
    echo "[ERROR] Could not load common functions"
    exit 1
}

# =============================================================================
# CONFIGURATION
# =============================================================================

# Module list in dependency order
MODULES=(
    "database"
    "dns" 
    "firewall"
    "ssl"
    "webserver"
    "extra"
    "backup"
)

# Colors for output (if not defined in common.sh)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
OVERALL_STATUS=0
FAILED_MODULES=()
WARNING_MODULES=()
UPDATED_MODULES=()
SKIPPED_MODULES=()
START_TIME=$(date +%s)

# =============================================================================
# FUNCTIONS
# =============================================================================

# Enhanced logging functions
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1" | tee -a "/tmp/update_server_$(date +%Y%m%d).log"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "/tmp/update_server_$(date +%Y%m%d).log"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "/tmp/update_server_$(date +%Y%m%d).log"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "/tmp/update_server_$(date +%Y%m%d).log"
}

log_header() {
    echo ""
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

# Show usage information
show_usage() {
    echo "Linux Setup - Server Update Script"
    echo "==================================="
    echo ""
    echo "Usage: $0 [options] [modules...]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -v, --verbose       Verbose output mode"
    echo "  -q, --quiet         Quiet mode (errors only)"
    echo "  -f, --force         Force update even if no updates available"
    echo "  -s, --summary       Show only summary at the end"
    echo "  --dry-run           Show what would be updated without making changes"
    echo "  --no-color          Disable colored output"
    echo "  --log-file FILE     Specify custom log file"
    echo "  --backup            Create full system backup before updates"
    echo ""
    echo "Modules (if not specified, all modules are updated):"
    echo "  database            Update database services (MySQL, PostgreSQL)"
    echo "  dns                 Update DNS services (BIND9, dnsmasq)"
    echo "  firewall            Update firewall services (UFW, Fail2Ban)"
    echo "  ssl                 Update SSL/TLS services and certificates"
    echo "  webserver           Update web server services (Apache, Nginx, PHP)"
    echo "  extra               Update extra services (mail, antivirus)"
    echo "  backup              Update backup system and tools"
    echo ""
    echo "Examples:"
    echo "  $0                          # Update all modules"
    echo "  $0 --verbose               # Update all modules with verbose output"
    echo "  $0 database webserver       # Update only database and webserver modules"
    echo "  $0 --force --backup         # Force update with system backup"
    echo "  $0 --dry-run                # Show what would be updated"
    echo ""
}

# Check if module update script exists
check_module_script() {
    local module="$1"
    local script_path="$SCRIPT_DIR/modules/$module/update_$module.sh"
    
    if [[ -f "$script_path" ]]; then
        if [[ -x "$script_path" ]]; then
            return 0
        else
            log_warning "Module script not executable: $script_path"
            return 2
        fi
    else
        log_error "Module script not found: $script_path"
        return 1
    fi
}

# Create system backup before updates
create_system_backup() {
    log_header "Creating System Backup"
    
    local backup_dir="/root/backups/pre-update"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$backup_dir"
    
    log_info "Creating pre-update system backup..."
    
    # Backup system configuration
    if tar -czf "$backup_dir/system_config_$timestamp.tar.gz" \
        /etc \
        /root/.ssh \
        /root/scripts \
        --exclude=/etc/ssl/private \
        >/dev/null 2>&1; then
        log_success "System configuration backed up"
    else
        log_error "Failed to backup system configuration"
        return 1
    fi
    
    # Backup databases if available
    if command -v mysqldump >/dev/null 2>&1; then
        if mysqldump --all-databases --single-transaction > "$backup_dir/mysql_all_$timestamp.sql" 2>/dev/null; then
            gzip "$backup_dir/mysql_all_$timestamp.sql"
            log_success "MySQL databases backed up"
        else
            log_warning "MySQL backup failed"
        fi
    fi
    
    if command -v pg_dumpall >/dev/null 2>&1; then
        if sudo -u postgres pg_dumpall > "$backup_dir/postgresql_all_$timestamp.sql" 2>/dev/null; then
            gzip "$backup_dir/postgresql_all_$timestamp.sql"
            log_success "PostgreSQL databases backed up"
        else
            log_warning "PostgreSQL backup failed"
        fi
    fi
    
    # Backup web content
    if [[ -d /var/www ]]; then
        if tar -czf "$backup_dir/www_$timestamp.tar.gz" /var/www >/dev/null 2>&1; then
            log_success "Web content backed up"
        else
            log_warning "Web content backup failed"
        fi
    fi
    
    log_success "Pre-update backup completed: $backup_dir"
    return 0
}

# Run individual module update
run_module_update() {
    local module="$1"
    local mode="$2"
    local script_path="$SCRIPT_DIR/modules/$module/update_$module.sh"
    
    log_header "Updating $module Module"
    
    # Check if script exists and is executable
    if ! check_module_script "$module"; then
        log_error "$module module update script is not available"
        FAILED_MODULES+=("$module")
        return 1
    fi
    
    # Prepare command arguments based on mode
    local cmd_args=""
    case "$mode" in
        "quiet")
            cmd_args="--quiet"
            ;;
        "verbose")
            cmd_args="--verbose"
            ;;
        "force")
            cmd_args="--force"
            ;;
        "dry-run")
            # Most update scripts don't have dry-run, so we'll just check for updates
            log_info "DRY RUN: Would run $script_path"
            return 0
            ;;
    esac
    
    # Run the module update script
    local start_time=$(date +%s)
    
    if [[ "$mode" == "summary" ]]; then
        # For summary mode, capture output but don't display
        local output
        output=$("$script_path" $cmd_args 2>&1)
        local exit_code=$?
    else
        # For normal mode, show output
        "$script_path" $cmd_args
        local exit_code=$?
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Process results
    case $exit_code in
        0)
            log_success "$module module update: COMPLETED (${duration}s)"
            UPDATED_MODULES+=("$module")
            ;;
        1)
            log_error "$module module update: FAILED (${duration}s)"
            FAILED_MODULES+=("$module")
            OVERALL_STATUS=1
            ;;
        *)
            log_warning "$module module update: WARNING (${duration}s)"
            WARNING_MODULES+=("$module")
            ;;
    esac
    
    return $exit_code
}

# Show system information
show_system_info() {
    log_header "System Information"
    
    # Basic system info
    if [[ -f /etc/os-release ]]; then
        local os_info=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
        log_info "Operating System: $os_info"
    fi
    
    # Kernel version
    local kernel_version=$(uname -r)
    log_info "Kernel Version: $kernel_version"
    
    # Uptime
    local uptime=$(uptime -p 2>/dev/null || uptime)
    log_info "System Uptime: $uptime"
    
    # Available updates
    if command -v apt >/dev/null 2>&1; then
        apt-get update >/dev/null 2>&1
        local available_updates=$(apt list --upgradable 2>/dev/null | wc -l)
        if [[ $available_updates -gt 1 ]]; then
            log_info "Available package updates: $((available_updates - 1))"
        else
            log_info "Available package updates: 0"
        fi
    fi
    
    # Disk space
    local disk_usage=$(df -h / | tail -1 | awk '{print "Used: " $3 "/" $2 " (" $5 ")"}')
    log_info "Root Disk Usage: $disk_usage"
    
    echo ""
}

# Show module status overview
show_module_overview() {
    log_header "Module Update Scripts Overview"
    
    for module in "${MODULES[@]}"; do
        local script_path="$SCRIPT_DIR/modules/$module/update_$module.sh"
        
        if [[ -f "$script_path" ]]; then
            if [[ -x "$script_path" ]]; then
                log_success "$module: Update script available"
            else
                log_warning "$module: Update script not executable"
            fi
        else
            log_error "$module: Update script missing"
        fi
    done
    
    echo ""
}

# Generate comprehensive summary
show_summary() {
    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))
    
    log_header "Server Update Summary"
    
    # Time information
    log_info "Update started: $(date -d @$START_TIME '+%Y-%m-%d %H:%M:%S')"
    log_info "Update completed: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "Total duration: ${total_duration}s"
    
    echo ""
    
    # Module results
    local total_modules=${#MODULES[@]}
    local updated_count=${#UPDATED_MODULES[@]}
    local failed_count=${#FAILED_MODULES[@]}
    local warning_count=${#WARNING_MODULES[@]}
    local skipped_count=${#SKIPPED_MODULES[@]}
    
    log_info "Modules processed: $total_modules"
    
    if [[ $updated_count -gt 0 ]]; then
        log_success "Modules updated: $updated_count"
        for module in "${UPDATED_MODULES[@]}"; do
            log_success "  ✓ $module"
        done
    fi
    
    if [[ $skipped_count -gt 0 ]]; then
        log_info "Modules skipped: $skipped_count"
        for module in "${SKIPPED_MODULES[@]}"; do
            log_info "  - $module (no updates available)"
        done
    fi
    
    if [[ $warning_count -gt 0 ]]; then
        log_warning "Modules with warnings: $warning_count"
        for module in "${WARNING_MODULES[@]}"; do
            log_warning "  ⚠ $module"
        done
    fi
    
    if [[ $failed_count -gt 0 ]]; then
        log_error "Modules failed: $failed_count"
        for module in "${FAILED_MODULES[@]}"; do
            log_error "  ✗ $module"
        done
    fi
    
    echo ""
    
    # Overall status
    if [[ $OVERALL_STATUS -eq 0 ]]; then
        if [[ $warning_count -gt 0 ]]; then
            log_warning "OVERALL STATUS: COMPLETED WITH WARNINGS"
        else
            log_success "OVERALL STATUS: ALL UPDATES COMPLETED SUCCESSFULLY"
        fi
    else
        log_error "OVERALL STATUS: FAILED"
        echo ""
        log_error "Some modules failed to update and may need manual attention!"
    fi
    
    # Post-update recommendations
    echo ""
    log_info "Post-Update Recommendations:"
    
    if [[ $updated_count -gt 0 ]]; then
        log_info "• Run health checks: sudo ./s3.sh"
        log_info "• Restart services if needed"
        log_info "• Test critical functionality"
    fi
    
    if [[ $failed_count -gt 0 ]]; then
        log_info "• Review failed modules and fix issues manually"
        log_info "• Check individual module logs for detailed error information"
    fi
    
    if [[ $warning_count -gt 0 ]]; then
        log_info "• Address warning conditions when possible"
        log_info "• Monitor modules with warnings closely"
    fi
    
    log_info "• Monitor system performance after updates"
    log_info "• Check application functionality"
    log_info "• Review system logs for any issues"
    
    echo ""
    log_info "Log file: /tmp/update_server_$(date +%Y%m%d).log"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    local update_mode="normal"
    local modules_to_update=()
    local show_help=false
    local dry_run=false
    local create_backup=false
    local force_update=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help=true
                shift
                ;;
            -v|--verbose)
                update_mode="verbose"
                shift
                ;;
            -q|--quiet)
                update_mode="quiet"
                shift
                ;;
            -f|--force)
                force_update=true
                shift
                ;;
            -s|--summary)
                update_mode="summary"
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --backup)
                create_backup=true
                shift
                ;;
            --no-color)
                # Disable colors
                RED=''
                GREEN=''
                YELLOW=''
                BLUE=''
                PURPLE=''
                CYAN=''
                NC=''
                shift
                ;;
            --log-file)
                shift
                if [[ -n "$1" ]]; then
                    exec 1> >(tee -a "$1")
                    exec 2> >(tee -a "$1" >&2)
                    shift
                fi
                ;;
            database|dns|firewall|ssl|webserver|extra|backup)
                modules_to_update+=("$1")
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help=true
                shift
                ;;
        esac
    done
    
    # Show help if requested or invalid arguments
    if [[ $show_help == true ]]; then
        show_usage
        exit 0
    fi
    
    # Use all modules if none specified
    if [[ ${#modules_to_update[@]} -eq 0 ]]; then
        modules_to_update=("${MODULES[@]}")
    fi
    
    # Initial setup
    log_header "Linux Setup - Server Update Script"
    log_info "Starting comprehensive server update process..."
    log_info "Mode: $update_mode"
    log_info "Modules: ${modules_to_update[*]}"
    
    if [[ $dry_run == true ]]; then
        log_info "DRY RUN MODE: No actual changes will be made"
    fi
    
    if [[ $force_update == true ]]; then
        log_info "FORCE MODE: Updates will be applied even if not needed"
    fi
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        log_error "Example: sudo ./update-server.sh"
        exit 1
    fi
    
    # Show system information (unless in quiet mode)
    if [[ "$update_mode" != "quiet" && "$update_mode" != "summary" ]]; then
        show_system_info
        show_module_overview
    fi
    
    # Create system backup if requested
    if [[ $create_backup == true ]] && [[ $dry_run == false ]]; then
        if ! create_system_backup; then
            log_error "System backup failed. Aborting update process."
            exit 1
        fi
    fi
    
    # Run module updates
    for module in "${modules_to_update[@]}"; do
        # Check if module is valid
        if [[ " ${MODULES[@]} " =~ " $module " ]]; then
            if [[ $dry_run == true ]]; then
                run_module_update "$module" "dry-run"
            elif [[ $force_update == true ]]; then
                run_module_update "$module" "force"
            else
                run_module_update "$module" "$update_mode"
            fi
            
            # Add separator between modules (unless in summary mode)
            if [[ "$update_mode" != "summary" ]]; then
                echo ""
            fi
        else
            log_error "Invalid module: $module"
            OVERALL_STATUS=1
        fi
    done
    
    # Always show summary
    show_summary
    
    # Suggest health check after updates
    if [[ $OVERALL_STATUS -eq 0 && $dry_run == false ]]; then
        echo ""
        log_info "💡 Recommendation: Run health check after updates"
        log_info "   sudo ./s3.sh --verbose"
    fi
    
    # Exit with appropriate code
    exit $OVERALL_STATUS
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Trap to ensure cleanup on exit
trap 'log_info "Update process interrupted"; exit 130' INT TERM

# Execute main function with all arguments
main "$@"
