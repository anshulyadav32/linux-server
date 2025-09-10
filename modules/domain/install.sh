#!/usr/bin/env bash
# =============================================================================
# Linux Setup - Domain Management Module Installer
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

# ---------- Installation ----------
install_domain_tools() {
  log_info "Installing domain management tools..."
  
  # Create domain management directories
  mkdir -p /etc/domain-manager/{zones,templates,logs}
  mkdir -p /var/lib/domain-manager/{configs,backups}
  
  # Install required packages
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y dig whois curl jq
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y bind-utils whois curl jq
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Sy --noconfirm bind-tools whois curl jq
  fi
  
  log_success "Domain management tools installed"
}

create_templates() {
  log_info "Creating domain templates..."
  
  # A Record template
  cat > /etc/domain-manager/templates/a-record.template <<'EOF'
$TTL 86400
@       IN      SOA     ns1.DOMAIN.     admin.DOMAIN. (
                        $(date +%Y%m%d%H)  ; Serial
                        3600               ; Refresh
                        1800               ; Retry
                        604800             ; Expire
                        86400 )            ; Negative Cache TTL

@       IN      NS      ns1.DOMAIN.
@       IN      A       SERVER_IP
ns1     IN      A       SERVER_IP
www     IN      A       SERVER_IP
EOF

  # CNAME template
  cat > /etc/domain-manager/templates/cname-record.template <<'EOF'
SUBDOMAIN    IN    CNAME    TARGET.
EOF

  # MX Record template
  cat > /etc/domain-manager/templates/mx-record.template <<'EOF'
@       IN      MX      10      mail.DOMAIN.
mail    IN      A       SERVER_IP
EOF

  # Create domain configuration template
  cat > /etc/domain-manager/templates/domain-config.template <<'EOF'
# Domain Configuration File
DOMAIN_NAME=DOMAIN
ZONE_FILE=/etc/bind/zones/db.DOMAIN
CONFIG_FILE=/etc/bind/sites-available/DOMAIN.conf
SSL_CERT=/etc/ssl/certs/DOMAIN.crt
SSL_KEY=/etc/ssl/private/DOMAIN.key
DOCUMENT_ROOT=/var/www/DOMAIN
ENABLED=true
CREATED_DATE=$(date)
LAST_MODIFIED=$(date)
EOF

  log_success "Domain templates created"
}

create_domain_scripts() {
  log_info "Creating domain management scripts..."
  
  # Create the main domain management script
  cat > /usr/local/bin/domain-manager <<'EOF'
#!/bin/bash
# Domain Manager CLI Tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="/home/runner/work/linux-server/linux-server/modules"

if [[ -f "$MODULES_DIR/domain/manage.sh" ]]; then
    exec bash "$MODULES_DIR/domain/manage.sh" "$@"
else
    echo "Error: Domain management script not found"
    exit 1
fi
EOF

  chmod +x /usr/local/bin/domain-manager
  
  log_success "Domain management scripts created"
}

setup_domain_config() {
  log_info "Setting up domain management configuration..."
  
  # Create main config file
  cat > /etc/domain-manager/config <<'EOF'
# Domain Manager Configuration

# Default settings
DEFAULT_TTL=86400
DEFAULT_NS=ns1
DEFAULT_ADMIN_EMAIL=admin@localhost
DEFAULT_WEBROOT=/var/www

# DNS Settings
DNS_SERVICE=bind9
ZONE_DIR=/etc/bind/zones
NAMED_CONF=/etc/bind/named.conf.local

# Web Server Settings
WEB_SERVICE=apache2
SITES_DIR=/etc/apache2/sites-available
NGINX_SITES_DIR=/etc/nginx/sites-available

# SSL Settings
SSL_CERT_DIR=/etc/ssl/certs
SSL_KEY_DIR=/etc/ssl/private

# Logging
LOG_LEVEL=INFO
LOG_FILE=/var/log/domain-manager.log
EOF

  # Set proper permissions
  chown -R root:root /etc/domain-manager
  chmod -R 755 /etc/domain-manager
  chmod 644 /etc/domain-manager/config
  chmod 644 /etc/domain-manager/templates/*
  
  log_success "Domain management configuration setup complete"
}

verify_installation() {
  log_info "Verifying domain management installation..."
  
  # Check directories
  if [[ -d /etc/domain-manager ]]; then
    log_success "Domain manager directories created"
  else
    log_error "Domain manager directories missing"
    return 1
  fi
  
  # Check templates
  if [[ -f /etc/domain-manager/templates/a-record.template ]]; then
    log_success "Domain templates created"
  else
    log_error "Domain templates missing"
    return 1
  fi
  
  # Check CLI tool
  if [[ -x /usr/local/bin/domain-manager ]]; then
    log_success "Domain manager CLI tool installed"
  else
    log_error "Domain manager CLI tool missing"
    return 1
  fi
  
  log_success "Domain management installation verified"
}

# ---------- Main Installation ----------
main() {
  log_info "Starting domain management module installation..."
  check_root
  
  install_domain_tools
  create_templates
  create_domain_scripts
  setup_domain_config
  verify_installation
  
  log_success "Domain management module installation complete!"
  log_info "Use 'domain-manager' command to access domain management features"
}

main "$@"