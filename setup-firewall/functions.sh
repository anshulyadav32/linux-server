#!/bin/bash
# Firewall Functions Library
# Reusable functions for firewall and security management

#===========================================
# INSTALLATION FUNCTIONS
#===========================================

install_firewall() {
    echo "[INFO] Installing firewall components..."
    
    # Update package list
    apt update -y
    
    # Install UFW (Uncomplicated Firewall) and Fail2Ban
    apt install -y ufw fail2ban iptables-persistent
    
    # Configure basic UFW settings
    configure_ufw_defaults
    
    # Configure Fail2Ban
    configure_fail2ban_defaults
    
    echo "[SUCCESS] Firewall components installed"
}

configure_ufw_defaults() {
    echo "[INFO] Configuring UFW defaults..."
    
    # Reset UFW to defaults
    ufw --force reset
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH (port 22) - important to avoid lockout
    ufw allow ssh
    
    # Enable UFW
    ufw --force enable
    
    echo "[SUCCESS] UFW configured with secure defaults"
}

configure_fail2ban_defaults() {
    echo "[INFO] Configuring Fail2Ban defaults..."
    
    # Create custom jail.local configuration
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Ban time (in seconds)
bantime = 3600

# Find time (in seconds)
findtime = 600

# Max retry attempts
maxretry = 3

# Ignore local IPs
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[apache]
enabled = true
port = http,https
filter = apache-auth
logpath = /var/log/apache2/error.log
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
EOF

    # Start and enable Fail2Ban
    systemctl enable fail2ban
    systemctl start fail2ban
    
    echo "[SUCCESS] Fail2Ban configured"
}

#===========================================
# UFW MANAGEMENT FUNCTIONS
#===========================================

allow_port() {
    local port="$1"
    local protocol="${2:-tcp}"
    
    if [[ -z "$port" ]]; then
        echo "[ERROR] Port parameter required"
        return 1
    fi
    
    echo "[INFO] Allowing port $port/$protocol"
    ufw allow "$port/$protocol"
    echo "[SUCCESS] Port $port/$protocol allowed"
}

deny_port() {
    local port="$1"
    local protocol="${2:-tcp}"
    
    if [[ -z "$port" ]]; then
        echo "[ERROR] Port parameter required"
        return 1
    fi
    
    echo "[INFO] Denying port $port/$protocol"
    ufw deny "$port/$protocol"
    echo "[SUCCESS] Port $port/$protocol denied"
}

allow_service() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        echo "[ERROR] Service parameter required"
        return 1
    fi
    
    echo "[INFO] Allowing service: $service"
    case "$service" in
        "web"|"http")
            ufw allow 80/tcp
            ufw allow 443/tcp
            echo "[SUCCESS] Web services (HTTP/HTTPS) allowed"
            ;;
        "mail"|"email")
            ufw allow 25/tcp   # SMTP
            ufw allow 587/tcp  # SMTP submission
            ufw allow 993/tcp  # IMAPS
            ufw allow 995/tcp  # POP3S
            echo "[SUCCESS] Mail services allowed"
            ;;
        "dns")
            ufw allow 53/tcp
            ufw allow 53/udp
            echo "[SUCCESS] DNS services allowed"
            ;;
        "mysql")
            ufw allow 3306/tcp
            echo "[SUCCESS] MySQL service allowed"
            ;;
        "postgresql")
            ufw allow 5432/tcp
            echo "[SUCCESS] PostgreSQL service allowed"
            ;;
        "ftp")
            ufw allow 21/tcp
            ufw allow 20/tcp
            echo "[SUCCESS] FTP services allowed"
            ;;
        *)
            echo "[ERROR] Unknown service: $service"
            echo "Supported services: web, mail, dns, mysql, postgresql, ftp"
            return 1
            ;;
    esac
}

deny_service() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        echo "[ERROR] Service parameter required"
        return 1
    fi
    
    echo "[INFO] Denying service: $service"
    case "$service" in
        "web"|"http")
            ufw deny 80/tcp
            ufw deny 443/tcp
            echo "[SUCCESS] Web services (HTTP/HTTPS) denied"
            ;;
        "mail"|"email")
            ufw deny 25/tcp
            ufw deny 587/tcp
            ufw deny 993/tcp
            ufw deny 995/tcp
            echo "[SUCCESS] Mail services denied"
            ;;
        "dns")
            ufw deny 53/tcp
            ufw deny 53/udp
            echo "[SUCCESS] DNS services denied"
            ;;
        "mysql")
            ufw deny 3306/tcp
            echo "[SUCCESS] MySQL service denied"
            ;;
        "postgresql")
            ufw deny 5432/tcp
            echo "[SUCCESS] PostgreSQL service denied"
            ;;
        "ftp")
            ufw deny 21/tcp
            ufw deny 20/tcp
            echo "[SUCCESS] FTP services denied"
            ;;
        *)
            echo "[ERROR] Unknown service: $service"
            return 1
            ;;
    esac
}

allow_ip() {
    local ip_address="$1"
    local port="$2"
    
    if [[ -z "$ip_address" ]]; then
        echo "[ERROR] IP address parameter required"
        return 1
    fi
    
    if [[ -n "$port" ]]; then
        echo "[INFO] Allowing IP $ip_address to port $port"
        ufw allow from "$ip_address" to any port "$port"
    else
        echo "[INFO] Allowing IP $ip_address (all ports)"
        ufw allow from "$ip_address"
    fi
    
    echo "[SUCCESS] IP $ip_address allowed"
}

deny_ip() {
    local ip_address="$1"
    
    if [[ -z "$ip_address" ]]; then
        echo "[ERROR] IP address parameter required"
        return 1
    fi
    
    echo "[INFO] Denying IP $ip_address"
    ufw deny from "$ip_address"
    echo "[SUCCESS] IP $ip_address denied"
}

delete_rule() {
    local rule_number="$1"
    
    if [[ -z "$rule_number" ]]; then
        echo "[ERROR] Rule number parameter required"
        echo "Use 'show_firewall_rules' to see rule numbers"
        return 1
    fi
    
    echo "[INFO] Deleting firewall rule #$rule_number"
    ufw --force delete "$rule_number"
    echo "[SUCCESS] Rule deleted"
}

#===========================================
# FAIL2BAN MANAGEMENT FUNCTIONS
#===========================================

ban_ip() {
    local ip_address="$1"
    local jail="${2:-sshd}"
    
    if [[ -z "$ip_address" ]]; then
        echo "[ERROR] IP address parameter required"
        return 1
    fi
    
    echo "[INFO] Banning IP $ip_address in jail $jail"
    fail2ban-client set "$jail" banip "$ip_address"
    echo "[SUCCESS] IP $ip_address banned"
}

unban_ip() {
    local ip_address="$1"
    local jail="${2:-sshd}"
    
    if [[ -z "$ip_address" ]]; then
        echo "[ERROR] IP address parameter required"
        return 1
    fi
    
    echo "[INFO] Unbanning IP $ip_address from jail $jail"
    fail2ban-client set "$jail" unbanip "$ip_address"
    echo "[SUCCESS] IP $ip_address unbanned"
}

list_banned_ips() {
    echo "[INFO] Currently banned IPs:"
    fail2ban-client status | grep "Jail list:" | sed 's/.*Jail list://' | tr ',' '\n' | while read jail; do
        jail=$(echo "$jail" | tr -d ' ')
        if [[ -n "$jail" ]]; then
            echo "=== Jail: $jail ==="
            fail2ban-client status "$jail" | grep "Banned IP list:" | sed 's/.*Banned IP list://'
        fi
    done
}

configure_fail2ban_jail() {
    local service="$1"
    local max_retry="${2:-3}"
    local ban_time="${3:-3600}"
    
    if [[ -z "$service" ]]; then
        echo "[ERROR] Service parameter required"
        return 1
    fi
    
    echo "[INFO] Configuring Fail2Ban jail for: $service"
    
    case "$service" in
        "apache")
            cat >> /etc/fail2ban/jail.local << EOF

[apache-overflows]
enabled = true
port = http,https
filter = apache-overflows
logpath = /var/log/apache2/error.log
maxretry = $max_retry
bantime = $ban_time
EOF
            ;;
        "nginx")
            cat >> /etc/fail2ban/jail.local << EOF

[nginx-limit-req]
enabled = true
port = http,https
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = $max_retry
bantime = $ban_time
EOF
            ;;
        "postfix")
            cat >> /etc/fail2ban/jail.local << EOF

[postfix]
enabled = true
port = smtp,465,submission
filter = postfix
logpath = /var/log/mail.log
maxretry = $max_retry
bantime = $ban_time
EOF
            ;;
        *)
            echo "[ERROR] Unknown service: $service"
            return 1
            ;;
    esac
    
    restart_fail2ban
    echo "[SUCCESS] Fail2Ban jail configured for $service"
}

#===========================================
# MONITORING FUNCTIONS
#===========================================

show_firewall_status() {
    echo "[INFO] UFW firewall status:"
    ufw status numbered
    echo ""
    echo "[INFO] Fail2Ban status:"
    fail2ban-client status
}

show_firewall_rules() {
    echo "[INFO] UFW firewall rules:"
    ufw status numbered
}

show_fail2ban_status() {
    echo "[INFO] Fail2Ban jail status:"
    fail2ban-client status
    echo ""
    
    # Show details for each jail
    fail2ban-client status | grep "Jail list:" | sed 's/.*Jail list://' | tr ',' '\n' | while read jail; do
        jail=$(echo "$jail" | tr -d ' ')
        if [[ -n "$jail" ]]; then
            echo "=== Jail: $jail ==="
            fail2ban-client status "$jail"
            echo ""
        fi
    done
}

view_firewall_logs() {
    echo "[INFO] Recent UFW logs:"
    grep "UFW" /var/log/syslog | tail -20
    echo ""
    echo "[INFO] Recent Fail2Ban logs:"
    grep "fail2ban" /var/log/auth.log | tail -20
}

scan_open_ports() {
    echo "[INFO] Scanning open ports..."
    echo "=== Local listening ports ==="
    netstat -tlnp | grep LISTEN
    echo ""
    echo "=== External port scan (common ports) ==="
    nmap -sT localhost 2>/dev/null | grep -E "^[0-9]"
}

#===========================================
# SECURITY HARDENING FUNCTIONS
#===========================================

harden_ssh() {
    echo "[INFO] Hardening SSH configuration..."
    
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Apply security hardening
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/#Protocol 2/Protocol 2/' /etc/ssh/sshd_config
    
    # Add additional security options
    echo "" >> /etc/ssh/sshd_config
    echo "# Additional security hardening" >> /etc/ssh/sshd_config
    echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
    echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
    echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config
    echo "X11Forwarding no" >> /etc/ssh/sshd_config
    
    # Restart SSH service
    systemctl restart sshd
    echo "[SUCCESS] SSH hardened"
}

disable_unused_services() {
    echo "[INFO] Disabling unused services..."
    
    # List of commonly unused services
    local services=("avahi-daemon" "cups" "bluetooth" "apache2" "nginx")
    
    for service in "${services[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            echo "[INFO] Disabling $service"
            systemctl disable "$service"
            systemctl stop "$service"
        fi
    done
    
    echo "[SUCCESS] Unused services disabled"
}

configure_automatic_updates() {
    echo "[INFO] Configuring automatic security updates..."
    
    apt install -y unattended-upgrades
    
    # Configure unattended upgrades
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

    # Enable automatic updates
    echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/20auto-upgrades
    echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/20auto-upgrades
    
    systemctl enable unattended-upgrades
    systemctl start unattended-upgrades
    
    echo "[SUCCESS] Automatic security updates configured"
}

#===========================================
# SERVICE MANAGEMENT FUNCTIONS
#===========================================

restart_firewall() {
    echo "[INFO] Restarting firewall services..."
    systemctl restart ufw
    restart_fail2ban
    echo "[SUCCESS] Firewall services restarted"
}

restart_fail2ban() {
    echo "[INFO] Restarting Fail2Ban..."
    systemctl restart fail2ban
    if systemctl is-active --quiet fail2ban; then
        echo "[SUCCESS] Fail2Ban restarted successfully"
    else
        echo "[ERROR] Fail2Ban failed to restart"
        return 1
    fi
}

enable_firewall() {
    echo "[INFO] Enabling UFW firewall..."
    ufw --force enable
    echo "[SUCCESS] UFW firewall enabled"
}

disable_firewall() {
    echo "[WARNING] Disabling UFW firewall..."
    read -p "Are you sure? This will disable firewall protection! (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        ufw disable
        echo "[WARNING] UFW firewall disabled"
    else
        echo "[INFO] Operation cancelled"
    fi
}

#===========================================
# UPDATE FUNCTIONS
#===========================================

update_firewall() {
    echo "[INFO] Updating firewall components..."
    apt update -y
    apt upgrade -y ufw fail2ban iptables-persistent
    
    restart_firewall
    echo "[SUCCESS] Firewall components updated"
}
