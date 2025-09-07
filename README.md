# Linux Setup - Modular Server Management System

A comprehensive, enterprise-grade server management system built with modular Bash scripts for Linux server administration. This professional solution provides a cohesive architecture with standardized interfaces, shared libraries, automated workflows, and a **25-checkpoint comprehensive installation system** for complete server setup and maintenance.

## 🌟 **Project Overview**

**Linux Setup** is more than just a collection of scripts—it's a complete infrastructure management platform designed for modern server administration. Whether you're deploying a single web server or managing complex multi-service environments, this system provides the tools and automation you need.

### 🏆 **Key Highlights**
- **Professional Architecture**: Enterprise-grade modular design with 8 specialized service modules
- **Advanced Installation**: Complete **server-installer.sh** with 25 comprehensive checkpoints and visual progress tracking
- **Automation Workflows**: 12 pre-configured workflows for common server deployments
- **Dual-Domain Website**: Professional documentation at [ls.r-u.live](https://ls.r-u.live) and [anshulyadav32.github.io/linux-setup](https://anshulyadav32.github.io/linux-setup)
- **One-Line Installation**: Simple deployment with comprehensive dependency checking
- **Enterprise Security**: Built-in security hardening, SSL automation, and intrusion prevention

## 🚀 **Features & Capabilities**

### **Core Architecture**
- **Modular Design**: 8 specialized service modules with standardized interfaces
- **Shared Library (`common.sh`)**: Centralized functions for logging, validation, and user interaction
- **Interdependent Automation**: Pre-configured workflows for complex server setups
- **Professional UI**: Color-coded menus with comprehensive error handling
- **Checkpoint System**: 12-step installation process with automatic resume capability

### **Installation System**
- **Comprehensive Server Installer** (`server-installer.sh`): Complete server setup with 25 installation checkpoints
- **Advanced Progress Tracking**: Real-time progress bar with step-by-step checkpoint verification
- **Enterprise Logging**: Detailed installation logs with error handling and recovery options
- **Multi-Distribution Support**: Ubuntu, Debian, CentOS, RHEL, Fedora compatibility
- **Testing Framework** (`test-installation.sh`): Validates installations and manages checkpoints
- **One-Line Deployment**: `curl -sSL ls.r-u.live/sh/s1.sh | sudo bash`

### **Service Modules**

#### 🌐 **Web Server Management Module**
- **Technologies**: Apache & Nginx installation and configuration
- **Language Support**: PHP, Node.js, Python, and static sites
- **Features**: Virtual host management, SSL integration, performance optimization
- **Security**: Hardened configurations, access controls, and monitoring
- **Automation**: Automated deployments, updates, and maintenance

#### 🌍 **DNS Server Management Module**
- **Technology**: BIND9 installation and configuration
- **Capabilities**: Zone creation and management, DNS record operations (A, AAAA, CNAME, MX, TXT, PTR, SRV)
- **Features**: DNS resolution testing, DNSSEC support, DNS over HTTPS
- **Security**: Secure DNS configurations, DDoS protection
- **Automation**: Automated zone file generation and record management

#### ✉️ **Mail Server Management Module**
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

- Built with modern Bash scripting best practices
- Inspired by infrastructure as code principles
- Designed for DevOps and system administrators
- Community-driven feature development

---

**Ready to manage your Linux servers like a pro?** 🚀

Start with `./setup.sh` and then run `./master.sh` to begin your server management journey!
