

# linux-server

Automated Linux server setup and configuration scripts for webserver, database, DNS, domain management, firewall, SSL, and backup. Easily deploy and manage all major server modules with a single install command.

[View GitHub Pages site](https://anshulyadav32.github.io/linux-server/)



## Quick Installation (Recommended)




### Quick Remote Install (Recommended):
Run this command in your terminal for a one-line remote install of all modules:
```bash
curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-server/main/s1.sh | bash
```

#### To install only a specific module remotely (e.g., Domain):
```bash
curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-server/main/s1.sh | bash -s domain
```

Available modules: webserver, database, dns, domain, firewall, ssl, backup


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
      - `modules/domain/install.sh`
      - `modules/firewall/install.sh`
      - `modules/ssl/install.sh`
      - `modules/backup/install.sh`

4. **Run the main install script:**
   ```bash
   bash install.sh
   ```
   This will install all major modules (webserver, database, dns, domain, firewall, ssl, backup) in parallel and report status.

5. **Access domain management:**
   After installation, use the domain management interface:
   ```bash
   sudo domain-manager
   ```

---

GitHub Repository: [linux-server](https://github.com/anshulyadav32/linux-server)

---

## Domain Management Features

The domain module provides comprehensive domain management capabilities:

### Key Features:
- **Easy Domain Setup**: Add/remove domains with automatic DNS zone creation
- **DNS Zone Management**: Automated zone file generation and validation
- **Web Server Integration**: Automatic virtual host configuration for Apache/Nginx
- **Domain Health Monitoring**: Check domain status and DNS propagation
- **Bulk Operations**: Import multiple domains from file
- **SSL Integration**: Ready for SSL certificate management
- **Backup & Restore**: Configuration backup and restoration tools

### Quick Domain Operations:
```bash
# Interactive domain management
sudo domain-manager

# Command line operations
sudo domain-manager add example.com
sudo domain-manager remove example.com
sudo domain-manager list
sudo domain-manager check example.com
```

### Domain Management Menu:
1. Add Domain - Create new domain with DNS zone and web configuration
2. Remove Domain - Clean removal of domain and all configurations
3. List Domains - View all configured domains
4. Check Domain - Health check and DNS verification
5. DNS Management - DNS service operations and configuration
6. Domain Tools - Whois, propagation checks, SSL verification

---

## Notes
- Ensure you have the necessary permissions to execute scripts.
- Some modules may require additional dependencies. Check each module's script for details.
- For troubleshooting, refer to the logs or output from the install scripts.
