#!/bin/bash
# Mail System Maintenance Script

while true; do
    clear
    echo "======================================"
    echo "      Mail System Maintenance"
    echo "======================================"
    echo "1) Restart Postfix"
    echo "2) Restart Dovecot"
    echo "3) Restart SpamAssassin"
    echo "4) View Mail Logs"
    echo "5) Flush Mail Queue"
    echo "6) Check Service Status"
    echo "7) Test Mail Configuration"
    echo "8) Back"
    echo "======================================"
    read -p "Choose an option [1-8]: " choice

    case $choice in
        1) 
            echo "Restarting Postfix..."
            systemctl restart postfix
            if systemctl is-active --quiet postfix; then
                echo "✅ Postfix restarted successfully!"
            else
                echo "❌ Postfix failed to restart!"
                systemctl status postfix --no-pager
            fi
            sleep 3
            ;;
        2) 
            echo "Restarting Dovecot..."
            systemctl restart dovecot
            if systemctl is-active --quiet dovecot; then
                echo "✅ Dovecot restarted successfully!"
            else
                echo "❌ Dovecot failed to restart!"
                systemctl status dovecot --no-pager
            fi
            sleep 3
            ;;
        3) 
            echo "Restarting SpamAssassin..."
            systemctl restart spamassassin
            if systemctl is-active --quiet spamassassin; then
                echo "✅ SpamAssassin restarted successfully!"
            else
                echo "❌ SpamAssassin failed to restart!"
                systemctl status spamassassin --no-pager
            fi
            sleep 3
            ;;
        4) 
            echo "======================================"
            echo "          Mail Server Logs"
            echo "======================================"
            echo "Mail Log (last 20 lines):"
            tail -n 20 /var/log/mail.log
            echo ""
            echo "Postfix Log (last 10 lines):"
            tail -n 10 /var/log/mail.log | grep postfix
            read -p "Press Enter to continue..."
            ;;
        5) 
            echo "Flushing mail queue..."
            postqueue -f
            echo "✅ Mail queue flushed!"
            echo ""
            echo "Current queue status:"
            postqueue -p
            sleep 3
            ;;
        6) 
            echo "======================================"
            echo "        Mail Service Status"
            echo "======================================"
            echo "Postfix Status:"
            systemctl status postfix --no-pager | head -5
            echo ""
            echo "Dovecot Status:"
            systemctl status dovecot --no-pager | head -5
            echo ""
            echo "SpamAssassin Status:"
            systemctl status spamassassin --no-pager | head -5
            echo "======================================"
            read -p "Press Enter to continue..."
            ;;
        7) 
            echo "Testing mail server configuration..."
            echo ""
            echo "Postfix Configuration Test:"
            postfix check
            echo ""
            echo "Dovecot Configuration Test:"
            dovecot -n | head -10
            echo ""
            echo "Port Status:"
            netstat -tlnp | grep -E ':25|:587|:993|:995|:143|:110'
            echo ""
            read -p "Press Enter to continue..."
            ;;
        8) 
            break 
            ;;
        *) 
            echo "Invalid choice!" 
            sleep 2
            ;;
    esac
done
