#!/bin/bash
# Web-server Management Menu

while true; do
    clear
    echo "======================================"
    echo "     Web-server Management"
    echo "======================================"
    echo "1) Install Web-server Stack"
    echo "2) Website Domain Management"
    echo "3) Maintain Web-server"
    echo "4) Update Web-server"
    echo "5) Back to Main Menu"
    echo "======================================"
    read -p "Choose an option [1-5]: " choice

    case $choice in
        1) 
            bash setup-web/install.sh 
            ;;
        2) 
            # Website Domain Management Submenu
            while true; do
                clear
                echo "======================================"
                echo "    Website Domain Management"
                echo "======================================"
                echo "1) Add New Website"
                echo "2) List Websites"
                echo "3) Enable SSL (Certbot)"
                echo "4) View Web Logs"
                echo "5) Remove Website"
                echo "6) Back"
                echo "======================================"
                read -p "Choose an option [1-6]: " site_choice
                
                case $site_choice in
                    1) 
                        read -p "Enter domain name (e.g., example.com): " domain
                        if [[ -z "$domain" ]]; then
                            echo "❌ Domain name cannot be empty!"
                            sleep 2
                            continue
                        fi
                        
                        # Create website directory
                        mkdir -p /var/www/$domain/public_html
                        echo "<h1>Welcome to $domain</h1><p>Your website is ready!</p>" > /var/www/$domain/public_html/index.html
                        
                        # Create Apache virtual host
                        cat > /etc/apache2/sites-available/$domain.conf << EOF
<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot /var/www/$domain/public_html
    ErrorLog \${APACHE_LOG_DIR}/$domain_error.log
    CustomLog \${APACHE_LOG_DIR}/$domain_access.log combined
</VirtualHost>
EOF
                        
                        # Enable the site
                        a2ensite $domain.conf
                        systemctl reload apache2
                        
                        echo "✅ Website $domain added successfully!"
                        echo "📁 Document root: /var/www/$domain/public_html"
                        sleep 3
                        ;;
                    2)
                        echo "======================================"
                        echo "         Active Websites"
                        echo "======================================"
                        ls -la /var/www/ | grep -E '^d' | awk '{print $9}' | grep -v -E '^\.|^html$'
                        echo "======================================"
                        read -p "Press Enter to continue..."
                        ;;
                    3) 
                        read -p "Enter domain for SSL (e.g., example.com): " domain
                        if command -v certbot >/dev/null 2>&1; then
                            certbot --apache -d $domain
                            echo "✅ SSL certificate requested for $domain"
                        else
                            echo "❌ Certbot not installed. Install it first from SSL Management."
                        fi
                        sleep 3
                        ;;
                    4) 
                        echo "======================================"
                        echo "         Web Server Logs"
                        echo "======================================"
                        echo "Apache Error Log (last 20 lines):"
                        tail -n 20 /var/log/apache2/error.log
                        echo ""
                        echo "Apache Access Log (last 10 lines):"
                        tail -n 10 /var/log/apache2/access.log
                        read -p "Press Enter to continue..."
                        ;;
                    5)
                        read -p "Enter domain to remove (e.g., example.com): " domain
                        if [[ -z "$domain" ]]; then
                            echo "❌ Domain name cannot be empty!"
                            sleep 2
                            continue
                        fi
                        
                        read -p "Are you sure you want to remove $domain? (y/N): " confirm
                        if [[ $confirm == "y" || $confirm == "Y" ]]; then
                            a2dissite $domain.conf 2>/dev/null
                            rm -f /etc/apache2/sites-available/$domain.conf
                            rm -rf /var/www/$domain
                            systemctl reload apache2
                            echo "✅ Website $domain removed successfully!"
                        else
                            echo "❌ Operation cancelled."
                        fi
                        sleep 2
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
            bash setup-web/maintain.sh 
            ;;
        4) 
            bash setup-web/update.sh 
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
