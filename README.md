

# linux-server

Automated Linux server setup and configuration scripts for webserver, database, DNS, firewall, SSL, and backup. Easily deploy and manage all major server modules with a single install command.

[View GitHub Pages site](https://anshulyadav32.github.io/linux-server/)



## Quick Installation (Recommended)




### Quick Remote Install (Recommended):
Run this command in your terminal for a one-line remote install of all modules:
```bash
curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-server/main/s1.sh | bash
```

#### To install only a specific module remotely (e.g., DNS):
```bash
curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-server/main/s1.sh | bash -s dns
```

Available modules: webserver, database, dns, firewall, ssl, backup


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

5. **Run comprehensive system health check:**
   ```bash
   chmod +x s3.sh
   sudo ./s3.sh
   ```

6. **Update server components:**
   ```bash
   chmod +x update-server.sh
   sudo ./update-server.sh
   ```

---

## Health Monitoring & Maintenance

### System Comprehensive Check (S3)
The `s3.sh` script provides a master health check that runs all module checks:

```bash
# Check all modules
sudo ./s3.sh

# Check specific modules
sudo ./s3.sh database webserver ssl

# Verbose mode for detailed output
sudo ./s3.sh --verbose

# Quiet mode for automated scripts
sudo ./s3.sh --quiet

# Fast mode for quick overview
sudo ./s3.sh --fast --summary
```

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

### Server Updates
Update all server components with the master update script:

```bash
# Update all modules
sudo ./update-server.sh

# Update with verbose output
sudo ./update-server.sh --verbose

# Dry run to see what would be updated
sudo ./update-server.sh --dry-run

# Force update with system backup
sudo ./update-server.sh --force --backup

# Update specific modules only
sudo ./update-server.sh database webserver ssl
```

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

### Scheduled Health Monitoring
Add to crontab for automated monitoring:

```bash
# Daily health check at 6 AM
0 6 * * * /path/to/linux-server/s3.sh --quiet >> /var/log/server_health.log 2>&1

# Weekly comprehensive check
0 2 * * 0 /path/to/linux-server/s3.sh --verbose >> /var/log/server_health_weekly.log 2>&1
```

---

GitHub Repository: [linux-server](https://github.com/anshulyadav32/linux-server)

---

## Notes
- Ensure you have the necessary permissions to execute scripts.
- Some modules may require additional dependencies. Check each module's script for details.
- For troubleshooting, refer to the logs or output from the install scripts.
