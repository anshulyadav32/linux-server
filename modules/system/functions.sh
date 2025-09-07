#!/bin/bash
# System Functions Library
# Reusable functions for system administration and monitoring

#===========================================
# SYSTEM INFORMATION FUNCTIONS
#===========================================

show_system_info() {
    echo "[INFO] System Information:"
    echo "=========================="
    echo "Hostname: $(hostname -f)"
    echo "OS: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Uptime: $(uptime -p)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    echo "=== Hardware Information ==="
    echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    echo "CPU Cores: $(nproc)"
    echo "Total Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
    echo "Available Memory: $(free -h | grep '^Mem:' | awk '{print $7}')"
    echo "Disk Usage: $(df -h / | grep -v Filesystem | awk '{print $5 " used of " $2}')"
    echo ""
    echo "=== Network Information ==="
    ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print "IP: " $2}' | head -3
}

show_resource_usage() {
    echo "[INFO] Current Resource Usage:"
    echo "=============================="
    
    # CPU Usage
    echo "=== CPU Usage ==="
    top -bn1 | grep "Cpu(s)" | awk '{print "CPU Usage: " $2 " user, " $4 " system, " $8 " idle"}'
    
    # Memory Usage
    echo ""
    echo "=== Memory Usage ==="
    free -h
    
    # Disk Usage
    echo ""
    echo "=== Disk Usage ==="
    df -h | grep -v tmpfs
    
    # Top Processes
    echo ""
    echo "=== Top 5 CPU Processes ==="
    ps aux --sort=-%cpu | head -6
    
    echo ""
    echo "=== Top 5 Memory Processes ==="
    ps aux --sort=-%mem | head -6
}

show_network_status() {
    echo "[INFO] Network Status:"
    echo "====================="
    
    # Network interfaces
    echo "=== Network Interfaces ==="
    ip addr show | grep -E '^[0-9]|inet ' | sed 's/^[[:space:]]*//'
    
    echo ""
    echo "=== Active Connections ==="
    netstat -tlnp | head -10
    
    echo ""
    echo "=== DNS Configuration ==="
    cat /etc/resolv.conf | grep nameserver
    
    echo ""
    echo "=== Routing Table ==="
    ip route show
}

#===========================================
# SYSTEM MONITORING FUNCTIONS
#===========================================

monitor_system() {
    local duration="${1:-60}"
    local interval="${2:-5}"
    
    echo "[INFO] Monitoring system for $duration seconds (interval: ${interval}s)"
    
    local end_time=$(($(date +%s) + duration))
    
    while [[ $(date +%s) -lt $end_time ]]; do
        clear
        echo "=== System Monitor ($(date)) ==="
        echo "Press Ctrl+C to stop monitoring"
        echo ""
        
        # CPU and Memory
        echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)% used"
        echo "Memory: $(free | grep '^Mem:' | awk '{printf "%.1f", $3/$2 * 100.0}')% used"
        echo "Disk: $(df / | tail -1 | awk '{print $5}') used"
        echo ""
        
        # Load average
        echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
        echo ""
        
        # Top processes
        echo "=== Top 5 Processes by CPU ==="
        ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "%-10s %5s%% %s\n", $1, $3, $11}'
        
        sleep "$interval"
    done
}

check_system_health() {
    echo "[INFO] System Health Check:"
    echo "=========================="
    
    local issues=0
    
    # Check disk space
    echo "=== Disk Space Check ==="
    df -h | awk 'NR>1 {usage=int($5); if(usage>90) print "WARNING: " $6 " is " usage "% full"; else if(usage>80) print "CAUTION: " $6 " is " usage "% full"}'
    
    # Check memory usage
    echo ""
    echo "=== Memory Check ==="
    local mem_usage=$(free | grep '^Mem:' | awk '{printf "%.1f", $3/$2 * 100.0}')
    if (( $(echo "$mem_usage > 90" | bc -l) )); then
        echo "WARNING: Memory usage is ${mem_usage}%"
        ((issues++))
    elif (( $(echo "$mem_usage > 80" | bc -l) )); then
        echo "CAUTION: Memory usage is ${mem_usage}%"
    else
        echo "Memory usage: ${mem_usage}% (OK)"
    fi
    
    # Check load average
    echo ""
    echo "=== Load Average Check ==="
    local load1=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
    local cores=$(nproc)
    if (( $(echo "$load1 > $cores * 2" | bc -l) )); then
        echo "WARNING: High load average: $load1 (cores: $cores)"
        ((issues++))
    else
        echo "Load average: $load1 (cores: $cores) (OK)"
    fi
    
    # Check critical services
    echo ""
    echo "=== Service Status Check ==="
    local services=("sshd" "systemd-resolved" "cron")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo "$service: Active"
        else
            echo "WARNING: $service is not active"
            ((issues++))
        fi
    done
    
    # Check failed systemd services
    echo ""
    echo "=== Failed Services Check ==="
    local failed_services=$(systemctl --failed --no-legend | wc -l)
    if [[ $failed_services -gt 0 ]]; then
        echo "WARNING: $failed_services failed services found"
        systemctl --failed --no-legend
        ((issues++))
    else
        echo "No failed services (OK)"
    fi
    
    echo ""
    if [[ $issues -eq 0 ]]; then
        echo "[SUCCESS] System health check passed"
    else
        echo "[WARNING] System health check found $issues issues"
    fi
}

view_system_logs() {
    local lines="${1:-50}"
    local service="$2"
    
    if [[ -n "$service" ]]; then
        echo "[INFO] Recent logs for service: $service"
        journalctl -u "$service" -n "$lines" --no-pager
    else
        echo "[INFO] Recent system logs (last $lines lines):"
        journalctl -n "$lines" --no-pager
    fi
}

#===========================================
# USER MANAGEMENT FUNCTIONS
#===========================================

create_system_user() {
    local username="$1"
    local password="$2"
    local sudo_access="${3:-no}"
    
    if [[ -z "$username" || -z "$password" ]]; then
        echo "[ERROR] Username and password parameters required"
        return 1
    fi
    
    echo "[INFO] Creating system user: $username"
    
    # Create user
    useradd -m -s /bin/bash "$username"
    echo "$username:$password" | chpasswd
    
    # Add to sudo group if requested
    if [[ "$sudo_access" =~ ^[Yy]|yes$ ]]; then
        usermod -aG sudo "$username"
        echo "[INFO] User $username added to sudo group"
    fi
    
    echo "[SUCCESS] User $username created"
}

delete_system_user() {
    local username="$1"
    local remove_home="${2:-yes}"
    
    if [[ -z "$username" ]]; then
        echo "[ERROR] Username parameter required"
        return 1
    fi
    
    echo "[WARNING] This will delete user: $username"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        if [[ "$remove_home" =~ ^[Yy]|yes$ ]]; then
            userdel -r "$username"
            echo "[SUCCESS] User $username and home directory deleted"
        else
            userdel "$username"
            echo "[SUCCESS] User $username deleted (home directory preserved)"
        fi
    else
        echo "[INFO] Operation cancelled"
    fi
}

list_system_users() {
    echo "[INFO] System users:"
    echo "=================="
    getent passwd | grep "/home/" | cut -d: -f1,3,5 | while IFS=: read username uid fullname; do
        local groups=$(groups "$username" 2>/dev/null | cut -d: -f2)
        echo "User: $username (UID: $uid)"
        echo "  Name: $fullname"
        echo "  Groups: $groups"
        echo ""
    done
}

change_user_password() {
    local username="$1"
    local new_password="$2"
    
    if [[ -z "$username" || -z "$new_password" ]]; then
        echo "[ERROR] Username and new password parameters required"
        return 1
    fi
    
    echo "[INFO] Changing password for user: $username"
    echo "$username:$new_password" | chpasswd
    echo "[SUCCESS] Password changed for $username"
}

#===========================================
# PACKAGE MANAGEMENT FUNCTIONS
#===========================================

update_system() {
    echo "[INFO] Updating system packages..."
    
    # Update package list
    apt update -y
    
    # Show available upgrades
    local upgrades=$(apt list --upgradable 2>/dev/null | wc -l)
    echo "[INFO] $upgrades packages available for upgrade"
    
    # Perform upgrade
    apt upgrade -y
    
    # Clean up
    apt autoremove -y
    apt autoclean
    
    echo "[SUCCESS] System updated"
}

install_package() {
    local package="$1"
    
    if [[ -z "$package" ]]; then
        echo "[ERROR] Package name parameter required"
        return 1
    fi
    
    echo "[INFO] Installing package: $package"
    apt update -y
    apt install -y "$package"
    
    if [[ $? -eq 0 ]]; then
        echo "[SUCCESS] Package $package installed"
    else
        echo "[ERROR] Failed to install package $package"
        return 1
    fi
}

remove_package() {
    local package="$1"
    local purge="${2:-no}"
    
    if [[ -z "$package" ]]; then
        echo "[ERROR] Package name parameter required"
        return 1
    fi
    
    echo "[INFO] Removing package: $package"
    
    if [[ "$purge" =~ ^[Yy]|yes$ ]]; then
        apt purge -y "$package"
        echo "[SUCCESS] Package $package purged"
    else
        apt remove -y "$package"
        echo "[SUCCESS] Package $package removed"
    fi
    
    # Clean up
    apt autoremove -y
}

search_package() {
    local search_term="$1"
    
    if [[ -z "$search_term" ]]; then
        echo "[ERROR] Search term parameter required"
        return 1
    fi
    
    echo "[INFO] Searching for packages matching: $search_term"
    apt search "$search_term" | head -20
}

list_installed_packages() {
    local pattern="${1:-.*}"
    
    echo "[INFO] Installed packages:"
    dpkg -l | grep "^ii" | awk '{print $2 " " $3}' | grep "$pattern" | head -50
}

#===========================================
# CRON JOB MANAGEMENT FUNCTIONS
#===========================================

add_cron_job() {
    local schedule="$1"
    local command="$2"
    local username="${3:-root}"
    
    if [[ -z "$schedule" || -z "$command" ]]; then
        echo "[ERROR] Schedule and command parameters required"
        return 1
    fi
    
    echo "[INFO] Adding cron job for user: $username"
    echo "Schedule: $schedule"
    echo "Command: $command"
    
    # Add to crontab
    (crontab -u "$username" -l 2>/dev/null; echo "$schedule $command") | crontab -u "$username" -
    
    echo "[SUCCESS] Cron job added"
}

list_cron_jobs() {
    local username="${1:-root}"
    
    echo "[INFO] Cron jobs for user: $username"
    echo "==================================="
    crontab -u "$username" -l 2>/dev/null || echo "No cron jobs found"
}

remove_cron_job() {
    local line_number="$1"
    local username="${2:-root}"
    
    if [[ -z "$line_number" ]]; then
        echo "[ERROR] Line number parameter required"
        echo "Use 'list_cron_jobs' to see line numbers"
        return 1
    fi
    
    echo "[INFO] Removing cron job line $line_number for user: $username"
    
    # Remove specific line from crontab
    crontab -u "$username" -l 2>/dev/null | sed "${line_number}d" | crontab -u "$username" -
    
    echo "[SUCCESS] Cron job removed"
}

#===========================================
# SYSTEM MAINTENANCE FUNCTIONS
#===========================================

cleanup_system() {
    echo "[INFO] Performing system cleanup..."
    
    # Clean package cache
    apt autoclean
    apt autoremove -y
    
    # Clean log files older than 30 days
    find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null || true
    
    # Clean temporary files
    find /tmp -type f -mtime +7 -delete 2>/dev/null || true
    find /var/tmp -type f -mtime +7 -delete 2>/dev/null || true
    
    # Clean user cache
    find /home -name ".cache" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Clean journal logs older than 30 days
    journalctl --vacuum-time=30d
    
    echo "[SUCCESS] System cleanup completed"
}

optimize_system() {
    echo "[INFO] Optimizing system performance..."
    
    # Update package database
    updatedb &
    
    # Sync and drop caches
    sync
    echo 3 > /proc/sys/vm/drop_caches
    
    # Update locate database
    updatedb
    
    echo "[SUCCESS] System optimization completed"
}

backup_system_config() {
    local backup_dir="/root/system-config-backup-$(date +%Y%m%d_%H%M%S)"
    
    echo "[INFO] Backing up system configuration to: $backup_dir"
    
    mkdir -p "$backup_dir"
    
    # Backup important configuration files
    cp -r /etc "$backup_dir/" 2>/dev/null || true
    cp -r /root/.bashrc "$backup_dir/" 2>/dev/null || true
    cp -r /root/.profile "$backup_dir/" 2>/dev/null || true
    
    # Backup crontabs
    mkdir -p "$backup_dir/crontabs"
    cp -r /var/spool/cron/crontabs/* "$backup_dir/crontabs/" 2>/dev/null || true
    
    # Backup package list
    dpkg --get-selections > "$backup_dir/package-list.txt"
    
    # Create archive
    tar -czf "$backup_dir.tar.gz" -C "$(dirname $backup_dir)" "$(basename $backup_dir)"
    rm -rf "$backup_dir"
    
    echo "[SUCCESS] System configuration backed up to: $backup_dir.tar.gz"
}

#===========================================
# SYSTEM SECURITY FUNCTIONS
#===========================================

harden_system() {
    echo "[INFO] Applying basic system hardening..."
    
    # Disable root login
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    
    # Set password policies
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs
    
    # Enable firewall if not already enabled
    if ! ufw status | grep -q "Status: active"; then
        ufw --force enable
    fi
    
    # Configure automatic updates
    apt install -y unattended-upgrades
    echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/20auto-upgrades
    echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/20auto-upgrades
    
    # Restart SSH service
    systemctl restart sshd
    
    echo "[SUCCESS] Basic system hardening applied"
}

scan_security() {
    echo "[INFO] Performing security scan..."
    
    # Check for rootkits (if chkrootkit is available)
    if command -v chkrootkit &> /dev/null; then
        echo "=== Rootkit Scan ==="
        chkrootkit | grep INFECTED || echo "No rootkits detected"
    fi
    
    # Check for unusual processes
    echo ""
    echo "=== Process Check ==="
    ps aux | awk '$3 > 50.0 {print "High CPU: " $0}'
    ps aux | awk '$4 > 20.0 {print "High Memory: " $0}'
    
    # Check for suspicious network connections
    echo ""
    echo "=== Network Connections ==="
    netstat -an | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10
    
    echo ""
    echo "[SUCCESS] Security scan completed"
}

#===========================================
# SYSTEM RESTORE FUNCTIONS
#===========================================

create_system_snapshot() {
    local snapshot_name="${1:-system-snapshot-$(date +%Y%m%d_%H%M%S)}"
    
    echo "[INFO] Creating system snapshot: $snapshot_name"
    
    # This is a basic implementation - in production, you might use LVM snapshots or similar
    tar --exclude='/proc' --exclude='/tmp' --exclude='/sys' --exclude='/dev' \
        --exclude='/run' --exclude='/mnt' --exclude='/media' \
        -czf "/root/$snapshot_name.tar.gz" / 2>/dev/null
    
    echo "[SUCCESS] System snapshot created: /root/$snapshot_name.tar.gz"
}
