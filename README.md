# 🚀 Linux Setup - Complete Server Management System

A comprehensive, enterprise-grade modular server management platform for Linux system administration. This professional solution provides automated installation, configuration, and management of essential server infrastructure with **5 core modules**, **25+ components** and **professional verification systems**.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-green.svg)
![Bash](https://img.shields.io/badge/shell-bash-yellow.svg)
![Status](https://img.shields.io/badge/status-production--ready-brightgreen.svg)

## 📖 **Table of Contents**
- [📘 Introduction](#-introduction)
- [⚡ Installation Methods](#-installation-methods)
- [🧩 Components & Modules](#-components--modules)
- [🔧 Configuration](#-configuration)
- [📊 Monitoring & Maintenance](#-monitoring--maintenance)
- [🌐 Live Documentation](#-live-documentation)
- [🤝 Contributing](#-contributing)

---

## 📘 **Introduction**

Linux Setup is a **complete server management platform** that automates the installation and configuration of enterprise-grade server infrastructure. Whether you're deploying SSL certificates, mail servers, databases, security systems, or backup solutions, this system provides the tools and automation you need.

### **🎯 What This Project Does:**
- **Automated Installation**: Deploy complete server stacks in minutes
- **Modular Architecture**: 5 specialized modules for essential server components
- **Enterprise Security**: Built-in security hardening and monitoring
- **Professional Management**: CLI-based management interfaces with colored output
- **Production Ready**: Tested configurations for production environments

### **🏆 Key Features:**
- ✅ **25+ Components** automatically installed and configured
- ✅ **Professional Verification** systems ensure everything works perfectly
- ✅ **5 Specialized Modules** for complete server management
- ✅ **Real-time Progress Tracking** with color-coded status
- ✅ **Enterprise Security** with automated hardening
- ✅ **Professional Documentation** with live support

---

## ⚡ **Installation Methods**

### **🔥 Quick Installation Methods**

#### **⚡ One-Line Remote Installation:**
```bash
# Install complete server stack from live repository
curl -sSL ls.r-u.live/sh/s1.sh | sudo bash
```

#### **📦 Local Installation:**
```bash
# Clone and install locally
git clone https://github.com/anshulyadav32/linux-setup.git
cd linux-setup
sudo ./install.sh
```

**What this does:**
- Downloads and runs the automated installer
- Installs all 25+ components with verification
- Configures security, SSL, and performance optimization
- Creates professional server management system
- Takes 10-15 minutes for complete setup

#### **🔧 Individual Module Installation:**
```bash
# Each module includes the quick install command
# SSL Module
./modules/ssl/install.sh

# Mail Module  
./modules/mail/install.sh

# Database Module
./modules/database/install.sh

# Firewall Module
./modules/firewall/install.sh

# Backup Module
./modules/backup/install.sh
```

#### **Quick Component Install:**
```bash
# Install specific components only
curl -sSL ls.r-u.live/sh/s1.sh | sudo bash -s -- --components="ssl,mail,database"
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

The system is organized into **5 specialized modules**, each handling essential server components:

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

### **🗄️ Database Module**
**Purpose**: Comprehensive database management for PostgreSQL, MariaDB, and MongoDB.

#### **Components:**
- **PostgreSQL** advanced relational database
- **MariaDB** MySQL-compatible database
- **MongoDB** NoSQL document database
- **Database backup** and restore tools
- **Performance monitoring** and optimization

#### **Quick Guide:**
```bash
# Install database components
sudo ./modules/database/install.sh

# Access database management
sudo ./modules/database/menu.sh

# Quick actions:
# 1. Install PostgreSQL     → Option 1
# 2. Install MariaDB        → Option 2
# 3. Install MongoDB        → Option 3
# 4. Setup database backup  → Option 4
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
├── ssl.conf             # SSL/TLS settings
├── mail.conf            # Mail server configuration
├── database.conf        # Database settings
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
sudo ./modules/ssl/functions.sh monitor_certificates
sudo ./modules/database/functions.sh check_database_health
sudo ./modules/firewall/functions.sh check_security_status
```

### **Log Management:**
```bash
# System logs location
/var/log/linux-setup/
├── installation.log     # Installation progress and errors
├── ssl.log             # SSL certificate operations
├── mail.log            # Mail server operations
├── database.log        # Database operations
├── security.log        # Security events
├── backup.log          # Backup operations
└── system.log          # System administration
```

### **Maintenance Tasks:**
```bash
# Weekly maintenance (runs automatically via cron)
sudo ./modules/backup/functions.sh weekly_maintenance

# Manual maintenance tasks
sudo ./modules/ssl/functions.sh renew_certificates
sudo ./modules/database/functions.sh optimize_database
sudo ./modules/firewall/functions.sh update_security_rules
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

- 📊 **Lines of Code**: 6,000+ lines across all modules
- 🧩 **Components**: 25+ software components
- 🔍 **Tests**: Professional verification systems
- 📚 **Documentation**: Professional documentation
- 🌟 **GitHub Stars**: Growing community support
- 🍴 **Forks**: Active development community
- 🐛 **Issues Resolved**: Rapid issue resolution
- 📈 **Downloads**: Growing installation base

---

**Ready to get started? Choose your installation method above and deploy your server in minutes!**

For questions, support, or contributions, visit our [GitHub repository](https://github.com/anshulyadav32/linux-setup) or [documentation site](https://ls.r-u.live).
