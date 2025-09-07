#!/usr/bin/env bash
# =============================================================================
# Linux Setup - DNS Module Maintenance
# =============================================================================

set -Eeuo pipefail

# ---------- Colors & Logging ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'

log_info()    { echo -e "[INFO] $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# ---------- System Checks ----------
check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)."
    exit 1
  fi
}

# ---------- Service Functions ----------
show_service_status() {
    log_info "Checking DNS service status..."

    # Check BIND/named status
    if systemctl is-active --quiet bind9; then
        systemctl status bind9 --no-pager
    elif systemctl is-active --quiet named; then
        systemctl status named --no-pager
    fi
    echo

    # Check ports
    log_info "Checking DNS ports..."
    ss -tulpn | grep ':53'
    echo

    # Check zone status
    log_info "Checking zone status..."
    if command -v rndc >/dev/null; then
        rndc status
        echo
        rndc zonestatus
    fi
}

show_error_logs() {
    log_info "Recent error logs:"

    # BIND/named logs
    if [[ -f "/var/log/syslog" ]]; then
        log_info "BIND logs from syslog (last 20 lines):"
        grep 'named\|bind' /var/log/syslog | tail -n 20
    elif [[ -f "/var/log/messages" ]]; then
        log_info "BIND logs from messages (last 20 lines):"
        grep 'named\|bind' /var/log/messages | tail -n 20
    fi
    echo

    # Query logs if enabled
    if [[ -f "/var/log/query.log" ]]; then
        log_info "DNS query logs (last 20 lines):"
        tail -n 20 /var/log/query.log
    fi
}

show_server_info() {
    log_info "DNS Server Information"

    # Version info
    log_info "BIND version:"
    named -v
    echo

    # Configuration check
    log_info "Checking configuration:"
    named-checkconf
    echo

    # Check all zones
    log_info "Checking all zones:"
    for zonefile in /etc/bind/zones/db.*; do
        if [[ -f "$zonefile" ]]; then
            local zone
            zone=$(basename "$zonefile" | sed 's/^db\.//')
            log_info "Checking zone: $zone"
            named-checkzone "$zone" "$zonefile"
        fi
    done
    echo

    # Resource usage
    log_info "Resource Usage:"
    echo "Memory usage:"
    free -h
    echo
    echo "Disk usage:"
    df -h /var
    echo
    echo "CPU load:"
    uptime
}

restart_services() {
    log_info "Restarting DNS services..."
    
    if systemctl is-active --quiet bind9; then
        systemctl restart bind9
        log_success "bind9 restarted"
    elif systemctl is-active --quiet named; then
        systemctl restart named
        log_success "named restarted"
    fi
    
    sleep 2
    show_service_status
}

cleanup_dns_logs() {
    log_info "Cleaning up DNS logs..."
    
    # Compress old logs
    find /var/log -name "*.log" -type f -mtime +7 -exec gzip {} \; 2>/dev/null || true
    
    # Remove logs older than 30 days
    find /var/log -name "*.gz" -type f -mtime +30 -delete 2>/dev/null || true
    
    log_success "Log cleanup completed"
}

analyze_dns_stats() {
    log_info "Analyzing DNS statistics..."
    
    if command -v rndc >/dev/null; then
        # Get BIND statistics
        rndc stats
        
        if [[ -f "/var/cache/bind/named.stats" ]]; then
            log_info "Recent DNS statistics:"
            tail -n 50 "/var/cache/bind/named.stats"
        fi
    fi
}

update_root_hints() {
    log_info "Updating root hints..."
    
    if command -v wget >/dev/null; then
        wget -O /etc/bind/db.root https://www.internic.net/domain/named.root
        chown bind:bind /etc/bind/db.root
        chmod 644 /etc/bind/db.root
        rndc reload
        log_success "Root hints updated"
    else
        log_error "wget not found. Please install wget to update root hints."
    fi
}

# ---------- Main Menu ----------
show_menu() {
    echo -e "${BLUE}=== DNS Server Maintenance ===${NC}"
    echo "1) Show Service Status"
    echo "2) Show Error Logs"
    echo "3) Show Server Information"
    echo "4) Restart Services"
    echo "5) Cleanup Logs"
    echo "6) Analyze DNS Statistics"
    echo "7) Update Root Hints"
    echo "0) Exit"
    echo
    read -rp "Select an option: " choice
}

# ---------- Main Function ----------
main() {
    check_root
    
    while true; do
        clear
        show_menu
        
        case $choice in
            1) show_service_status ;;
            2) show_error_logs ;;
            3) show_server_info ;;
            4) restart_services ;;
            5) cleanup_dns_logs ;;
            6) analyze_dns_stats ;;
            7) update_root_hints ;;
            0) 
                log_info "Exiting maintenance module..."
                exit 0
                ;;
            *) log_error "Invalid option" ;;
        esac
        
        echo
        read -rp "Press Enter to continue..."
    done
}

main "$@"
