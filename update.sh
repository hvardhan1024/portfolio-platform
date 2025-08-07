#!/bin/bash

# update.sh - System update and dependency installation script

echo "Starting system update and dependency installation..."

# Update system packages
sudo apt update -y
sudo apt upgrade -y

# Install Python and pip
sudo apt install python3 python3-pip python3-venv -y

# Install PostgreSQL client (for database connectivity testing)
sudo apt install postgresql-client -y

# Install Git (in case it's not installed)
sudo apt install git -y

# Install other essential packages
sudo apt install curl wget unzip -y

# Install AWS CLI v2
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI v2..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws/
else
    echo "AWS CLI already installed"
fi

# Verify installations
echo "Verifying installations..."
python3 --version
pip3 --version
aws --version
psql --version

echo "System update and dependency installation completed successfully!"
echo "Next step: Run ./env.sh to set up the virtual environment"
