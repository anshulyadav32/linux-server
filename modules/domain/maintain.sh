#!/usr/bin/env bash
# =============================================================================
# Linux Setup - Domain Management Module Maintenance
# =============================================================================

set -Eeuo pipefail

# ---------- Colors & Logging ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'

log_info()    { echo -e "[INFO] $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# ---------- Configuration ----------
ZONE_DIR="/etc/bind/zones"
NAMED_CONF="/etc/bind/named.conf.local"
DOMAIN_CONFIG="/etc/domain-manager/config"
LOG_FILE="/var/log/domain-manager.log"

# ---------- System Checks ----------
check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)."
    exit 1
  fi
}

# ---------- Maintenance Functions ----------

check_domain_health() {
    log_info "Checking domain health..."
    
    if [[ ! -d "$ZONE_DIR" ]]; then
        log_warning "Zone directory not found: $ZONE_DIR"
        return 1
    fi
    
    local healthy=0
    local unhealthy=0
    
    echo ""
    echo "Domain Health Report:"
    echo "===================="
    
    for zone_file in "$ZONE_DIR"/db.*; do
        if [[ -f "$zone_file" ]]; then
            local domain=$(basename "$zone_file" | sed 's/^db\.//')
            echo -n "Checking $domain... "
            
            # Check zone file syntax
            if command -v named-checkzone >/dev/null; then
                if named-checkzone "$domain" "$zone_file" >/dev/null 2>&1; then
                    echo "✓ Healthy"
                    ((healthy++))
                else
                    echo "✗ Zone file has errors"
                    ((unhealthy++))
                fi
            else
                echo "? Cannot verify (named-checkzone not available)"
            fi
        fi
    done
    
    echo ""
    log_info "Health Summary: $healthy healthy, $unhealthy unhealthy"
    
    return $unhealthy
}

validate_all_zones() {
    log_info "Validating all zone files..."
    
    local valid=0
    local invalid=0
    
    for zone_file in "$ZONE_DIR"/db.*; do
        if [[ -f "$zone_file" ]]; then
            local domain=$(basename "$zone_file" | sed 's/^db\.//')
            
            if command -v named-checkzone >/dev/null; then
                echo "Validating $domain..."
                if named-checkzone "$domain" "$zone_file"; then
                    ((valid++))
                else
                    ((invalid++))
                fi
                echo ""
            fi
        fi
    done
    
    log_info "Validation Summary: $valid valid, $invalid invalid zones"
    
    if command -v named-checkconf >/dev/null; then
        log_info "Validating BIND configuration..."
        if named-checkconf; then
            log_success "BIND configuration is valid"
        else
            log_error "BIND configuration has errors"
        fi
    fi
}

backup_domain_configs() {
    log_info "Creating backup of domain configurations..."
    
    local backup_dir="/var/lib/domain-manager/backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$backup_dir/domain-backup-$timestamp"
    
    mkdir -p "$backup_path"
    
    # Backup zone files
    if [[ -d "$ZONE_DIR" ]]; then
        cp -r "$ZONE_DIR" "$backup_path/zones"
        log_success "Zone files backed up"
    fi
    
    # Backup BIND configuration
    if [[ -f "$NAMED_CONF" ]]; then
        cp "$NAMED_CONF" "$backup_path/named.conf.local"
        log_success "BIND configuration backed up"
    fi
    
    # Backup domain manager configuration
    if [[ -d "/etc/domain-manager" ]]; then
        cp -r "/etc/domain-manager" "$backup_path/domain-manager"
        log_success "Domain manager configuration backed up"
    fi
    
    # Backup web server configurations
    if [[ -d "/etc/apache2/sites-available" ]]; then
        mkdir -p "$backup_path/apache-sites"
        cp /etc/apache2/sites-available/*.conf "$backup_path/apache-sites/" 2>/dev/null || true
    fi
    
    if [[ -d "/etc/nginx/sites-available" ]]; then
        mkdir -p "$backup_path/nginx-sites"
        cp -r /etc/nginx/sites-available "$backup_path/nginx-sites" 2>/dev/null || true
    fi
    
    # Create backup manifest
    cat > "$backup_path/manifest.txt" <<EOF
Domain Configuration Backup
Created: $(date)
Backup Path: $backup_path

Contents:
- Zone files: $(ls -1 "$ZONE_DIR"/db.* 2>/dev/null | wc -l) files
- BIND configuration: $([ -f "$NAMED_CONF" ] && echo "Yes" || echo "No")
- Domain manager config: $([ -d "/etc/domain-manager" ] && echo "Yes" || echo "No")
- Apache configurations: $(ls -1 /etc/apache2/sites-available/*.conf 2>/dev/null | wc -l) files
- Nginx configurations: $(ls -1 /etc/nginx/sites-available/* 2>/dev/null | wc -l) files
EOF
    
    # Compress backup
    tar -czf "$backup_dir/domain-backup-$timestamp.tar.gz" -C "$backup_dir" "domain-backup-$timestamp"
    rm -rf "$backup_path"
    
    log_success "Backup created: domain-backup-$timestamp.tar.gz"
}

cleanup_old_backups() {
    local backup_dir="/var/lib/domain-manager/backups"
    local days="${1:-30}"
    
    log_info "Cleaning up backups older than $days days..."
    
    if [[ -d "$backup_dir" ]]; then
        local count=$(find "$backup_dir" -name "domain-backup-*.tar.gz" -mtime +$days | wc -l)
        
        if [[ $count -gt 0 ]]; then
            find "$backup_dir" -name "domain-backup-*.tar.gz" -mtime +$days -delete
            log_success "Removed $count old backup files"
        else
            log_info "No old backup files to remove"
        fi
    else
        log_warning "Backup directory not found: $backup_dir"
    fi
}

update_serial_numbers() {
    log_info "Updating zone file serial numbers..."
    
    local updated=0
    local current_date=$(date +%Y%m%d)
    
    for zone_file in "$ZONE_DIR"/db.*; do
        if [[ -f "$zone_file" ]]; then
            local domain=$(basename "$zone_file" | sed 's/^db\.//')
            
            # Find and update serial number
            if grep -q "Serial" "$zone_file"; then
                local new_serial="${current_date}$(printf "%02d" $(($(date +%H) + 1)))"
                
                # Backup original
                cp "$zone_file" "$zone_file.bak"
                
                # Update serial number
                sed -i "s/[0-9]\{10\}[[:space:]]*;[[:space:]]*Serial/${new_serial}  ; Serial/" "$zone_file"
                
                log_success "Updated serial for $domain to $new_serial"
                ((updated++))
            fi
        fi
    done
    
    if [[ $updated -gt 0 ]]; then
        log_info "Updated $updated zone serial numbers"
        reload_dns_service
    else
        log_info "No zone files needed serial number updates"
    fi
}

check_dns_propagation() {
    log_info "Checking DNS propagation for all domains..."
    
    local dns_servers=("8.8.8.8" "1.1.1.1" "208.67.222.222")
    
    for zone_file in "$ZONE_DIR"/db.*; do
        if [[ -f "$zone_file" ]]; then
            local domain=$(basename "$zone_file" | sed 's/^db\.//')
            
            echo ""
            echo "Domain: $domain"
            echo "=================="
            
            for server in "${dns_servers[@]}"; do
                echo -n "DNS Server $server: "
                if command -v dig >/dev/null; then
                    local result=$(dig +short "@$server" "$domain" 2>/dev/null)
                    if [[ -n "$result" ]]; then
                        echo "$result"
                    else
                        echo "No response"
                    fi
                else
                    echo "dig command not available"
                fi
            done
        fi
    done
}

optimize_zone_files() {
    log_info "Optimizing zone files..."
    
    for zone_file in "$ZONE_DIR"/db.*; do
        if [[ -f "$zone_file" ]]; then
            local domain=$(basename "$zone_file" | sed 's/^db\.//')
            
            # Backup original
            cp "$zone_file" "$zone_file.bak"
            
            # Remove duplicate entries and sort records
            awk '!seen[$0]++' "$zone_file" > "$zone_file.tmp"
            mv "$zone_file.tmp" "$zone_file"
            
            # Set proper permissions
            chown bind:bind "$zone_file" 2>/dev/null || true
            chmod 644 "$zone_file"
            
            log_success "Optimized zone file for $domain"
        fi
    done
}

generate_domain_report() {
    local report_file="/var/lib/domain-manager/domain-report-$(date +%Y%m%d).txt"
    
    log_info "Generating domain report: $report_file"
    
    cat > "$report_file" <<EOF
Domain Management Report
Generated: $(date)
=======================

System Information:
- Hostname: $(hostname)
- OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -a)
- DNS Service: $(systemctl is-active bind9 named 2>/dev/null | head -1)

Configuration:
- Zone Directory: $ZONE_DIR
- Named Config: $NAMED_CONF
- Total Domains: $(ls -1 "$ZONE_DIR"/db.* 2>/dev/null | wc -l)

Domain List:
EOF
    
    # Add domain details
    for zone_file in "$ZONE_DIR"/db.*; do
        if [[ -f "$zone_file" ]]; then
            local domain=$(basename "$zone_file" | sed 's/^db\.//')
            local size=$(stat -c%s "$zone_file" 2>/dev/null || echo "0")
            local modified=$(stat -c%y "$zone_file" 2>/dev/null || echo "Unknown")
            
            cat >> "$report_file" <<EOF
- Domain: $domain
  Zone File: $zone_file
  File Size: $size bytes
  Last Modified: $modified
  
EOF
        fi
    done
    
    # Add DNS service status
    echo "" >> "$report_file"
    echo "DNS Service Status:" >> "$report_file"
    
    if systemctl is-active --quiet bind9; then
        systemctl status bind9 --no-pager >> "$report_file" 2>&1
    elif systemctl is-active --quiet named; then
        systemctl status named --no-pager >> "$report_file" 2>&1
    else
        echo "DNS service not running" >> "$report_file"
    fi
    
    log_success "Domain report generated: $report_file"
}

reload_dns_service() {
    log_info "Reloading DNS service..."
    
    if systemctl is-active --quiet bind9; then
        systemctl reload bind9
        log_success "bind9 reloaded"
    elif systemctl is-active --quiet named; then
        systemctl reload named
        log_success "named reloaded"
    else
        log_warning "No active DNS service found"
        return 1
    fi
}

restart_web_services() {
    log_info "Restarting web services..."
    
    local restarted=0
    
    if systemctl is-active --quiet apache2; then
        systemctl restart apache2
        log_success "Apache2 restarted"
        ((restarted++))
    fi
    
    if systemctl is-active --quiet httpd; then
        systemctl restart httpd
        log_success "httpd restarted"
        ((restarted++))
    fi
    
    if systemctl is-active --quiet nginx; then
        systemctl restart nginx
        log_success "Nginx restarted"
        ((restarted++))
    fi
    
    if [[ $restarted -eq 0 ]]; then
        log_warning "No web services found to restart"
    fi
}

# ---------- Menu System ----------

show_maintenance_menu() {
    while true; do
        clear
        echo -e "${BLUE}=== Domain Management Maintenance ===${NC}"
        echo "1) Check Domain Health"
        echo "2) Validate All Zones"
        echo "3) Backup Configurations"
        echo "4) Cleanup Old Backups"
        echo "5) Update Serial Numbers"
        echo "6) Check DNS Propagation"
        echo "7) Optimize Zone Files"
        echo "8) Generate Domain Report"
        echo "9) Reload DNS Service"
        echo "10) Restart Web Services"
        echo "0) Exit"
        echo ""
        read -rp "Select an option: " choice
        
        case $choice in
            1) check_domain_health; pause ;;
            2) validate_all_zones; pause ;;
            3) backup_domain_configs; pause ;;
            4) 
                read -p "Delete backups older than how many days? [30]: " days
                cleanup_old_backups "${days:-30}"
                pause
                ;;
            5) update_serial_numbers; pause ;;
            6) check_dns_propagation; pause ;;
            7) optimize_zone_files; pause ;;
            8) generate_domain_report; pause ;;
            9) reload_dns_service; pause ;;
            10) restart_web_services; pause ;;
            0) 
                log_info "Exiting maintenance module..."
                exit 0
                ;;
            *) log_error "Invalid option"; sleep 2 ;;
        esac
        
        echo ""
        read -rp "Press Enter to continue..."
    done
}

pause() {
    echo ""
    read -rp "Press Enter to continue..."
}

# ---------- Main Function ----------
main() {
    check_root
    show_maintenance_menu
}

main "$@"