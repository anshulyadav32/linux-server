# Enhanced Mail Server Setup Guide

This folder contains scripts and templates for setting up a complete mail server with multiple component options for SMTP, IMAP/POP3, and webmail.

## 📋 Setup Script Features

The `setup-mail.sh` script automates the installation and configuration of a complete mail server with:

- **SMTP Server Options**:
  - Postfix (default) - Full-featured SMTP server
  - Support for additional SMTP servers

- **IMAP/POP3 Server Options**:
  - Dovecot (default) - Modern, secure IMAP/POP3 server
  - Courier - Alternative IMAP/POP3 server

- **Webmail Options**:
  - Roundcube (default) - Modern, feature-rich webmail client
  - SquirrelMail - Lightweight alternative webmail

- **Additional Components**:
  - msmtp - Mail sending client
  - SpamAssassin - Anti-spam filtering
  - ClamAV - Anti-virus scanning
  - OpenDKIM - DKIM signing for improved deliverability

## 🚀 Usage

```bash
# Basic usage with defaults (Postfix + Dovecot + Roundcube)
./setup-mail.sh --domain example.com

# Using Courier instead of Dovecot
./setup-mail.sh --domain example.com --imap-server courier

# Using SquirrelMail instead of Roundcube
./setup-mail.sh --domain example.com --webmail-type squirrelmail

# Full configuration with multiple options
./setup-mail.sh \
  --domain example.com \
  --hostname mail.example.com \
  --admin-email admin@example.com \
  --imap-server courier \
  --webmail-type roundcube \
  --install-msmtp \
  --server-type full
```

## 🔧 Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `--domain` | Primary domain name (required) | - |
| `--hostname` | Server hostname | mail.DOMAIN |
| `--admin-email` | Admin email address | postmaster@DOMAIN |
| `--no-mysql` | Don't use MySQL | Uses MySQL by default |
| `--use-postgres` | Use PostgreSQL | Uses MySQL by default |
| `--no-webmail` | Don't install webmail | Installs webmail by default |
| `--webmail-type` | Webmail type: roundcube, squirrelmail | roundcube |
| `--imap-server` | IMAP server: dovecot, courier | dovecot |
| `--smtp-server` | SMTP server: postfix, exim | postfix |
| `--install-msmtp` | Install msmtp mail client | Not installed by default |
| `--no-dkim` | Don't configure DKIM | Configures DKIM by default |
| `--no-spf` | Don't configure SPF | Configures SPF by default |
| `--no-dmarc` | Don't configure DMARC | Configures DMARC by default |
| `--no-antispam` | Don't install anti-spam | Installs anti-spam by default |
| `--no-antivirus` | Don't install anti-virus | Installs anti-virus by default |
| `--server-type` | Server type: full, relay, incoming | full |
| `--help` | Show help message | - |

## 📝 Component Combinations

| Setup Type | SMTP Server | IMAP Server | Webmail |
|------------|-------------|------------|---------|
| Default | Postfix | Dovecot | Roundcube |
| Alternative | Postfix | Courier | SquirrelMail |
| Minimal | Postfix | Dovecot | None |
| Custom | Your choice | Your choice | Your choice |

## 📝 Post-Installation Steps

After running the script, you should:

1. **Add DNS Records**:
   - MX record pointing to your mail server
   - SPF record to prevent email spoofing
   - DKIM record for email signing verification
   - DMARC record for reporting and policy

2. **Configure SSL/TLS**:
   ```bash
   sudo certbot --apache -d mail.example.com
   ```

3. **Change Default Password**:
   ```bash
   sudo nano /etc/dovecot/users
   # Replace the password hash with a new one
   ```

4. **Test Email Delivery**:
   - Send a test email to an external address
   - Check the configuration using [mail-tester.com](https://www.mail-tester.com/)

## 📋 Configuration Templates

See the `config-templates.md` file for example configuration templates for:
- Postfix main.cf
- Dovecot configuration files
- SpamAssassin local.cf
- OpenDKIM configuration
- DNS record examples

## 🔒 Security Considerations

- Always change default passwords immediately
- Keep all software updated
- Configure firewall to only allow necessary ports
- Set up monitoring and alerting
- Regularly backup mail data and configuration

## 📊 Supported Distributions

- Ubuntu 18.04/20.04/22.04
- Debian 10/11/12
- Linux Mint (based on Ubuntu)
- Pop!_OS (based on Ubuntu)
