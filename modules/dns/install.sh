#!/usr/bin/env bash
# =============================================================================
# Linux Setup - DNS Module Installer (Standalone)
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

# ---------- OS Detection ----------
detect_os() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID,,}" in
      ubuntu|debian) echo "debian" ;;
      centos|rhel|rocky|almalinux) echo "rhel" ;;
      arch) echo "arch" ;;
      *) echo "unknown" ;;
    esac
  else
    echo "unknown"
  fi
}

# ---------- Installation ----------
install_packages() {
  local os
  os=$(detect_os)
  
  case "$os" in
    debian)
      apt-get update -qq
      DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils dnsutils resolvconf
      ;;
    rhel)
      dnf install -y bind bind-utils
      ;;
    arch)
      pacman -Sy --noconfirm bind bind-tools
      ;;
    *)
      log_error "Unsupported OS: $os"
      exit 1
      ;;
  esac
}

configure_bind() {
  local os
  os=$(detect_os)

  # Create needed directories
  mkdir -p /etc/bind/zones

  # Configure main BIND options
  cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-recursion { localnets; localhost; };
    listen-on { any; };
    listen-on-v6 { any; };
    
    dnssec-validation auto;
    auth-nxdomain no;
    
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
};
EOF

  # Configure local zones
  cat > /etc/bind/named.conf.local <<'EOF'
// Add your zones here
// Example:
// zone "example.com" {
//     type master;
//     file "/etc/bind/zones/db.example.com";
// };
EOF

  # Create a sample zone file template
  cat > /etc/bind/zones/zone.template <<'EOF'
$TTL    86400
@       IN      SOA     ns1.domain.tld. admin.domain.tld. (
                        2025090801  ; Serial
                        3600        ; Refresh
                        1800        ; Retry
                        604800      ; Expire
                        86400 )     ; Negative Cache TTL

@       IN      NS      ns1.domain.tld.
@       IN      A       127.0.0.1
ns1     IN      A       127.0.0.1
www     IN      A       127.0.0.1
EOF

  # Set proper permissions
  chown -R bind:bind /etc/bind /var/cache/bind
  chmod -R 755 /etc/bind
  chmod -R 644 /etc/bind/*
}

start_services() {
  local os
  os=$(detect_os)

  if [[ "$os" == "debian" ]]; then
    systemctl restart named bind9
    systemctl enable named bind9
  else
    systemctl restart named
    systemctl enable named
  fi
}

verify() {
  local os
  os=$(detect_os)
  
  # Wait for service to fully start
  sleep 3
  
  # Check if service is running
  if [[ "$os" == "debian" ]]; then
    systemctl is-active --quiet bind9 && log_success "bind9 is running" || log_error "bind9 failed"
  else
    systemctl is-active --quiet named && log_success "named is running" || log_error "named failed"
  fi
  
  # Test DNS resolution
  if command -v dig >/dev/null; then
    dig @localhost google.com +short >/dev/null && log_success "DNS resolution working" || log_error "DNS resolution failed"
  fi
  
  # Check listening ports
  ss -tulpn | grep -q ':53' && log_success "Port 53 is listening" || log_error "Port 53 not listening"
}

# ---------- Main Installation ----------
main() {
  log_info "Starting DNS server installation..."
  check_root

  log_info "Installing packages..."
  install_packages

  log_info "Configuring BIND..."
  configure_bind

  log_info "Starting services..."
  start_services

  log_info "Verifying installation..."
  verify

  log_success "DNS server installation complete!"
}

main "$@"
