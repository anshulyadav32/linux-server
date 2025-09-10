# Domain Management Module

The Domain Management Module provides comprehensive domain administration capabilities for the Linux Server project. It integrates seamlessly with the existing DNS and webserver modules to provide a complete domain hosting solution.

## Features

### Core Functionality
- **Domain Addition/Removal**: Easy setup and teardown of domain configurations
- **DNS Zone Management**: Automated BIND zone file creation and management
- **Web Server Integration**: Automatic virtual host configuration for Apache/Nginx
- **Domain Validation**: Built-in domain format validation and health checks
- **CLI & Interactive Interfaces**: Both command-line and menu-driven operations

### Advanced Tools
- **Health Monitoring**: Domain status checks and DNS propagation verification
- **Maintenance Tools**: Zone optimization, backup/restore, serial number management
- **Bulk Operations**: Import multiple domains from file
- **DNS Tools**: Whois lookup, propagation checking across multiple DNS servers
- **SSL Integration**: Ready for SSL certificate management (integrates with SSL module)

## Installation

The domain module is included in the main linux-server installation:

```bash
# Full installation (includes domain module)
curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-server/main/s1.sh | bash

# Install only domain module
curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-server/main/s1.sh | bash -s domain
```

Or manually:
```bash
sudo bash modules/domain/install.sh
```

## Usage

### Interactive Interface
```bash
sudo domain-manager
```

This opens a full-featured menu system with options for:
1. Add Domain
2. Remove Domain  
3. List Domains
4. Check Domain
5. DNS Management
6. Domain Tools

### Command Line Interface

#### Basic Operations
```bash
# Add a new domain
sudo domain-manager add example.com

# Add domain with specific IP
sudo domain-manager add example.com 192.168.1.100

# Remove a domain
sudo domain-manager remove example.com

# List all configured domains
sudo domain-manager list

# Check domain health and status
sudo domain-manager check example.com
```

#### Domain Addition Process
When adding a domain, the system automatically:

1. **Creates DNS Zone**: Generates BIND zone file with SOA, NS, and A records
2. **Updates BIND Config**: Adds zone configuration to named.conf.local
3. **Creates Web Config**: Sets up Apache/Nginx virtual host
4. **Document Root**: Creates web directory with default index page
5. **Permissions**: Sets proper file/directory permissions
6. **Validation**: Validates all configurations
7. **Service Reload**: Reloads DNS and web services

#### Domain Removal Process
When removing a domain:

1. **Backup Creation**: Creates backup of current configuration
2. **DNS Cleanup**: Removes zone files and BIND configuration
3. **Web Cleanup**: Removes virtual host configurations
4. **Service Reload**: Reloads affected services
5. **Verification**: Confirms successful removal

## Configuration

### Default Settings
The module uses these default configurations:

- **Zone Directory**: `/etc/bind/zones`
- **BIND Config**: `/etc/bind/named.conf.local`
- **Web Root**: `/var/www/[domain]`
- **Templates**: `/etc/domain-manager/templates`
- **Backups**: `/var/lib/domain-manager/backups`

### Templates

The system includes DNS record templates:

- **A Record Template**: Basic domain with A, NS, SOA records
- **CNAME Template**: For subdomain aliases
- **MX Template**: For mail server records

### Customization

Edit `/etc/domain-manager/config` to customize:

```bash
# DNS Settings
DEFAULT_TTL=86400
DEFAULT_NS=ns1
DNS_SERVICE=bind9

# Web Server Settings  
WEB_SERVICE=apache2
DEFAULT_WEBROOT=/var/www

# SSL Settings
SSL_CERT_DIR=/etc/ssl/certs
SSL_KEY_DIR=/etc/ssl/private
```

## Maintenance

### Domain Health Monitoring
```bash
sudo domain-manager check [domain]
```

Performs comprehensive health checks:
- DNS resolution verification
- Zone file syntax validation  
- Web server response check
- Configuration consistency check

### Backup Operations
```bash
# Access maintenance menu
sudo bash modules/domain/maintain.sh
```

Maintenance options include:
- Configuration backups
- Zone file optimization
- Log cleanup
- Serial number updates
- DNS propagation checks

### Bulk Import
Create a file with one domain per line:
```
example.com
mysite.org
testdomain.net
```

Then import:
```bash
sudo domain-manager
# Select "6) Domain Tools" → "4) Bulk Domain Import"
```

## Integration

### DNS Module Integration
- Uses existing BIND9 installation and configuration
- Manages zone files in standard BIND format
- Integrates with DNS module maintenance tools

### Webserver Module Integration  
- Creates virtual hosts for Apache/Nginx
- Uses existing web server configurations
- Supports both Apache and Nginx simultaneously

### SSL Module Integration
- Prepares domains for SSL certificate installation
- Compatible with Let's Encrypt and custom certificates
- Maintains SSL configuration structure

### Backup Module Integration
- Domain configurations included in system backups
- Separate domain-specific backup functionality
- Restoration capabilities for domain configs

## Troubleshooting

### Common Issues

**Domain not resolving**:
1. Check zone file syntax: `named-checkzone domain.com /etc/bind/zones/db.domain.com`
2. Verify BIND configuration: `named-checkconf`
3. Check DNS service: `systemctl status bind9`

**Web server not responding**:
1. Check virtual host configuration
2. Verify document root permissions
3. Check web server error logs

**Permission denied errors**:
- Ensure running commands with sudo
- Check file/directory permissions in `/etc/bind` and `/var/www`

### Logs
- Domain Manager: `/var/log/domain-manager.log`
- BIND: `/var/log/syslog` (search for 'named' or 'bind')
- Apache: `/var/log/apache2/error.log`
- Nginx: `/var/log/nginx/error.log`

## Security Considerations

- Always run with appropriate privileges (sudo)
- Zone files are readable by BIND user only
- Web directories have restricted permissions
- Configuration backups are protected
- Domain validation prevents malformed entries

## Dependencies

The domain module requires:
- BIND9 (installed by DNS module)
- Apache2 or Nginx (installed by webserver module)  
- Standard utilities: dig, whois, curl, jq

## File Structure

```
modules/domain/
├── install.sh          # Module installer
├── manage.sh           # Main management interface
├── maintain.sh         # Maintenance tools
└── README.md           # This documentation

/etc/domain-manager/
├── config              # Main configuration
├── templates/          # DNS record templates
└── logs/              # Operation logs

/var/lib/domain-manager/
├── configs/           # Domain configurations  
└── backups/           # Configuration backups
```

## Support

For issues or questions:
1. Check logs for error messages
2. Verify all dependencies are installed
3. Run domain health checks
4. Review this documentation
5. Check the main project repository for updates

The domain management module seamlessly extends the linux-server project with professional-grade domain hosting capabilities.