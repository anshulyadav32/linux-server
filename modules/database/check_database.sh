#!/bin/bash
# =============================================================================
# Linux Setup - Database Module Health Check
# =============================================================================
# Author: Anshul Yadav
# Description: Check the health and status of database services
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
    print_header "Database Module Health Check"
    
    local overall_status=0
    local mysql_status=0
    local postgresql_status=0
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Run comprehensive database module check
    print_step "Running comprehensive database module check..."
    if check_database_module; then
        print_success "Database module check passed"
    else
        print_error "Database module check failed"
        overall_status=1
    fi
    
    echo ""
    
    # Individual component checks
    print_step "Checking individual database components..."

    # Check MySQL/MariaDB
    echo ""
    print_substep "MySQL/MariaDB Check:"
    if command -v mysql >/dev/null 2>&1; then
        mysql_status=1
        print_success "MySQL/MariaDB is installed"
        # Additional MySQL checks
        if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
            print_info "MySQL Service: Active"
            # Test database connection
            if mysql -u root -padmin123 -e "SELECT 1;" >/dev/null 2>&1; then
                print_success "MySQL Connection: OK"
            else
                print_warning "MySQL Connection: Failed (check credentials)"
            fi
            # Check database count
            local db_count=$(mysql -u root -padmin123 -e "SHOW DATABASES;" 2>/dev/null | wc -l)
            if [[ $db_count -gt 0 ]]; then
                print_info "MySQL Databases: $((db_count - 1)) found"
            fi
        else
            print_warning "MySQL/MariaDB service is not running"
        fi
    else
        print_warning "MySQL/MariaDB is not installed"
    fi

    # Check PostgreSQL
    echo ""
    print_substep "PostgreSQL Check:"
    if command -v psql >/dev/null 2>&1; then
        postgresql_status=1
        print_success "PostgreSQL is installed"
        # Additional PostgreSQL checks
        if systemctl is-active --quiet postgresql; then
            print_info "PostgreSQL Service: Active"
            # Test database connection
            if sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then
                print_success "PostgreSQL Connection: OK"
            else
                print_warning "PostgreSQL Connection: Failed"
            fi
            # Check database count
            local pg_db_count=$(sudo -u postgres psql -t -c "SELECT count(*) FROM pg_database WHERE datistemplate = false;" 2>/dev/null | tr -d ' ')
            if [[ -n "$pg_db_count" ]] && [[ $pg_db_count -gt 0 ]]; then
                print_info "PostgreSQL Databases: $pg_db_count found"
            fi
        else
            print_warning "PostgreSQL service is not running"
        fi
    else
        print_warning "PostgreSQL is not installed"
    fi
    
    echo ""
    
    # Check for available updates
    print_step "Checking for available updates..."
    if check_database_update; then
        print_success "Database module is up to date"
    else
        print_warning "Database updates are available"
        print_info "Run 'sudo bash update_database.sh' to update"
    fi
    
    echo ""
    
    # Summary
    print_header "Database Module Summary"
    
    if [[ $mysql_status -eq 1 ]]; then
        print_success "✓ MySQL/MariaDB: Operational"
    else
        print_info "○ MySQL/MariaDB: Not installed"
    fi
    
    if [[ $postgresql_status -eq 1 ]]; then
        print_success "✓ PostgreSQL: Operational"
    else
        print_info "○ PostgreSQL: Not installed"
    fi
    
    if [[ $mysql_status -eq 1 || $postgresql_status -eq 1 ]]; then
        print_success "Database module is operational"
        exit 0
    else
        print_warning "No database systems are currently operational"
        print_info "Run 'sudo bash install.sh' to install database services"
        exit 2
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
        echo "  --quiet, -q    Quiet mode (minimal output)"
        echo "  --verbose, -v  Verbose mode (detailed output)"
        echo ""
        echo "This script checks the health and status of database services."
        exit 0
        ;;
    --quiet|-q)
        QUIET_MODE=1
        ;;
    --verbose|-v)
        VERBOSE_MODE=1
        ;;
esac

# Execute main function
main "$@"