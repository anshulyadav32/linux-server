# Windows DNS Server Setup Script
# Can be executed directly via: iwr -useb ls.r-u.live/sh/windows-dns-setup.ps1 | iex

Write-Host "====================================================="
Write-Host "  Windows DNS Server Setup - Quick Install"
Write-Host "  From ls.r-u.live"
Write-Host "====================================================="

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Please restart PowerShell as Administrator and try again"
    exit 1
}

# Detect Windows version
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$osVersion = $osInfo.Caption
Write-Host "Detected: $osVersion"

# Install Chocolatey if not already installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey package manager..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    refreshenv
} else {
    Write-Host "Chocolatey already installed. Updating..."
    choco upgrade chocolatey -y
}

# Install Windows DNS Server feature
Write-Host "Installing Windows DNS Server Role..."
Install-WindowsFeature -Name DNS -IncludeManagementTools

# Check if DNS Server was installed successfully
if ((Get-WindowsFeature -Name DNS).InstallState -eq "Installed") {
    Write-Host "DNS Server role installed successfully." -ForegroundColor Green
} else {
    Write-Host "Failed to install DNS Server role." -ForegroundColor Red
    exit 1
}

# Configure basic DNS settings
Write-Host "Configuring basic DNS settings..."

# Create DNS Forward Lookup Zone
$zoneName = Read-Host "Enter the primary zone name to create (e.g., example.com)"
if ($zoneName) {
    Add-DnsServerPrimaryZone -Name $zoneName -ZoneFile "$zoneName.dns"
    Write-Host "Created primary zone: $zoneName" -ForegroundColor Green
    
    # Add some basic records
    Add-DnsServerResourceRecordA -ZoneName $zoneName -Name "www" -IPv4Address "192.168.1.10"
    Add-DnsServerResourceRecordA -ZoneName $zoneName -Name "mail" -IPv4Address "192.168.1.20"
    Add-DnsServerResourceRecordMX -ZoneName $zoneName -Name "." -MailExchange "mail.$zoneName" -Preference 10
    Write-Host "Added basic DNS records to the zone" -ForegroundColor Green
}

# Configure DNS forwarders
$configureForwarders = Read-Host "Would you like to configure DNS forwarders? (y/n)"
if ($configureForwarders -eq "y") {
    Set-DnsServerForwarder -IPAddress 8.8.8.8, 8.8.4.4
    Write-Host "Configured DNS forwarders to use Google DNS (8.8.8.8, 8.8.4.4)" -ForegroundColor Green
}

# Enable DNS logging
$enableLogging = Read-Host "Enable DNS query logging? (y/n)"
if ($enableLogging -eq "y") {
    Set-DnsServerDiagnostics -All $true
    Write-Host "DNS logging enabled" -ForegroundColor Green
}

Write-Host "====================================================="
Write-Host "  Windows DNS Server Setup Complete!"
Write-Host "  Visit ls.r-u.live for more scripts"
Write-Host "====================================================="

Write-Host "Script completed successfully"
