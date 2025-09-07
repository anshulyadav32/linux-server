# BIND DNS Server Setup

This directory contains scripts for setting up and configuring BIND DNS servers in different roles.

## 📋 Setup Script Features

The `setup-dns.sh` script automates the installation and configuration of BIND DNS server in various roles:

- **Master/Primary DNS Server** - Authoritative DNS server for your domain
- **Slave/Secondary DNS Server** - Backup DNS server that replicates from a master
- **Caching-only DNS Server** - Non-authoritative DNS server that improves lookup speed

## 🚀 Usage

```bash
# Setup as a Master/Primary DNS server
./setup-dns.sh --domain example.com --server-ip 192.168.1.10

# Setup as a Slave/Secondary DNS server
./setup-dns.sh --setup-slave --domain example.com --master-dns 192.168.1.10

# Setup as a Caching-only DNS server
./setup-dns.sh --setup-caching --forwarders "8.8.8.8;1.1.1.1"

# Setup for internal network with specific options
./setup-dns.sh --domain internal.example --server-ip 10.0.0.1 --internal --allow-transfer "10.0.0.2;10.0.0.3"
```

## 🔧 Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `--domain` | Primary domain name for DNS server | Required for master/slave |
| `--server-ip` | Server IP address | Auto-detect for master |
| `--forwarders` | DNS forwarders (semicolon-separated) | 8.8.8.8;8.8.4.4 |
| `--setup-master` | Setup as master/primary DNS server | Default if not specified |
| `--setup-slave` | Setup as slave/secondary DNS server | - |
| `--setup-caching` | Setup as caching-only DNS server | - |
| `--no-dnssec` | Disable DNSSEC validation | DNSSEC enabled by default |
| `--master-dns` | Master DNS IP | Required for slave setup |
| `--internal` | Configure for internal network use only | - |
| `--port` | DNS port | 53 |
| `--allow-transfer` | IPs allowed for zone transfers | - |
| `--listen-on` | Address to listen on | any |
| `--help` | Show help message | - |

## 📝 DNS Server Types

### Master/Primary DNS Server
The authoritative source for your domain's DNS records. It contains the original zone files that define all DNS records for your domain.

### Slave/Secondary DNS Server
Provides redundancy by replicating zone data from a master server. It automatically updates itself when changes are made on the master.

### Caching-only DNS Server
Improves DNS lookup performance for clients by caching results from previous queries. It doesn't host any zones of its own.

## 🔒 Security Features

- DNSSEC validation for improved security
- IP-based access control for zone transfers
- Hidden BIND version to prevent fingerprinting
- Firewall configuration for DNS ports
- Recursive query restrictions

## 📊 Supported Distributions

- Ubuntu 18.04/20.04/22.04
- Debian 10/11/12
- Linux Mint (based on Ubuntu)
- Pop!_OS (based on Ubuntu)
