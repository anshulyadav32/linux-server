#!/usr/bin/env bash
# Setup Script: Calls webserver install and check
set -Eeuo pipefail

log() { echo -e "[SETUP] $*"; }

main() {
  log "Running webserver install..."
  bash modules/webserver/install.sh
  log "Running webserver check..."
  bash modules/webserver/check.sh
}

main "$@"
