# 🐧 WSL (Windows Subsystem for Linux) Setup Guide

Complete guide for running the Linux Server Automation Suite in WSL (Windows Subsystem for Linux) environment.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Setup](#quick-setup)
- [WSL Root Access](#wsl-root-access)
- [Line Ending Issues](#line-ending-issues)
- [Installation Methods](#installation-methods)
- [Common Issues](#common-issues)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## 🔧 Prerequisites

### WSL Installation
Ensure you have WSL installed on your Windows system:

```powershell
# Install WSL (Windows 10 version 2004+ or Windows 11)
wsl --install

# Or install specific distribution
wsl --install -d Ubuntu
```

### Required Components
- **WSL 2** (recommended over WSL 1)
- **Ubuntu 18.04+**, Debian 9+, or compatible Linux distribution
- **Root/sudo access** in WSL
- **Internet connection** for package downloads

## 🚀 Quick Setup

### Method 1: Automated Setup (Recommended)

Clone the repository and run the WSL setup script:

```bash
# In WSL terminal
git clone https://github.com/anshulyadav32/linux-server.git
cd linux-server

# Run automated WSL setup
./scripts/wsl-setup.sh setup
```

This will:
- ✅ Install required dependencies (including `dos2unix`)
- ✅ Fix any line ending issues in scripts
- ✅ Make all scripts executable
- ✅ Configure WSL-specific settings
- ✅ Provide quick-start commands

### Method 2: Manual Setup

```bash
# Clone repository
git clone https://github.com/anshulyadav32/linux-server.git
cd linux-server

# Fix line endings (if needed)
./scripts/fix-line-endings.sh

# Make scripts executable
find . -name "*.sh" -type f -exec chmod +x {} \;

# Install server components
sudo ./install.sh
```

## 👑 WSL Root Access

The Linux Server Automation Suite requires root privileges for most operations. WSL provides several ways to access root:

### Method 1: Switch to Root in Current Session
```bash
# Switch to root user interactively
sudo -i

# Or use the helper script
./scripts/wsl-setup.sh root
```

### Method 2: Start WSL as Root (from Windows)
```powershell
# From Windows PowerShell or Command Prompt
wsl -u root

# Or for specific distribution
wsl -d Ubuntu -u root
```

### Method 3: Run Single Commands as Root
```bash
# Run specific script as root
sudo ./s3.sh

# Or use helper commands
./scripts/wsl-setup.sh check    # Health check as root
./scripts/wsl-setup.sh install  # Install as root
./scripts/wsl-setup.sh update   # Update as root
```

## 🔄 Line Ending Issues

### The Problem
When editing shell scripts on Windows, text editors may save files with Windows-style line endings (CRLF: `\r\n`) instead of Unix-style line endings (LF: `\n`). This causes scripts to fail in WSL with errors like:

```
$'\r': command not found
```

### The Solution

#### Automatic Fix (Recommended)
```bash
# Fix all shell scripts in the project
./scripts/fix-line-endings.sh

# Fix scripts in specific directory
./scripts/fix-line-endings.sh /path/to/directory

# Preview what would be fixed (dry run)
./scripts/fix-line-endings.sh --dry-run

# Verbose output
./scripts/fix-line-endings.sh --verbose
```

#### Manual Fix Options

**Option 1: Using dos2unix (if installed)**
```bash
# Install dos2unix
sudo apt-get update && sudo apt-get install -y dos2unix

# Convert all shell scripts
find . -name "*.sh" -type f -exec dos2unix {} \;

# Convert specific file
dos2unix script-name.sh
```

**Option 2: Using sed**
```bash
# Convert all shell scripts
find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;

# Convert specific file
sed -i 's/\r$//' script-name.sh
```

### Prevention in Editors

**Visual Studio Code:**
1. Open the `.sh` file
2. Look at bottom-right corner for line ending indicator
3. Click on "CRLF" and change to "LF"
4. Save the file

**Configure VS Code globally:**
```json
{
    "files.eol": "\n",
    "files.associations": {
        "*.sh": "shellscript"
    }
}
```

## 📦 Installation Methods

### Complete Installation
```bash
# Automated installation with WSL setup
./scripts/wsl-setup.sh install

# Or traditional method
sudo ./install.sh
```

### Module-Specific Installation
```bash
# Install only web server
sudo ./modules/webserver/install.sh

# Install only database
sudo ./modules/database/install.sh

# Available modules: webserver, database, dns, firewall, ssl, extra, backup
```

### One-Line Installation (from internet)
```bash
# Complete installation
curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-server/main/install.sh | sudo bash

# Note: Fix line endings first if you encounter issues
```

## 🔧 Common Issues

### Issue 1: Permission Denied
```bash
# Error: Permission denied when running scripts
chmod +x script-name.sh

# Or fix all scripts
find . -name "*.sh" -type f -exec chmod +x {} \;
```

### Issue 2: Command Not Found Errors
```bash
# Error: $'\r': command not found
./scripts/fix-line-endings.sh

# Or manually
dos2unix script-name.sh
```

### Issue 3: Package Installation Failures
```bash
# Update package lists first
sudo apt-get update

# Then retry installation
sudo ./install.sh
```

### Issue 4: WSL Network Issues
```bash
# Reset WSL networking
# From Windows PowerShell (as Administrator):
wsl --shutdown
netsh winsock reset
netsh int ip reset all
netsh winhttp reset proxy

# Restart WSL
wsl
```

## ✅ Best Practices

### 1. Always Use LF Line Endings
- Configure your editor to use Unix line endings for `.sh` files
- Run line ending fixes after editing scripts on Windows
- Use the provided `fix-line-endings.sh` script regularly

### 2. Use Root Access Appropriately
- Use `sudo` for individual commands when possible
- Switch to root (`sudo -i`) for multiple administrative tasks
- Use `wsl -u root` from Windows for direct root access

### 3. Keep Scripts Executable
```bash
# Make scripts executable after cloning/editing
chmod +x *.sh
find . -name "*.sh" -type f -exec chmod +x {} \;
```

### 4. Regular Updates
```bash
# Update the automation suite
./scripts/wsl-setup.sh update

# Or manually
sudo ./update-server.sh
```

### 5. Monitor System Health
```bash
# Regular health checks
./scripts/wsl-setup.sh check

# Or manually
sudo ./s3.sh
```

## 🐛 Troubleshooting

### Debug Mode
Enable verbose logging for troubleshooting:

```bash
# Verbose WSL setup
./scripts/wsl-setup.sh --verbose setup

# Verbose line ending fix
./scripts/fix-line-endings.sh --verbose

# Verbose health check
sudo ./s3.sh --verbose
```

### Check WSL Version
```bash
# Check WSL version
wsl -l -v

# Upgrade to WSL 2 if needed (from Windows PowerShell)
wsl --set-version Ubuntu 2
```

### Verify Environment
```bash
# Check if running in WSL
uname -a | grep -i microsoft

# Check distribution
cat /etc/os-release

# Check available disk space
df -h

# Check memory
free -h
```

### Log Files
Check log files for detailed error information:

```bash
# System logs
sudo journalctl -xe

# Installation logs (if any errors occur)
ls -la /var/log/
```

## 🚀 Quick Commands Reference

```bash
# Setup and access
./scripts/wsl-setup.sh setup      # Complete WSL setup
./scripts/wsl-setup.sh root       # Switch to root
wsl -u root                       # Start WSL as root (from Windows)

# Fix issues
./scripts/fix-line-endings.sh     # Fix line endings
chmod +x *.sh                     # Make scripts executable

# Operations
./scripts/wsl-setup.sh install    # Install server stack
./scripts/wsl-setup.sh check      # System health check
./scripts/wsl-setup.sh update     # Update server

# Manual operations
sudo ./install.sh                 # Manual installation
sudo ./s3.sh                      # Manual health check
sudo ./update-server.sh           # Manual update
```

## 📚 Additional Resources

- **[Main README](../README.md)** - Complete project documentation
- **[S3 Health Check Guide](../S3_COMPREHENSIVE_CHECK_GUIDE.md)** - Advanced monitoring
- **[Contributing Guidelines](../CONTRIBUTING.md)** - How to contribute
- **[WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)** - Official Microsoft WSL docs

---

## 💡 Tips for WSL Users

1. **Use Windows Terminal** for better WSL experience
2. **Mount Windows drives** are available at `/mnt/c/`, `/mnt/d/`, etc.
3. **File permissions** may behave differently between Windows and WSL filesystems
4. **Performance** is better when working within the WSL filesystem (`/home/`)
5. **Backup important data** as WSL environments can be reset

---

*Built with ❤️ for the WSL and Linux community. Tested on Windows 10/11 with WSL 2.*