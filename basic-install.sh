#!/bin/bash
# basic-install.sh: Update system and install git, gh (GitHub CLI), and python

set -e

# Update package lists
apt update

# Upgrade installed packages
apt upgrade -y

# Install git
apt install -y git

# Install GitHub CLI (gh)
if ! command -v gh &> /dev/null; then
    type -p curl >/dev/null || apt install curl -y
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    apt update
    apt install gh -y
fi

# Install python3 and pip
apt install -y python3 python3-pip

# Install Docker
if ! command -v docker &> /dev/null; then
    apt install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

echo "Basic install complete: git, gh, python3, pip, and docker installed and system updated."
