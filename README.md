# 🚀 Linux Setup - Complete Server Management System

A comprehensive server management platform that automates installation and configuration of enterprise-grade Linux infrastructure. Deploy complete server stacks with web servers, databases, security tools, and monitoring in minutes.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-green.svg)
![Bash](https://img.shields.io/badge/shell-bash-yellow.svg)
![Status](https://img.shields.io/badge/status-production--ready-brightgreen.svg)

## 📖 Table of Contents
- [📘 Project Overview](#-project-overview)
- [⚡ Installation (Two Ways)](#-installation-two-ways)
- [🛠️ Usage Methods](#️-usage-methods)
- [🧩 Components](#-components)
- [📋 Modules (Quick Guide)](#-modules-quick-guide)
- [🔧 Maintenance & Update](#-maintenance--update)

---

## 📘 Project Overview

**What this project does:**
Automates the complete setup of Linux servers with web hosting, databases, mail systems, DNS, security, and monitoring tools.

**Tech stack:**
- **Shell/Bash** - Core automation scripts
- **Apache/Nginx** - Web servers
- **MySQL/PostgreSQL/Redis** - Database systems
- **Postfix/Dovecot** - Mail server components
- **BIND9** - DNS management
- **Let's Encrypt** - SSL certificate automation
- **UFW/Fail2Ban** - Security and firewall
- **Systemd** - Service management

---

## ⚡ Installation (Two Ways)

### **Quick Install (Short Way)**

```bash
git clone https://github.com/anshulyadav32/linux-setup.git
cd linux-setup
sudo ./install.sh
```

### **Step-by-Step Install (Long Way)**

```bash
# Update system and install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git

# Clone repository
git clone https://github.com/anshulyadav32/linux-setup.git
cd linux-setup

# Make scripts executable
chmod +x *.sh
chmod +x modules/**/*.sh

# Choose installation type
sudo ./install.sh --type=full          # Complete installation
sudo ./install.sh --type=basic         # Basic components only
sudo ./install.sh --type=development   # Development environment
sudo ./install.sh --type=production    # Production optimized

# Verify installation
sudo ./system-status-checker.sh
```

---

## 🛠️ Usage Methods

### **Method 1: Installation Method**

After installation, access your server:
- **Web Interface**: `http://your-server-ip`
- **Admin Dashboard**: `http://your-server-ip/admin`
- **System Status**: `sudo ./system-status-checker.sh`
- **Quick Health Check**: `./quick-check.sh`

### **Method 2: CLI Method**

```bash
# Main management interface
sudo ./master.sh

# Quick CLI commands
./master.sh --help                    # Show all options
./master.sh --status                  # System status
./master.sh --update                  # Update all components
./master.sh --backup                  # Create system backup
./master.sh --module web              # Access web module
./master.sh --module db               # Access database module
```

---

## 🧩 Components

### **Web Server** (Apache/Nginx options)
- Apache 2.4 or Nginx web server
- PHP 8.x with extensions
- Virtual host management
- SSL/TLS integration

### **Mail System** (Postfix/Dovecot/Roundcube)
- Postfix SMTP server
- Dovecot IMAP/POP3
- Roundcube webmail
- DKIM/SPF/DMARC authentication

### **DNS Management** (BIND9/PowerDNS)
- BIND9 DNS server
- Zone file management
- Record management (A, AAAA, CNAME, MX, TXT)
- DNSSEC support

### **Database** (MySQL/PostgreSQL/Redis)
- MySQL 8.0 relational database
- PostgreSQL advanced database
- Redis in-memory cache
- Database backup automation

### **Firewall & Security** (UFW/Fail2Ban)
- UFW firewall with security rules
- Fail2Ban intrusion prevention
- ClamAV antivirus
- Security auditing tools

### **SSL/TLS** (Let's Encrypt/Certbot)
- Let's Encrypt certificate automation
- Multi-domain SSL support
- Auto-renewal system
- Certificate monitoring

---

## 📋 Modules (Quick Guide)

### Web Module
```bash
./modules/web/menu.sh                  # Web management interface
./modules/web/functions.sh create_vhost domain.com  # Add website
./modules/web/functions.sh install_ssl domain.com   # Enable SSL
```

### DNS Module
```bash
./modules/dns/menu.sh                  # DNS management interface
./modules/dns/functions.sh add_zone domain.com      # Add DNS zone
./modules/dns/functions.sh add_record domain.com A 192.168.1.100  # Add A record
```

### Mail Module
```bash
./modules/mail/menu.sh                 # Mail management interface
./modules/mail/functions.sh add_user user@domain.com  # Add email user
./modules/mail/functions.sh setup_dkim domain.com     # Configure DKIM
```

### Database Module
```bash
./modules/db/menu.sh                   # Database management interface
./modules/db/functions.sh create_db myapp_db          # Create database
./modules/db/functions.sh create_user dbuser myapp_db # Create DB user
```

### Firewall Module
```bash
./modules/firewall/menu.sh             # Security management interface
./modules/firewall/functions.sh allow_port 80,443     # Open web ports
./modules/firewall/functions.sh block_ip 192.168.1.50 # Block IP
```

### SSL Module
```bash
./modules/ssl/menu.sh                  # SSL management interface
./modules/ssl/functions.sh install_cert domain.com    # Install SSL cert
./modules/ssl/functions.sh renew_all                  # Renew all certs
```

### Backup Module
```bash
./modules/backup/menu.sh               # Backup management interface
./modules/backup/functions.sh backup_all              # Backup everything
./modules/backup/functions.sh restore_backup 2024-01-01  # Restore backup
```

### System Module
```bash
./modules/system/menu.sh               # System management interface
./modules/system/functions.sh add_user john admin     # Add system user
./modules/system/functions.sh monitor_performance     # Monitor system
```

---

## 🔧 Maintenance & Update

### **Update Commands**
```bash
# Update the Linux Setup system
cd /path/to/linux-setup
git pull origin main
sudo ./setup.sh --update

# Update individual modules
sudo ./modules/web/functions.sh update_components
sudo ./modules/db/functions.sh update_databases
sudo ./modules/system/functions.sh update_system
```

### **Troubleshooting Common Errors**

**Permission Issues:**
```bash
# Fix script permissions
chmod +x *.sh modules/**/*.sh
```

**Service Not Starting:**
```bash
# Check service status
sudo systemctl status apache2
sudo systemctl status mysql

# Restart services
sudo systemctl restart apache2
sudo systemctl restart mysql
```

**SSL Certificate Issues:**
```bash
# Check SSL certificates
sudo certbot certificates

# Renew certificates
sudo certbot renew --dry-run
```

**Database Connection Problems:**
```bash
# Check MySQL status
sudo systemctl status mysql

# Reset MySQL root password
sudo mysql_secure_installation
```

**Firewall Blocking Access:**
```bash
# Check firewall status
sudo ufw status

# Allow web traffic
sudo ufw allow 80,443/tcp
```

### **System Health Monitoring**
```bash
# Comprehensive system check
sudo ./system-status-checker.sh

# Monitor logs
sudo tail -f /var/log/linux-setup/installation.log

# Performance monitoring
sudo ./modules/system/functions.sh monitor_resources
```

### **Backup & Recovery**
```bash
# Create full system backup
sudo ./modules/backup/functions.sh backup_all

# Schedule automated backups
sudo ./modules/backup/functions.sh setup_cron_backup

# Restore from backup
sudo ./modules/backup/functions.sh restore_backup [backup-name]
```

---

## 📚 Additional Resources

- **GitHub Repository**: [https://github.com/anshulyadav32/linux-setup](https://github.com/anshulyadav32/linux-setup)
- **Documentation**: [https://ls.r-u.live](https://ls.r-u.live)
- **Issues**: [https://github.com/anshulyadav32/linux-setup/issues](https://github.com/anshulyadav32/linux-setup/issues)
- **Support**: support@ls.r-u.live

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Ready to deploy your server?** Start with the [Quick Install](#-installation-two-ways) above! 🚀

**What this does:**
- Downloads and runs the automated installer
- Installs all 45+ components with verification
- Configures security, SSL, and performance optimization
- Creates a professional web dashboard
- Takes 10-15 minutes for complete setup

#### **Quick Component Install:**
```bash
# Install specific components only
curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-setup/main/install.sh | sudo bash -s -- --components="web,db,ssl"
```

---

### **🔧 Long Way (Manual)**

#### **1. Clone Repository:**
```bash
# Download the project
git clone https://github.com/anshulyadav32/linux-setup.git
cd linux-setup

# Make scripts executable
chmod +x *.sh
chmod +x modules/**/*.sh
```

#### **2. Choose Installation Method:**

**A) Complete Automated Installation:**
```bash
# Run full automated installer
sudo ./install.sh

# Available options:
# --type=full          # Complete installation (default)
# --type=basic         # Basic components only
# --type=development   # Development environment
# --type=production    # Production optimized
# --type=minimal       # Minimal installation
```

**B) CLI Management Interface:**
```bash
# Launch interactive management interface
sudo ./master.sh

# This provides:
# - Menu-driven installation
# - Individual module management
# - System monitoring and maintenance
# - Configuration management
```

#### **3. Verification:**
```bash
# Check installation status
sudo ./system-status-checker.sh

# Quick health check
./quick-check.sh

# Access web dashboard
http://your-server-ip
```

---

## 🧩 **Components & Modules**

The system is organized into **8 specialized modules**, each handling specific server components:

### **🌐 Web Server Module**
**Purpose**: Complete web server management with Apache/Nginx, PHP, and performance optimization.

#### **Components:**
- **Apache 2.4** or **Nginx** web servers
- **PHP 8.x** with 19+ essential extensions
- **SSL/TLS** certificate automation
- **Performance optimization** (caching, compression)
- **Virtual host management**

#### **Quick Guide:**
```bash
# Install web server components
sudo ./modules/web/install.sh

# Access web management
sudo ./modules/web/menu.sh

# Quick actions:
# 1. Install Apache + PHP    → Option 1
# 2. Create virtual host     → Option 2  
# 3. Install SSL certificate → Option 3
# 4. Performance optimization → Option 4
```

---

### **🗄️ Database Module**
**Purpose**: Comprehensive database management for MySQL, PostgreSQL, Redis, and more.

#### **Components:**
- **MySQL 8.0** relational database
- **PostgreSQL** advanced database
- **Redis** in-memory cache
- **SQLite** lightweight database
- **Database backup** and restore tools

#### **Quick Guide:**
```bash
# Install database components
sudo ./modules/db/install.sh

# Access database management
sudo ./modules/db/menu.sh

# Quick actions:
# 1. Install MySQL          → Option 1
# 2. Create database        → Option 2
# 3. Setup database backup  → Option 3
# 4. Monitor performance    → Option 4
```

---

### **🌍 DNS Module**
**Purpose**: BIND9 DNS server management with zone and record operations.

#### **Components:**
- **BIND9** DNS server
- **Zone management** tools
- **DNS record** operations (A, AAAA, CNAME, MX, TXT, PTR, SRV)
- **DNSSEC** security features
- **DNS monitoring** and testing

#### **Quick Guide:**
```bash
# Install DNS components
sudo ./modules/dns/install.sh

# Access DNS management
sudo ./modules/dns/menu.sh

# Quick actions:
# 1. Install BIND9          → Option 1
# 2. Create DNS zone        → Option 2
# 3. Add DNS records        → Option 3
# 4. Test DNS resolution    → Option 4
```

---

### **✉️ Mail Module**
**Purpose**: Complete mail server with Postfix, Dovecot, and security features.

#### **Components:**
- **Postfix** SMTP server
- **Dovecot** IMAP/POP3 server
- **DKIM, SPF, DMARC** authentication
- **Anti-spam** protection (SpamAssassin)
- **Webmail** interfaces (Roundcube)

#### **Quick Guide:**
```bash
# Install mail components
sudo ./modules/mail/install.sh

# Access mail management
sudo ./modules/mail/menu.sh

# Quick actions:
# 1. Install mail server    → Option 1
# 2. Create email accounts  → Option 2
# 3. Configure security     → Option 3
# 4. Setup webmail         → Option 4
```

---

### **🔒 Firewall Module**
**Purpose**: Advanced security management with firewall, intrusion prevention, and monitoring.

#### **Components:**
- **UFW Firewall** with security rules
- **Fail2Ban** intrusion prevention
- **ClamAV** antivirus protection
- **Security auditing** tools
- **Real-time monitoring**

#### **Quick Guide:**
```bash
# Install security components
sudo ./modules/firewall/install.sh

# Access security management
sudo ./modules/firewall/menu.sh

# Quick actions:
# 1. Configure firewall     → Option 1
# 2. Setup intrusion prevention → Option 2
# 3. Run security audit     → Option 3
# 4. Monitor security logs  → Option 4
```

---

### **🔐 SSL Module**
**Purpose**: SSL/TLS certificate management with Let's Encrypt automation.

#### **Components:**
- **Let's Encrypt** certificate automation
- **Self-signed** certificate generation
- **Multi-domain** certificate support
- **Auto-renewal** system
- **Certificate monitoring**

#### **Quick Guide:**
```bash
# Install SSL components
sudo ./modules/ssl/install.sh

# Access SSL management
sudo ./modules/ssl/menu.sh

# Quick actions:
# 1. Install SSL certificate → Option 1
# 2. Setup auto-renewal     → Option 2
# 3. Validate certificates  → Option 3
# 4. Monitor SSL status     → Option 4
```

---

### **💾 Backup Module**
**Purpose**: Comprehensive backup and restore system for all server components.

#### **Components:**
- **Automated backups** for all data
- **Multiple storage** options (local, remote, cloud)
- **Incremental backup** strategies
- **Point-in-time** restore
- **Backup monitoring** and verification

#### **Quick Guide:**
```bash
# Install backup components
sudo ./modules/backup/install.sh

# Access backup management
sudo ./modules/backup/menu.sh

# Quick actions:
# 1. Configure backups      → Option 1
# 2. Create backup now      → Option 2
# 3. Restore from backup    → Option 3
# 4. Schedule automated backups → Option 4
```

---

### **⚙️ System Module**
**Purpose**: System administration tools for users, packages, and monitoring.

#### **Components:**
- **User management** (accounts, groups, permissions)
- **Package management** (installation, updates)
- **System monitoring** (performance, resources)
- **Log management** (centralized logging, analysis)
- **Maintenance automation**

#### **Quick Guide:**
```bash
# Install system components
sudo ./modules/system/install.sh

# Access system management
sudo ./modules/system/menu.sh

# Quick actions:
# 1. User management        → Option 1
# 2. System monitoring      → Option 2
# 3. Package updates        → Option 3
# 4. System maintenance     → Option 4
```

---

## 🔧 **Configuration**

### **System Requirements:**
- **Operating System**: Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+
- **Memory**: Minimum 1GB RAM (2GB+ recommended)
- **Storage**: Minimum 2GB free space (10GB+ recommended)
- **Network**: Internet connectivity for package downloads
- **Privileges**: Root/sudo access required

### **Environment Setup:**
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
sudo yum update -y                      # CentOS/RHEL

# Install git (if not present)
sudo apt install git -y                 # Ubuntu/Debian
sudo yum install git -y                 # CentOS/RHEL
```

### **Configuration Files:**
```bash
# Global configuration
configs/
├── apache.conf           # Apache configuration templates
├── nginx.conf           # Nginx configuration templates  
├── php.ini              # PHP optimization settings
├── mysql.cnf            # MySQL configuration
├── ssl.conf             # SSL/TLS settings
├── firewall.rules       # UFW firewall rules
└── backup.conf          # Backup configuration
```

---

## 📊 **Monitoring & Maintenance**

### **System Health Monitoring:**
```bash
# Comprehensive system status
sudo ./system-status-checker.sh

# Quick health check
./quick-check.sh

# Service-specific monitoring
sudo ./modules/web/functions.sh monitor_services
sudo ./modules/db/functions.sh check_database_health
```

### **Log Management:**
```bash
# System logs location
/var/log/linux-setup/
├── installation.log     # Installation progress and errors
├── web-server.log      # Web server operations
├── database.log        # Database operations
├── security.log        # Security events
├── backup.log          # Backup operations
└── system.log          # System administration
```

### **Maintenance Tasks:**
```bash
# Weekly maintenance (runs automatically via cron)
sudo ./modules/system/functions.sh weekly_maintenance

# Manual maintenance tasks
sudo ./modules/system/functions.sh update_system
sudo ./modules/system/functions.sh clean_logs
sudo ./modules/system/functions.sh optimize_database
```

---

## 🌐 **Live Documentation**

### **Online Resources:**
- 🌐 **Main Site**: [https://ls.r-u.live](https://ls.r-u.live)
- 📚 **GitHub Pages**: [https://anshulyadav32.github.io/linux-setup](https://anshulyadav32.github.io/linux-setup)
- 📖 **Wiki**: [GitHub Wiki](https://github.com/anshulyadav32/linux-setup/wiki)
- 📋 **Issues**: [GitHub Issues](https://github.com/anshulyadav32/linux-setup/issues)

### **Support Channels:**
- 📧 **Email**: support@ls.r-u.live
- 🐛 **Issues**: [GitHub Issues](https://github.com/anshulyadav32/linux-setup/issues)
- 📚 **Documentation**: [ls.r-u.live/docs](https://ls.r-u.live/docs)

---

## 🤝 **Contributing**

### **Development Setup:**
```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/your-username/linux-setup.git
cd linux-setup

# Add upstream remote
git remote add upstream https://github.com/anshulyadav32/linux-setup.git
```

### **Code Standards:**
- **Shell Style**: Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Function Naming**: Use descriptive names with underscores
- **Comments**: Document complex functions and logic
- **Error Handling**: Always check return codes and handle errors
- **Logging**: Use standardized logging functions from `common.sh`

### **Pull Request Process:**
1. **Create Feature Branch**: `git checkout -b feature/your-feature`
2. **Make Changes**: Implement your feature or fix
3. **Test Thoroughly**: Run all tests and verify functionality
4. **Document Changes**: Update relevant documentation
5. **Submit PR**: Create pull request with detailed description

---

## 📄 **License**

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### **License Summary:**
- ✅ **Commercial Use**: Use in commercial projects
- ✅ **Modification**: Modify and distribute
- ✅ **Private Use**: Use privately
- ✅ **Distribution**: Distribute freely
- ❌ **Liability**: No warranty or liability
- ❌ **Patent Claims**: No patent protection

---

## 📈 **Project Statistics**

- 📊 **Lines of Code**: 10,000+ lines across all modules
- 🧩 **Components**: 45+ software components
- 🔍 **Tests**: 25+ verification checkpoints
- 📚 **Documentation**: Professional documentation
- 🌟 **GitHub Stars**: Growing community support
- 🍴 **Forks**: Active development community
- 🐛 **Issues Resolved**: Rapid issue resolution
- 📈 **Downloads**: Thousands of installations

---

**Ready to get started? Choose your installation method above and deploy your server in minutes!**

For questions, support, or contributions, visit our [GitHub repository](https://github.com/anshulyadav32/linux-setup) or [documentation site](https://ls.r-u.live).
