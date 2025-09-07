# Server Setup Scripts

A collection of scripts for automating server setup and configuration across different operating systems.

## 📁 Repository Structure

- [`setup-server/`](./setup-server/) - Scripts for server setup and configuration
  - [`setup.sh`](./setup-server/setup.sh) - Ubuntu/Debian server setup script with checkpoints

## 🚀 Ubuntu/Debian Setup Script

The `setup.sh` script automates the installation and configuration of essential server software on Ubuntu/Debian-based systems.

### Features

- ✅ **Built-in checkpoints** to verify successful installations
- 🔍 **Distribution detection** to ensure compatibility
- 📊 **Status messages** for each installation step
- 🛑 **Error handling** that stops execution if something fails
- 🔄 **Update verification** to ensure system is fully updated

### Included Software

- Git and GitHub CLI
- Node.js (LTS version)
- PostgreSQL and MySQL databases
- Docker with Docker Compose
- Fail2Ban for security
- Roundcube webmail with dependencies
- SSL tools (OpenSSL and Certbot)
- SSH server and client
- Terminal utilities (zsh, tmux, htop, etc.)

### Usage

```bash
# Make the script executable
chmod +x setup-server/setup.sh

# Run the script
./setup-server/setup.sh
```

## 🔒 Security Features

- Fail2Ban installation for brute force protection
- SSL setup with Certbot for HTTPS
- SSH server configuration

## 📋 Post-Installation Tasks

After running the script, you should:

1. Reboot or run `newgrp docker` to use Docker without sudo
2. Configure Roundcube with your database and Apache setup
3. Set up Fail2Ban jail rules in `/etc/fail2ban/jail.local`

## 🛠️ Requirements

- Ubuntu, Debian, Linux Mint, or Pop!_OS
- Root/sudo access
