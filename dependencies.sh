#!/bin/bash

# setup.sh: Script to update Ubuntu and install dependencies for the Flask portfolio application

# Exit on any error
set -e

echo "=== Starting Ubuntu Update and Dependency Installation ==="

# Update Ubuntu package lists and upgrade installed packages
echo "🔄 Updating Ubuntu..."
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
sudo apt autoclean

# Install Python 3 and pip
echo "🐍 Installing Python 3 and pip..."
sudo apt install -y python3 python3-pip python3-venv

# Verify Python and pip versions
python3 --version
pip3 --version

# Install dependencies for PostgreSQL client, curl, and openssl
echo "🛠️ Installing system dependencies (postgresql-client, curl, openssl)..."
sudo apt install -y postgresql-client curl openssl

# Verify installations
if ! command -v psql &> /dev/null; then
    echo "❌ Error: psql installation failed"
    exit 1
fi
if ! command -v curl &> /dev/null; then
    echo "❌ Error: curl installation failed"
    exit 1
fi
if ! command -v openssl &> /dev/null; then
    echo "❌ Error: openssl installation failed"
    exit 1
fi
echo "✅ System dependencies installed successfully"

# Check if requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    echo "❌ Error: requirements.txt not found in the current directory"
    exit 1
fi

# Install Python dependencies from requirements.txt
echo "📦 Installing Python dependencies from requirements.txt..."
pip3 install -r requirements.txt

# Verify Python dependencies
echo "🔍 Verifying Python dependencies..."
for pkg in Flask Flask-SQLAlchemy psycopg2-binary boto3 python-dotenv bcrypt; do
    if pip3 show "$pkg" > /dev/null; then
        echo "✅ $pkg is installed"
    else
        echo "❌ Error: $pkg installation failed"
        exit 1
    fi
done

echo -e "\n=== Setup Summary ==="
echo "✅ Ubuntu updated successfully"
echo "✅ Python 3 and pip installed"
echo "✅ System dependencies (postgresql-client, curl, openssl) installed"
echo "✅ Python dependencies installed from requirements.txt"
echo "✅ Setup completed successfully! You can now run './test.sh' and 'python3 app.py'"
