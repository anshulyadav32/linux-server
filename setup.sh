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
  log "Calling install-server.sh for full modular install..."
  if bash install-server.sh; then
    log "Server setup completed successfully."
  else
    log "[ERROR] Server setup failed. See above for details."
    exit 1
  fi
}

main "$@"
