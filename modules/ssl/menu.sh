#!/bin/bash
# SSL System Menu
# Purpose: Interactive CLI for SSL management

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(dirname "$0")"

# Function to display menu
show_menu() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           SSL SYSTEM MANAGEMENT         ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}Available Options:${NC}"
    echo -e "${GREEN}1)${NC} Install SSL System"
    echo -e "${GREEN}2)${NC} Update SSL System (renew & update tools)"
    echo -e "${GREEN}3)${NC} Maintain SSL (check validity & status)"
    echo -e "${GREEN}4)${NC} Manual Certificate Management"
    echo -e "${GREEN}5)${NC} View Certificate Information"
    echo -e "${GREEN}6)${NC} Test SSL Configuration"
    echo -e "${YELLOW}7)${NC} Back to Master Menu"
    echo -e "${RED}0)${NC} Exit"
    echo
}

# Function to pause and wait for user input
pause() {
    echo
    read -p "Press Enter to continue..."
}

# Function for manual certificate management
manual_cert_management() {
    clear
    echo -e "${BLUE}Manual Certificate Management${NC}"
    echo -e "${CYAN}1)${NC} Install new certificate"
    echo -e "${CYAN}2)${NC} Renew specific certificate"
    echo -e "${CYAN}3)${NC} Delete certificate"
    echo -e "${CYAN}4)${NC} Back to main menu"
    echo
    read -p "Select option [1-4]: " cert_choice
    
    case $cert_choice in
        1)
            read -p "Enter domain for new certificate: " domain
            read -p "Enter email: " email
            if [[ -n "$domain" && -n "$email" ]]; then
                certbot certonly --webroot -w /var/www/html -d "$domain" --email "$email" --agree-tos
            fi
            ;;
        2)
            read -p "Enter domain to renew: " domain
            if [[ -n "$domain" ]]; then
                certbot renew --cert-name "$domain"
            fi
            ;;
        3)
            read -p "Enter domain to delete certificate for: " domain
            if [[ -n "$domain" ]]; then
                read -p "Are you sure you want to delete the certificate for $domain? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    certbot delete --cert-name "$domain"
                fi
            fi
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    pause
}

# Function to view certificate information
view_cert_info() {
    clear
    echo -e "${BLUE}Certificate Information${NC}"
    echo
    
    if command -v certbot >/dev/null 2>&1; then
        certbot certificates
        echo
        
        read -p "Enter domain to view detailed info (or press Enter to skip): " domain
        if [[ -n "$domain" ]]; then
            cert_path="/etc/letsencrypt/live/$domain/fullchain.pem"
            if [[ -f "$cert_path" ]]; then
                echo -e "${CYAN}Detailed certificate information for $domain:${NC}"
                openssl x509 -in "$cert_path" -text -noout | head -30
            else
                echo -e "${RED}Certificate not found for $domain${NC}"
            fi
        fi
    else
        echo -e "${RED}Certbot not installed${NC}"
    fi
    pause
}

# Function to test SSL configuration
test_ssl_config() {
    clear
    echo -e "${BLUE}SSL Configuration Test${NC}"
    echo
    
    read -p "Enter domain to test: " domain
    if [[ -n "$domain" ]]; then
        echo -e "${YELLOW}Testing SSL configuration for $domain...${NC}"
        echo
        
        # Test with curl
        echo -e "${CYAN}Testing with curl:${NC}"
        curl -I "https://$domain" --max-time 10
        echo
        
        # Test SSL certificate details
        echo -e "${CYAN}SSL Certificate Details:${NC}"
        echo | openssl s_client -servername "$domain" -connect "$domain":443 2>/dev/null | openssl x509 -noout -subject -issuer -dates
        
        # Test SSL grade (simplified)
        echo
        echo -e "${CYAN}SSL Test completed${NC}"
    fi
    pause
}

# Main menu loop
while true; do
    show_menu
    read -p "Select an option [0-7]: " choice
    
    case $choice in
        1)
            echo -e "${YELLOW}Starting SSL System Installation...${NC}"
            bash "$SCRIPT_DIR/install.sh"
            pause
            ;;
        2)
            echo -e "${YELLOW}Starting SSL System Update...${NC}"
            bash "$SCRIPT_DIR/update.sh"
            pause
            ;;
        3)
            echo -e "${YELLOW}Starting SSL System Maintenance...${NC}"
            bash "$SCRIPT_DIR/maintain.sh"
            pause
            ;;
        4)
            manual_cert_management
            ;;
        5)
            view_cert_info
            ;;
        6)
            test_ssl_config
            ;;
        7)
            echo -e "${YELLOW}Returning to Master Menu...${NC}"
            break
            ;;
        0)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 2
            ;;
    esac
done
