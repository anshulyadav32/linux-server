#!/usr/bin/env bash
# Webserver Check Script
set -Eeuo pipefail

log() { echo -e "[CHECK] $*"; }

main() {
  log "Checking Apache2..."
  service apache2 status >/dev/null 2>&1 && log "Apache2 running" || log "Apache2 not running"
  log "Checking Nginx..."
  service nginx status >/dev/null 2>&1 && log "Nginx running" || log "Nginx not running"
  log "Checking PHP-FPM..."
  service php8.3-fpm status >/dev/null 2>&1 && log "PHP-FPM running" || log "PHP-FPM not running"
}

main "$@"
