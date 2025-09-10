

# 🚀 Linux Server Automation Suite

A comprehensive, production-ready automation framework for Linux server deployment, monitoring, and maintenance. Deploy and manage complete server infrastructure with enterprise-grade reliability.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)

[🌐 View GitHub Pages Documentation](https://anshulyadav32.github.io/linux-server/)

## ✨ Features

- 🏗️ **Complete Infrastructure**: Web server, database, DNS, firewall, SSL, and backup systems
- 🔄 **Automated Updates**: Intelligent dependency-aware update management
- 🩺 **Health Monitoring**: Comprehensive system health checks and diagnostics
- 🛡️ **Security First**: Hardened configurations and security best practices
- 📊 **Production Ready**: Enterprise-grade logging, monitoring, and error handling
- 🎯 **Modular Design**: Install individual components or complete stack

## 🚀 Quick Installation

### One-Command Installation
Deploy the complete server stack with a single command:
```bash
curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-server/main/install.sh | sudo bash
```

### Module-Specific Installation
Install only specific components:
```bash
# Clone repository first
git clone https://github.com/anshulyadav32/linux-server.git
cd linux-server

# Install specific module
sudo ./modules/webserver/install.sh
```

**Available Modules:** webserver, database, dns, firewall, ssl, extra, backup


---

## Manual Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/anshulyadav32/linux-server.git
   cd linux-server
   ```

2. **Make sure you have bash installed.**


3. **(Optional) Review and configure module scripts as needed:**
    - All modules are located in the `modules/` directory.
    - You can inspect or modify individual module scripts before installation.
    - To install only a specific module manually (e.g., DNS):
       ```bash
       bash modules/dns/install.sh
       ```
    - Available modules:
      - `modules/webserver/install.sh`
      - `modules/database/install.sh`
      - `modules/dns/install.sh`
      - `modules/firewall/install.sh`
      - `modules/ssl/install.sh`
      - `modules/backup/install.sh`

4. **Run the main install script:**
   ```bash
   bash install.sh
   ```
   This will install all major modules (webserver, database, dns, firewall, ssl, backup) in parallel and report status.

5. **Run post-installation setup:**
   ```bash
   # Make scripts executable
   chmod +x s3.sh update-server.sh
   
   # Run initial system health check
   sudo ./s3.sh
   ```

---

## 🛠️ Core Management Scripts

### 🩺 s3.sh - System Comprehensive Check
The master health monitoring script that provides enterprise-grade system diagnostics:

```bash
# Complete system health check
sudo ./s3.sh

# Verbose diagnostic output
sudo ./s3.sh --verbose

# Quick system overview
sudo ./s3.sh --fast --summary

# Check specific modules only
sudo ./s3.sh database webserver ssl

# Automated monitoring mode
sudo ./s3.sh --quiet

# Performance benchmarking
sudo ./s3.sh --performance
```

**Key Features:**
- 🔍 **Deep System Analysis**: Comprehensive health checks across all modules
- 📊 **Performance Metrics**: System resource monitoring and benchmarking  
- 🚨 **Intelligent Alerting**: Automated issue detection and reporting
- 📈 **Trend Analysis**: Historical performance tracking
- ⚡ **Fast Scanning**: Quick overview mode for rapid assessment

### 🔄 update-server.sh - Intelligent Update Management
Advanced update management system with dependency resolution:

```bash
# Update entire server stack
sudo ./update-server.sh

# Detailed update process
sudo ./update-server.sh --verbose

# Preview changes (safe testing)
sudo ./update-server.sh --dry-run

# Force update with backup
sudo ./update-server.sh --force --backup

# Update specific modules
sudo ./update-server.sh database webserver ssl

# Emergency rollback
sudo ./update-server.sh --rollback
```

**Key Features:**
- 🎯 **Dependency Resolution**: Intelligent update ordering and conflict resolution
- 🛡️ **Automatic Backups**: Pre-update system state preservation
- 🧪 **Dry-Run Testing**: Preview changes before execution
- 📋 **Change Validation**: Post-update verification and health checks
- ⚡ **Parallel Processing**: Optimized concurrent updates where safe

---

## 🩺 Health Monitoring & Maintenance

### System Comprehensive Check (S3)
Enterprise-grade health monitoring with intelligent diagnostics:

```bash
# Complete system health check
sudo ./s3.sh

# Target specific modules
sudo ./s3.sh database webserver ssl

# Detailed diagnostic output
sudo ./s3.sh --verbose

# Automated monitoring mode
sudo ./s3.sh --quiet

# Quick system overview
sudo ./s3.sh --fast --summary

# Performance benchmarking
sudo ./s3.sh --performance
```

**Advanced Health Features:**
- 🔍 Deep system diagnostics
- 📈 Performance metrics collection  
- 🚨 Intelligent alerting
- 📊 Comprehensive reporting
- ⚡ Fast scanning modes

### Individual Module Health Checks
Each module has its own health check script:

```bash
# Database health check
sudo ./modules/database/check_database.sh

# Web server health check  
sudo ./modules/webserver/check_webserver.sh --verbose

# SSL certificate check
sudo ./modules/ssl/check_ssl.sh

# Firewall status check
sudo ./modules/firewall/check_firewall.sh

# DNS service check
sudo ./modules/dns/check_dns.sh

# Mail server check
sudo ./modules/extra/check_extra.sh

# Backup system check
sudo ./modules/backup/check_backup.sh
```

### 🔄 Intelligent Update Management
Dependency-aware updates with comprehensive safety features:

```bash
# Update entire server stack
sudo ./update-server.sh

# Detailed update process
sudo ./update-server.sh --verbose

# Preview changes (safe testing)
sudo ./update-server.sh --dry-run

# Forced update with backup
sudo ./update-server.sh --force --backup

# Selective module updates
sudo ./update-server.sh database webserver ssl

# Emergency rollback mode
sudo ./update-server.sh --rollback
```

**Update System Features:**
- 🎯 Dependency resolution
- 🛡️ Automatic backups
- 🧪 Dry-run testing
- 📋 Change validation
- ⚡ Parallel processing

### Individual Module Updates
Update individual modules manually:

```bash
# Update specific module
sudo ./modules/webserver/update_webserver.sh

# Update all modules (example loop)
for module in database dns webserver firewall ssl extra backup; do
    sudo ./modules/$module/update_${module}.sh
done
```

### ⏰ Automated Monitoring
Production-ready scheduled monitoring:

```bash
# Add to crontab for automated monitoring
crontab -e

# Daily health checks (6 AM)
0 6 * * * /opt/linux-server/s3.sh --quiet >> /var/log/server_health.log 2>&1

# Weekly comprehensive analysis (Sunday 2 AM)  
0 2 * * 0 /opt/linux-server/s3.sh --verbose >> /var/log/server_health_weekly.log 2>&1

# Monthly update checks (1st of month, 3 AM)
0 3 1 * * /opt/linux-server/update-server.sh --dry-run >> /var/log/update_check.log 2>&1
```

## 📚 Documentation

- 📖 **[Complete S3 Health Check Guide](S3_COMPREHENSIVE_CHECK_GUIDE.md)** - Advanced monitoring documentation
- 🔧 **Module Documentation** - Individual component guides in `modules/*/README.md`
- 🌐 **[GitHub Pages Site](https://anshulyadav32.github.io/linux-server/)** - Web documentation

## 🤝 Contributing

We welcome contributions! Please see our [contributing guidelines](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **GitHub Repository**: [linux-server](https://github.com/anshulyadav32/linux-server)
- **Issues & Support**: [GitHub Issues](https://github.com/anshulyadav32/linux-server/issues)
- **Documentation**: [GitHub Pages](https://anshulyadav32.github.io/linux-server/)

## 💡 System Requirements

- **OS**: Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+
- **Memory**: Minimum 2GB RAM (4GB+ recommended)
- **Storage**: Minimum 10GB free space
- **Network**: Internet connection for package downloads
- **Privileges**: Root or sudo access required

---

*Built with ❤️ for the Linux community. Production-tested and enterprise-ready.*
