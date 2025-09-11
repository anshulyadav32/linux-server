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

install_bind_packages() {
  local os
  os=$(detect_os)
  log_info "Installing BIND packages..."
  case "$os" in
    debian)
      apt-get update -qq
      DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils dnsutils resolvconf || { log_error "Failed to install BIND packages"; exit 1; }
      ;;
    rhel)
      dnf install -y bind bind-utils || { log_error "Failed to install BIND packages"; exit 1; }
      ;;
    arch)
      pacman -Sy --noconfirm bind bind-tools || { log_error "Failed to install BIND packages"; exit 1; }
      ;;
    *)
      log_error "Unsupported OS: $os"; exit 1;
      ;;
  esac
  log_success "BIND packages installed."
}

test_bind_packages() {
  if command -v named >/dev/null && command -v dig >/dev/null; then
    log_success "BIND and dig commands available."
    return 0
  else
    log_error "BIND or dig not found after install."
    return 1
  fi
}

configure_bind() {
  log_info "Configuring BIND..."
  mkdir -p /etc/bind/zones
  # ...existing code...
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
  # ...existing code...
  cat > /etc/bind/named.conf.local <<'EOF'
// Add your zones here
// Example:
// zone "example.com" {
//     type master;
//     file "/etc/bind/zones/db.example.com";
// };
EOF
  # ...existing code...
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
  chown -R bind:bind /etc/bind /var/cache/bind
  chmod -R 755 /etc/bind
  chmod -R 644 /etc/bind/*
  log_success "BIND configuration complete."
}

test_bind_config() {
  if named-checkconf >/dev/null 2>&1; then
    log_success "BIND configuration is valid."
    return 0
  else
    log_error "BIND configuration is invalid."
    return 1
  fi
}


# WSL-compatible: skip service start/enable, print message
start_bind_service() {
  log_warning "Skipping BIND service start (not supported in WSL)."
}


# WSL-compatible: skip service status check, print message
test_bind_service() {
  log_warning "Skipping BIND service status check (not supported in WSL)."
  return 0
}

test_dns_resolution() {
  if command -v dig >/dev/null; then
    dig @localhost google.com +short >/dev/null && log_success "DNS resolution working" || { log_error "DNS resolution failed"; return 1; }
  else
    log_error "dig command not found for DNS resolution test."; return 1;
  fi
  return 0
}

test_bind_port() {
  ss -tulpn | grep -q ':53' && log_success "Port 53 is listening" || { log_error "Port 53 not listening"; return 1; }
  return 0
}

main() {
  log_info "Starting DNS server installation..."
  check_root

  local error_count=0

  install_bind_packages || { log_error "BIND package install failed."; error_count=$((error_count+1)); }
  test_bind_packages || { log_error "BIND package test failed."; error_count=$((error_count+1)); }

  configure_bind || { log_error "BIND configuration failed."; error_count=$((error_count+1)); }
  test_bind_config || { log_error "BIND config test failed."; error_count=$((error_count+1)); }

  start_bind_service || { log_error "BIND service start skipped or failed."; error_count=$((error_count+1)); }
  test_bind_service || { log_error "BIND service status skipped or failed."; error_count=$((error_count+1)); }

  test_dns_resolution || { log_error "DNS resolution test failed. If in WSL, manually start BIND: sudo named -c /etc/bind/named.conf"; error_count=$((error_count+1)); }
  test_bind_port || { log_error "BIND port test failed."; error_count=$((error_count+1)); }

  if [ "$error_count" -eq 0 ]; then
    log_success "DNS server installation complete!"
  else
    log_warning "DNS server installation completed with $error_count error(s). See above for details."
  fi
}

main "$@"
