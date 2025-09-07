# Modular Server Management System

A comprehensive, professional-grade server management system built with modular Bash scripts for Linux server administration. This system provides a cohesive design with standardized interfaces, shared libraries, and automated workflows for complete server setup and maintenance.

## 🚀 Features

### Core Architecture
- **Modular Design**: 8 specialized service modules with standardized interfaces
- **Shared Library**: Common functions for logging, validation, and user interaction
- **Interdependent Automation**: Pre-configured workflows for complex server setups
- **Professional UI**: Color-coded menus with comprehensive error handling

### Service Modules

#### 🌐 Web Server Management
- Apache & Nginx installation and configuration
- PHP, Node.js, and Python support
- Virtual host management
- SSL integration
- Performance optimization

#### 🌍 DNS Server Management
- BIND9 installation and configuration
- Zone creation and management
- DNS record operations (A, AAAA, CNAME, MX, TXT, PTR, SRV)
- DNS resolution testing
- DNSSEC and DNS over HTTPS support

#### ✉️ Mail Server Management
- Postfix & Dovecot installation
- DKIM, SPF, and DMARC configuration
- Mail user and domain management
- Security hardening
- Spam and virus protection

#### 🗄️ Database Management
- MySQL & PostgreSQL support
- Database and user creation
- Backup and restore operations
- Performance monitoring
- Security configuration

#### 🔥 Firewall Management
- UFW (Uncomplicated Firewall) configuration
- Fail2Ban intrusion prevention
- Port management
- Security rule templates
- Attack monitoring

#### 🔒 SSL Certificate Management
- Let's Encrypt automation
- Self-signed certificate generation
- Certificate renewal automation
- Multiple domain support
- Security best practices

#### ⚙️ System Administration
- User and group management
- Package management
- System monitoring
- Performance optimization
- Security hardening

#### 💾 Backup Management
- Automated backup scheduling
- System, database, and file backups
- Remote backup synchronization
- Restore operations
- Disaster recovery planning

## 📁 Directory Structure

```
script/
├── master.sh                    # Main entry point
├── setup.sh                     # Initial system setup
├── QUICK_START.md               # Quick start guide
├── README.md                    # This file
├── logs/                        # System logs
├── backups/                     # Backup storage
├── configs/                     # Configuration files
└── modules/
    ├── common.sh                # Shared library
    ├── interdependent.sh        # Automation workflows
    ├── web/
    │   ├── functions.sh         # Web module functions
    │   ├── install.sh           # Installation script
    │   ├── maintain.sh          # Maintenance operations
    │   ├── update.sh            # Update operations
    │   └── menu.sh              # Interactive menu
    ├── dns/
    │   ├── functions.sh         # DNS module functions
    │   ├── install.sh           # Installation script
    │   ├── maintain.sh          # Maintenance operations
    │   ├── update.sh            # Update operations
    │   └── menu.sh              # Interactive menu
    ├── mail/
    │   ├── functions.sh         # Mail module functions
    │   ├── install.sh           # Installation script
    │   ├── maintain.sh          # Maintenance operations
    │   ├── update.sh            # Update operations
    │   └── menu.sh              # Interactive menu
    ├── db/
    │   ├── functions.sh         # Database module functions
    │   ├── install.sh           # Installation script
    │   ├── maintain.sh          # Maintenance operations
    │   ├── update.sh            # Update operations
    │   └── menu.sh              # Interactive menu
    ├── firewall/
    │   ├── functions.sh         # Firewall module functions
    │   ├── install.sh           # Installation script
    │   ├── maintain.sh          # Maintenance operations
    │   ├── update.sh            # Update operations
    │   └── menu.sh              # Interactive menu
    ├── ssl/
    │   ├── functions.sh         # SSL module functions
    │   ├── install.sh           # Installation script
    │   ├── maintain.sh          # Maintenance operations
    │   ├── update.sh            # Update operations
    │   └── menu.sh              # Interactive menu
    ├── system/
    │   ├── functions.sh         # System module functions
    │   ├── install.sh           # Installation script
    │   ├── maintain.sh          # Maintenance operations
    │   ├── update.sh            # Update operations
    │   └── menu.sh              # Interactive menu
    └── backup/
        ├── functions.sh         # Backup module functions
        ├── install.sh           # Installation script
        ├── maintain.sh          # Maintenance operations
        ├── update.sh            # Update operations
        └── menu.sh              # Interactive menu
```

## 🛠️ Installation

### Prerequisites
- Ubuntu 18.04+ or Debian 10+ (recommended)
- Root or sudo access
- Internet connectivity
- Basic understanding of Linux server administration

### Quick Install

1. **Clone or download the repository:**
   ```bash
   git clone <your-repo-url> server-management
   cd server-management
   ```

2. **Run the setup script:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Start the main menu:**
   ```bash
   ./master.sh
   ```

## 🚀 Quick Start

### Basic Usage

1. **Main Menu Access:**
   ```bash
   ./master.sh
   ```
   - Interactive main menu with all modules
   - System prerequisites check
   - Color-coded navigation

2. **Individual Module Access:**
   ```bash
   ./modules/web/menu.sh      # Web server management
   ./modules/dns/menu.sh      # DNS management
   ./modules/mail/menu.sh     # Mail server management
   # ... etc for other modules
   ```

3. **Automated Workflows:**
   ```bash
   ./modules/interdependent.sh
   ```
   - Pre-configured server setups
   - LAMP/LEMP stack installation
   - Complete mail server setup
   - Full website deployment

### Common Tasks

#### Deploy a LAMP Stack
1. Run `./master.sh`
2. Choose "Interdependent Automation"
3. Select "Full LAMP Stack Setup"
4. Follow the prompts for domain and database configuration

#### Setup a Mail Server
1. Run `./master.sh`
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
