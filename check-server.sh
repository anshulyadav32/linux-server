#!/bin/bash
# =============================================================================
# Linux Setup - Server Health Check Aggregator
# =============================================================================
# Author: Anshul Yadav
# Description: Sequentially run health checks for all major modules
# =============================================================================

status=0

echo "==============================="
echo " SERVER HEALTH CHECK SUMMARY "
echo "==============================="

# Webserver
echo "\n--- Checking webserver module ---"
if [ -x ./modules/webserver/check_webserver.sh ]; then
	./modules/webserver/check_webserver.sh
	rc=$?
	if [ $rc -eq 0 ]; then
		echo "[OK] webserver module healthy"
	else
		echo "[WARN] webserver module has issues (exit code $rc)"
		status=1
	fi
else
	echo "[ERROR] Check script not found or not executable: ./modules/webserver/check_webserver.sh"
	status=1
fi

# Database
echo "\n--- Checking database module ---"
if [ -x ./modules/database/check_database.sh ]; then
	./modules/database/check_database.sh
	rc=$?
	if [ $rc -eq 0 ]; then
		echo "[OK] database module healthy"
	else
		echo "[WARN] database module has issues (exit code $rc)"
		status=1
	fi
else
	echo "[ERROR] Check script not found or not executable: ./modules/database/check_database.sh"
	status=1
fi

# DNS
echo "\n--- Checking dns module ---"
if [ -x ./modules/dns/check_dns.sh ]; then
	./modules/dns/check_dns.sh
	rc=$?
	if [ $rc -eq 0 ]; then
		echo "[OK] dns module healthy"
	else
		echo "[WARN] dns module has issues (exit code $rc)"
		status=1
	fi
else
	echo "[ERROR] Check script not found or not executable: ./modules/dns/check_dns.sh"
	status=1
fi

# Firewall
echo "\n--- Checking firewall module ---"
if [ -x ./modules/firewall/check_firewall.sh ]; then
	./modules/firewall/check_firewall.sh
	rc=$?
	if [ $rc -eq 0 ]; then
		echo "[OK] firewall module healthy"
	else
		echo "[WARN] firewall module has issues (exit code $rc)"
		status=1
	fi
else
	echo "[ERROR] Check script not found or not executable: ./modules/firewall/check_firewall.sh"
	status=1
fi

# SSL
echo "\n--- Checking ssl module ---"
if [ -x ./modules/ssl/check_ssl.sh ]; then
	./modules/ssl/check_ssl.sh
	rc=$?
	if [ $rc -eq 0 ]; then
		echo "[OK] ssl module healthy"
	else
		echo "[WARN] ssl module has issues (exit code $rc)"
		status=1
	fi
else
	echo "[ERROR] Check script not found or not executable: ./modules/ssl/check_ssl.sh"
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
