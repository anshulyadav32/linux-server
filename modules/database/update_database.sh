#!/bin/bash
# =============================================================================
# Linux Setup - Database Module Update
# =============================================================================
# Author: Anshul Yadav
# Description: Update database services and components
# =============================================================================

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common functions
source "$SCRIPT_DIR/../common.sh" 2>/dev/null || {
    echo "[ERROR] Could not load common functions"
    exit 1
}

# Load database functions
source "$SCRIPT_DIR/functions.sh" 2>/dev/null || {
    echo "[ERROR] Could not load database functions"
    exit 1
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "Database Module Update"
    
    local overall_status=0
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Check for available updates first
    print_step "Checking for available updates..."
    if check_database_update; then
        print_info "No updates available"
        if [[ "${FORCE_UPDATE:-}" != "1" ]]; then
            print_success "Database module is already up to date"
            exit 0
        fi
    else
        print_info "Updates are available, proceeding with update..."
    fi
    
    echo ""
    
    # Backup databases before updating
    print_step "Creating backup before update..."
    if command -v backup_databases >/dev/null 2>&1; then
        backup_databases
    else
        print_warning "Backup function not available, skipping backup"
    fi
    
    echo ""
    
    # Run comprehensive database module update
    print_step "Running comprehensive database module update..."
    if update_database_module; then
        print_success "Database module updated successfully"
    else
        print_error "Database module update failed"
        overall_status=1
    fi
    
    echo ""
    
    # Individual component updates
    print_step "Updating individual database components..."
    
    # Update MySQL/MariaDB if installed
    if systemctl list-unit-files | grep -q "mariadb.service\|mysql.service"; then
        echo ""
        print_substep "Updating MySQL/MariaDB..."
        if update_mysql; then
            print_success "MySQL/MariaDB updated successfully"
            
            # Verify service is running after update
            if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
                print_success "MySQL/MariaDB service is running after update"
            else
                print_warning "MySQL/MariaDB service not running, attempting restart..."
                systemctl restart mariadb 2>/dev/null || systemctl restart mysql 2>/dev/null
            fi
        else
            print_error "MySQL/MariaDB update failed"
            overall_status=1
        fi
    else
        print_info "MySQL/MariaDB not installed, skipping"
    fi
    
    # Update PostgreSQL if installed
    if systemctl list-unit-files | grep -q "postgresql.service"; then
        echo ""
        print_substep "Updating PostgreSQL..."
        if update_postgresql; then
            print_success "PostgreSQL updated successfully"
            
            # Verify service is running after update
            if systemctl is-active --quiet postgresql; then
                print_success "PostgreSQL service is running after update"
            else
                print_warning "PostgreSQL service not running, attempting restart..."
                systemctl restart postgresql
            fi
        else
            print_error "PostgreSQL update failed"
            overall_status=1
        fi
    else
        print_info "PostgreSQL not installed, skipping"
    fi
    
    echo ""
    
    # Update additional database tools
    print_step "Updating database management tools..."
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y phpmyadmin adminer >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        print_success "Database management tools updated"
    else
        print_warning "Some database tools may not have updated properly"
    fi
    
    echo ""
    
    # Post-update verification
    print_step "Verifying database services after update..."
    
    local mysql_ok=0
    local postgresql_ok=0
    
    # Verify MySQL
    if systemctl list-unit-files | grep -q "mariadb.service\|mysql.service"; then
        if check_mysql >/dev/null 2>&1; then
            print_success "MySQL/MariaDB verification: PASSED"
            mysql_ok=1
        else
            print_error "MySQL/MariaDB verification: FAILED"
            overall_status=1
        fi
    fi
    
    # Verify PostgreSQL
    if systemctl list-unit-files | grep -q "postgresql.service"; then
        if check_postgresql >/dev/null 2>&1; then
            print_success "PostgreSQL verification: PASSED"
            postgresql_ok=1
        else
            print_error "PostgreSQL verification: FAILED"
            overall_status=1
        fi
    fi
    
    echo ""
    
    # Final status
    print_header "Database Update Summary"
    
    if [[ $overall_status -eq 0 ]]; then
        print_success "Database module update completed successfully"
        
        if [[ $mysql_ok -eq 1 ]]; then
            print_success "✓ MySQL/MariaDB: Updated and verified"
        fi
        
        if [[ $postgresql_ok -eq 1 ]]; then
            print_success "✓ PostgreSQL: Updated and verified"
        fi
        
        print_info "Database services are ready for use"
        exit 0
    else
        print_error "Database module update completed with errors"
        print_warning "Some components may require manual attention"
        exit 1
    fi
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --force, -f    Force update even if no updates detected"
        echo "  --quiet, -q    Quiet mode (minimal output)"
        echo "  --verbose, -v  Verbose mode (detailed output)"
        echo ""
        echo "This script updates database services and components."
        exit 0
        ;;
    --force|-f)
        FORCE_UPDATE=1
        ;;
    --quiet|-q)
        QUIET_MODE=1
        ;;
    --verbose|-v)
        VERBOSE_MODE=1
        ;;
esac

# Export update_database function for orchestration
update_database() {
    main "$@"
}

# Execute main function if run directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi