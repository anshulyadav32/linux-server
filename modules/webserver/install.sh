#!/usr/bin/env bash
# =============================================================================
# Linux Setup - Webserver Module Installer (Standalone)
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

# Get PHP-FPM service name
get_php_fpm_service() {
  for svc in php8.3-fpm php8.2-fpm php8.1-fpm php8.0-fpm php7.4-fpm php-fpm; do
    if systemctl is-active "$svc" >/dev/null 2>&1 || systemctl list-unit-files "$svc.service" >/dev/null 2>&1; then
      echo "$svc"
      return 0
    fi
  done
  echo "php8.3-fpm"  # Default to 8.3 if none found
}

# ---------- Installation ----------
install_packages() {
  local os
  os=$(detect_os)
  
  case "$os" in
    debian)
      apt-get update -qq
      DEBIAN_FRONTEND=noninteractive apt-get install -y \
        apache2 apache2-utils nginx \
        php php-fpm libapache2-mod-php \
        php-mysql php-gd php-curl php-mbstring php-xml php-zip
      ;;
    rhel)
      dnf install -y epel-release
      dnf install -y httpd nginx php php-fpm php-mysqlnd php-gd
      ;;
    arch)
      pacman -Sy --noconfirm apache nginx php php-fpm
      ;;
    *)
      log_error "Unsupported OS: $os"
      exit 1
      ;;
  esac
}

stop_services() {
  service apache2 stop || true
  service nginx stop || true
  service php8.3-fpm stop || true
}

configure_apache() {
  local os
  os=$(detect_os)

  if [[ "$os" == "debian" ]]; then
    # Update Apache ports
    cat > /etc/apache2/ports.conf <<'EOF'
Listen 8080

<IfModule ssl_module>
    Listen 8443
</IfModule>

<IfModule mod_gnutls.c>
    Listen 8443
</IfModule>
EOF

    # Update default site
    sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8080>/' /etc/apache2/sites-available/000-default.conf
    
    # Enable modules
    a2enmod rewrite proxy proxy_http headers ssl
    
    # Enable PHP-FPM
    a2enmod proxy_fcgi setenvif
    a2enconf php8.3-fpm
  else
    sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
  fi
}

configure_nginx() {
  # Stop nginx before configuration
  service nginx stop || true

  # Remove default config
  rm -f /etc/nginx/sites-enabled/default

  # Configure Nginx as reverse proxy
  cat > /etc/nginx/conf.d/default.conf <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    access_log /var/log/nginx/reverse-access.log;
    error_log /var/log/nginx/reverse-error.log;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

  # Verify configuration
  nginx -t
}

configure_php() {
  local os php_fpm
  os=$(detect_os)
  php_fpm=$(get_php_fpm_service)

  # Basic PHP settings
  if [[ "$os" == "debian" ]]; then
    local php_version
    php_version=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    local ini="/etc/php/${php_version}/fpm/php.ini"
  else
    local ini="/etc/php.ini"
  fi

  if [[ -f "$ini" ]]; then
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' "$ini"
    sed -i 's/post_max_size = .*/post_max_size = 64M/' "$ini"
    sed -i 's/memory_limit = .*/memory_limit = 256M/' "$ini"
  fi
}

start_services() {
  local os php_fpm
  os=$(detect_os)
  php_fpm=$(get_php_fpm_service)

  if [[ "$os" == "debian" ]]; then
    # Start PHP-FPM first
    systemctl restart "$php_fpm"
    sleep 2
    
    # Then Apache
    systemctl restart apache2
    sleep 2
    
    # Finally Nginx
    systemctl restart nginx
    
    # Enable services
    systemctl enable apache2 nginx "$php_fpm"
  else
    systemctl restart php-fpm
    sleep 2
    systemctl restart httpd
    sleep 2
    systemctl restart nginx
    
    systemctl enable httpd nginx php-fpm
  fi
}

verify() {
  local os svc php_fpm
  os=$(detect_os)
  php_fpm=$(get_php_fpm_service)
  
  # Wait for services to fully start
  sleep 3
  
  # Check Apache
  svc=$(if [[ "$os" == "debian" ]]; then echo "apache2"; else echo "httpd"; fi)
  systemctl is-active --quiet "$svc" && log_success "$svc is running" || log_error "$svc failed"
  
  # Check Nginx
  systemctl is-active --quiet nginx && log_success "nginx is running" || log_error "nginx failed"
  
  # Check PHP-FPM
  systemctl is-active --quiet "$php_fpm" && log_success "$php_fpm is running" || log_error "php-fpm failed"
  
  # Test ports
  if command -v curl >/dev/null; then
    sleep 2
    curl -s -f http://localhost:80 >/dev/null && log_success "Port 80 (Nginx) responding" || log_error "Port 80 failed"
    curl -s -f http://localhost:8080 >/dev/null && log_success "Port 8080 (Apache) responding" || log_error "Port 8080 failed"
  fi
}

# ---------- Main Installation ----------
main() {
  log_info "Starting webserver installation..."
  check_root

  log_info "Stopping any running services..."
  # Use service commands for WSL compatibility
  service apache2 stop || true
  service nginx stop || true
  service php8.3-fpm stop || true

  # --- Apache ---
  log_info "Installing Apache..."
  install_packages
  log_info "Configuring Apache..."
  configure_apache
  log_info "Starting Apache..."
  service apache2 start
  sleep 2
  service apache2 status >/dev/null 2>&1 && log_success "Apache is running" || { log_error "Apache failed"; exit 1; }

  # --- Nginx ---
  log_info "Installing Nginx..."
  # Nginx is installed with install_packages
  log_info "Configuring Nginx..."
  configure_nginx
  log_info "Starting Nginx..."
  service nginx start
  sleep 2
  service nginx status >/dev/null 2>&1 && log_success "Nginx is running" || { log_error "Nginx failed"; exit 1; }

  # --- PHP ---
  log_info "Installing PHP..."
  # PHP is installed with install_packages
  log_info "Configuring PHP..."
  configure_php
  log_info "Starting PHP-FPM..."
  service php8.3-fpm start
  sleep 2
  service php8.3-fpm status >/dev/null 2>&1 && log_success "php8.3-fpm is running" || { log_error "PHP-FPM failed"; exit 1; }

  # --- Final Verification ---
  log_info "Verifying webserver stack..."
  sleep 2
  local all_ok=1
  if command -v curl >/dev/null; then
    curl -s -f http://localhost:80 >/dev/null && log_success "Port 80 (Nginx) responding" || { log_error "Port 80 failed"; all_ok=0; }
    curl -s -f http://localhost:8080 >/dev/null && log_success "Port 8080 (Apache) responding" || { log_error "Port 8080 failed"; all_ok=0; }
  fi

  # --- Summary Check ---
  log_info "Summary of component status:"
  service apache2 status >/dev/null 2>&1 && log_success "Apache2: running" || log_error "Apache2: not running"
  service nginx status >/dev/null 2>&1 && log_success "Nginx: running" || log_error "Nginx: not running"
  service php8.3-fpm status >/dev/null 2>&1 && log_success "PHP-FPM: running" || log_error "PHP-FPM: not running"
  if [[ $all_ok -eq 1 ]]; then
    log_success "All components are installed and responding."
  else
    log_warning "Some components failed port checks."
  fi
}

main "$@"
