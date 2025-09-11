#!/bin/bash
# =============================================================================
# Linux Setup - Server Health update Aggregator
# =============================================================================
# Author: Anshul Yadav
# Description: Sequentially run health updates for all major modules
# =============================================================================

status=0

echo "==============================="
echo " SERVER HEALTH UPDATE SUMMARY "
echo "==============================="

# Webserver
echo "\n--- updating webserver module ---"
if [ -x ./modules/webserver/update_webserver.sh ]; then
	./modules/webserver/update_webserver.sh
	rc=$?
	if [ $rc -eq 0 ]; then
		echo "[OK] webserver module healthy"
	else
		echo "[WARN] webserver module has issues (exit code $rc)"
		status=1
	fi
else
	echo "[ERROR] update script not found or not executable: ./modules/webserver/update_webserver.sh"
	status=1
fi

 # Database
echo "\n--- updating database module ---"
if [ -x ./modules/database/update_database.sh ]; then
	./modules/database/update_database.sh
	rc=$?
	if [ $rc -eq 0 ]; then
		echo "[OK] database module healthy"
	else
		echo "[WARN] database module has issues (exit code $rc)"
		status=1
	fi
else
	echo "[ERROR] update script not found or not executable: ./modules/database/update_database.sh"
	status=1
fi

# DNS
echo "\n--- updating dns module ---"
if [ -x ./modules/dns/update_dns.sh ]; then
	./modules/dns/update_dns.sh
	rc=$?
	if [ $rc -eq 0 ]; then
		echo "[OK] dns module healthy"
	else
		echo "[WARN] dns module has issues (exit code $rc)"
		status=1
	fi
else
	echo "[ERROR] update script not found or not executable: ./modules/dns/update_dns.sh"
	status=1
fi

# Firewall
echo "\n--- updating firewall module ---"
if [ -x ./modules/firewall/update_firewall.sh ]; then
	./modules/firewall/update_firewall.sh
	rc=$?
	if [ $rc -eq 0 ]; then
		echo "[OK] firewall module healthy"
	else
		echo "[WARN] firewall module has issues (exit code $rc)"
		status=1
	fi
else
	echo "[ERROR] update script not found or not executable: ./modules/firewall/update_firewall.sh"
	status=1
fi

# SSL
echo "\n--- updating ssl module ---"
if [ -x ./modules/ssl/update_ssl.sh ]; then
	./modules/ssl/update_ssl.sh
	rc=$?
	if [ $rc -eq 0 ]; then
		echo "[OK] ssl module healthy"
	else
		echo "[WARN] ssl module has issues (exit code $rc)"
		status=1
	fi
else
	echo "[ERROR] update script not found or not executable: ./modules/ssl/update_ssl.sh"
	status=1
fi

echo "\n==============================="
if [ $status -eq 0 ]; then
    echo "All modules healthy."
    exit 0
else
    echo "Some modules reported issues. See above for details."
    exit 1
fi
