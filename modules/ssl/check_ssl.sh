#!/bin/bash
# =============================================================================
# Linux Setup - SSL Module Health Check
# =============================================================================
# Author: Anshul Yadav
# Description: Check the health and status of SSL services
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
    print_header "SSL Module Health Check"
    
    local overall_status=0
    local certbot_status=0
    local openssl_status=0
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Run comprehensive SSL module check
    print_step "Running comprehensive SSL module check..."
    if check_ssl_module; then
        print_success "SSL module check passed"
    else
        print_error "SSL module check failed"
        overall_status=1
    fi
    
    echo ""
    
    # Individual component checks
    print_step "Checking individual SSL components..."
    
    # Check Certbot
    echo ""
    print_substep "Certbot Check:"
    if command -v certbot >/dev/null 2>&1; then
        certbot_status=1
        print_success "Certbot is installed"
        
        # Check Certbot version
        local certbot_version=$(certbot --version 2>&1 | awk '{print $2}')
        print_info "Certbot Version: $certbot_version"
        
        # Check for existing certificates
        local cert_count=0
        if [[ -d /etc/letsencrypt/live ]]; then
            cert_count=$(ls -1 /etc/letsencrypt/live 2>/dev/null | wc -l)
        fi
        
        if [[ $cert_count -gt 0 ]]; then
            print_success "SSL Certificates: $cert_count domains found"
            
            # Check certificate expiration
            for domain_dir in /etc/letsencrypt/live/*/; do
                if [[ -d "$domain_dir" ]]; then
                    local domain=$(basename "$domain_dir")
                    local cert_file="$domain_dir/cert.pem"
                    
                    if [[ -f "$cert_file" ]]; then
                        local expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | cut -d= -f2)
                        local expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null)
                        local current_epoch=$(date +%s)
                        local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
                        
                        if [[ $days_until_expiry -gt 30 ]]; then
                            print_success "$domain: Valid for $days_until_expiry days"
                        elif [[ $days_until_expiry -gt 7 ]]; then
                            print_warning "$domain: Expires in $days_until_expiry days"
                        else
                            print_error "$domain: CRITICAL - Expires in $days_until_expiry days"
                        fi
                    fi
                fi
            done
        else
            print_info "No SSL certificates found"
        fi
        
        # Check Certbot auto-renewal
        if crontab -l 2>/dev/null | grep -q certbot || systemctl list-timers 2>/dev/null | grep -q certbot; then
            print_success "Certbot auto-renewal: Configured"
        else
            print_warning "Certbot auto-renewal: Not configured"
        fi
        
    else
        print_error "Certbot is not installed"
    fi
    
    # Check OpenSSL
    echo ""
    print_substep "OpenSSL Check:"
    if command -v openssl >/dev/null 2>&1; then
        openssl_status=1
        print_success "OpenSSL is installed"
        
        # Check OpenSSL version
        local openssl_version=$(openssl version 2>/dev/null | awk '{print $2}')
        print_info "OpenSSL Version: $openssl_version"
        
        # Check for DH parameters
        if [[ -f /etc/ssl/certs/dhparam.pem ]]; then
            print_success "DH Parameters: Available"
        else
            print_warning "DH Parameters: Not found"
        fi
        
        # Check SSL directories
        if [[ -d /etc/ssl/private && -d /etc/ssl/certs ]]; then
            print_success "SSL Directories: Properly configured"
        else
            print_warning "SSL Directories: Missing or misconfigured"
        fi
        
    else
        print_error "OpenSSL is not installed"
    fi
    
    echo ""
    
    # Check SSL/TLS on web servers
    print_step "Checking SSL/TLS configuration..."
    
    # Check if HTTPS is listening
    if netstat -tuln 2>/dev/null | grep -q ":443 "; then
        print_success "HTTPS Port (443): Listening"
        
        # Test SSL connection to localhost
        if echo | timeout 5 openssl s_client -connect localhost:443 2>/dev/null | grep -q "CONNECTED"; then
            print_success "SSL Connection Test: PASSED"
        else
            print_warning "SSL Connection Test: FAILED"
        fi
    else
        print_info "HTTPS Port (443): Not listening (SSL not configured)"
    fi
    
    # Check Apache SSL configuration
    if systemctl is-active --quiet apache2; then
        if apache2ctl -M 2>/dev/null | grep -q ssl; then
            print_success "Apache SSL Module: Enabled"
        else
            print_warning "Apache SSL Module: Not enabled"
        fi
    fi
    
    # Check Nginx SSL configuration
    if systemctl is-active --quiet nginx; then
        if nginx -T 2>/dev/null | grep -q "ssl_certificate"; then
            print_success "Nginx SSL: Configured"
        else
            print_info "Nginx SSL: Not configured"
        fi
    fi
    
    echo ""
    
    # Check for available updates
    print_step "Checking for available updates..."
    if check_ssl_update; then
        print_success "SSL module is up to date"
    else
        print_warning "SSL updates are available"
        print_info "Run 'sudo bash update_ssl.sh' to update"
    fi
    
    echo ""
    
    # Summary
    print_header "SSL Module Summary"
    
    if [[ $certbot_status -eq 1 ]]; then
        print_success "✓ Certbot: Installed and ready"
    else
        print_error "✗ Certbot: Not installed"
    fi
    
    if [[ $openssl_status -eq 1 ]]; then
        print_success "✓ OpenSSL: Installed and ready"
    else
        print_error "✗ OpenSSL: Not installed"
    fi
    
    # Check certificate status
    local cert_count=0
    if [[ -d /etc/letsencrypt/live ]]; then
        cert_count=$(ls -1 /etc/letsencrypt/live 2>/dev/null | wc -l)
    fi
    
    if [[ $cert_count -gt 0 ]]; then
        print_success "✓ SSL Certificates: $cert_count domains configured"
    else
        print_info "○ SSL Certificates: None configured"
    fi
    
    if [[ $certbot_status -eq 1 && $openssl_status -eq 1 ]]; then
        print_success "SSL module is fully operational"
        exit 0
    else
        print_warning "SSL module is not fully operational"
        print_info "Run 'sudo bash install.sh' to install SSL services"
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
        echo "This script checks the health and status of SSL services."
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
