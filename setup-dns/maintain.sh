#!/bin/bash
# DNS Server Maintenance Script

while true; do
    clear
    echo "======================================"
    echo "      DNS Server Maintenance"
    echo "======================================"
    echo "1) Restart BIND9"
    echo "2) Reload DNS Configuration"
    echo "3) View DNS Logs"
    echo "4) Check DNS Status"
    echo "5) Test DNS Configuration"
    echo "6) Clear DNS Cache"
    echo "7) Back"
    echo "======================================"
    read -p "Choose an option [1-7]: " choice

    case $choice in
        1) 
            echo "Restarting BIND9..."
            systemctl restart bind9
            if systemctl is-active --quiet bind9; then
                echo "✅ BIND9 restarted successfully!"
            else
                echo "❌ BIND9 failed to restart!"
                systemctl status bind9 --no-pager
            fi
            sleep 3
            ;;
        2) 
            echo "Reloading DNS configuration..."
            if named-checkconf; then
                systemctl reload bind9
                echo "✅ DNS configuration reloaded successfully!"
            else
                echo "❌ Configuration has errors!"
                named-checkconf
            fi
            sleep 3
            ;;
        3) 
            echo "======================================"
            echo "           DNS Server Logs"
            echo "======================================"
            echo "BIND9 System Log (last 20 lines):"
            journalctl -u bind9 -n 20 --no-pager
            echo ""
            echo "Query Log (if enabled):"
            if [[ -f /var/log/named/query.log ]]; then
                tail -n 10 /var/log/named/query.log
            else
                echo "Query logging not enabled"
            fi
            read -p "Press Enter to continue..."
            ;;
        4) 
            echo "======================================"
            echo "         DNS Server Status"
            echo "======================================"
            echo "BIND9 Service Status:"
            systemctl status bind9 --no-pager | head -10
            echo ""
            echo "Listening Ports:"
            netstat -tlnp | grep :53
            echo ""
            echo "Process Information:"
            ps aux | grep named | grep -v grep
            echo "======================================"
            read -p "Press Enter to continue..."
            ;;
        5) 
            echo "Testing DNS server configuration..."
            echo ""
            echo "Configuration Syntax Check:"
            named-checkconf
            echo ""
            echo "Zone File Checks:"
            for zone_file in /etc/bind/zones/db.*; do
                if [[ -f "$zone_file" ]]; then
                    domain=$(basename "$zone_file" | sed 's/^db\.//')
                    echo "Checking zone: $domain"
                    named-checkzone "$domain" "$zone_file"
                fi
            done
            echo ""
            echo "DNS Resolution Test:"
            dig @localhost google.com +short
            echo ""
            read -p "Press Enter to continue..."
            ;;
        6) 
            echo "Clearing DNS cache..."
            rndc flush
            echo "✅ DNS cache cleared!"
            echo ""
            echo "Cache statistics:"
            rndc stats
            sleep 3
            ;;
        7) 
            break 
            ;;
        *) 
            echo "Invalid choice!" 
            sleep 2
            ;;
    esac
done
