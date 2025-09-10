#!/bin/bash
# =============================================================================
# Linux Setup - SSL Module Update
# =============================================================================
# Author: Anshul Yadav
# Description: Update SSL services and components
# =============================================================================

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common functions
source "$SCRIPT_DIR/../common.sh" 2>/dev/null || {
    echo "[ERROR] Could not load common functions"
    exit 1
}

# Load SSL functions
source "$SCRIPT_DIR/functions.sh" 2>/dev/null || {
    echo "[ERROR] Could not load SSL functions"
    exit 1
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "SSL Module Update"
    
    local overall_status=0
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Check for available updates first
    print_step "Checking for available updates..."
    if check_ssl_update; then
        print_info "No updates available"
        if [[ "${FORCE_UPDATE:-}" != "1" ]]; then
            print_success "SSL module is already up to date"
            exit 0
        fi
    else
        print_info "Updates are available, proceeding with update..."
    fi
    
    echo ""
    
    # Backup SSL configuration before updating
    print_step "Creating backup before update..."
    
    # Backup SSL certificates and configuration
    local backup_dir="/root/backups/ssl"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$backup_dir"
    
    # Backup Let's Encrypt certificates
    if [[ -d /etc/letsencrypt ]]; then
        tar -czf "$backup_dir/letsencrypt_$timestamp.tar.gz" -C /etc letsencrypt 2>/dev/null
        print_info "Let's Encrypt certificates backed up"
    fi
    
    # Backup SSL directories
    if [[ -d /etc/ssl ]]; then
        tar -czf "$backup_dir/ssl_config_$timestamp.tar.gz" -C /etc ssl 2>/dev/null
        print_info "SSL configuration backed up"
    fi
    
    echo ""
    
    # Run comprehensive SSL module update
    print_step "Running comprehensive SSL module update..."
    if update_ssl_module; then
        print_success "SSL module updated successfully"
    else
        print_error "SSL module update failed"
        overall_status=1
    fi
    
    echo ""
    
    # Individual component updates
    print_step "Updating individual SSL components..."
    
    # Update Certbot
    echo ""
    print_substep "Updating Certbot..."
    apt-get update >/dev/null 2>&1
    apt-get upgrade -y certbot python3-certbot-apache python3-certbot-nginx >/dev/null 2>&1
    
    # Update snap version if available
    if command -v snap >/dev/null 2>&1 && snap list certbot >/dev/null 2>&1; then
        print_info "Updating Certbot via snap..."
        snap refresh certbot >/dev/null 2>&1
    fi
    
    if command -v certbot >/dev/null 2>&1; then
        print_success "Certbot updated successfully"
        
        # Verify Certbot functionality
        if certbot --version >/dev/null 2>&1; then
            local certbot_version=$(certbot --version 2>&1 | awk '{print $2}')
            print_info "Certbot Version: $certbot_version"
        else
            print_error "Certbot version check failed"
            overall_status=1
        fi
    else
        print_error "Certbot update failed"
        overall_status=1
    fi
    
    # Update OpenSSL
    echo ""
    print_substep "Updating OpenSSL..."
    apt-get upgrade -y openssl ca-certificates >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "OpenSSL updated successfully"
        
        # Verify OpenSSL functionality
        if openssl version >/dev/null 2>&1; then
            local openssl_version=$(openssl version 2>/dev/null | awk '{print $2}')
            print_info "OpenSSL Version: $openssl_version"
        else
            print_error "OpenSSL version check failed"
            overall_status=1
        fi
    else
        print_error "OpenSSL update failed"
        overall_status=1
    fi
    
    echo ""
    
    # Renew certificates if they exist
    print_step "Checking and renewing SSL certificates..."
    
    if [[ -d /etc/letsencrypt/live ]] && [[ -n "$(ls -A /etc/letsencrypt/live 2>/dev/null)" ]]; then
        print_info "Existing certificates found, attempting renewal..."
        
        # Dry run first to check for issues
        if certbot renew --dry-run >/dev/null 2>&1; then
            print_success "Certificate renewal dry run: PASSED"
            
            # Perform actual renewal
            if certbot renew --quiet; then
                print_success "Certificate renewal: COMPLETED"
                
                # Restart web servers to load new certificates
                systemctl reload apache2 2>/dev/null || true
                systemctl reload nginx 2>/dev/null || true
            else
                print_warning "Certificate renewal: Some certificates may not have renewed"
            fi
        else
            print_warning "Certificate renewal dry run: FAILED"
            print_info "Certificates may need manual attention"
        fi
    else
        print_info "No existing certificates to renew"
    fi
    
    echo ""
    
    # Post-update verification
    print_step "Verifying SSL services after update..."
    
    local certbot_ok=0
    local openssl_ok=0
    
    # Verify Certbot
    if command -v certbot >/dev/null 2>&1 && certbot --version >/dev/null 2>&1; then
        print_success "Certbot verification: PASSED"
        certbot_ok=1
    else
        print_error "Certbot verification: FAILED"
        overall_status=1
    fi
    
    # Verify OpenSSL
    if command -v openssl >/dev/null 2>&1 && openssl version >/dev/null 2>&1; then
        print_success "OpenSSL verification: PASSED"
        openssl_ok=1
    else
        print_error "OpenSSL verification: FAILED"
        overall_status=1
    fi
    
    # Test SSL functionality
    if [[ -d /etc/letsencrypt/live ]] && [[ -n "$(ls -A /etc/letsencrypt/live 2>/dev/null)" ]]; then
        # Check certificate validity
        local cert_issues=0
        for domain_dir in /etc/letsencrypt/live/*/; do
            if [[ -d "$domain_dir" ]]; then
                local domain=$(basename "$domain_dir")
                local cert_file="$domain_dir/cert.pem"
                
                if [[ -f "$cert_file" ]]; then
                    if openssl x509 -in "$cert_file" -noout -checkend 86400 >/dev/null 2>&1; then
                        print_success "Certificate $domain: Valid"
                    else
                        print_error "Certificate $domain: Expires soon or invalid"
                        cert_issues=1
                    fi
                fi
            fi
        done
        
        if [[ $cert_issues -eq 0 ]]; then
            print_success "Certificate validation: PASSED"
        else
            print_warning "Certificate validation: Issues detected"
        fi
    fi
    
    # Test HTTPS if available
    if netstat -tuln 2>/dev/null | grep -q ":443 "; then
        if echo | timeout 5 openssl s_client -connect localhost:443 2>/dev/null | grep -q "CONNECTED"; then
            print_success "HTTPS connection test: PASSED"
        else
            print_warning "HTTPS connection test: FAILED"
        fi
    fi
    
    echo ""
    
    # Final status
    print_header "SSL Update Summary"
    
    if [[ $overall_status -eq 0 ]]; then
        print_success "SSL module update completed successfully"
        
        if [[ $certbot_ok -eq 1 ]]; then
            print_success "✓ Certbot: Updated and verified"
        fi
        
        if [[ $openssl_ok -eq 1 ]]; then
            print_success "✓ OpenSSL: Updated and verified"
        fi
        
        print_info "SSL services are ready for secure connections"
        exit 0
    else
        print_error "SSL module update completed with errors"
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
        echo "This script updates SSL services and components."
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

# Execute main function
main "$@"
