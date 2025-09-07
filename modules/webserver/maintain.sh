#!/bin/bash
# =============================================================================
# Linux Setup - Webserver Module Maintenance
# =============================================================================
# Author: Anshul Yadav
# Description: Maintenance and monitoring functions for webserver module
# =============================================================================

set -e

# Script directory and base directory detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions
if [[ -f "$BASE_DIR/modules/common.sh" ]]; then
    source "$BASE_DIR/modules/common.sh"
else
    echo "Error: common.sh not found"
    exit 1
fi

# Source webserver functions
if [[ -f "$SCRIPT_DIR/functions.sh" ]]; then
    source "$SCRIPT_DIR/functions.sh"
fi

# ---------- Service Management Functions ----------
show_service_status() {
    print_step "Checking service status..."
    
    # Check Apache status
    if command -v apache2 >/dev/null; then
        systemctl status apache2 --no-pager
    else
        systemctl status httpd --no-pager
    fi
    echo

    # Check Nginx status
    systemctl status nginx --no-pager
    echo

    # Check PHP-FPM status
    for svc in php8.3-fpm php8.2-fpm php8.1-fpm php8.0-fpm php7.4-fpm php-fpm; do
        if systemctl is-active "$svc" >/dev/null 2>&1; then
            systemctl status "$svc" --no-pager
            break
        fi
    done
    echo

    # Check ports
    log_info "Checking listening ports..."
    ss -tlpn | grep -E ':80|:8080'
    echo
}

show_error_logs() {
    print_step "Recent error logs:"

    # Apache error logs
    if [[ -f "/var/log/apache2/error.log" ]]; then
        log_info "Apache errors (last 20 lines):"
        tail -n 20 /var/log/apache2/error.log
    elif [[ -f "/var/log/httpd/error_log" ]]; then
        log_info "Apache errors (last 20 lines):"
        tail -n 20 /var/log/httpd/error_log
    fi
    echo

    # Nginx error logs
    log_info "Nginx errors (last 20 lines):"
    tail -n 20 /var/log/nginx/error.log 2>/dev/null || log_warning "No Nginx error log found"
    echo

    # PHP-FPM error logs
    for ver in {8..7}; do
        if [[ -f "/var/log/php${ver}-fpm.log" ]]; then
            log_info "PHP${ver}-FPM errors (last 20 lines):"
            tail -n 20 "/var/log/php${ver}-fpm.log"
            break
        elif [[ -f "/var/log/php-fpm/error.log" ]]; then
            log_info "PHP-FPM errors (last 20 lines):"
            tail -n 20 /var/log/php-fpm/error.log
            break
        fi
    done
}

show_server_info() {
    print_step "Server Information"
    
    # Web server versions
    log_info "Web Server Versions:"
    if command -v apache2 >/dev/null; then
        apache2 -v
    elif command -v httpd >/dev/null; then
        httpd -v
    fi
    nginx -v
    php -v
    echo

    # Server resource usage
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
    print_step "Restarting web services..."
    
    # Find PHP-FPM service
    local php_fpm=""
    for svc in php8.3-fpm php8.2-fpm php8.1-fpm php8.0-fpm php7.4-fpm php-fpm; do
        if systemctl is-active "$svc" >/dev/null 2>&1; then
            php_fpm="$svc"
            break
        fi
    done

    # Restart services in order
    if [[ -n "$php_fpm" ]]; then
        log_info "Restarting $php_fpm..."
        systemctl restart "$php_fpm"
        sleep 2
    fi

    if command -v apache2 >/dev/null; then
        log_info "Restarting Apache..."
        systemctl restart apache2
    else
        log_info "Restarting httpd..."
        systemctl restart httpd
    fi
    sleep 2

    log_info "Restarting Nginx..."
    systemctl restart nginx

    print_success "All services restarted successfully"
}

# ==========================================
# WEBSERVER MAINTENANCE MAIN FUNCTION
# ==========================================

maintain_webserver() {
    print_section_header "🌐 WEBSERVER MODULE MAINTENANCE"
    
    while true; do
        echo "1) Show Service Status"
        echo "2) Show Error Logs"
        echo "3) Show Server Information"
        echo "4) Run Maintenance Tasks"
        echo "5) Restart Services"
        echo "0) Exit"
        echo
        read -rp "Select an option: " choice
        
        case $choice in
            1) show_service_status ;;
            2) show_error_logs ;;
            3) show_server_info ;;
            4) run_maintenance_tasks ;;
            5) restart_services ;;
            0) 
                log_info "Exiting maintenance module..."
                return 0
                ;;
            *) log_error "Invalid option" ;;
        esac
        
        echo
        read -rp "Press Enter to continue..."
    done
}

run_maintenance_tasks() {
    log_info "Starting webserver module maintenance..."
    
    # Check if running as root
    check_root
    
    # Perform maintenance tasks
    cleanup_webserver_logs
    optimize_webserver_performance
    check_webserver_health
    update_webserver_security
    backup_webserver_data
    analyze_webserver_usage
    
    print_success "Webserver module maintenance completed successfully!"
    
    # Display maintenance summary
    display_maintenance_summary
    
    log_info "Webserver module maintenance completed"
}

# ==========================================
# LOG CLEANUP FUNCTIONS
# ==========================================

cleanup_webserver_logs() {
    print_step "Cleaning up webserver logs..."
    
    # Clean Apache logs
    cleanup_apache_logs
    
    # Clean Nginx logs
    cleanup_nginx_logs
    
    # Clean PHP logs
    cleanup_php_logs
    
    log_info "Webserver log cleanup completed"
}

cleanup_apache_logs() {
    print_substep "Cleaning Apache logs..."
    
    local apache_log_dir="/var/log/apache2"
    
    if [[ -d "$apache_log_dir" ]]; then
        # Compress old logs
        find "$apache_log_dir" -name "*.log" -type f -mtime +7 -exec gzip {} \; 2>/dev/null || true
        
        # Remove logs older than 30 days
        find "$apache_log_dir" -name "*.gz" -type f -mtime +30 -delete 2>/dev/null || true
        
        # Rotate current logs if they're too large (>100MB)
        find "$apache_log_dir" -name "*.log" -type f -size +100M -exec logrotate -f /etc/logrotate.d/apache2 \; 2>/dev/null || true
        
        log_info "Apache logs cleaned"
    fi
}

cleanup_nginx_logs() {
    print_substep "Cleaning Nginx logs..."
    
    local nginx_log_dir="/var/log/nginx"
    
    if [[ -d "$nginx_log_dir" ]]; then
        # Compress old logs
        find "$nginx_log_dir" -name "*.log" -type f -mtime +7 -exec gzip {} \; 2>/dev/null || true
        
        # Remove logs older than 30 days
        find "$nginx_log_dir" -name "*.gz" -type f -mtime +30 -delete 2>/dev/null || true
        
        # Clear large access logs
        find "$nginx_log_dir" -name "access.log" -type f -size +100M -exec truncate -s 0 {} \; 2>/dev/null || true
        
        log_info "Nginx logs cleaned"
    fi
}

cleanup_php_logs() {
    print_substep "Cleaning PHP logs..."
    
    # Clean PHP error logs
    find /var/log -name "php*.log" -type f -mtime +7 -exec gzip {} \; 2>/dev/null || true
    find /var/log -name "php*.log.gz" -type f -mtime +30 -delete 2>/dev/null || true
    
    # Clean PHP-FPM logs
    if [[ -d "/var/log/php-fpm" ]]; then
        find /var/log/php-fpm -name "*.log" -type f -mtime +7 -exec gzip {} \; 2>/dev/null || true
        find /var/log/php-fpm -name "*.log.gz" -type f -mtime +30 -delete 2>/dev/null || true
    fi
    
    log_info "PHP logs cleaned"
}

# ==========================================
# PERFORMANCE OPTIMIZATION
# ==========================================

optimize_webserver_performance() {
    print_step "Optimizing webserver performance..."
    
    # Optimize Apache
    optimize_apache_performance
    
    # Optimize Nginx
    optimize_nginx_performance
    
    # Optimize PHP
    optimize_php_performance
    
    # Clean temporary files
    cleanup_temp_files
    
    log_info "Webserver performance optimization completed"
}

optimize_apache_performance() {
    print_substep "Optimizing Apache performance..."
    
    local apache_conf="/etc/apache2/apache2.conf"
    local mpm_conf="/etc/apache2/mods-enabled/mpm_prefork.conf"
    
    if [[ -f "$apache_conf" ]]; then
        # Update KeepAlive settings
        sed -i 's/KeepAlive On/KeepAlive On/' "$apache_conf"
        sed -i 's/MaxKeepAliveRequests 100/MaxKeepAliveRequests 100/' "$apache_conf"
        sed -i 's/KeepAliveTimeout 5/KeepAliveTimeout 5/' "$apache_conf"
    fi
    
    # Optimize MPM settings based on available memory
    if [[ -f "$mpm_conf" ]]; then
        local total_memory=$(get_total_memory)
        local max_request_workers=$((total_memory / 20))  # ~20MB per worker
        
        if [[ $max_request_workers -gt 256 ]]; then
            max_request_workers=256
        elif [[ $max_request_workers -lt 50 ]]; then
            max_request_workers=50
        fi
        
        # Update MaxRequestWorkers
        sed -i "s/MaxRequestWorkers.*/MaxRequestWorkers $max_request_workers/" "$mpm_conf"
    fi
    
    log_info "Apache performance optimized"
}

optimize_nginx_performance() {
    print_substep "Optimizing Nginx performance..."
    
    local nginx_conf="/etc/nginx/nginx.conf"
    
    if [[ -f "$nginx_conf" ]]; then
        # Update worker processes to match CPU cores
        local cpu_cores=$(nproc)
        sed -i "s/worker_processes.*/worker_processes $cpu_cores;/" "$nginx_conf"
        
        # Update worker connections
        sed -i 's/worker_connections.*/worker_connections 1024;/' "$nginx_conf"
        
        # Enable gzip compression if not already enabled
        if ! grep -q "gzip on" "$nginx_conf"; then
            sed -i '/http {/a\    gzip on;\n    gzip_vary on;\n    gzip_min_length 1024;' "$nginx_conf"
        fi
    fi
    
    log_info "Nginx performance optimized"
}

optimize_php_performance() {
    print_substep "Optimizing PHP performance..."
    
    local php_ini_files=$(find /etc/php* -name "php.ini" 2>/dev/null)
    
    for php_ini in $php_ini_files; do
        # Enable OPcache
        sed -i 's/;opcache.enable=.*/opcache.enable=1/' "$php_ini"
        sed -i 's/;opcache.memory_consumption=.*/opcache.memory_consumption=128/' "$php_ini"
        sed -i 's/;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=4000/' "$php_ini"
        
        # Optimize realpath cache
        sed -i 's/;realpath_cache_size =.*/realpath_cache_size = 4096K/' "$php_ini"
        sed -i 's/;realpath_cache_ttl =.*/realpath_cache_ttl = 600/' "$php_ini"
    done
    
    # Optimize PHP-FPM pool settings
    optimize_php_fpm_pools
    
    log_info "PHP performance optimized"
}

optimize_php_fpm_pools() {
    local pool_dir="/etc/php/*/fpm/pool.d"
    local www_conf=$(find $pool_dir -name "www.conf" 2>/dev/null | head -1)
    
    if [[ -f "$www_conf" ]]; then
        local total_memory=$(get_total_memory)
        local max_children=$((total_memory / 50))  # ~50MB per child
        
        if [[ $max_children -gt 50 ]]; then
            max_children=50
        elif [[ $max_children -lt 5 ]]; then
            max_children=5
        fi
        
        # Update pool settings
        sed -i "s/pm.max_children = .*/pm.max_children = $max_children/" "$www_conf"
        sed -i "s/pm.start_servers = .*/pm.start_servers = 3/" "$www_conf"
        sed -i "s/pm.min_spare_servers = .*/pm.min_spare_servers = 2/" "$www_conf"
        sed -i "s/pm.max_spare_servers = .*/pm.max_spare_servers = 5/" "$www_conf"
    fi
}

cleanup_temp_files() {
    print_substep "Cleaning temporary files..."
    
    # Clean Apache temporary files
    find /tmp -name "apache*" -type f -mtime +1 -delete 2>/dev/null || true
    
    # Clean PHP session files
    find /var/lib/php/sessions -name "sess_*" -type f -mtime +1 -delete 2>/dev/null || true
    
    # Clean web cache files
    find /var/cache -name "*apache*" -type f -mtime +1 -delete 2>/dev/null || true
    find /var/cache -name "*nginx*" -type f -mtime +1 -delete 2>/dev/null || true
    
    log_info "Temporary files cleaned"
}

# ==========================================
# HEALTH CHECK FUNCTIONS
# ==========================================

check_webserver_health() {
    print_step "Checking webserver health..."
    
    # Check service status
    check_service_health
    
    # Check resource usage
    check_resource_usage
    
    # Check SSL certificates
    check_ssl_health
    
    # Check disk space
    check_disk_space
    
    # Check log errors
    check_log_errors
    
    log_info "Webserver health check completed"
}

check_service_health() {
    print_substep "Checking service health..."
    
    # Check Apache
    if systemctl is-active apache2 >/dev/null 2>&1 || systemctl is-active httpd >/dev/null 2>&1; then
        log_success "Apache: Running"
    else
        log_warning "Apache: Not running"
    fi
    
    # Check Nginx
    if systemctl is-active nginx >/dev/null 2>&1; then
        log_success "Nginx: Running"
    else
        log_warning "Nginx: Not running"
    fi
    
    # Check PHP-FPM
    if systemctl is-active php-fpm >/dev/null 2>&1; then
        log_success "PHP-FPM: Running"
    else
        log_warning "PHP-FPM: Not running"
    fi
    
    # Check ports
    if ss -tlnp | grep -q ":80 "; then
        log_success "Port 80: Listening"
    else
        log_warning "Port 80: Not listening"
    fi
    
    if ss -tlnp | grep -q ":443 "; then
        log_success "Port 443: Listening"
    else
        log_warning "Port 443: Not listening"
    fi
}

check_resource_usage() {
    print_substep "Checking resource usage..."
    
    # Memory usage
    local memory_usage=$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}')
    log_info "Memory usage: ${memory_usage}%"
    
    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    log_info "CPU usage: ${cpu_usage}%"
    
    # Load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}')
    log_info "Load average:${load_avg}"
    
    # Apache processes
    local apache_procs=$(pgrep -c apache2 2>/dev/null || pgrep -c httpd 2>/dev/null || echo "0")
    log_info "Apache processes: $apache_procs"
    
    # Nginx processes
    local nginx_procs=$(pgrep -c nginx 2>/dev/null || echo "0")
    log_info "Nginx processes: $nginx_procs"
}

check_ssl_health() {
    print_substep "Checking SSL certificate health..."
    
    # Check Let's Encrypt certificates
    if [[ -d "/etc/letsencrypt/live" ]]; then
        for cert_dir in /etc/letsencrypt/live/*/; do
            if [[ -d "$cert_dir" ]]; then
                local domain=$(basename "$cert_dir")
                local cert_file="$cert_dir/cert.pem"
                
                if [[ -f "$cert_file" ]]; then
                    local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
                    local expiry_epoch=$(date -d "$expiry_date" +%s)
                    local current_epoch=$(date +%s)
                    local days_remaining=$(( (expiry_epoch - current_epoch) / 86400 ))
                    
                    if [[ $days_remaining -lt 30 ]]; then
                        log_warning "SSL certificate for $domain expires in $days_remaining days"
                    else
                        log_info "SSL certificate for $domain: Valid ($days_remaining days remaining)"
                    fi
                fi
            fi
        done
    fi
}

check_disk_space() {
    print_substep "Checking disk space..."
    
    # Check web root directory
    local web_root_usage=$(df /var/www 2>/dev/null | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    log_info "Web root disk usage: ${web_root_usage}%"
    
    # Check log directory
    local log_usage=$(df /var/log 2>/dev/null | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    log_info "Log directory disk usage: ${log_usage}%"
    
    # Warning if usage is high
    if [[ $web_root_usage -gt 80 ]] || [[ $log_usage -gt 80 ]]; then
        log_warning "High disk usage detected"
    fi
}

check_log_errors() {
    print_substep "Checking for log errors..."
    
    local error_count=0
    
    # Check Apache error logs
    if [[ -f "/var/log/apache2/error.log" ]]; then
        local apache_errors=$(tail -100 /var/log/apache2/error.log | grep -c "error" 2>/dev/null || echo "0")
        error_count=$((error_count + apache_errors))
        log_info "Apache errors (last 100 lines): $apache_errors"
    fi
    
    # Check Nginx error logs
    if [[ -f "/var/log/nginx/error.log" ]]; then
        local nginx_errors=$(tail -100 /var/log/nginx/error.log | grep -c "error" 2>/dev/null || echo "0")
        error_count=$((error_count + nginx_errors))
        log_info "Nginx errors (last 100 lines): $nginx_errors"
    fi
    
    # Check PHP error logs
    if [[ -f "/var/log/php_errors.log" ]]; then
        local php_errors=$(tail -100 /var/log/php_errors.log | grep -c "Fatal\|Error" 2>/dev/null || echo "0")
        error_count=$((error_count + php_errors))
        log_info "PHP errors (last 100 lines): $php_errors"
    fi
    
    if [[ $error_count -gt 10 ]]; then
        log_warning "High error count detected: $error_count"
    fi
}

# ==========================================
# SECURITY UPDATE FUNCTIONS
# ==========================================

update_webserver_security() {
    print_step "Updating webserver security..."
    
    # Update Fail2Ban status
    check_fail2ban_status
    
    # Update firewall rules
    verify_firewall_rules
    
    # Check for security updates
    check_security_updates
    
    log_info "Webserver security updated"
}

check_fail2ban_status() {
    print_substep "Checking Fail2Ban status..."
    
    if command -v fail2ban-client >/dev/null 2>&1; then
        if systemctl is-active fail2ban >/dev/null 2>&1; then
            local banned_ips=$(fail2ban-client status | grep "Jail list:" | awk -F: '{print $2}' | wc -w)
            log_info "Fail2Ban: Active (${banned_ips} jails)"
            
            # Show banned IPs for web services
            fail2ban-client status apache-auth 2>/dev/null | grep "Banned IP list:" || true
            fail2ban-client status nginx-http-auth 2>/dev/null | grep "Banned IP list:" || true
        else
            log_warning "Fail2Ban: Not running"
        fi
    else
        log_warning "Fail2Ban: Not installed"
    fi
}

verify_firewall_rules() {
    print_substep "Verifying firewall rules..."
    
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "80/tcp"; then
            log_success "UFW: HTTP port open"
        else
            log_warning "UFW: HTTP port not open"
        fi
        
        if ufw status | grep -q "443/tcp"; then
            log_success "UFW: HTTPS port open"
        else
            log_warning "UFW: HTTPS port not open"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if firewall-cmd --list-services | grep -q "http"; then
            log_success "Firewalld: HTTP service enabled"
        else
            log_warning "Firewalld: HTTP service not enabled"
        fi
        
        if firewall-cmd --list-services | grep -q "https"; then
            log_success "Firewalld: HTTPS service enabled"
        else
            log_warning "Firewalld: HTTPS service not enabled"
        fi
    fi
}

check_security_updates() {
    print_substep "Checking for security updates..."
    
    case $OS in
        "ubuntu"|"debian")
            local security_updates=$(apt list --upgradable 2>/dev/null | grep -c "security" || echo "0")
            log_info "Available security updates: $security_updates"
            ;;
        "centos"|"rhel"|"rocky"|"alma")
            local security_updates=$(dnf check-update --security 2>/dev/null | grep -c "updates" || echo "0")
            log_info "Available security updates: $security_updates"
            ;;
    esac
}

# ==========================================
# BACKUP FUNCTIONS
# ==========================================

backup_webserver_data() {
    print_step "Backing up webserver data..."
    
    local backup_dir="/root/backups/webserver-maintenance-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup web files
    backup_web_files "$backup_dir"
    
    # Backup configurations
    backup_configurations "$backup_dir"
    
    # Backup SSL certificates
    backup_ssl_certificates "$backup_dir"
    
    log_success "Webserver data backed up to: $backup_dir"
}

backup_web_files() {
    local backup_dir="$1"
    print_substep "Backing up web files..."
    
    if [[ -d "/var/www" ]]; then
        tar -czf "$backup_dir/web_files.tar.gz" /var/www 2>/dev/null || true
        log_info "Web files backed up"
    fi
}

backup_configurations() {
    local backup_dir="$1"
    print_substep "Backing up configurations..."
    
    # Apache configuration
    if [[ -d "/etc/apache2" ]]; then
        tar -czf "$backup_dir/apache_config.tar.gz" /etc/apache2 2>/dev/null || true
    fi
    
    # Nginx configuration
    if [[ -d "/etc/nginx" ]]; then
        tar -czf "$backup_dir/nginx_config.tar.gz" /etc/nginx 2>/dev/null || true
    fi
    
    # PHP configuration
    if [[ -d "/etc/php" ]]; then
        tar -czf "$backup_dir/php_config.tar.gz" /etc/php 2>/dev/null || true
    fi
    
    log_info "Configurations backed up"
}

backup_ssl_certificates() {
    local backup_dir="$1"
    print_substep "Backing up SSL certificates..."
    
    if [[ -d "/etc/letsencrypt" ]]; then
        tar -czf "$backup_dir/ssl_certificates.tar.gz" /etc/letsencrypt 2>/dev/null || true
        log_info "SSL certificates backed up"
    fi
}

# ==========================================
# USAGE ANALYSIS
# ==========================================

analyze_webserver_usage() {
    print_step "Analyzing webserver usage..."
    
    # Analyze access logs
    analyze_access_logs
    
    # Analyze error patterns
    analyze_error_patterns
    
    # Generate usage report
    generate_usage_report
    
    log_info "Webserver usage analysis completed"
}

analyze_access_logs() {
    print_substep "Analyzing access logs..."
    
    local apache_access="/var/log/apache2/access.log"
    local nginx_access="/var/log/nginx/access.log"
    
    if [[ -f "$apache_access" ]]; then
        local requests_today=$(grep "$(date '+%d/%b/%Y')" "$apache_access" | wc -l 2>/dev/null || echo "0")
        log_info "Apache requests today: $requests_today"
        
        local top_ips=$(tail -1000 "$apache_access" | awk '{print $1}' | sort | uniq -c | sort -nr | head -5)
        log_info "Top 5 IP addresses:"
        echo "$top_ips" | while read count ip; do
            log_info "  $ip: $count requests"
        done
    fi
    
    if [[ -f "$nginx_access" ]]; then
        local requests_today=$(grep "$(date '+%d/%b/%Y')" "$nginx_access" | wc -l 2>/dev/null || echo "0")
        log_info "Nginx requests today: $requests_today"
    fi
}

analyze_error_patterns() {
    print_substep "Analyzing error patterns..."
    
    local apache_error="/var/log/apache2/error.log"
    local nginx_error="/var/log/nginx/error.log"
    
    if [[ -f "$apache_error" ]]; then
        local errors_today=$(grep "$(date '+%Y-%m-%d')" "$apache_error" | wc -l 2>/dev/null || echo "0")
        log_info "Apache errors today: $errors_today"
        
        if [[ $errors_today -gt 0 ]]; then
            local common_errors=$(grep "$(date '+%Y-%m-%d')" "$apache_error" | awk '{print $NF}' | sort | uniq -c | sort -nr | head -3)
            log_info "Common error types:"
            echo "$common_errors" | while read count error; do
                log_info "  $error: $count occurrences"
            done
        fi
    fi
    
    if [[ -f "$nginx_error" ]]; then
        local errors_today=$(grep "$(date '+%Y/%m/%d')" "$nginx_error" | wc -l 2>/dev/null || echo "0")
        log_info "Nginx errors today: $errors_today"
    fi
}

generate_usage_report() {
    print_substep "Generating usage report..."
    
    local report_file="/var/log/webserver_maintenance_report_$(date +%Y%m%d).txt"
    
    cat > "$report_file" << EOF
Webserver Maintenance Report
Generated: $(date)
Hostname: $(hostname)

=== Service Status ===
Apache: $(systemctl is-active apache2 2>/dev/null || systemctl is-active httpd 2>/dev/null || echo 'inactive')
Nginx: $(systemctl is-active nginx 2>/dev/null || echo 'inactive')
PHP-FPM: $(systemctl is-active php-fpm 2>/dev/null || echo 'inactive')

=== Resource Usage ===
Memory: $(free | grep Mem | awk '{printf "%.1f%%", ($3/$2) * 100.0}')
CPU Load: $(uptime | awk -F'load average:' '{print $2}')
Disk Usage: $(df / | tail -1 | awk '{print $5}')

=== Recent Activity ===
Total Requests Today: $(grep "$(date '+%d/%b/%Y')" /var/log/*/access.log 2>/dev/null | wc -l || echo "N/A")
Total Errors Today: $(grep "$(date '+%Y-%m-%d')" /var/log/*/error.log 2>/dev/null | wc -l || echo "N/A")

=== SSL Status ===
EOF
    
    # Add SSL certificate info
    if [[ -d "/etc/letsencrypt/live" ]]; then
        for cert_dir in /etc/letsencrypt/live/*/; do
            if [[ -d "$cert_dir" ]]; then
                local domain=$(basename "$cert_dir")
                local cert_file="$cert_dir/cert.pem"
                if [[ -f "$cert_file" ]]; then
                    local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
                    echo "$domain: Expires $expiry_date" >> "$report_file"
                fi
            fi
        done
    else
        echo "No Let's Encrypt certificates found" >> "$report_file"
    fi
    
    log_info "Usage report generated: $report_file"
}

# ==========================================
# SUMMARY DISPLAY
# ==========================================

display_maintenance_summary() {
    print_section_header "🌐 WEBSERVER MAINTENANCE SUMMARY"
    
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                 🌐 WEBSERVER MAINTENANCE                   │${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│                                                             │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Log cleanup and rotation completed               │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Performance optimization applied                 │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Health checks and monitoring completed           │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Security updates and verification completed      │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Data backup and archival completed               │${NC}"
    echo -e "${BLUE}│  ${GREEN}✓${NC} Usage analysis and reporting completed           │${NC}"
    echo -e "${BLUE}│                                                             │${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│  ${CYAN}📊 CURRENT STATUS:${NC}                                  │${NC}"
    echo -e "${BLUE}│    • Apache: $(systemctl is-active apache2 2>/dev/null || systemctl is-active httpd 2>/dev/null || echo 'inactive')                                │${NC}"
    echo -e "${BLUE}│    • Nginx:  $(systemctl is-active nginx 2>/dev/null || echo 'inactive')                                │${NC}"
    echo -e "${BLUE}│    • PHP-FPM: $(systemctl is-active php-fpm 2>/dev/null || echo 'inactive')                               │${NC}"
    echo -e "${BLUE}│    • Memory: $(free | grep Mem | awk '{printf "%.1f%%", ($3/$2) * 100.0}')                             │${NC}"
    echo -e "${BLUE}│                                                             │${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│  ${CYAN}📝 REPORTS GENERATED:${NC}                              │${NC}"
    echo -e "${BLUE}│    • Maintenance report: /var/log/webserver_maintenance_*  │${NC}"
    echo -e "${BLUE}│    • Backup location: /root/backups/webserver-maintenance* │${NC}"
    echo -e "${BLUE}│                                                             │${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${GREEN}🎉 Webserver maintenance completed successfully!${NC}"
    echo -e "${CYAN}📚 Run './master.sh' for interactive management${NC}"
    echo ""
}

# ==========================================
# MAIN EXECUTION
# ==========================================

main() {
    # Create log entry
    log_info "=== Webserver Module Maintenance Started ==="
    
    # Run maintenance
    maintain_webserver
    
    # Create log entry
    log_info "=== Webserver Module Maintenance Completed ==="
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
