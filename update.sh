#!/bin/bash

# System update and dependency installation script for Flask app on EC2
# Compatible with Amazon Linux 2/Ubuntu

set -e

echo "Starting system update and dependency installation..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

echo "Detected OS: $OS"

# Update system packages
if [[ "$OS" == *"Amazon Linux"* ]]; then
    echo "Updating Amazon Linux packages..."
    sudo yum update -y

    # Install Python 3.9+ and development tools
    sudo yum install -y python3 python3-pip python3-devel
    sudo yum install -y gcc gcc-c++ make
    sudo yum install -y git curl wget

    # Install PostgreSQL client libraries
    sudo yum install -y postgresql-devel libpq-devel

elif [[ "$OS" == *"Ubuntu"* ]]; then
    echo "Updating Ubuntu packages..."
    sudo apt-get update -y
    sudo apt-get upgrade -y

    # Install Python 3.9+ and development tools
    sudo apt-get install -y python3 python3-pip python3-venv python3-dev
    sudo apt-get install -y build-essential
    sudo apt-get install -y git curl wget

    # Install PostgreSQL client libraries
    sudo apt-get install -y libpq-dev postgresql-client

else
    echo "Unsupported OS: $OS"
    exit 1
fi

# Upgrade pip
echo "Upgrading pip..."
python3 -m pip install --upgrade pip --user

# Verify installations
echo "Verifying installations..."
python3 --version
pip3 --version

echo "System update and dependency installation completed successfully!"
echo "Next steps:"
echo "1. Run ./env.sh to set up the Python virtual environment"
echo "2. Create your .env file with AWS and database credentials"
echo "3. Run python3 test.py to verify connectivity"
