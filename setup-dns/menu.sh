#!/bin/bash
# DNS Management Menu

while true; do
    clear
    echo "======================================"
    echo "        DNS Management"
    echo "======================================"
    echo "1) Install DNS Server"
    echo "2) Zone Management"
    echo "3) Maintain DNS Server"
    echo "4) Update DNS Server"
    echo "5) Back to Main Menu"
    echo "======================================"
    read -p "Choose an option [1-5]: " choice

    case $choice in
        1) 
            bash setup-dns/install.sh 
            ;;
        2) 
            # Zone Management Submenu
            while true; do
                clear
                echo "======================================"
                echo "       Zone Management"
                echo "======================================"
                echo "1) Add New Zone"
                echo "2) List Zones"
                echo "3) Edit Zone File"
                echo "4) Delete Zone"
                echo "5) Test DNS Resolution"
                echo "6) Back"
                echo "======================================"
                read -p "Choose an option [1-6]: " zone_choice
                
                case $zone_choice in
                    1) 
                        read -p "Enter domain name (e.g., example.com): " domain
                        if [[ -z "$domain" ]]; then
                            echo "❌ Domain name cannot be empty!"
                            sleep 2
                            continue
                        fi
                        
                        read -p "Enter server IP address: " server_ip
                        if [[ -z "$server_ip" ]]; then
                            echo "❌ Server IP cannot be empty!"
                            sleep 2
                            continue
                        fi
                        
                        # Create zone file
                        cat > /etc/bind/zones/db.$domain << EOF
\$TTL    604800
@       IN      SOA     ns1.$domain. admin.$domain. (
                        $(date +%Y%m%d)01 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL

; Name servers
@       IN      NS      ns1.$domain.
@       IN      NS      ns2.$domain.

; A records
@       IN      A       $server_ip
ns1     IN      A       $server_ip
ns2     IN      A       $server_ip
www     IN      A       $server_ip
mail    IN      A       $server_ip

; MX record
@       IN      MX 10   mail.$domain.

; CNAME records
ftp     IN      CNAME   @
EOF

                        # Add zone to named.conf.local
                        cat >> /etc/bind/named.conf.local << EOF

zone "$domain" {
    type master;
    file "/etc/bind/zones/db.$domain";
};
EOF

                        # Check configuration and reload
                        if named-checkconf; then
                            if named-checkzone $domain /etc/bind/zones/db.$domain; then
                                systemctl reload bind9
                                echo "✅ Zone $domain added successfully!"
                            else
                                echo "❌ Zone file has errors!"
                            fi
                        else
                            echo "❌ BIND configuration has errors!"
                        fi
                        sleep 3
                        ;;
                    2)
                        echo "======================================"
                        echo "         Active Zones"
                        echo "======================================"
                        grep -E "^zone" /etc/bind/named.conf.local | awk '{print $2}' | tr -d '"'
                        echo "======================================"
                        read -p "Press Enter to continue..."
                        ;;
                    3) 
                        read -p "Enter domain to edit: " domain
                        if [[ -f "/etc/bind/zones/db.$domain" ]]; then
                            nano /etc/bind/zones/db.$domain
                            if named-checkzone $domain /etc/bind/zones/db.$domain; then
                                systemctl reload bind9
                                echo "✅ Zone file updated and reloaded!"
                            else
                                echo "❌ Zone file has errors!"
                            fi
                        else
                            echo "❌ Zone file for $domain not found!"
                        fi
                        sleep 3
                        ;;
                    4)
                        read -p "Enter domain to delete: " domain
                        read -p "Are you sure you want to delete zone $domain? (y/N): " confirm
                        if [[ $confirm == "y" || $confirm == "Y" ]]; then
                            # Remove from named.conf.local
                            sed -i "/zone \"$domain\"/,/};/d" /etc/bind/named.conf.local
                            # Remove zone file
                            rm -f /etc/bind/zones/db.$domain
                            systemctl reload bind9
                            echo "✅ Zone $domain deleted!"
                        else
                            echo "❌ Operation cancelled."
                        fi
                        sleep 2
                        ;;
                    5)
                        read -p "Enter domain to test: " test_domain
                        echo "======================================"
                        echo "    DNS Resolution Test for $test_domain"
                        echo "======================================"
                        dig @localhost $test_domain
                        echo "======================================"
                        read -p "Press Enter to continue..."
                        ;;
                    6) 
                        break 
                        ;;
                    *) 
                        echo "Invalid choice!" 
                        sleep 2
                        ;;
                esac
            done
            ;;
        3) 
            bash setup-dns/maintain.sh 
            ;;
        4) 
            bash setup-dns/update.sh 
            ;;
        5) 
            break 
            ;;
        *) 
            echo "Invalid choice!" 
            sleep 2
            ;;
    esac
done
