# 🚀 Linux Setup - Complete Server Management System

A comprehensive, enterprise-grade modular server management platform for Linux system administration. This professional solution provides automated installation, configuration, and management of web servers, databases, security tools, and complete infrastructure with **45+ components** and **25 verification checkpoints**.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-green.svg)
![Bash](https://img.shields.io/badge/shell-bash-yellow.svg)
![Status](https://img.shields.io/badge/status-production--ready-brightgreen.svg)

## 📖 **Table of Contents**
- [🏃‍♂️ Quick Start](#️-quick-start)
- [💾 Complete Installation](#-complete-installation)
- [🧩 Component Installation](#-component-installation)
- [📋 Project Components](#-project-components)
- [🛠️ Individual Modules](#️-individual-modules)
- [🔧 Configuration](#-configuration)
- [📊 Monitoring & Maintenance](#-monitoring--maintenance)
- [🌐 Live Documentation](#-live-documentation)
- [🤝 Contributing](#-contributing)

---

## �‍♂️ **Quick Start**

### **One-Line Installation (Recommended)**
```bash
# Complete automated installation with all components
curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-setup/main/install.sh | sudo bash
```

### **Manual Clone & Install**
```bash
# Clone the repository
git clone https://github.com/anshulyadav32/linux-setup.git
cd linux-setup

# Make scripts executable
chmod +x *.sh
chmod +x modules/**/*.sh

# Run complete installation
sudo ./install.sh

# Or run master management interface
sudo ./master.sh
```

---

## 💾 **Complete Installation**

### **🎯 Automated Full Stack Installation**

The `install.sh` script provides a **complete automated installation** with comprehensive verification and testing.

#### **What Gets Installed:**
- ✅ **Apache Web Server** with SSL support and performance optimization
- ✅ **PHP 8.x** with 19 essential extensions (mysql, curl, gd, mbstring, xml, zip, etc.)
- ✅ **MySQL Database** + **Redis Cache** + **SQLite** for complete database support
- ✅ **SSL/TLS certificates** with Let's Encrypt automation
- ✅ **Security stack** (UFW Firewall + Fail2Ban intrusion prevention)
- ✅ **Development tools** (Git, Node.js, NPM, Composer, editors)
- ✅ **Monitoring tools** (htop, nload, tcpdump, system monitors)
- ✅ **Performance optimization** (caching, compression, OPCache)
- ✅ **Default website** with professional dashboard

#### **Installation Process:**
```bash
# 1. Download and run the installer
sudo ./install.sh

# 2. Installation provides:
#    - Real-time progress tracking (14 major steps)
#    - Color-coded status indicators
#    - 8 comprehensive checkpoints with verification
#    - 25+ individual verification tests
#    - Detailed logging and error reporting
#    - Automatic service configuration and startup

# 3. Access your server:
#    http://localhost          - Default website
#    http://localhost/phpinfo.php - PHP configuration
```

#### **🔍 Installation Verification System:**

| Checkpoint | Verification Tests | Purpose |
|------------|-------------------|---------|
| **System Preparation** | Privileges, connectivity, disk space | Ensures installation readiness |
| **Web Server Setup** | Apache status, PHP processing, HTTP response | Validates web server functionality |
| **Database Installation** | MySQL/Redis connectivity, service status | Confirms database operations |
| **SSL Configuration** | Certbot installation, SSL modules, certificates | Verifies security infrastructure |
| **Security Setup** | Firewall status, Fail2Ban operation | Validates protection systems |
| **Performance Optimization** | Cache systems, module verification | Confirms speed enhancements |
| **Final Verification** | Complete system testing, port accessibility | Full functionality validation |

---

## 🧩 **Component Installation**

### **Individual Component Installation**

Each component can be installed separately for customized setups:

#### **Web Server Components**
```bash
# Install only web server stack
sudo ./modules/web/install.sh

# Available installation types:
# - Full: Complete web server with all features
# - Basic: Apache + PHP minimal setup
# - Development: Full stack + development tools
# - Production: Optimized for production use
# - Custom: Choose specific components
# - Minimal: Lightweight setup
```

#### **Database Components**
```bash
# Install database systems
sudo ./modules/db/install.sh

# Available databases:
# - MySQL Server (with root configuration)
# - PostgreSQL (with user setup)
# - Redis Cache Server
# - SQLite (lightweight database)
# - MongoDB (document database)
```

#### **Security Components**
```bash
# Install security tools
sudo ./modules/firewall/install.sh

# Security features:
# - UFW Firewall with rules
# - Fail2Ban intrusion prevention
# - ClamAV antivirus
# - Lynis security auditing
# - AIDE intrusion detection
```

#### **SSL Certificate Management**
```bash
# Install SSL management
sudo ./modules/ssl/install.sh

# SSL features:
# - Let's Encrypt automation
# - Self-signed certificate generation
# - Certificate renewal automation
# - Multi-domain support
# - Wildcard certificate support
```

---

## 📋 **Project Components**

### **🗂️ Core System Files**

| File | Purpose | Usage |
|------|---------|-------|
| **`install.sh`** | Complete automated installation | `sudo ./install.sh` |
| **`master.sh`** | Main management interface | `sudo ./master.sh` |
| **`setup.sh`** | Initial system setup | `sudo ./setup.sh` |
| **`system-status-checker.sh`** | System health monitoring | `./system-status-checker.sh` |
| **`quick-check.sh`** | Fast system verification | `./quick-check.sh` |

### **📁 Module Structure**

```
modules/
├── common.sh              # Shared functions library
├── interdependent.sh      # Workflow automation
├── web/                   # Web server management
│   ├── install.sh         # Web stack installation
│   ├── functions.sh       # Web management functions (2000+ lines)
│   └── menu.sh            # Web management interface
├── db/                    # Database management
│   ├── install.sh         # Database installation
│   ├── functions.sh       # Database operations
│   └── menu.sh            # Database interface
├── dns/                   # DNS server management
│   ├── install.sh         # BIND9 installation
│   ├── functions.sh       # DNS operations
│   └── menu.sh            # DNS management
├── mail/                  # Mail server management
│   ├── install.sh         # Mail stack installation
│   ├── functions.sh       # Mail operations
│   └── menu.sh            # Mail configuration
├── firewall/              # Security management
│   ├── install.sh         # Security tools
│   ├── functions.sh       # Security operations
│   └── menu.sh            # Security interface
├── ssl/                   # Certificate management
│   ├── install.sh         # SSL tools installation
│   ├── functions.sh       # Certificate operations
│   └── menu.sh            # SSL management
├── backup/                # Backup management
│   ├── install.sh         # Backup tools
│   ├── functions.sh       # Backup operations
│   └── menu.sh            # Backup interface
└── system/                # System administration
    ├── install.sh         # System tools
    ├── functions.sh       # System operations
    └── menu.sh            # System management
```

---

## 🛠️ **Individual Modules**

### **🌐 Web Server Module (`modules/web/`)**

**Purpose**: Complete web server management with Apache/Nginx, PHP, and performance optimization.

#### **Features:**
- **6 Installation Types**: Full, Basic, Development, Production, Custom, Minimal
- **Web Technologies**: Apache 2.4, Nginx, PHP 8.x with 19+ extensions
- **Language Support**: PHP, Node.js, Python frameworks
- **Performance**: OPCache, Redis, Memcached, compression
- **Security**: Hardened configurations, access controls

#### **Usage:**
```bash
# Access web management
sudo ./modules/web/menu.sh

# Menu Options:
# 1. Installation & Setup (6 options)
# 2. Website Management (5 options)  
# 3. SSL & Security (5 options)
# 4. Service Management (6 options)
# 5. Advanced Tools (6 options)
# 6. Monitoring & Maintenance (5 options)
# 7. Quick Actions (4 options)
```

#### **Key Functions:**
- **Virtual Host Creation**: Automated domain setup with SSL
- **PHP Configuration**: Version management and optimization
- **Website Deployment**: Automated deployment workflows
- **Performance Monitoring**: Real-time performance tracking
- **Security Hardening**: Automated security configurations

---

### **🗄️ Database Module (`modules/db/`)**

**Purpose**: Comprehensive database management for MySQL, PostgreSQL, Redis, and more.

#### **Features:**
- **Multiple Databases**: MySQL, PostgreSQL, Redis, SQLite, MongoDB
- **User Management**: Database users, permissions, security
- **Backup/Restore**: Automated database backups
- **Performance Tuning**: Query optimization, caching
- **Monitoring**: Database performance tracking

#### **Usage:**
```bash
# Access database management
sudo ./modules/db/menu.sh

# Capabilities:
# - Database installation and configuration
# - User and permission management  
# - Backup and restore operations
# - Performance monitoring and tuning
# - Security configuration
```

---

### **🌍 DNS Module (`modules/dns/`)**

**Purpose**: BIND9 DNS server management with zone and record operations.

#### **Features:**
- **DNS Server**: BIND9 installation and configuration
- **Zone Management**: Create, modify, delete DNS zones
- **Record Types**: A, AAAA, CNAME, MX, TXT, PTR, SRV records
- **Security**: DNSSEC, access controls, DDoS protection
- **Testing**: DNS resolution validation and diagnostics

#### **Usage:**
```bash
# Access DNS management
sudo ./modules/dns/menu.sh

# DNS Operations:
# - Zone creation and management
# - DNS record operations
# - DNSSEC configuration
# - DNS testing and validation
# - Security configurations
```

---

### **✉️ Mail Module (`modules/mail/`)**

**Purpose**: Complete mail server with Postfix, Dovecot, and security features.

#### **Features:**
- **Mail Server**: Postfix SMTP + Dovecot IMAP/POP3
- **Security**: DKIM, SPF, DMARC authentication
- **Anti-spam**: SpamAssassin, ClamAV integration
- **Encryption**: TLS/SSL encryption for all connections
- **Webmail**: Roundcube and Rainloop interfaces

#### **Usage:**
```bash
# Access mail management
sudo ./modules/mail/menu.sh

# Mail Features:
# - Mail server installation
# - User management
# - Security configuration
# - Anti-spam setup
# - Webmail installation
```

---

### **🔒 Firewall Module (`modules/firewall/`)**

**Purpose**: Advanced security management with firewall, intrusion prevention, and monitoring.

#### **Features:**
- **Firewall**: UFW with predefined security rules
- **Intrusion Prevention**: Fail2Ban with custom jails
- **Antivirus**: ClamAV with real-time scanning
- **Security Auditing**: Lynis security audits
- **Monitoring**: Real-time security monitoring

#### **Usage:**
```bash
# Access security management
sudo ./modules/firewall/menu.sh

# Security Tools:
# - Firewall configuration
# - Intrusion prevention setup
# - Security scanning and auditing
# - Log monitoring and analysis
# - Incident response
```

---

### **🔐 SSL Module (`modules/ssl/`)**

**Purpose**: SSL/TLS certificate management with Let's Encrypt automation.

#### **Features:**
- **Let's Encrypt**: Automated certificate generation and renewal
- **Self-signed Certificates**: Internal certificate creation
- **Multi-domain Support**: Wildcard and SAN certificates
- **Auto-renewal**: Automated certificate renewal
- **Integration**: Seamless web server integration

#### **Usage:**
```bash
# Access SSL management  
sudo ./modules/ssl/menu.sh

# SSL Operations:
# - Certificate generation
# - Domain validation
# - Auto-renewal setup
# - Certificate monitoring
# - Security validation
```

---

### **💾 Backup Module (`modules/backup/`)**

**Purpose**: Comprehensive backup and restore system for all server components.

#### **Features:**
- **Automated Backups**: Scheduled backups of all critical data
- **Multiple Targets**: Local, remote, cloud storage support
- **Incremental Backups**: Space-efficient backup strategies
- **Restore Operations**: Point-in-time restore capabilities
- **Monitoring**: Backup verification and alerting

#### **Usage:**
```bash
# Access backup management
sudo ./modules/backup/menu.sh

# Backup Features:
# - Backup configuration
# - Restore operations
# - Schedule management
# - Storage management
# - Monitoring and alerts
```

---

### **⚙️ System Module (`modules/system/`)**

**Purpose**: System administration tools for users, packages, and monitoring.

#### **Features:**
- **User Management**: User accounts, groups, permissions
- **Package Management**: Software installation and updates
- **System Monitoring**: Performance tracking and alerting
- **Log Management**: Centralized logging and analysis
- **Maintenance**: Automated system maintenance tasks

#### **Usage:**
```bash
# Access system management
sudo ./modules/system/menu.sh

# System Tools:
# - User administration
# - Package management
# - System monitoring
# - Log analysis
# - Maintenance automation
```

---
- **Technologies**: Postfix & Dovecot installation and configuration
- **Security**: DKIM, SPF, and DMARC configuration with security hardening
- **Features**: Mail user and domain management, spam and virus protection
- **Automation**: Automated mail server deployment with webmail interface
- **Monitoring**: Mail queue monitoring and performance optimization

#### 🗄️ **Database Management Module**
- **Technologies**: MySQL, MariaDB & PostgreSQL support
- **Features**: Database and user creation, backup and restore operations
- **Monitoring**: Performance monitoring and optimization
- **Security**: Security configuration, access controls, and encryption
- **Automation**: Automated database deployments and maintenance

#### 🔥 **Firewall Management Module**
- **Technology**: UFW (Uncomplicated Firewall) configuration
- **Security**: Fail2Ban intrusion prevention, port management
- **Features**: Security rule templates, attack monitoring
- **Automation**: Automated security hardening and rule deployment
- **Monitoring**: Real-time security monitoring and alerting

#### 🔒 **SSL Certificate Management Module**
- **Technology**: Let's Encrypt automation and management
- **Features**: Self-signed certificate generation, certificate renewal automation
- **Capabilities**: Multiple domain support, wildcard certificates
- **Security**: Security best practices, certificate monitoring
- **Automation**: Fully automated certificate lifecycle management

#### ⚙️ **System Administration Module**
- **Features**: User and group management, package management
- **Monitoring**: System monitoring, performance optimization
- **Security**: Security hardening, access controls
- **Automation**: Automated system maintenance and updates
- **Optimization**: Performance tuning and resource management

#### 💾 **Backup Management Module**
- **Features**: Automated backup scheduling, system and database backups
- **Storage**: Remote backup synchronization, multiple storage backends
- **Recovery**: Restore operations, disaster recovery planning
- **Automation**: Fully automated backup lifecycle management
- **Monitoring**: Backup verification and health monitoring

## 🎯 **Automation Workflows**

### **Web Stack Workflows**
1. **LAMP Stack**: Complete Linux + Apache + MySQL + PHP deployment
2. **LEMP Stack**: Linux + Nginx + MySQL + PHP with optimizations
3. **Node.js Stack**: Modern JavaScript backend with PM2 and monitoring
4. **Python Stack**: Django/Flask application deployment with WSGI

### **Service Workflows**
5. **Mail Server**: Complete email solution with Postfix, Dovecot, and webmail
6. **DNS Server**: Authoritative DNS with BIND9 and security features
7. **Database Server**: High-performance database deployment with replication
8. **Reverse Proxy**: Load balancing and SSL termination with Nginx

### **Management Workflows**
9. **Security Hardening**: Comprehensive security configuration and monitoring
10. **Monitoring Setup**: System and application monitoring with alerting
11. **Backup Configuration**: Automated backup systems with disaster recovery
12. **Website Deployment**: Complete website deployment with CI/CD integration

## 📦 **Installation & Deployment**

### **🚀 Complete Server Installation**
```bash
# Complete server installation with 25 checkpoints
sudo ./server-installer.sh

# Quick pre-installation check
sudo ./server-installer.sh --check

# Show installer help and options
./server-installer.sh --help
```

### **🚀 One-Line Installation**
```bash
# Complete system installation
curl -sSL ls.r-u.live/sh/s1.sh | sudo bash

# Master CLI tool
curl -sSL ls.r-u.live/sh/master-server-cli.sh | sudo bash
```

### **🔧 Manual Installation**
```bash
# Clone the repository
git clone https://github.com/anshulyadav32/linux-setup.git
cd linux-setup

# Run the comprehensive server installer
sudo ./server-installer.sh

# Start the management system
./master.sh
```

### **🧪 Testing & Validation**
```bash
# Quick installation status check
./quick-check.sh

# Comprehensive system status checker
./system-status-checker.sh

# Detailed installation testing
sudo ./test-installation.sh --status

# Run comprehensive tests
sudo ./test-installation.sh --test-all

# View detailed logs
sudo ./test-installation.sh --logs
```

## 🔍 **Installation Status Checkers**

### **🚀 Quick Status Check**
```bash
# Fast overview of installation status
./quick-check.sh

# Shows:
# ✓ Web Servers (Nginx, Apache, PHP)
# ✓ Database Servers (MySQL, PostgreSQL) 
# ✓ Mail Servers (Postfix, Dovecot)
# ✓ DNS & Security (BIND9, Fail2Ban, UFW)
# ✓ Essential Tools (Git, Node.js, Certbot)
# 📊 Installation completion percentage
```

### **🔬 Comprehensive System Checker**
```bash
# Detailed analysis of all components
./system-status-checker.sh

# Available options:
./system-status-checker.sh --help     # Show all options
./system-status-checker.sh --quick    # Quick essential check
./system-status-checker.sh --services # Service status only
./system-status-checker.sh --packages # Package installation only
```

### **📊 What Gets Checked**
- **✅ Web Servers**: Nginx, Apache, PHP-FPM with version info and port status
- **✅ Database Servers**: MySQL, PostgreSQL with service status and connectivity
- **✅ Mail Servers**: Postfix, Dovecot with SMTP/IMAP port verification
- **✅ DNS Server**: BIND9 with configuration validation
- **✅ Security Tools**: UFW firewall status, Fail2Ban, Certbot SSL tools
- **✅ Monitoring Tools**: htop, iotop, nethogs, network monitoring tools
- **✅ Development Tools**: Git, Node.js, Python, package managers
- **✅ Backup Systems**: rsync, duplicity, archive tools
- **✅ System Configuration**: Limits, kernel parameters, cron jobs
- **✅ Management Modules**: All 8 service modules and system commands

### **📋 Status Report Features**
- **Color-coded output** with clear status indicators (✓, ✗, ⚠)
- **Installation percentage** showing completion status
- **Service health** verification with version information
- **Port connectivity** testing for all services
- **Configuration validation** for critical system files
- **Automated recommendations** for fixing issues
- **Detailed logging** with timestamps for troubleshooting
- **Exit codes** for scripting integration

## 📁 **Project Structure**

```
linux-setup/
├── server-installer.sh          # Complete server installer with 25 comprehensive checkpoints
├── system-status-checker.sh     # 🆕 Comprehensive installation status checker
├── quick-check.sh               # 🆕 Quick installation status verification
├── test-installation.sh         # Testing framework and checkpoint management
├── master.sh                    # Main entry point and system controller
├── setup.sh                     # Initial system setup and prerequisites
├── README.md                    # This comprehensive documentation
├── QUICK_START.md              # Quick start guide and common tasks
├── _config.yml                 # Project configuration
├── .gitignore                  # Git ignore patterns
├── logs/                       # System logs and installation history
│   └── .gitkeep
├── backups/                    # Backup storage and recovery files
│   └── .gitkeep
├── configs/                    # Configuration templates and files
│   └── .gitkeep
├── website/                    # Professional documentation website
│   ├── index.html              # Main homepage
│   ├── _config.yml             # Jekyll configuration
│   ├── CNAME                   # Custom domain configuration
│   ├── robots.txt              # SEO configuration
│   ├── README.md               # Website documentation
│   ├── docs/                   # Documentation pages
│   │   └── index.html          # Comprehensive system documentation
│   ├── sh/                     # Installation scripts and examples
│   │   └── index.html          # Installation scripts showcase
│   ├── assets/                 # Website assets
│   │   ├── css/                # Stylesheets
│   │   ├── js/                 # JavaScript and domain switcher
│   │   └── images/             # Images and graphics
│   ├── _layouts/               # Jekyll layout templates
│   └── _includes/              # Jekyll partial templates
└── modules/                    # Modular service architecture
    ├── common.sh               # Shared library with utility functions
    ├── interdependent.sh       # Automation workflow orchestrator
    ├── web/                    # Web server management module
    │   ├── functions.sh        # Web module core functions
    │   ├── install.sh          # Installation and setup scripts
    │   ├── maintain.sh         # Maintenance and update operations
    │   ├── update.sh           # Update and upgrade procedures
    │   └── menu.sh             # Interactive management interface
    ├── dns/                    # DNS server management module
    │   ├── functions.sh        # DNS module core functions
    │   ├── install.sh          # BIND9 installation and configuration
    │   ├── maintain.sh         # Zone and record management
    │   ├── update.sh           # DNS server updates and security
    │   └── menu.sh             # DNS management interface
    ├── mail/                   # Mail server management module
    │   ├── functions.sh        # Mail module core functions
    │   ├── install.sh          # Postfix/Dovecot installation
    │   ├── maintain.sh         # Mail server maintenance
    │   ├── update.sh           # Mail server updates and security
    │   └── menu.sh             # Mail management interface
    ├── db/                     # Database management module
    │   ├── functions.sh        # Database module core functions
    │   ├── install.sh          # Database server installation
    │   ├── maintain.sh         # Database maintenance and optimization
    │   ├── update.sh           # Database updates and security
    │   └── menu.sh             # Database management interface
    ├── firewall/               # Firewall and security module
    │   ├── functions.sh        # Security module core functions
    │   ├── install.sh          # Firewall and security setup
    │   ├── maintain.sh         # Security maintenance and monitoring
    │   ├── update.sh           # Security updates and hardening
    │   └── menu.sh             # Security management interface
    ├── ssl/                    # SSL certificate management module
    │   ├── functions.sh        # SSL module core functions
    │   ├── install.sh          # Certificate authority setup
    │   ├── maintain.sh         # Certificate management and renewal
    │   ├── update.sh           # SSL updates and security
    │   └── menu.sh             # Certificate management interface
    ├── system/                 # System administration module
    │   ├── functions.sh        # System module core functions
    │   ├── install.sh          # System optimization and setup
    │   ├── maintain.sh         # System maintenance and monitoring
    │   ├── update.sh           # System updates and optimization
    │   └── menu.sh             # System management interface
    └── backup/                 # Backup and recovery module
        ├── functions.sh        # Backup module core functions
        ├── install.sh          # Backup system setup
        ├── maintain.sh         # Backup operations and monitoring
        ├── update.sh           # Backup system updates
        └── menu.sh             # Backup management interface
```

## 🌐 **Website & Documentation**

### **Dual-Domain Access**
- **Primary Domain**: [https://ls.r-u.live](https://ls.r-u.live)
- **GitHub Pages Mirror**: [https://anshulyadav32.github.io/linux-setup](https://anshulyadav32.github.io/linux-setup)

### **Professional Documentation**
- **Homepage**: Complete system overview and features showcase
- **Installation Scripts**: `/sh/` - One-line installation commands and examples
- **Documentation**: `/docs/` - Comprehensive guides, tutorials, and troubleshooting
- **Domain Switcher**: Automatic domain switching with professional notifications

### **Website Features**
- **Responsive Design**: Professional, mobile-friendly interface
- **Smart Copy-to-Clipboard**: Domain-aware URL copying for installation commands
- **SEO Optimized**: Enhanced search engine visibility and performance
- **Professional Branding**: Consistent enterprise-grade messaging and design

## 🛠️ **Installation & Setup**

### **System Requirements**
- **Operating System**: Ubuntu 18.04+ or Debian 10+ (recommended)
- **Privileges**: Root or sudo access
- **Network**: Internet connectivity for package downloads
- **Resources**: Minimum 1GB RAM, 10GB disk space
- **Knowledge**: Basic understanding of Linux server administration

### **🚀 Quick Installation (Recommended)**

#### **Complete System Installation**
```bash
# One-line installation with all modules and dependencies
curl -sSL ls.r-u.live/sh/s1.sh | sudo bash
```

#### **Master CLI Tool Installation**
```bash
# Install the master CLI for direct system access
curl -sSL ls.r-u.live/sh/master-server-cli.sh | sudo bash
```

### **📋 Manual Installation**

#### **Step 1: Clone Repository**
```bash
# Clone the repository
git clone https://github.com/anshulyadav32/linux-setup.git
cd linux-setup

# Make scripts executable
chmod +x install-server.sh test-installation.sh master.sh setup.sh
```

#### **Step 2: Run Comprehensive Installer**
```bash
# Install all dependencies and modules
sudo ./install-server.sh

# This will run through all 12 checkpoints:
# 1. System requirements validation
# 2. Package manager updates  
# 3. Core dependency installation
# 4. Service module downloads
# 5. Configuration file setup
# 6. Database initialization
# 7. Security configuration
# 8. SSL certificate setup
# 9. Service activation
# 10. Firewall configuration
# 11. Testing and validation
# 12. Final optimization
```

#### **Step 3: Start the System**
```bash
# Launch the main management interface
./master.sh
```

### **🔧 Installation Management**

#### **Checkpoint System**
```bash
# Check installation status
sudo ./test-installation.sh --status

# Resume from specific checkpoint (if interrupted)
sudo ./install-server.sh --resume-from 5

# Reset installation and start fresh
sudo ./test-installation.sh --reset

# View detailed installation logs
sudo ./test-installation.sh --logs
```

#### **Testing & Validation**
```bash
# Run comprehensive system tests
sudo ./test-installation.sh --test-all

# Test specific modules
sudo ./test-installation.sh --test-module web
sudo ./test-installation.sh --test-module mail

# Performance testing
sudo ./test-installation.sh --performance
```

## 🚀 **Quick Start Guide**

### **Basic System Operation**

#### **Main Menu Access**
```bash
# Launch the main management interface
./master.sh
```
- Interactive main menu with all 8 modules
- System prerequisites check and validation
- Color-coded navigation and status indicators
- Professional error handling and logging

#### **Individual Module Access**
```bash
# Access specific modules directly
./modules/web/menu.sh      # Web server management
./modules/dns/menu.sh      # DNS server management  
./modules/mail/menu.sh     # Mail server management
./modules/db/menu.sh       # Database management
./modules/firewall/menu.sh # Security and firewall
./modules/ssl/menu.sh      # SSL certificate management
./modules/system/menu.sh   # System administration
./modules/backup/menu.sh   # Backup and recovery
```

#### **Automated Workflows**
```bash
# Access pre-configured automation workflows
./modules/interdependent.sh
```
- 12 professional automation workflows
- LAMP/LEMP stack deployments
- Complete mail server setup
- Full website deployment with CI/CD
- Security hardening and monitoring

### **Common Deployment Scenarios**

#### **🌐 Deploy a LAMP Stack**
1. Run `./master.sh`
2. Choose "Interdependent Automation"
3. Select "Full LAMP Stack Setup"
4. Follow prompts for domain and database configuration
5. System automatically configures Apache, MySQL, PHP with SSL

#### **✉️ Setup a Complete Mail Server**
1. Run `./master.sh`
2. Choose "Interdependent Automation"
3. Select "Complete Mail Server Setup"
4. Provide domain and administrator details
5. System configures Postfix, Dovecot, DKIM, SPF, DMARC

#### **🔒 Deploy with Enhanced Security**
1. Run `./master.sh`
2. Choose "Interdependent Automation"
3. Select "Security Hardening Workflow"
4. System applies enterprise security configurations
5. Automated firewall, fail2ban, and monitoring setup

#### **🗄️ Database Server Deployment**
1. Run `./master.sh`
2. Choose "Database Management"
3. Select database type (MySQL/PostgreSQL)
4. Configure users, databases, and security
5. Automated backup and monitoring setup

## 🔧 **Advanced Usage**

### **Custom Automation Workflows**
```bash
# Create custom workflow
nano modules/custom-workflow.sh

# Test custom workflow
sudo ./test-installation.sh --test-workflow custom

# Deploy custom configuration
./modules/interdependent.sh --custom-config
```

### **Module Customization**
```bash
# Edit module configurations
sudo nano modules/web/config.conf
sudo nano modules/mail/mail.conf
sudo nano modules/db/database.conf

# Apply custom configurations
./modules/web/install.sh --custom-config
```

### **System Monitoring & Maintenance**
```bash
# Check system health
./master.sh --health-check

# View system logs
./master.sh --view-logs

# Update all modules
./master.sh --update-all

# Backup system configuration
./modules/backup/menu.sh --backup-config
```

## 🔒 **Security Features**

### **Enterprise Security Implementation**
- **System Hardening**: Automated security configurations following industry best practices
- **Firewall Management**: Advanced UFW/iptables with fail2ban intrusion prevention
- **SSL/TLS Automation**: Let's Encrypt integration with automatic certificate renewal
- **Access Control**: Role-based access control with privilege escalation protection
- **Audit Logging**: Comprehensive logging and monitoring with real-time alerts

### **Security Validation**
```bash
# Run comprehensive security audit
sudo ./modules/firewall/security-audit.sh

# Check SSL certificate status
sudo ./modules/ssl/check-certificates.sh

# Review security logs and alerts
sudo ./modules/system/review-logs.sh

# Test firewall configuration
sudo ./modules/firewall/test-rules.sh
```

## 📊 **Monitoring & Maintenance**

### **System Health Monitoring**
- **Real-time Monitoring**: System performance, resource usage, and service health
- **Automated Alerts**: Email and log-based notifications for critical events
- **Performance Optimization**: Automated performance tuning and resource management
- **Log Analysis**: Comprehensive log aggregation and analysis tools

### **Maintenance Operations**
```bash
# System health check
./master.sh --health-check

# Update all modules and dependencies
./master.sh --update-all

# Optimize system performance
./modules/system/optimize.sh

# Generate system reports
./modules/system/generate-report.sh
```

## 🆘 **Support & Troubleshooting**

### **Documentation Resources**
- **Online Documentation**: [ls.r-u.live/docs](https://ls.r-u.live/docs)
- **Installation Guides**: [ls.r-u.live/sh](https://ls.r-u.live/sh)
- **GitHub Repository**: [github.com/anshulyadav32/linux-setup](https://github.com/anshulyadav32/linux-setup)

### **Common Issues & Solutions**
```bash
# Re-run installation if issues occur
sudo ./server-installer.sh

# Check system compatibility
sudo ./server-installer.sh --check

# View installation logs
sudo ./test-installation.sh --logs

# Test specific modules
sudo ./test-installation.sh --test-module MODULE_NAME

# Service not starting
sudo ./modules/MODULE_NAME/test.sh --status
sudo ./modules/MODULE_NAME/test.sh --logs

# Performance issues
sudo ./modules/system/test.sh --performance
sudo ./modules/system/configure.sh --optimize
```

### **Getting Help**
- **GitHub Issues**: Report bugs and request features
- **Documentation**: Comprehensive guides and troubleshooting
- **Community Support**: Professional community assistance
- **Diagnostic Tools**: Built-in diagnostic and testing tools

## 📈 **Project Status & Roadmap**

### **Current Version Features**
- ✅ 8 Complete Service Modules
- ✅ 12 Automation Workflows  
- ✅ 12-Checkpoint Installation System
- ✅ Professional Documentation Website
- ✅ Dual-Domain Support
- ✅ Enterprise Security Features
- ✅ Comprehensive Testing Framework

### **Upcoming Features**
- 🔄 Windows PowerShell Version
- 🔄 Container/Docker Support
- 🔄 Cloud Provider Integration
- 🔄 Advanced Monitoring Dashboard
- 🔄 API Integration Support
- 🔄 Multi-Server Management

## 🤝 **Contributing**

We welcome contributions to the Linux Setup project! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

### **How to Contribute**
1. **Fork the Repository**: Create your own fork of the project
2. **Create Feature Branch**: `git checkout -b feature/amazing-feature`
3. **Make Changes**: Implement your improvements
4. **Test Thoroughly**: Ensure all tests pass
5. **Submit Pull Request**: Describe your changes and improvements

### **Development Guidelines**
- Follow existing code style and conventions
- Add comprehensive tests for new features
- Update documentation for any changes
- Ensure compatibility with supported Linux distributions

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- **Community Contributors**: Thanks to all contributors who help improve this project
- **Open Source Projects**: Built on the foundation of excellent open source tools
- **Linux Community**: Dedicated to the professional Linux server administration community
- **Security Community**: Following best practices from security professionals

---

## 📞 **Contact & Links**

- **Website**: [ls.r-u.live](https://ls.r-u.live)
- **GitHub**: [github.com/anshulyadav32/linux-setup](https://github.com/anshulyadav32/linux-setup)
- **Documentation**: [ls.r-u.live/docs](https://ls.r-u.live/docs)
- **Installation**: [ls.r-u.live/sh](https://ls.r-u.live/sh)

---

**Linux Setup - Modular Server Management System**  
*Professional server management made simple*

## 🛠️ **Installation & Setup**

### **System Requirements**
- **Operating System**: Ubuntu 18.04+ or Debian 10+ (recommended)
- **Privileges**: Root or sudo access
- **Network**: Internet connectivity for package downloads
- **Resources**: Minimum 1GB RAM, 10GB disk space
- **Knowledge**: Basic understanding of Linux server administration

### **🚀 Quick Installation (Recommended)**

#### **Complete System Installation**
```bash
# One-line installation with all modules and dependencies
curl -sSL ls.r-u.live/sh/s1.sh | sudo bash
```

#### **Master CLI Tool Installation**
```bash
# Install the master CLI for direct system access
curl -sSL ls.r-u.live/sh/master-server-cli.sh | sudo bash
```

### **📋 Manual Installation**

#### **Step 1: Clone Repository**
```bash
# Clone the repository
git clone https://github.com/anshulyadav32/linux-setup.git
cd linux-setup

# Make scripts executable
chmod +x install-server.sh test-installation.sh master.sh setup.sh
```

#### **Step 2: Run Comprehensive Installer**
```bash
# Install all dependencies and modules
sudo ./install-server.sh

# This will run through all 12 checkpoints:
# 1. System requirements validation
# 2. Package manager updates  
# 3. Core dependency installation
# 4. Service module downloads
# 5. Configuration file setup
# 6. Database initialization
# 7. Security configuration
# 8. SSL certificate setup
# 9. Service activation
# 10. Firewall configuration
# 11. Testing and validation
# 12. Final optimization
```

#### **Step 3: Start the System**
```bash
# Launch the main management interface
./master.sh
```

### **🔧 Installation Management**

#### **Checkpoint System**
```bash
# Check installation status
sudo ./test-installation.sh --status

# Resume from specific checkpoint (if interrupted)
sudo ./install-server.sh --resume-from 5

# Reset installation and start fresh
sudo ./test-installation.sh --reset

# View detailed installation logs
sudo ./test-installation.sh --logs
```

#### **Testing & Validation**
```bash
# Run comprehensive system tests
sudo ./test-installation.sh --test-all

# Test specific modules
sudo ./test-installation.sh --test-module web
sudo ./test-installation.sh --test-module mail

# Performance testing
sudo ./test-installation.sh --performance
```

## 🚀 **Quick Start Guide**

### **Basic System Operation**

#### **Main Menu Access**
```bash
# Launch the main management interface
./master.sh
```
- Interactive main menu with all 8 modules
- System prerequisites check and validation
- Color-coded navigation and status indicators
- Professional error handling and logging

#### **Individual Module Access**
```bash
# Access specific modules directly
./modules/web/menu.sh      # Web server management
./modules/dns/menu.sh      # DNS server management  
./modules/mail/menu.sh     # Mail server management
./modules/db/menu.sh       # Database management
./modules/firewall/menu.sh # Security and firewall
./modules/ssl/menu.sh      # SSL certificate management
./modules/system/menu.sh   # System administration
./modules/backup/menu.sh   # Backup and recovery
```

#### **Automated Workflows**
```bash
# Access pre-configured automation workflows
./modules/interdependent.sh
```
- 12 professional automation workflows
- LAMP/LEMP stack deployments
- Complete mail server setup
- Full website deployment with CI/CD
- Security hardening and monitoring

### **Common Deployment Scenarios**

#### **🌐 Deploy a LAMP Stack**
1. Run `./master.sh`
2. Choose "Interdependent Automation"
3. Select "Full LAMP Stack Setup"
4. Follow prompts for domain and database configuration
5. System automatically configures Apache, MySQL, PHP with SSL

#### **✉️ Setup a Complete Mail Server**
1. Run `./master.sh`
2. Choose "Interdependent Automation"
3. Select "Complete Mail Server Setup"
4. Provide domain and administrator details
5. System configures Postfix, Dovecot, DKIM, SPF, DMARC

#### **🔒 Deploy with Enhanced Security**
1. Run `./master.sh`
2. Choose "Interdependent Automation"
3. Select "Security Hardening Workflow"
4. System applies enterprise security configurations
5. Automated firewall, fail2ban, and monitoring setup

#### **🗄️ Database Server Deployment**
1. Run `./master.sh`
2. Choose "Database Management"
3. Select database type (MySQL/PostgreSQL)
4. Configure users, databases, and security
5. Automated backup and monitoring setup

## 🔧 **Advanced Usage**

### **Custom Automation Workflows**
```bash
# Create custom workflow
nano modules/custom-workflow.sh

# Test custom workflow
sudo ./test-installation.sh --test-workflow custom

# Deploy custom configuration
./modules/interdependent.sh --custom-config
```

### **Module Customization**
```bash
# Edit module configurations
sudo nano modules/web/config.conf
sudo nano modules/mail/mail.conf
sudo nano modules/db/database.conf

# Apply custom configurations
./modules/web/install.sh --custom-config
```

### **System Monitoring & Maintenance**
```bash
# Check system health
./master.sh --health-check

# View system logs
./master.sh --view-logs

# Update all modules
./master.sh --update-all

# Backup system configuration
./modules/backup/menu.sh --backup-config
```
2. Choose "Interdependent Automation"
3. Select "Complete Mail Server Setup"
4. Configure domain, DNS, and user accounts

#### Deploy Website with SSL
1. Run `./master.sh`
2. Choose "Interdependent Automation"
3. Select "Full Website Deploy"
4. Configure domain, SSL, and security settings

## 🔧 Advanced Configuration

### Module Customization

Each module can be customized by editing its `functions.sh` file:

```bash
# Web module customization
nano modules/web/functions.sh

# DNS module customization
nano modules/dns/functions.sh
```

### Automation Workflows

Create custom automation workflows in `modules/interdependent.sh`:

```bash
# Add custom workflow function
setup_custom_stack() {
    # Your custom automation logic
}
```

### Common Library Extension

Extend shared functionality in `modules/common.sh`:

```bash
# Add custom validation function
validate_custom_input() {
    # Your validation logic
}
```

## 📊 Monitoring & Maintenance

### Log Management
- All operations are logged to `logs/` directory
- Structured logging with timestamps and severity levels
- Automatic log rotation and cleanup

### Health Checks
- Built-in system health monitoring
- Service status verification
- Performance metrics collection

### Backup Management
- Automated backup scheduling
- Multiple backup strategies (daily, weekly, monthly)
- Easy restore operations

## 🔒 Security Features

### Security Hardening
- SSH configuration hardening
- Firewall configuration
- Intrusion detection and prevention
- SSL/TLS encryption enforcement

### Access Control
- User and group management
- Permission validation
- Audit logging
- Security policy enforcement

## 🐛 Troubleshooting

### Common Issues

1. **Permission Denied:**
   ```bash
   chmod +x master.sh
   chmod +x modules/*/menu.sh
   ```

2. **Module Not Found:**
   ```bash
   # Verify directory structure
   ls -la modules/
   
   # Check file permissions
   find modules/ -name "*.sh" -exec ls -la {} \;
   ```

3. **Service Installation Failed:**
   ```bash
   # Check system requirements
   ./setup.sh
   
   # Review logs
   tail -f logs/install.log
   ```

### Log Analysis
```bash
# View recent logs
tail -f logs/system.log

# Search for errors
grep -i error logs/*.log

# Check service status
systemctl status <service-name>
```

## 🤝 Contributing

### Development Guidelines
1. Follow the established modular pattern
2. Use the common library for shared functionality
3. Implement comprehensive error handling
4. Add logging for all operations
5. Test on Ubuntu/Debian systems

### Adding New Modules
1. Create module directory: `modules/newmodule/`
2. Implement required scripts: `functions.sh`, `install.sh`, `maintain.sh`, `update.sh`, `menu.sh`
3. Source common library: `source "../common.sh"`
4. Update interdependent workflows as needed

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

### Documentation
- Quick Start Guide: `QUICK_START.md`
- Module-specific documentation in each module directory
- Inline code documentation and comments

### Community Support
- Issue tracking via GitHub Issues
- Wiki documentation
- Community forums

### Professional Support
- Enterprise deployment assistance
- Custom module development
- Training and consultation services

## 🙏 Acknowledgments

## 🔧 **Configuration & Customization**

### **Environment Configuration**

#### **System Requirements:**
- **Operating System**: Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+
- **Memory**: Minimum 1GB RAM (2GB+ recommended)
- **Storage**: Minimum 2GB free space (10GB+ recommended)
- **Network**: Internet connectivity for package downloads
- **Privileges**: Root/sudo access required

#### **Pre-Installation Setup:**
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
sudo yum update -y                      # CentOS/RHEL

# Install git (if not present)
sudo apt install git -y                 # Ubuntu/Debian
sudo yum install git -y                 # CentOS/RHEL

# Clone repository
git clone https://github.com/anshulyadav32/linux-setup.git
cd linux-setup
```

### **Configuration Files Structure**

#### **Main Configuration:**
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

### **Customization Options**

#### **Installation Customization:**
```bash
# Custom installation with specific components
sudo ./install.sh --components="web,db,ssl" --type="production"

# Available components: web, db, dns, mail, firewall, ssl, backup, system
# Available types: full, basic, development, production, minimal, custom
```

---

## 📊 **Monitoring & Maintenance**

### **System Health Monitoring**

#### **Real-time System Check:**
```bash
# Comprehensive system status
sudo ./system-status-checker.sh

# Quick health check
./quick-check.sh

# Service-specific monitoring
sudo ./modules/web/functions.sh monitor_services
sudo ./modules/db/functions.sh check_database_health
```

#### **Performance Monitoring:**
```bash
# Web server performance
sudo ./modules/web/functions.sh show_performance_stats

# Database performance
sudo ./modules/db/functions.sh show_db_performance

# System resource monitoring
sudo ./modules/system/functions.sh monitor_resources
```

### **Log Management**

#### **Centralized Logging:**
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

---

## 🌐 **Live Documentation & Support**

### **Online Resources:**

#### **Primary Documentation Sites:**
- 🌐 **Main Site**: [https://ls.r-u.live](https://ls.r-u.live)
- 📚 **GitHub Pages**: [https://anshulyadav32.github.io/linux-setup](https://anshulyadav32.github.io/linux-setup)
- 📖 **Wiki**: [GitHub Wiki](https://github.com/anshulyadav32/linux-setup/wiki)
- 📋 **Issues**: [GitHub Issues](https://github.com/anshulyadav32/linux-setup/issues)

#### **Documentation Structure:**
- **Installation Guides**: Step-by-step installation instructions
- **Module Documentation**: Detailed documentation for each module
- **API Reference**: Function and command reference
- **Troubleshooting**: Common issues and solutions
- **Best Practices**: Security and performance recommendations

### **Getting Help:**

#### **Support Channels:**
- 📧 **Email**: support@ls.r-u.live
- 🐛 **Issues**: [GitHub Issues](https://github.com/anshulyadav32/linux-setup/issues)
- 📚 **Documentation**: [ls.r-u.live/docs](https://ls.r-u.live/docs)

---

## 🤝 **Contributing**

### **Development Setup**

#### **Fork & Clone:**
```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/your-username/linux-setup.git
cd linux-setup

# Add upstream remote
git remote add upstream https://github.com/anshulyadav32/linux-setup.git
```

### **Contribution Guidelines**

#### **Code Standards:**
- **Shell Style**: Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Function Naming**: Use descriptive names with underscores
- **Comments**: Document complex functions and logic
- **Error Handling**: Always check return codes and handle errors
- **Logging**: Use standardized logging functions from `common.sh`

#### **Pull Request Process:**
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

## 🏆 **Acknowledgments**

### **Contributors:**
- **Anshul Yadav** - Project Creator & Lead Developer
- **Community Contributors** - Feature additions and bug fixes
- **Security Researchers** - Security improvements and audits
- **Documentation Team** - Documentation and guides

### **Technologies Used:**
- **Bash/Shell Scripting** - Core automation
- **Apache/Nginx** - Web servers
- **MySQL/PostgreSQL** - Databases
- **Let's Encrypt** - SSL certificates
- **UFW/Fail2Ban** - Security tools
- **GitHub Pages** - Documentation hosting

### **Special Thanks:**
- Linux community for testing and feedback
- Security community for vulnerability reports
- Open source projects that inspire this work
- Users who provide valuable feedback and suggestions

---

## 📈 **Project Statistics**

- 📊 **Lines of Code**: 10,000+ lines across all modules
- 🧩 **Components**: 45+ software components
- 🔍 **Tests**: 25+ verification checkpoints
- 📚 **Documentation**: 50+ pages of documentation
- 🌟 **GitHub Stars**: Growing community support
- 🍴 **Forks**: Active development community
- 🐛 **Issues Resolved**: Rapid issue resolution
- 📈 **Downloads**: Thousands of installations

---

**Ready to get started? Choose your installation method above and deploy your server in minutes!**

For questions, support, or contributions, visit our [GitHub repository](https://github.com/anshulyadav32/linux-setup) or [documentation site](https://ls.r-u.live).
