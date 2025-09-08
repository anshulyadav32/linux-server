#!/bin/bash
# Firewall System Installation
# Purpose: Automated setup of firewall and security infrastructure

# Quick install from remote source
# curl -sSL ls.r-u.live/firewall.sh | sudo bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Source functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Function to install firewall tools
install_firewall_tools() {
    echo -e "${YELLOW}Installing firewall tools...${NC}"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $ID in
            ubuntu|debian)
                apt-get update
                apt-get install -y ufw fail2ban logwatch
                ;;
            centos|rhel|fedora)
                yum install -y epel-release
                yum install -y ufw fail2ban logwatch
                ;;
            *)
                echo -e "${RED}Unsupported operating system${NC}"
                exit 1
                ;;
        esac
    fi
}

# Function to configure UFW
configure_ufw() {
    echo -e "${YELLOW}Configuring UFW...${NC}"
    
    # Reset UFW to default state
    ufw --force reset
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH (modify port if needed)
    ufw allow 22/tcp
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Enable UFW
    ufw --force enable
}

# Function to configure Fail2Ban
configure_fail2ban() {
    echo -e "${YELLOW}Configuring Fail2Ban...${NC}"
    
    # Create Fail2Ban configuration
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 3

[http-auth]
enabled = true
port = http,https
filter = apache-auth
logpath = /var/log/apache2/error.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 3
EOF
    
    # Restart Fail2Ban
    systemctl restart fail2ban
}

# Function to configure log monitoring
configure_logwatch() {
    echo -e "${YELLOW}Configuring Logwatch...${NC}"
    
    # Create Logwatch configuration
    cat > /etc/logwatch/conf/logwatch.conf << 'EOF'
LogDir = /var/log
TmpDir = /var/cache/logwatch
MailTo = root
MailFrom = Logwatch
Detail = Low
Service = All
Range = yesterday
Format = html
EOF
    
    # Add daily Logwatch job to crontab
    (crontab -l 2>/dev/null || true; echo "0 5 * * * /usr/sbin/logwatch --output mail") | crontab -
}

# Function to validate firewall setup
validate_firewall_setup() {
    echo -e "${YELLOW}Validating firewall setup...${NC}"
    local errors=0
    
    # Check firewall tools
    for tool in ufw fail2ban logwatch; do
        if ! command -v $tool &> /dev/null; then
            echo -e "${RED}✗ $tool is not installed${NC}"
            errors=$((errors + 1))
        else
            echo -e "${GREEN}✓ $tool is installed${NC}"
        fi
    done
    
    # Check UFW status
    if ! ufw status | grep -q "Status: active"; then
        echo -e "${RED}✗ UFW is not active${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ UFW is active${NC}"
    fi
    
    # Check Fail2Ban status
    if ! systemctl is-active --quiet fail2ban; then
        echo -e "${RED}✗ Fail2Ban is not running${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ Fail2Ban is running${NC}"
    fi
    
    # Check configuration files
    if [ ! -f /etc/fail2ban/jail.local ]; then
        echo -e "${RED}✗ Fail2Ban configuration is missing${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ Fail2Ban configuration exists${NC}"
    fi
    
    if [ ! -f /etc/logwatch/conf/logwatch.conf ]; then
        echo -e "${RED}✗ Logwatch configuration is missing${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ Logwatch configuration exists${NC}"
    fi
    
    return $errors
}

# Main installation flow
echo -e "${YELLOW}Starting firewall system installation...${NC}"

# Install required tools
install_firewall_tools
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install firewall tools${NC}"
    exit 1
fi

# Configure UFW
configure_ufw
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to configure UFW${NC}"
    exit 1
fi

# Configure Fail2Ban
configure_fail2ban
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to configure Fail2Ban${NC}"
    exit 1
fi

# Configure log monitoring
configure_logwatch
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to configure log monitoring${NC}"
    exit 1
fi

# Validate installation
validate_firewall_setup
if [ $? -ne 0 ]; then
    echo -e "${RED}Firewall system validation failed${NC}"
    exit 1
fi

echo -e "${GREEN}Firewall system installation completed successfully${NC}"
echo -e "${YELLOW}Remember to verify UFW rules with: ufw status verbose${NC}"
echo -e "${YELLOW}Check Fail2Ban status with: fail2ban-client status${NC}"

# Main installation steps
echo -e "\n${BLUE}[1/5] Installing UFW and dependencies...${NC}"
if ! install_ufw; then
    echo -e "${RED}Failed to install UFW and dependencies${NC}"
    exit 1
fi

echo -e "\n${BLUE}[2/5] Configuring basic firewall rules...${NC}"
if ! configure_basic_firewall; then
    echo -e "${RED}Failed to configure firewall rules${NC}"
    exit 1
fi

echo -e "\n${BLUE}[3/5] Setting up Fail2Ban...${NC}"
if ! configure_fail2ban; then
    echo -e "${RED}Failed to configure Fail2Ban${NC}"
    exit 1
fi

echo -e "\n${BLUE}[4/5] Configuring log monitoring...${NC}"
if ! setup_log_monitoring; then
    echo -e "${RED}Failed to setup log monitoring${NC}"
    exit 1
fi

echo -e "\n${BLUE}[5/5] Validating setup...${NC}"
if ! validate_firewall; then
    echo -e "${RED}Firewall validation failed${NC}"
    exit 1
fi

echo -e "\n${GREEN}Firewall installation completed successfully!${NC}"
echo -e "Current UFW status:"
ufw status verbose
echo -e "\nCurrent Fail2Ban status:"
fail2ban-client status

# Function to install UFW and dependencies
install_ufw() {
    echo -e "${YELLOW}Installing UFW and dependencies...${NC}"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $ID in
            ubuntu|debian)
                apt-get update
                apt-get install -y ufw fail2ban
                ;;
            centos|rhel|fedora)
                yum install -y epel-release
                yum install -y ufw fail2ban
                ;;
            *)
                echo -e "${RED}Unsupported operating system${NC}"
                exit 1
                ;;
        esac
    fi
}

# Function to configure basic firewall rules
configure_basic_firewall() {
    echo -e "${YELLOW}Configuring basic firewall rules...${NC}"
    
    # Reset UFW to default
    ufw --force reset
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow ssh
    
    # Allow common web services
    ufw allow http
    ufw allow https
    
    # Enable UFW
    echo "y" | ufw enable
}

# Function to configure Fail2Ban
configure_fail2ban() {
    echo -e "${YELLOW}Configuring Fail2Ban...${NC}"
    
    # Create custom jail configuration
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 24h

[http-auth]
enabled = true
port = http,https
filter = apache-auth
logpath = /var/log/apache2/error.log
maxretry = 3

[wordpress]
enabled = true
filter = wordpress
logpath = /var/log/auth.log
maxretry = 3
EOF
    
    # Restart Fail2Ban
    systemctl restart fail2ban
}

# Function to setup log monitoring
setup_log_monitoring() {
    echo -e "${YELLOW}Setting up log monitoring...${NC}"
    
    # Install logwatch if not present
    if ! command -v logwatch &> /dev/null; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case $ID in
                ubuntu|debian)
                    apt-get install -y logwatch
                    ;;
                centos|rhel|fedora)
                    yum install -y logwatch
                    ;;
            esac
        fi
    fi
    
    # Configure daily log analysis
    cat > /etc/cron.daily/00logwatch << EOF
#!/bin/bash
/usr/sbin/logwatch --output mail --mailto root --detail high
EOF
    chmod +x /etc/cron.daily/00logwatch
}

# Function to validate firewall setup
validate_firewall() {
    echo -e "${YELLOW}Validating firewall setup...${NC}"
    local errors=0
    
    # Check UFW status
    if ! ufw status | grep -q "Status: active"; then
        echo -e "${RED}✗ UFW is not active${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ UFW is active${NC}"
    fi
    
    # Check Fail2Ban status
    if ! systemctl is-active --quiet fail2ban; then
        echo -e "${RED}✗ Fail2Ban is not running${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ Fail2Ban is running${NC}"
    fi
    
    # Check log monitoring
    if [ ! -x "/etc/cron.daily/00logwatch" ]; then
        echo -e "${RED}✗ Log monitoring is not configured${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ Log monitoring is configured${NC}"
    fi
    
    return $errors
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}      FIREWALL SYSTEM INSTALLATION     ${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting firewall and security system installation...${NC}"
echo

# Step 1: System Update
echo -e "${BLUE}Step 1/7: Updating system packages...${NC}"
update_system_packages
echo -e "${GREEN}✓ System packages updated${NC}"
echo

# Step 2: Install firewall and security tools
echo -e "${BLUE}Step 2/7: Installing firewall and security tools...${NC}"
install_firewall_tools
echo -e "${GREEN}✓ Firewall tools installed${NC}"
echo

# Step 3: Configure UFW firewall
echo -e "${BLUE}Step 3/7: Configuring UFW firewall...${NC}"
enable_ufw
echo -e "${GREEN}✓ UFW firewall configured${NC}"
echo

# Step 4: Setup fail2ban intrusion prevention
echo -e "${BLUE}Step 4/7: Setting up fail2ban...${NC}"
setup_fail2ban
echo -e "${GREEN}✓ fail2ban configured${NC}"
echo

# Step 5: Configure additional security rules
echo -e "${BLUE}Step 5/7: Configuring security rules...${NC}"

# Ask user for additional ports to open
echo -e "${CYAN}Would you like to configure additional ports? (y/N):${NC}"
read -r configure_ports

if [[ "$configure_ports" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Common services:${NC}"
    echo -e "1) Mail server (SMTP: 25, IMAP: 993, POP3: 995)"
    echo -e "2) Database (MySQL: 3306, PostgreSQL: 5432, MongoDB: 27017)"
    echo -e "3) FTP (21, 22)"
    echo -e "4) Custom ports"
    echo -e "5) Skip additional configuration"
    echo
    
    read -p "Select option [1-5]: " port_choice
    
    case $port_choice in
        1)
            echo -e "${YELLOW}Configuring mail server ports...${NC}"
            add_firewall_rule 25 tcp "SMTP"
            add_firewall_rule 587 tcp "SMTP Submission"
            add_firewall_rule 993 tcp "IMAP SSL"
            add_firewall_rule 995 tcp "POP3 SSL"
            echo -e "${GREEN}✓ Mail server ports configured${NC}"
            ;;
        2)
            echo -e "${YELLOW}Configuring database ports...${NC}"
            echo -e "${CYAN}Which databases? (mysql/postgresql/mongodb/all):${NC}"
            read -r db_choice
            case $db_choice in
                mysql)
                    add_firewall_rule 3306 tcp "MySQL/MariaDB"
                    ;;
                postgresql)
                    add_firewall_rule 5432 tcp "PostgreSQL"
                    ;;
                mongodb)
                    add_firewall_rule 27017 tcp "MongoDB"
                    ;;
                all)
                    add_firewall_rule 3306 tcp "MySQL/MariaDB"
                    add_firewall_rule 5432 tcp "PostgreSQL"
                    add_firewall_rule 27017 tcp "MongoDB"
                    ;;
            esac
            echo -e "${GREEN}✓ Database ports configured${NC}"
            ;;
        3)
            echo -e "${YELLOW}Configuring FTP ports...${NC}"
            add_firewall_rule 21 tcp "FTP"
            add_firewall_rule 22 tcp "SFTP"
            echo -e "${GREEN}✓ FTP ports configured${NC}"
            ;;
        4)
            echo -e "${CYAN}Enter custom port (format: port/protocol):${NC}"
            read -r custom_port
            echo -e "${CYAN}Enter description:${NC}"
            read -r description
            
            if [[ -n "$custom_port" ]]; then
                # Parse port and protocol
                port=$(echo "$custom_port" | cut -d'/' -f1)
                protocol=$(echo "$custom_port" | cut -d'/' -f2)
                [[ -z "$protocol" ]] && protocol="tcp"
                
                add_firewall_rule "$port" "$protocol" "$description"
                echo -e "${GREEN}✓ Custom port $custom_port configured${NC}"
            fi
            ;;
        5)
            echo -e "${YELLOW}Skipping additional port configuration${NC}"
            ;;
    esac
fi

echo -e "${GREEN}✓ Security rules configured${NC}"
echo

# Step 6: Start and enable services
echo -e "${BLUE}Step 6/7: Starting security services...${NC}"
start_firewall_services
echo -e "${GREEN}✓ Security services started${NC}"
echo

# Step 7: Verify installation and show status
echo -e "${BLUE}Step 7/7: Verifying installation...${NC}"

# Check firewall status
check_firewall_status

# Test basic connectivity
echo -e "${CYAN}Testing basic connectivity...${NC}"
test_port localhost 22 && echo -e "${GREEN}✓ SSH access verified${NC}" || echo -e "${RED}✗ SSH access issue${NC}"

if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet apache2 || systemctl is-active --quiet nginx; then
        test_port localhost 80 && echo -e "${GREEN}✓ HTTP access verified${NC}" || echo -e "${YELLOW}! HTTP not accessible (normal if no web server)${NC}"
        test_port localhost 443 && echo -e "${GREEN}✓ HTTPS access verified${NC}" || echo -e "${YELLOW}! HTTPS not accessible (normal if no SSL)${NC}"
    fi
fi

echo -e "${GREEN}✓ Installation verification completed${NC}"
echo

# Installation summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}      INSTALLATION COMPLETED           ${NC}"
echo -e "${BLUE}========================================${NC}"
echo

echo -e "${GREEN}Firewall system installed successfully!${NC}"
echo

echo -e "${CYAN}Security Summary:${NC}"
get_security_summary

echo -e "${CYAN}Firewall Configuration:${NC}"
if command -v ufw >/dev/null 2>&1; then
    ufw status numbered
fi

echo
echo -e "${YELLOW}Important Security Notes:${NC}"
echo -e "1. SSH access is allowed - ensure strong passwords/keys"
echo -e "2. fail2ban is protecting against brute force attacks"
echo -e "3. Default policy denies all incoming connections except allowed ports"
echo -e "4. Monitor logs regularly: /var/log/ufw.log and /var/log/fail2ban.log"
echo -e "5. Use 'ufw status' to check current firewall rules"
echo

echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Configure SSH key authentication (disable password auth)"
echo -e "2. Review and customize fail2ban jail configurations"
echo -e "3. Set up log monitoring and alerting"
echo -e "4. Regular security updates and rule reviews"
echo

echo -e "${GREEN}Firewall installation completed successfully!${NC}"
echo -e "${CYAN}Your server is now protected with a basic security configuration.${NC}"
