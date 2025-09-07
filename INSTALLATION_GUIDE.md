# Server Installation Guide

## Quick Start

### 1. Initial Installation
```bash
# Make scripts executable (if on Linux)
chmod +x install-server.sh test-installation.sh

# Start the comprehensive installation
./install-server.sh
```

### 2. Test Installation
```bash
# Test all components after installation
./test-installation.sh
```

### 3. Resume Interrupted Installation
```bash
# If installation was interrupted, resume from last checkpoint
./test-installation.sh
# Select option 2: "Resume installation"
```

## Installation Features

### 🔍 Checkpoint System
- **Automatic Resume**: Installation can resume from any checkpoint if interrupted
- **Error Recovery**: Failed steps can be retried without repeating successful ones
- **Progress Tracking**: View exactly which components have been installed

### 🧪 Comprehensive Testing
- **Component Testing**: Test each stack independently (web, database, mail, DNS, SSL)
- **Service Verification**: Verify services are running and configured correctly
- **Command Availability**: Ensure all required commands are accessible
- **Configuration Validation**: Check that configuration files exist and are valid

### 📊 Installation Monitoring
- **Real-time Progress**: See installation progress with detailed checkpoints
- **Detailed Logging**: All operations logged with timestamps
- **Error Tracking**: Specific error messages and troubleshooting guidance
- **System Requirements**: Pre-installation system validation

## Installation Components

### Essential Packages
- System utilities (curl, wget, git, htop, tree, nano, vim)
- Network tools (net-tools, dnsutils, telnet, nmap)
- Development tools (build-essential, python3, nodejs, npm)

### Web Server Stack
- **Apache2**: Web server with modules
- **Nginx**: Alternative web server
- **PHP**: With FPM, MySQL, PostgreSQL, and common extensions
- **Node.js**: JavaScript runtime with npm
- **Python3**: With pip and virtual environment support

### Database Stack
- **MySQL**: Server and client with administration tools
- **PostgreSQL**: Server with contrib packages
- **Redis**: In-memory data store
- **SQLite3**: Lightweight database

### Mail Server Stack
- **Postfix**: SMTP server (configured non-interactively)
- **Dovecot**: IMAP/POP3 server with core modules
- **OpenDKIM**: DKIM signing and verification
- **SpamAssassin**: Spam filtering
- **ClamAV**: Antivirus scanning

### DNS Server Stack
- **BIND9**: DNS server with utilities and documentation
- **DNS Utils**: dig, nslookup, host commands
- **Configuration**: Default configurations for immediate use

### SSL & Security Stack
- **Certbot**: Let's Encrypt SSL certificate management
- **UFW**: Uncomplicated Firewall
- **Fail2Ban**: Intrusion prevention system
- **OpenSSL**: SSL/TLS toolkit

### Backup & Monitoring Stack
- **Rsync**: File synchronization
- **Duplicity**: Encrypted backup system
- **BorgBackup**: Deduplicating backup program
- **System Monitoring**: htop, iotop, iftop, nethogs, sysstat

## Checkpoint System Details

### Available Checkpoints
1. `SYSTEM_REQUIREMENTS_CHECK` - Validates system compatibility
2. `SYSTEM_UPDATE` - Updates package lists and system
3. `ESSENTIAL_PACKAGES` - Installs core utilities
4. `WEB_DEPENDENCIES` - Installs web server components
5. `DATABASE_DEPENDENCIES` - Installs database systems
6. `MAIL_DEPENDENCIES` - Installs mail server components
7. `DNS_DEPENDENCIES` - Installs DNS server components
8. `SSL_DEPENDENCIES` - Installs SSL and security tools
9. `BACKUP_DEPENDENCIES` - Installs backup and monitoring tools
10. `MONITORING_DEPENDENCIES` - Installs system monitoring tools
11. `SYSTEM_TEST` - Performs comprehensive system validation
12. `INSTALLATION_SUMMARY` - Displays final installation summary

### Checkpoint Management
```bash
# View current checkpoint status
./test-installation.sh
# Select option 1: "Show installation status"

# Reset all checkpoints (start fresh)
./test-installation.sh
# Select option 3: "Reset installation checkpoints"

# Resume from last checkpoint
./test-installation.sh
# Select option 2: "Resume installation"
```

## Testing Features

### Individual Component Testing
```bash
./test-installation.sh
# Component-specific tests:
# - Option 4: Test web stack (Apache, Nginx, PHP, Node.js, Python)
# - Option 5: Test database stack (MySQL, PostgreSQL, Redis, SQLite)
# - Option 6: Test mail stack (Postfix, Dovecot, OpenDKIM)
# - Option 7: Test DNS stack (BIND9, DNS utilities)
# - Option 8: Test SSL/security (Certbot, UFW, Fail2Ban, OpenSSL)
```

### Comprehensive Testing
```bash
./test-installation.sh
# Select option 9: "Run comprehensive test"
# This runs all component tests and provides a complete system report
```

## Error Handling

### Common Issues and Solutions

1. **Permission Denied**
   ```bash
   # Ensure user has sudo privileges
   sudo -v
   
   # Make scripts executable
   chmod +x *.sh
   ```

2. **Network Issues**
   ```bash
   # Test connectivity
   ping -c 3 8.8.8.8
   
   # Test DNS resolution
   dig google.com
   ```

3. **Package Installation Failures**
   ```bash
   # Update package lists
   sudo apt update
   
   # Fix broken packages
   sudo apt --fix-broken install
   ```

4. **Service Start Failures**
   ```bash
   # Check service status
   systemctl status <service-name>
   
   # View service logs
   journalctl -u <service-name> -f
   ```

### Log Analysis
```bash
# View installation logs
./test-installation.sh
# Select option 10: "View installation logs"

# Manual log inspection
tail -f logs/install-*.log

# Search for errors
grep -i error logs/install-*.log
```

## System Requirements

### Minimum Requirements
- **OS**: Ubuntu 18.04+ or Debian 10+
- **RAM**: 2GB minimum (4GB recommended)
- **Disk**: 10GB free space
- **Network**: Internet connectivity required
- **Access**: sudo privileges required

### Supported Distributions
- Ubuntu 18.04 LTS, 20.04 LTS, 22.04 LTS
- Debian 10 (Buster), 11 (Bullseye), 12 (Bookworm)
- Other Debian-based distributions (with warnings)

## Post-Installation

### Verify Installation
```bash
# Run comprehensive test
./test-installation.sh

# Check all services
systemctl status apache2 nginx mysql postgresql postfix dovecot bind9
```

### Next Steps
1. **Configure Services**: Use individual module menus
2. **Run Automated Workflows**: Use `./modules/interdependent.sh`
3. **Access Main Menu**: Run `./master.sh`

### Security Considerations
- Change default passwords for database systems
- Configure firewall rules appropriately
- Set up SSL certificates for web services
- Configure mail server security settings

## Troubleshooting

### Installation Stuck
```bash
# Check if a service is hanging
ps aux | grep apt
ps aux | grep dpkg

# Kill hanging processes (if safe)
sudo killall apt
sudo killall dpkg

# Reconfigure dpkg if needed
sudo dpkg --configure -a
```

### Disk Space Issues
```bash
# Check available space
df -h

# Clean package cache
sudo apt autoremove
sudo apt autoclean
```

### Memory Issues
```bash
# Check memory usage
free -h

# Monitor memory during installation
watch free -h
```

## Support

### Getting Help
1. **Check Logs**: Review installation logs for specific errors
2. **Run Tests**: Use component-specific tests to isolate issues
3. **System Status**: Verify system requirements and dependencies
4. **Documentation**: Refer to module-specific documentation

### Reporting Issues
When reporting issues, include:
- OS version and distribution
- Installation log excerpt showing the error
- Current checkpoint status
- Output of failed component test
