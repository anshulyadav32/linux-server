echo "[INFO] Starting full server setup via setup.sh..."
#!/usr/bin/env bash
# Unified server installer: modular install logic moved from setup.sh

set -euo pipefail

log() { echo -e "[SETUP] $*"; }

main() {
	log "Running webserver install..."
	if bash modules/webserver/install.sh; then
		log "Webserver install completed."
	else
		log "[ERROR] Webserver install failed."
		echo "[ERROR] Check modules/webserver/install.sh for details."
		echo "[HINT] Fix the error above and rerun install-server.sh."
		exit 1
	fi

	log "Running DNS install..."
	if bash modules/dns/install.sh; then
		log "DNS install completed."
	else
		log "[ERROR] DNS install failed."
		echo "[ERROR] Check modules/dns/install.sh for details."
		echo "[HINT] If DNS resolution fails in WSL, manually start BIND: sudo named -c /etc/bind/named.conf"
		echo "[HINT] Fix the error above and rerun install-server.sh."
		exit 1
	fi

	log "Running database install..."
	if bash modules/database/install.sh; then
		log "Database install completed."
	else
		log "[ERROR] Database install failed."
		echo "[ERROR] Check modules/database/install.sh for details."
		echo "[HINT] Fix the error above and rerun install-server.sh."
		exit 1
	fi

	log "Running SSL install..."
	if bash modules/ssl/install.sh; then
		log "SSL install completed."
	else
		log "[ERROR] SSL install failed."
		echo "[ERROR] Check modules/ssl/install.sh for details."
		echo "[HINT] Fix the error above and rerun install-server.sh."
		exit 1
	fi

	log "Running final health check (check-server.sh)..."
	if bash check-server.sh; then
		log "All modules passed health checks."
	else
		log "[WARN] Some modules reported issues. See above for details."
	fi
}

main "$@"
