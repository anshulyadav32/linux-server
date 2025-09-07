# Windows Mail Server Setup Script
# Can be executed directly via: iwr -useb ls.r-u.live/sh/windows-mail-setup.ps1 | iex

Write-Host "====================================================="
Write-Host "  Windows Mail Server Setup - Quick Install"
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

# Get domain name for mail server
$domainName = Read-Host "Enter your mail domain name (e.g., example.com)"
if (-not $domainName) {
    $domainName = "example.local"
    Write-Host "Using default domain: $domainName"
}

# Install hMailServer (popular open-source mail server for Windows)
Write-Host "Installing hMailServer (mail server)..."
choco install hmailserver -y

# Configure firewall
Write-Host "Configuring firewall rules for mail services..."
New-NetFirewallRule -DisplayName "SMTP" -Direction Inbound -Protocol TCP -LocalPort 25 -Action Allow
New-NetFirewallRule -DisplayName "SMTPS" -Direction Inbound -Protocol TCP -LocalPort 465 -Action Allow
New-NetFirewallRule -DisplayName "Submission" -Direction Inbound -Protocol TCP -LocalPort 587 -Action Allow
New-NetFirewallRule -DisplayName "IMAP" -Direction Inbound -Protocol TCP -LocalPort 143 -Action Allow
New-NetFirewallRule -DisplayName "IMAPS" -Direction Inbound -Protocol TCP -LocalPort 993 -Action Allow
New-NetFirewallRule -DisplayName "POP3" -Direction Inbound -Protocol TCP -LocalPort 110 -Action Allow
New-NetFirewallRule -DisplayName "POP3S" -Direction Inbound -Protocol TCP -LocalPort 995 -Action Allow

# Check if hMailServer is installed
if (Test-Path "C:\Program Files (x86)\hMailServer") {
    Write-Host "hMailServer installed successfully." -ForegroundColor Green
    
    # Set up admin password
    $adminPassword = Read-Host "Enter an administrator password for hMailServer" -AsSecureString
    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword))
    
    # Note: For security reasons, we can't fully automate hMailServer configuration
    # as it requires COM automation, but we'll provide instructions
    
    Write-Host "Please complete the hMailServer configuration manually:" -ForegroundColor Yellow
    Write-Host "1. Open hMailServer Administrator (from Start menu)" -ForegroundColor Yellow
    Write-Host "2. Connect to localhost with the administrator password you just provided" -ForegroundColor Yellow
    Write-Host "3. Add your domain: $domainName" -ForegroundColor Yellow
    Write-Host "4. Configure SMTP, POP3, and IMAP settings as needed" -ForegroundColor Yellow
} else {
    Write-Host "hMailServer installation may have failed. Please check manually." -ForegroundColor Red
}

# Option to install webmail client (Roundcube using IIS)
$installWebmail = Read-Host "Would you like to install Roundcube webmail client? (y/n)"
if ($installWebmail -eq "y") {
    # Install IIS with required features
    Write-Host "Installing IIS and PHP..."
    Install-WindowsFeature -Name Web-Server, Web-Mgmt-Tools, Web-CGI
    
    # Install PHP and MySQL using Chocolatey
    choco install php -y
    choco install mysql -y
    
    Write-Host "Please complete Roundcube installation manually:" -ForegroundColor Yellow
    Write-Host "1. Download Roundcube from https://roundcube.net/download/" -ForegroundColor Yellow
    Write-Host "2. Extract to C:\inetpub\wwwroot\roundcube" -ForegroundColor Yellow
    Write-Host "3. Create a MySQL database for Roundcube" -ForegroundColor Yellow
    Write-Host "4. Follow the Roundcube installer at http://localhost/roundcube/installer/" -ForegroundColor Yellow
}

Write-Host "====================================================="
Write-Host "  Windows Mail Server Setup Complete!"
Write-Host "  Visit ls.r-u.live for more scripts"
Write-Host "====================================================="

Write-Host "Script completed successfully"
