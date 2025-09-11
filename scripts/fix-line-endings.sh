#!/bin/bash

# Line Ending Conversion Utility for WSL
# Converts Windows CRLF line endings to Unix LF line endings in shell scripts
# Part of the Linux Server Automation Suite WSL support

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
DRY_RUN=false
VERBOSE=false
BACKUP=true
TARGET_DIR=""
FILE_PATTERN="*.sh"

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [DIRECTORY]

Converts Windows-style CRLF line endings to Unix LF line endings in shell scripts.
Designed for WSL users who edit scripts on Windows but run them in Linux.

OPTIONS:
    -h, --help          Show this help message
    -d, --dry-run       Show what would be converted without making changes
    -v, --verbose       Enable verbose output
    -n, --no-backup     Skip creating backup files
    -p, --pattern PATTERN   File pattern to match (default: *.sh)

DIRECTORY:
    Path to directory containing scripts to convert
    If not specified, uses current directory

EXAMPLES:
    # Convert all .sh files in current directory
    $0
    
    # Convert scripts in specific directory
    $0 /path/to/scripts
    
    # Dry run to see what would be changed
    $0 --dry-run
    
    # Convert with verbose output, no backups
    $0 --verbose --no-backup

NOTES:
    - Creates .bak backup files by default
    - Only processes files that actually have CRLF line endings
    - Safe to run multiple times on the same files
    - Preserves file permissions and ownership

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
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

check_dependencies() {
    local missing_deps=()
    
    # Check for required commands
    for cmd in file sed; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install missing commands and try again"
        return 1
    fi
    
    # Check for dos2unix (optional but preferred)
    if command -v dos2unix >/dev/null 2>&1; then
        log_verbose "Found dos2unix - will use for conversion"
        return 0
    else
        log_verbose "dos2unix not found - will use sed for conversion"
        return 0
    fi
}

has_crlf_endings() {
    local file="$1"
    
    # Check if file contains CRLF sequences
    if file "$file" | grep -q "CRLF"; then
        return 0
    fi
    
    # Alternative check using hexdump
    if hexdump -C "$file" | grep -q "0d 0a"; then
        return 0
    fi
    
    return 1
}

convert_file() {
    local file="$1"
    local converted=false
    
    if [[ ! -f "$file" ]]; then
        log_warning "File not found: $file"
        return 1
    fi
    
    if [[ ! -r "$file" ]]; then
        log_warning "Cannot read file: $file"
        return 1
    fi
    
    # Check if file has CRLF line endings
    if ! has_crlf_endings "$file"; then
        log_verbose "File already has Unix line endings: $file"
        return 0
    fi
    
    log_info "Converting line endings: $file"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would convert $file"
        return 0
    fi
    
    # Create backup if requested
    if [[ "$BACKUP" == "true" ]]; then
        if cp "$file" "$file.bak"; then
            log_verbose "Created backup: $file.bak"
        else
            log_error "Failed to create backup for: $file"
            return 1
        fi
    fi
    
    # Convert using dos2unix if available, otherwise use sed
    if command -v dos2unix >/dev/null 2>&1; then
        if dos2unix "$file" >/dev/null 2>&1; then
            converted=true
        fi
    else
        # Use sed to convert CRLF to LF
        if sed -i 's/\r$//' "$file"; then
            converted=true
        fi
    fi
    
    if [[ "$converted" == "true" ]]; then
        log_success "Converted: $file"
        return 0
    else
        log_error "Failed to convert: $file"
        # Restore backup if conversion failed
        if [[ "$BACKUP" == "true" && -f "$file.bak" ]]; then
            mv "$file.bak" "$file"
            log_info "Restored backup for: $file"
        fi
        return 1
    fi
}

process_directory() {
    local dir="$1"
    local files_found=0
    local files_converted=0
    local files_failed=0
    
    if [[ ! -d "$dir" ]]; then
        log_error "Directory not found: $dir"
        return 1
    fi
    
    log_info "Processing directory: $dir"
    log_info "File pattern: $FILE_PATTERN"
    
    # Find files matching pattern
    while IFS= read -r -d '' file; do
        ((files_found++))
        
        if convert_file "$file"; then
            ((files_converted++))
        else
            ((files_failed++))
        fi
    done < <(find "$dir" -name "$FILE_PATTERN" -type f -print0)
    
    # Summary
    log_info "Processing complete:"
    log_info "  Files found: $files_found"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "  Files that would be converted: $files_converted"
    else
        log_info "  Files converted: $files_converted"
        log_info "  Files failed: $files_failed"
    fi
    
    return 0
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_usage
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -n|--no-backup)
                BACKUP=false
                shift
                ;;
            -p|--pattern)
                FILE_PATTERN="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
            *)
                if [[ -z "$TARGET_DIR" ]]; then
                    TARGET_DIR="$1"
                else
                    log_error "Multiple directories specified: $TARGET_DIR and $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Use current directory if no target specified
    if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$(pwd)"
    fi
    
    # Make path absolute
    TARGET_DIR="$(readlink -f "$TARGET_DIR")"
    
    log_info "Linux Server Automation Suite - Line Ending Converter"
    log_info "Converting Windows CRLF to Unix LF line endings"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN MODE - No files will be modified"
    fi
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    # Process directory
    if process_directory "$TARGET_DIR"; then
        log_success "Line ending conversion completed successfully"
        exit 0
    else
        log_error "Line ending conversion completed with errors"
        exit 1
    fi
}

# Handle script being sourced vs executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi