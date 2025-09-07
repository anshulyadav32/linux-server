#!/bin/bash
# Web-server Maintenance Script

while true; do
    clear
    echo "======================================"
    echo "     Web-server Maintenance"
    echo "======================================"
    echo "1) Restart Apache"
    echo "2) Restart Nginx"
    echo "3) Reload Configurations"
    echo "4) Clear Web Logs"
    echo "5) Check Service Status"
    echo "6) Test Configuration"
    echo "7) Back"
    echo "======================================"
    read -p "Choose an option [1-7]: " choice

    case $choice in
        1) 
            echo "Restarting Apache..."
            systemctl restart apache2
            if systemctl is-active --quiet apache2; then
                echo "✅ Apache restarted successfully!"
            else
                echo "❌ Apache failed to restart!"
                systemctl status apache2 --no-pager
            fi
            sleep 3
            ;;
        2) 
            echo "Restarting Nginx..."
            systemctl restart nginx
            if systemctl is-active --quiet nginx; then
                echo "✅ Nginx restarted successfully!"
            else
                echo "❌ Nginx failed to restart!"
                systemctl status nginx --no-pager
            fi
            sleep 3
            ;;
        3) 
            echo "Reloading configurations..."
            systemctl reload apache2
            systemctl reload nginx
            echo "✅ Configurations reloaded!"
            sleep 2
            ;;
        4) 
            echo "Clearing web server logs..."
            truncate -s 0 /var/log/apache2/error.log
            truncate -s 0 /var/log/apache2/access.log
            truncate -s 0 /var/log/nginx/error.log 2>/dev/null
            truncate -s 0 /var/log/nginx/access.log 2>/dev/null
            echo "✅ Web server logs cleared!"
            sleep 2
            ;;
        5) 
            echo "======================================"
            echo "        Service Status"
            echo "======================================"
            echo "Apache Status:"
            systemctl status apache2 --no-pager | head -5
            echo ""
            echo "Nginx Status:"
            systemctl status nginx --no-pager | head -5
            echo "======================================"
            read -p "Press Enter to continue..."
            ;;
        6) 
            echo "Testing web server configurations..."
            echo ""
            echo "Apache Configuration Test:"
            apache2ctl configtest
            echo ""
            echo "Nginx Configuration Test:"
            nginx -t
            echo ""
            read -p "Press Enter to continue..."
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
