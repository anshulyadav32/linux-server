#!/bin/bash
# =============================================================================
# Linux Setup - System Comprehensive Check (S3)
# =============================================================================
# Author: Anshul Yadav
# Description: Master health check script that runs all module checks
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
PASSED_MODULES=()
START_TIME=$(date +%s)

# =============================================================================
# FUNCTIONS
# =============================================================================

# Enhanced logging functions
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1" | tee -a "/tmp/s3_check_$(date +%Y%m%d).log"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "/tmp/s3_check_$(date +%Y%m%d).log"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "/tmp/s3_check_$(date +%Y%m%d).log"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "/tmp/s3_check_$(date +%Y%m%d).log"
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
    echo "Linux Setup - System Comprehensive Check (S3)"
    echo "=============================================="
    echo ""
    echo "Usage: $0 [options] [modules...]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -v, --verbose       Verbose output mode"
    echo "  -q, --quiet         Quiet mode (errors only)"
    echo "  -f, --fast          Fast mode (skip detailed checks)"
    echo "  -s, --summary       Show only summary at the end"
    echo "  --no-color          Disable colored output"
    echo "  --log-file FILE     Specify custom log file"
    echo ""
    echo "Modules (if not specified, all modules are checked):"
    echo "  database            Check database services (MySQL, PostgreSQL)"
    echo "  dns                 Check DNS services (BIND9, dnsmasq)"
    echo "  firewall            Check firewall services (UFW, Fail2Ban)"
    echo "  ssl                 Check SSL/TLS services and certificates"
    echo "  webserver           Check web server services (Apache, Nginx, PHP)"
    echo "  extra               Check extra services (mail, antivirus)"
    echo "  backup              Check backup system and integrity"
    echo ""
    echo "Examples:"
    echo "  $0                          # Check all modules"
    echo "  $0 --verbose               # Check all modules with verbose output"
    echo "  $0 database webserver       # Check only database and webserver modules"
    echo "  $0 --fast --summary         # Quick check with summary only"
    echo ""
}

# Check if module check script exists
check_module_script() {
    local module="$1"
    local script_path="$SCRIPT_DIR/modules/$module/check_$module.sh"
    
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

# Run individual module check
run_module_check() {
    local module="$1"
    local mode="$2"
    local script_path="$SCRIPT_DIR/modules/$module/check_$module.sh"
    
    log_header "Checking $module Module"
    
    # Check if script exists and is executable
    if ! check_module_script "$module"; then
        log_error "$module module check script is not available"
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
        "fast")
            cmd_args="--quiet"
            ;;
    esac
    
    # Run the module check script
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
            log_success "$module module check: PASSED (${duration}s)"
            PASSED_MODULES+=("$module")
            ;;
        1)
            log_error "$module module check: FAILED (${duration}s)"
            FAILED_MODULES+=("$module")
            OVERALL_STATUS=1
            ;;
        *)
            log_warning "$module module check: WARNING (${duration}s)"
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
    
    # Load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    log_info "Load Average: $load_avg"
    
    # Memory usage
    local memory_info=$(free -h | grep Mem | awk '{print "Used: " $3 "/" $2 " (" $3/$2*100 "%)"}')
    log_info "Memory Usage: $memory_info"
    
    # Disk usage for root partition
    local disk_usage=$(df -h / | tail -1 | awk '{print "Used: " $3 "/" $2 " (" $5 ")"}')
    log_info "Root Disk Usage: $disk_usage"
    
    echo ""
}

# Show module status overview
show_module_overview() {
    log_header "Module Overview"
    
    for module in "${MODULES[@]}"; do
        local script_path="$SCRIPT_DIR/modules/$module/check_$module.sh"
        
        if [[ -f "$script_path" ]]; then
            if [[ -x "$script_path" ]]; then
                log_success "$module: Check script available"
            else
                log_warning "$module: Check script not executable"
            fi
        else
            log_error "$module: Check script missing"
        fi
    done
    
    echo ""
}

# Generate comprehensive summary
show_summary() {
    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))
    
    log_header "System Health Check Summary"
    
    # Time information
    log_info "Check started: $(date -d @$START_TIME '+%Y-%m-%d %H:%M:%S')"
    log_info "Check completed: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "Total duration: ${total_duration}s"
    
    echo ""
    
    # Module results
    local total_modules=${#MODULES[@]}
    local passed_count=${#PASSED_MODULES[@]}
    local failed_count=${#FAILED_MODULES[@]}
    local warning_count=${#WARNING_MODULES[@]}
    
    log_info "Modules checked: $total_modules"
    log_success "Modules passed: $passed_count"
    
    if [[ $warning_count -gt 0 ]]; then
        log_warning "Modules with warnings: $warning_count"
        for module in "${WARNING_MODULES[@]}"; do
            log_warning "  - $module"
        done
    fi
    
    if [[ $failed_count -gt 0 ]]; then
        log_error "Modules failed: $failed_count"
        for module in "${FAILED_MODULES[@]}"; do
            log_error "  - $module"
        done
    fi
    
    echo ""
    
    # Overall status
    if [[ $OVERALL_STATUS -eq 0 ]]; then
        if [[ $warning_count -gt 0 ]]; then
            log_warning "OVERALL STATUS: PASSED WITH WARNINGS"
        else
            log_success "OVERALL STATUS: ALL CHECKS PASSED"
        fi
    else
        log_error "OVERALL STATUS: FAILED"
        echo ""
        log_error "Critical issues detected that require immediate attention!"
    fi
    
    # Recommendations
    echo ""
    log_info "Recommendations:"
    
    if [[ $failed_count -gt 0 ]]; then
        log_info "• Review failed modules and fix critical issues"
        log_info "• Check individual module logs for detailed error information"
    fi
    
    if [[ $warning_count -gt 0 ]]; then
        log_info "• Address warning conditions when possible"
        log_info "• Monitor modules with warnings closely"
    fi
    
    log_info "• Run individual module checks with --verbose for detailed output"
    log_info "• Schedule regular health checks via cron"
    log_info "• Keep system and services updated regularly"
    
    echo ""
    log_info "Log file: /tmp/s3_check_$(date +%Y%m%d).log"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    local check_mode="normal"
    local modules_to_check=()
    local show_help=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help=true
                shift
                ;;
            -v|--verbose)
                check_mode="verbose"
                shift
                ;;
            -q|--quiet)
                check_mode="quiet"
                shift
                ;;
            -f|--fast)
                check_mode="fast"
                shift
                ;;
            -s|--summary)
                check_mode="summary"
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
                modules_to_check+=("$1")
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
    if [[ ${#modules_to_check[@]} -eq 0 ]]; then
        modules_to_check=("${MODULES[@]}")
    fi
    
    # Initial setup
    log_header "Linux Setup - System Comprehensive Check (S3)"
    log_info "Starting comprehensive system health check..."
    log_info "Mode: $check_mode"
    log_info "Modules: ${modules_to_check[*]}"
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_warning "Not running as root - some checks may fail"
        echo ""
    fi
    
    # Show system information (unless in quiet mode)
    if [[ "$check_mode" != "quiet" && "$check_mode" != "summary" ]]; then
        show_system_info
        show_module_overview
    fi
    
    # Run module checks
    for module in "${modules_to_check[@]}"; do
        # Check if module is valid
        if [[ " ${MODULES[@]} " =~ " $module " ]]; then
            run_module_check "$module" "$check_mode"
            
            # Add separator between modules (unless in summary mode)
            if [[ "$check_mode" != "summary" ]]; then
                echo ""
            fi
        else
            log_error "Invalid module: $module"
            OVERALL_STATUS=1
        fi
    done
    
    # Always show summary
    show_summary
    
    # Exit with appropriate code
    exit $OVERALL_STATUS
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Trap to ensure cleanup on exit
trap 'log_info "Health check interrupted"; exit 130' INT TERM

# Execute main function with all arguments
main "$@"
