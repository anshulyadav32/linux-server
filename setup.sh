#!/usr/bin/env bash
# Setup Script: Calls webserver install and check

# Ensure running in bash
if [ -z "$BASH_VERSION" ]; then
  echo "[ERROR] This script must be run with bash."
  exit 1
fi

set -euo pipefail

log() { echo -e "[SETUP] $*"; }

main() {
  log "Running webserver install..."
  if bash modules/webserver/install.sh; then
    log "Webserver install completed."
  else
    log "[ERROR] Webserver install failed."
    echo "[ERROR] Check modules/webserver/install.sh for details."
    echo "[HINT] Fix the error above and rerun setup.sh."
    exit 1
  fi

  log "Running DNS install..."
  if bash modules/dns/install.sh; then
    log "DNS install completed."
  else
    log "[ERROR] DNS install failed."
    echo "[ERROR] Check modules/dns/install.sh for details."
    echo "[HINT] If DNS resolution fails in WSL, manually start BIND: sudo named -c /etc/bind/named.conf"
    echo "[HINT] Fix the error above and rerun setup.sh."
    exit 1
  fi

  log "Running database install..."
  if bash modules/database/install.sh; then
    log "Database install completed."
  else
    log "[ERROR] Database install failed."
    echo "[ERROR] Check modules/database/install.sh for details."
    echo "[HINT] Fix the error above and rerun setup.sh."
    exit 1
  fi

    log "Running SSL install..."
    if bash modules/ssl/install.sh; then
      log "SSL install completed."
    else
      log "[ERROR] SSL install failed."
      echo "[ERROR] Check modules/ssl/install.sh for details."
      echo "[HINT] Fix the error above and rerun setup.sh."
      exit 1
    fi
}

main "$@"
