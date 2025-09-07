# Windows Server Setup Script
# Can be executed directly via: iwr -useb ls.r-u.live/sh/windows-setup.ps1 | iex

Write-Host "====================================================="
Write-Host "  Windows Server Setup Script - Quick Install"
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

# Install essential software
Write-Host "Installing essential software..."
choco install git 7zip vscode notepadplusplus chrome-remote-desktop-host -y
choco install sysinternals putty winscp -y

# Configure Windows features
Write-Host "Configuring Windows features..."
# Enable Windows Remote Management
Enable-PSRemoting -Force
# Configure Windows Firewall
Set-NetFirewallRule -DisplayGroup "Remote Desktop" -Enabled True
Set-NetFirewallRule -DisplayGroup "Windows Remote Management" -Enabled True

# Configure Windows Updates
Write-Host "Configuring Windows Updates..."
# Set Windows to automatically download and install updates
$AutoUpdateNotificationLevel = 4 # 4 = Automatically download and install
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -Value $AutoUpdateNotificationLevel

# Configure security settings
Write-Host "Configuring security settings..."
# Enable Windows Defender
Set-MpPreference -DisableRealtimeMonitoring $false
# Enable SmartScreen
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "Prompt"

Write-Host "====================================================="
Write-Host "  Basic Windows setup complete!"
Write-Host "  Visit ls.r-u.live for more scripts"
Write-Host "====================================================="

# Offer to install additional components
$installMore = Read-Host "Would you like to install additional components? (y/n)"
if ($installMore -eq "y") {
    Write-Host "Visit ls.r-u.live for more installation options"
    Write-Host "Try: iwr -useb ls.r-u.live/sh/windows-iis-setup.ps1 | iex"
    Write-Host "Or:  iwr -useb ls.r-u.live/sh/windows-sql-setup.ps1 | iex"
}

Write-Host "Script completed successfully"
