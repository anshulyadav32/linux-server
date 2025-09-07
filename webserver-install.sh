#!/bin/bash
# =============================================================================
# Quick Webserver Module Installer
# =============================================================================
# Usage: curl -sSL ls.r-u.live/webserver-install.sh | sudo bash
# =============================================================================

# Simply redirect to the main installer with webserver parameter
curl -sSL https://raw.githubusercontent.com/anshulyadav32/linux-setup/main/s1.sh | sudo bash -s webserver
